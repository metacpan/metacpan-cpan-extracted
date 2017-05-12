package GPIB::llp;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw();
@EXPORT_OK = qw();

$VERSION = '0.30';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined GPIB macro $constname";
	}
    }
    # *$AUTOLOAD = sub () { $val };
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap GPIB::llp $VERSION;

sub new {
    my $pkg = shift; 
    my $g = undef;
    my $i;

    if (@_ == 1) {
        $g = ibfind($_[0]);
    } elsif (@_ == 6) {
        $g = ibdev(@_);
    } else {
        die("Bad parameter list to GPIB::llp::new($pkg @_)");
    }

    # Larry thinks new() should die on failure...
    if ($g->ibsta & GPIB->ERR) {
        my  @c = caller;
        die "GPIB::llp::new(@_) failed\n    ";
    }
    bless $g, $pkg;
    return $g;
}

# LLP is missing some standard GPIB calls.  They are stubbed out
# to tacitly do nothing here.  Maybe they should be noisy...
#
sub ibdev { -1; }
sub ibask { 0; }
sub ibbna { 0; }
sub ibist { 0; }
sub ibln { 1; }    #  Hmm, we need this
sub ibpct { 0; }
sub ibppc { 0; }
sub ibrdf { 0; }
sub ibrsc { 0; }
sub ibstop { 0; }
sub ibwrtf { 0; }


1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

GPIB::llp - Perl-GPIB interface for Linux Lab Project GPIB device drivers

=head1 SYNOPSIS

  use GPIB;

  $g = GPIB->new("name");
  $g->ibwrt('*IDN?');
  print $g->ibrd(1024);

=head1 DESCRIPTION

GPIB::llp is an interface module for accessing Linux Lab Project GPIB
device drivers.  This XS module builds and has been tested on Linux using
an NI PCIIA card.  This module is normally not used directly, but called
by GPIB.pm according to an entry in /etc/pgpib.conf or by calling
GPIB->new() and passing GPIB::llp as the first parameter.

A typical /etc/pgpib.conf entry for using GPIB::llp is shown below:

  # name              /etc/pgpib.conf name
  K2002   GPIB::llp   K2002

The device is used in a Perl program as follows:

  use GPIB;

  $g = GPIB->new("K2002");
  
In the above example, the K2002 entry indicates that GPIB::llp 
interface will use the string K2002 in a call to ibfind() to locate
the device.  Unlike GPIB::ni, GPIB:llp uses the configuration information
maintained by the LLP driver in /etc/gpib.conf (not /etc/pgpib.conf)
for accessing the device.  The LLP library does not provide an ibdev()
call so it's not possible to provide the same specification control
available to GPIB::ni.

The LLP library is missing a few other standard GPIB calls in addtion
to ibdev().  The following calls are stubbed out to do nothing:

        ibdev
        ibask
        ibbna
        ibist
        ibln
        ibpct
        ibppc
        ibrdf
        ibrsc
        ibstop
        ibwrtf

There is some odd behaviour particular to the GPIB::llp interface:
If a call to ibrd() is made with a long timeout, the system will
pretty much hang waiting on the read to complete or timeout.  The 
driver seems to take full control of the system.

An ibwrt() or ibrd() seems to be limited to about 64k bytes.  I 
cannot find a precise answer, but larger reads fail.  Keep
I/O operations using GPIB::llp small.

The module seems to have some unusual behaviour with CPUs faster
than 300MHz, I haven't narrowed this down.

I think there is an off-by-one error in $g->ibrd(). Sometimes I 
get the last character in the returned string twice.

This interface is not tested as well as the National Instruments
interface (GPIB::ni).  I use GPIB::ni most of the time.

=head1 CREDIT

This module is loosely based on a Perl XS module Steve Tell at UNC
(tell@cs.unc.edu) wrote for accessing GPIB devices from Perl.

=head1 AUTHOR

Jeff Mock, jeff@mock.com

=head1 SEE ALSO

perl(1), GPIB(3), GPIB::ni(3), GPIB::hpserial(3), GPIB::rmt(3),
Linux Lab Project http://www.llp.fu-berlin.de/

=cut

