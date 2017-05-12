#######################################################################
#                                                                     #
# Linux::stat                                                         #
#                                                                     #
#   Extract data from /proc/stat                                      #
#   Supported kernels: 2.4.x, 2.2.x (don't know about others)         #
#                                                                     #
#######################################################################

package Linux::stat;

$VERSION = "1.00";

require 5.000;
use strict;

my $kernel = `uname -r`;
$kernel =~ s/^(\d+\.\d+)\..*/$1/;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $this = {
    stat => "/proc/stat",
    @_,
  };
  die "Unable to read ".$this->{stat}.", stopped" unless -r $this->{stat};
  $this = bless $this, $class;
  return $this;
}

sub stat {
  my $this = shift;
  my $stat;
  if (defined $this) {
    if (ref($this)) {
      $stat = $this->{stat};
    } else {
      $stat = $this;
    }
  } else {
    $stat = "/proc/stat";
  }
  die "Unable to read $stat, stopped" unless -r $stat;
  open(STAT, $stat);
  my %result = ();
  if ($kernel < 2.4) {
    $result{disks} = [];
    foreach (0..3) {
      my $tmpHash = {
        major => 0,
        disk => $_,
        io => 0,
        read_count => 0,
        read_sectors => 0,
        write_count => 0,
        write_sectors => 0,
      };
      push @{$result{disks}}, $tmpHash;
    }
  }
  foreach (<STAT>) {
    chomp($_);
    next unless /^([^\s:]+):?\s+(.+)$/;
    my ($desc, $data) = ($1, $2);
    $desc =~ tr/A-Z/a-z/;
    if ($desc =~ /^cpu(\d*)$/) {
      my ($user, $nice, $system, $idle) = split(/ /, $data);
      $result{$desc} = {
        user => $user / 100,
        nice => $nice / 100,
        system => $system / 100,
        idle => $idle / 100,
      };
      $result{uptime} = ($user + $nice + $system + $idle) / 100 if $desc eq "cpu";
    } elsif ($desc eq "page") {
      my @pgs = split(/\s+/, $data);
      ($result{pages_in}, $result{pages_out}) = @pgs;
    } elsif ($desc eq "swap") {
      my @swps = split(/\s+/, $data);
      ($result{swap_pages_in}, $result{swap_pages_out}) = @swps;
    } elsif ($desc eq "intr") {
      my @irqs = split(/\s+/, $data);
      $result{interrupts_total} = shift @irqs;
      $result{interrupts} = [@irqs];
    } elsif (($desc eq "disk_io") && ($kernel >= 2.4)) {
      my @disks = split(/\s+/, $data);
      my @diskResult;
      my $tot = $result{disks_io};
      foreach (@disks) {
        next unless /^\((\d+),(\d+)\):\((\d+),(\d+),(\d+),(\d+),(\d+)\)$/;
        my $currDisk = {
          major => $1,
          disk => $2,
          io => $3,
          read_count => $4,
          read_sectors => $5,
          write_count => $6,
          write_sectors => $7,
        };
        push @diskResult, $currDisk;
        if (defined $tot) {
          foreach (keys %$currDisk) {
            $tot->{$_} += $currDisk->{$_};
          }
        } else {
          %$tot = %$currDisk;
        }
      }
      push @{$result{disks}}, @diskResult;
      delete $tot->{major};
      delete $tot->{disk};
      $result{disks_io} = $tot;
    } elsif (($desc =~ /^disk(_(rio|wio|rblk|wblk))?$/) && ($kernel < 2.4)) {
      my @diskData = split(/ /, $data);
      next if @diskData < 4;
      $desc = {
        "" => "io",
        "rio" => "read_count", "wio" => "write_count",
        "rblk" => "read_sectors", "wblk" => "write_sectors",
      }->{$2 || ""};
      foreach (0..3) {
        $result{disks}->[$_]->{$desc} = $diskData[$_];
      }
    } elsif ($desc eq "ctxt") {
      next unless $data =~ /^(\d+)/;
      $result{context_switch} = $1;
    } elsif ($desc eq "btime") {
      next unless $data =~ /^(\d+)/;
      $result{boot_timestamp} = $1;
    } elsif ($desc eq "processes") {
      next unless $data =~ /^(\d+)/;
      $result{total_forks} = $1;
    } else {
      $result{$desc} = $data;
      next;
    }
  }
  return \%result;
}

1;

__END__

=head1 NAME

Linux::stat - parse /proc/stat

=head1 SYNOPSIS

  use Linux::stat;

  my $stat = Linux::stat->new( [ stat => "path to /proc/stat" ] );
  my $hashref = $stat->stat();

or

  my $hashref = Linux::stat::stat( [ "path to /proc/stat" ] );

=head1 DESCRIPTION

B<Linux::stat> is a simple Perl module which parses B</proc/stat> file.  
Info is arranged in hash reference with descriptive keys.

B<Linux::stat> was written on RedHat Linux 7.2, kernel 2.4.7 and tested on
RedHat 6.2, kernel 2.2.14. It is expected to work with other versions as
well, but this depends on Linux configuration and kernel version.

Output data can be easily previewed with B<Data::VarPrint> package, 
available at CPAN.

Output fields (some of these are unavailable on kernels older than 2.4):

=over 4

=item B<boot_timestamp>

Timestamp (number of seconds since epoch) when the system was booted

=item B<context_switch>

Context switch, used by Linux job scheduler; for more info check Linux
kernel sources: kernel/sched.c (look for kstat.context_swtch)

=item B<cpu>, B<cpu0>, B<cpu1>,...

Overall and per-CPU time: B<user>, B<nice>, B<system>, B<idle>

=item B<disks>

Disks I/O (for each partition):

=over 4

=item B<disk> - disk number (0 for /dev/hda, 1 for /dev/hdb,...)

=item B<io> - total number of I/O requests

=item B<major> - major disk number (partition number on the disk)

=item B<read_count> - number of reads from disk

=item B<read_sectors> - number of sectors read from disk

=item B<write_count> - number of writes to disk

=item B<write_sectors> - number of sectors written to disk

=back

=item B<disks_io>

Overall disk I/O info; same fields as in B<disks> (of course, except for
B<disk> and B<major>)

=item B<interrupts>

Number for interrupts for each IRQ

=item B<interrupts_total>

Total number of interrupts (same as sum of all numbers in B<interrupts>)

=item B<kstat.*>

Not parsed, just added to hash

=item B<pages_in>

Number of pages read

=item B<pages_out>

Number of pages written

=item B<swap_pages_in>

Number of pages read from swap

=item B<swap_pages_out>

Number of pages written to swap

=item B<total_forks>

Number of processes run since boot

=item B<uptime>

System uptime in seconds (same as sum of all four times for B<cpu>)

=back

All not-recognized fields are just passed on without parsing.

=head1 OPTIONS

Currently, the only option available is B<stat> which is path to 
B</proc/stat> in case this changes for some reason.

=head1 FILES

B</proc/stat> CPU, disk and some other information

=head1 REQUIRES

Perl 5.000

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Vedran Sego, vsego@math.hr

=cut
