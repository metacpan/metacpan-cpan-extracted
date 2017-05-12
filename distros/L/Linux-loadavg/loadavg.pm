package Linux::loadavg;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Linux::loadavg ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
   loadavg	
   LOADAVG_1MIN
   LOADAVG_5MIN
   LOADAVG_15MIN
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
   loadavg	
   LOADAVG_1MIN
   LOADAVG_5MIN
   LOADAVG_15MIN
);
our $VERSION = '0.09';

use constant LOADAVG_1MIN => 0;
use constant LOADAVG_5MIN => 1;
use constant LOADAVG_15MIN => 2;

bootstrap Linux::loadavg $VERSION;

# Preloaded methods go here.

die "Wrong OS ('$^O' !~ m#(?i)linux#)" 
  unless $^O =~ m#(?i)linux#;

1;
__END__

=head1 NAME

Linux::loadavg - Get system load averages (via getloadavg(3C) system call)

=head1 SYNOPSIS

  use Linux::loadavg;

  @avgs = loadavg();
  printf "load average: %f %f %f\n", @avgs;
  
=head1 DESCRIPTION

The Linux::loadavg module provides simple interface to Linux getloadavg(3C) library
function, which returns the number of processes in the  system run queue averaged over 
various periods of time. Up to 3 samples are retrieved and returned to successive 
elements of the output array. The system imposes a maximum of 3 samples, representing 
averages over the last 1, 5 and 15 minutes, respectively.

The LOADAVG_1MIN, LOADAVG_5MIN, and LOADAVG_15MIN indices can be used to extract 
the data from the appropriate element of the output array.

When called without an argument, the loadavg() function returns all three load averages.

=head1 EXPORT

=over

=item loadavg	

=item LOADAVG_1MIN

=item LOADAVG_5MIN

=item LOADAVG_15MIN

=back

=head1 EXAMPLE

  use strict;

  # Autodetect Linux::loadavg or Solaris::loadavg
  die $@ if eval sprintf('use %s::loadavg qw(loadavg)', ucfirst $^O) || $@;

  # get the first two load averages

  @avgs = loadavg(2);
  printf "first load avg (1min): %f\n", @avgs[LOADAVG_1MIN];
  printf "second load avg (5min): %f\n", @avgs[LOADAVG_5MIN];

=head1 AUTHOR

Niels van Dijke, E<lt>CpanDotOrgAtPerlboyDotNetE<gt>

=head1 CREDITS

The Linux::loadavg is nearly one on one based on Solaris::loadavg. Therefore credits 
should go to: Alexander Golomshtok (http://search.cpan.org/~agolomsh/)

=head1 SEE ALSO

L<perl>,L<getloadavg(3C)>,L<Solaris::loadavg>

=cut
