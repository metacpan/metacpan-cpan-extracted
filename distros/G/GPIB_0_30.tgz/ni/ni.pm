package GPIB::ni;

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
		croak "Your vendor has not defined gpib macro $constname";
	}
    }
    # *$AUTOLOAD = sub () { $val };
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap GPIB::ni $VERSION;

sub new {
    my $pkg = shift; 
    my $g = undef;
    my $i;

    if (@_ == 1) {
        $g = ibfind($_[0]);
    } elsif (@_ == 6) {
        $g = ibdev(@_);
    } else {
        die("Bad parameter list to GPIB::ni::new($pkg @_)");
    }

    # Larry thinks new() should die on failure...
    if ($g->ibsta & GPIB->ERR) {
        my  @c = caller;
        die "GPIB::ni::new(@_) failed\n    ";
    }
    bless $g, $pkg;
    return $g;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

GPIB::ni - Perl-GPIB interface for National Instruments GPIB device drivers

=head1 SYNOPSIS

  use GPIB;

  $g = GPIB->new("name");
  $g->ibwrt('*IDN?');
  print $g->ibrd(1024);

=head1 DESCRIPTION

GPIB::ni is an interface module for accessing National Instruments GPIB
devices.  This XS module builds and has been tested on Linux and 
Windows NT.  This module is normally not used directly, but called
by GPIB.pm according to an entry in /etc/pgpib.conf or by calling
GPIB->new() and passing GPIB::ni as the first parameter.

A typical /etc/pgpib.conf entry for using GPIB::ni is shown below:

  # name              Board   PAD     SAD     TMO     EOT     EOS
  K2002   GPIB::ni    0       0x10    0       T1s     1       0

The device is used in a Perl program as follows:

  use GPIB;
  $g = GPIB->new("K2002");
  
In the above example, the K2002 entry provides GPIB::ni with 6 parameters
that coorespond to the parameters to ibdev() for opening a device.  This
is the most common form for configuring a GPIB device.  Alternatively,
if only 1 parameter is supplied for GPIB::ni ibfind() is called to 
open the device.  Here is an example for opening the GPIB directly 
on GPIB board 0 in a system:

  # /etc/pgpib.conf              
  bus   GPIB::ni    gpib0

  use GPIB;

  $g = GPIB->new("bus");

The intention is that a Perl GPIB program should run identically on
a Windows or Linux platform.  This is pretty much true but there are
a couple of small differences in the NI driver.

The Linux driver deasserts REN when the application closes the driver 
and exits.  NT4.0 seems to leave REN asserted unless the application
specifically opens the bus and manually deasserts REN. 

=head1 CREDIT

This module is loosely based on a Perl XS module Steve Tell at UNC
(tell@cs.unc.edu) wrote for accessing GPIB devices from Perl.

=head1 AUTHOR

Jeff Mock, jeff@mock.com

=head1 SEE ALSO

perl(1), GPIB(3), GPIB::hpserial(3), GPIB::rmt(3).

=cut




