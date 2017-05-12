use strict;
use warnings;
use Time::HiRes      qw/time/;
use Math::Random::MT qw/rand irand/;
use lib "../blib/lib";
use Hash::Type;

sub elapsed_cpu_time (&);

my ($impl, $n_chars, $n_keys, $n_records) = @ARGV;

if ($impl eq 'all') {
  # recursive call for each implementation, in separate suprocesses
  print_headers();
  foreach my $impl (qw/HCore HType HOrd IxHash HIndexed/) {
    system "perl $0 $impl $n_chars $n_keys $n_records";
  }
  exit;
}

# generate $n_keys random keys of $n_chars
my %keys_gen;
while ($n_keys > values %keys_gen) {
  my $key = join "", map {chr(32 + int(rand(95)))} 1 .. $n_chars;
  $keys_gen{$key} += 1;
}
my @keys   = values %keys_gen;


my $records;

# create the list of hashes
my $t_creat = elapsed_cpu_time {
  $records = $impl->create($n_records, \@keys);
};


# assign new values, to measure update time
my $t_upd = elapsed_cpu_time {
  @{$_}{@keys} = map {irand()} 1 .. @keys foreach @$records;
};

# sum some random values, to measure access time
my $t_acc = elapsed_cpu_time {
  my $sum = 0;
  for my $attempt (1 .. $n_records) {
    my $record = $records->[int(rand($n_records))];
    my $val = $record->{$keys[int(rand($n_keys))]};
    $sum += $val;
  }
};


# measure sorting time
my $t_sort = elapsed_cpu_time {
  my @to_sort = @{$records}[0 .. int(@$records/10)]; # only 10%
  my $sorted = $impl->sort(\@to_sort, $keys[0]);
};


# get memory usage
my $mem_usage = $^O eq 'MSWin32' ? win32_memory_usage() : unix_memory_usage();
$mem_usage    /= 2**20; # in MB

# measure deleting time
my $t_del = elapsed_cpu_time {
  undef $records;
};

# print results
printf "%7.3f %7.3f %7.3f %7.3f %7.3f %6.1fMB (%s)\n",
  $t_creat, $t_upd, $t_acc, $t_sort, $t_del, $mem_usage, $impl->info;


#======================================================================
# auxiliary functions
#======================================================================

sub print_headers {
  my $w = 7; # width of a cpu field
  printf "%${w}s %${w}s %${w}s %${w}s %${w}s %8s\n",
    qw/create update access sort delete memory/;
  printf "%${w}s %${w}s %${w}s %${w}s %${w}s %8s\n",
    ('=' x $w) x 5, ('=' x 8);
}


sub elapsed_cpu_time (&) {
  my $code = shift;
  my $cpu0 = times;
  $code->();
  my $cpu1 = times;
  return $cpu1 - $cpu0;
}


sub win32_memory_usage {
  require Win32::OLE;
  my $objWMI = Win32::OLE->GetObject('winmgmts:\\\\.\\root\\cimv2');
  my $query  = "select * from Win32_Process where ProcessId=$$";
  my ($proc) = Win32::OLE::in($objWMI->ExecQuery($query));
  return $proc->{VirtualSize};
}


sub unix_memory_usage {
  require Proc::ProcessTable;
  my $t = Proc::ProcessTable->new;
  my ($proc) = grep {$_->pid eq $$} @{$t->table};
  return $proc->size;
}


#======================================================================
# packages as interfaces for modules to test
#======================================================================


package HCore;
use Math::Random::MT qw(rand irand);

sub info {
  return "perl core hashes";
}

sub create {
  my ($class, $n_records, $keys) = @_;

  my @list;
  for (1 .. $n_records) {
    my %h = map {$_ => irand()} @$keys;
    push @list, \%h;
  }

  return \@list;
}

sub sort {
  my ($class, $records, $k) = @_;
  my @sorted = sort {$a->{$k} <=> $b->{$k}} @$records;
  return \@sorted;
}


#======================================================================

package HType;
use Hash::Type;
use Math::Random::MT qw(rand irand);

sub info {
  return "Hash::Type v" . Hash::Type->VERSION;
}



sub create {
  my ($class, $n_records, $keys) = @_;

  my @list;
  my $ht = Hash::Type->new(@$keys);

  for (1 .. $n_records) {
    my $h = $ht->new(map {irand()} 1 .. @$keys);
    push @list, $h;
  }

  return \@list;
}


sub sort {
  my ($class, $records, $k) = @_;
  my $ht  = $records->[0]{'Hash::Type'};
  my $cmp = $ht->cmp("$k: num");
  my @sorted = sort $cmp @$records;
  return \@sorted;
}


#======================================================================

package HOrd;
use Math::Random::MT qw(rand irand);
use Hash::Ordered;

sub info {
  return "Hash::Ordered v" . Hash::Ordered->VERSION;
}


sub create {
  my ($class, $n_records, $keys) = @_;

  my @list;

  for (1 .. $n_records) {
    tie my %h, 'Hash::Ordered', map {$_ => irand()} @$keys;
    push @list, \%h;
  }

  return \@list;
}

sub sort {
  my ($class, $records, $k) = @_;
  my @sorted = sort {$a->{$k} <=> $b->{$k}} @$records;
  return \@sorted;
}

#======================================================================

package IxHash;
use Math::Random::MT qw(rand irand);
use Tie::IxHash;

sub info {
  return "Tie::IxHash v" . Tie::IxHash->VERSION;
}

sub create {
  my ($class, $n_records, $keys) = @_;

  my @list;

  for (1 .. $n_records) {
    tie my %h, 'Tie::IxHash', map {$_ => irand()} @$keys;
    push @list, \%h;
  }

  return \@list;
}

sub sort {
  my ($class, $records, $k) = @_;
  my @sorted = sort {$a->{$k} <=> $b->{$k}} @$records;
  return \@sorted;
}

#======================================================================

package HIndexed;
use Math::Random::MT qw(rand irand);
use Tie::Hash::Indexed;

sub info {
  return "Tie::Hash::Indexed v" . Tie::Hash::Indexed->VERSION;
}

sub create {
  my ($class, $n_records, $keys) = @_;

  my @list;

  for (1 .. $n_records) {
    tie my %h, 'Tie::Hash::Indexed', map {$_ => irand()} @$keys;
    push @list, \%h;
  }

  return \@list;
}

sub sort {
  my ($class, $records, $k) = @_;
  my @sorted = sort {$a->{$k} <=> $b->{$k}} @$records;
  return \@sorted;
}


__END__
