#!perl

use strict;
use Test::More;
use Test::Exception;
use MMapDB qw/:error/;
use Benchmark qw/:hireswallclock timethese cmpthese/;

plan skip_all=>'set BENCHMARK=1 in the environment to run this test'
  unless $ENV{BENCHMARK};

my @fmts=qw/L N J/;
eval {my $x=pack 'Q', 0; push @fmts, 'Q'};

my @keys;
my %check;
my @ins;
my ($k1, $k2);

my $benchcount=-3;

{
  my %h;
  warn "\ngenerating keys\n";
  for( my $i=0; $i<10000; $i++ ) {
    my ($k1, $k2);
    my $r=rand 3;
    if( @keys and $r<1 ) {		# reuse a key pair
      ($k1, $k2)=@{$keys[int rand 0+@keys]};
    } elsif( @keys and $r<2 ) {	# reuse first key
      ($k1)=@{$keys[int rand 0+@keys]};
    REDO: {
	$k2=pack "C*", map {65+int rand 26} (1)x30;
	redo REDO if exists $h{$k1.$k2};
      }
      undef $h{$k1.$k2};
      push @keys, [$k1,$k2];
    } else {
    REDO: {
	$k1=pack "C*", map {65+int rand 26} (1)x20;
	$k2=pack "C*", map {65+int rand 26} (1)x30;
	redo REDO if exists $h{$k1.$k2};
      }
      undef $h{$k1.$k2};
      push @keys, [$k1,$k2];
    }
    my $data='dat'x($i%30);
    push @ins, [[$k1, $k2], $i, $data];
    push @{$check{$k1}->{$k2}}, [[$k1, $k2], $i, $data, $i+1];
  }

  my ($max, $maxd, $maxk)=(0)x2;
  my $m;
  for my $k (@keys) {
    @{$check{$k->[0]}->{$k->[1]}}
      =sort {$a->[1] cmp $b->[1]} @{$check{$k->[0]}->{$k->[1]}};
    $m=keys %{$check{$k->[0]}};
    if($m>$max) {
      $max=$m;
      $maxk=$k->[0];
    }
    $m=@{$check{$k->[0]}->{$k->[1]}}; $maxd=$m if $m>$maxd;
  }

  $m=keys %check;
  warn "number of first level keys: $m\n";
  warn "max. number of second level keys: $max (key=$maxk)\n";
  warn "max. length of data list: $maxd\n";
  $k1=$maxk;
  $k2=(keys %{$check{$k1}})[int $max/2];
  warn "k1=$k1, k2=$k2\n";
}

my $bench;
my $checkval;
{
  my $c=\%check;
  my $f_hash1=sub {(sub {scalar @{$c->{$_[0]}->{$_[1]}}})->($k1, $k2)};
  my $f_hash2=sub {scalar @{$c->{$k1}->{$k2}}};
  open my $saveout, '>&STDOUT';
  open STDOUT, '>&STDERR';

  $checkval=$f_hash1->();
  $bench=timethese $benchcount,
    {
     'hash1'=>$f_hash1,
     'hash2'=>$f_hash2,
    };

  open STDOUT, '>&', $saveout;
}

plan tests=>(2+@keys)*@fmts;

sub doone {
  my $fmt=shift;

  unlink 'tmpdb';			# make sure
  die "Please move tmpdb out of the way!\n" if -e 'tmpdb';

  my $d=MMapDB->new(filename=>"tmpdb", intfmt=>$fmt);

  $d->start;

  print "# building database\n";
  $d->begin;
  $d->insert($_) for (@ins);
  $d->commit;

  for my $k (@keys) {
    is_deeply($d->main_index->{$k->[0]}->{$k->[1]},
	      [@{$check{$k->[0]}->{$k->[1]}}]);
  }

  {
    my @el;
    my $indx=$d->main_index;
    my $mi=$d->mainidx;
    my $f_mmdb=sub {scalar @{$indx->{$k1}->{$k2}}};
    my $f_idxl=sub {@el=$d->MMapDB::index_lookup($mi, $k1, $k2);scalar @el};
    # my $f_idx2=sub {@el=MMapDB::index_lookup($d, $mi, $k1, $k2);scalar @el};

    is $f_mmdb->(), $checkval;
    is $f_idxl->(), $checkval;
    # is $f_idx2->(), $checkval;

    open my $saveout, '>&STDOUT';
    open STDOUT, '>&STDERR';

    print "\nBenchmarking format $fmt\n";

    my $h=timethese $benchcount,
      {
       'mmdb_'.$fmt=>$f_mmdb,
       'idxl_'.$fmt=>$f_idxl,
       # 'idx2_'.$fmt=>$f_idx2,
      };
    @{$bench}{keys %{$h}}=values %{$h};

    open STDOUT, '>&', $saveout;
  }
}

for my $f (@fmts) {
  doone $f;
}

{
  open my $saveout, '>&STDOUT';
  open STDOUT, '>&STDERR';

  cmpthese $bench;

  open STDOUT, '>&', $saveout;
}
