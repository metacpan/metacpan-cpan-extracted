package Device::USB::TranceVibrator;

use strict;
use warnings;
use Carp;
use Device::USB;

our $VERSION = '0.01';

my @vibe_command = (
    0x41,   # bmRequestType
    0x00,   # bRequest
    0xFFFF, # value
    0x30F,  # index
    undef,  # bytes
    0,      # size
    1000,   # timeout
   );

my $Debug = undef;

sub _dprint(@) { ## no critic
    return unless $Debug;
    my @m = @_;
    chomp @m;
    print STDERR 'DEBUG: ', @m,"\n";
}

sub new {
    my($class, %args) = @_;
    my $self  = {};
    bless $self, $class;

    $Debug  = delete $args{debug};

    my $vendor    = $args{vendor}  || 0x0B49;
    my $product   = $args{product} || 0x064F;
    my $interface = 0; # interface number
    _dprint "vendor:$vendor product:$product";

    my $usb = Device::USB->new()                  or croak "D::USB new: $!";
    my $dev = $usb->find_device($vendor,$product) or croak "D::USB find: $!";
    $dev->open()                                  or croak "D::USB open $!";

    $dev->set_configuration(1)         >= 0       or croak "D::USB conf: $!";
    $dev->claim_interface($interface)  >= 0       or croak "D::USB claim: $!";
    $dev->set_altinterface($interface) >= 0       or croak "D::USB alt: $!";

    $self->{device} = $dev;
    return $self;
}

sub vibrate {
    my($self, %param) = @_;

    my $speed = delete $param{speed} || 128;
    if ($speed !~ /^\d+$/ || $speed > 255) {
        carp "speed parameter must be between 0 and 255, so force to be 129";
        $speed = 129;
    }
    _dprint "speed:$speed";

    my $speed_value  = $speed + $speed * 256;
    $vibe_command[2] = $speed_value;
    $vibe_command[3] = 0x0300 + ($speed_value & 0x0F);

    return $self->{device}->control_msg(@vibe_command);
}

sub stop {
    my($self) = @_;
    return $self->vibrate(speed => 1);
}

1;

__END__

=head1 NAME

Device::USB::TranceVibrator - interface to toy Trance Vibrator

=head1 SYNOPSIS

    use Device::USB::TranceVibrator;

    my $vibe = Device::USB::TranceVibrator->new;
    $vibe->vibrate(speed => 100);
    sleep 10;
    $vibe->vibrate(speed => 200);
    sleep 10;
    $vibe->stop;

=head1 DESCRIPTION

Device::USB::TranceVibrator provides interface to toy "Trance Vibrator".

"Trance Vibrator" is USB device which included with Rez's special
package. Rez is a video game for Dreamcast and PlayStation 2 and Xbox
360. for more details on Rez, see trailing links.

=head1 METHODS

=head2 new

  $vibe = Device::USB::TranceVibrator->new( %option );

This method constructs a new "Device::USB::TranceVibrator" instance
and returns it. %option is following:

  KEY       VALUE
  ---------------------------------------------------
  vendor    device's vendor code.  default is 0x0B49
  product   device's product code. default is 0x064F

=head2 vibrate

  $vibe->vibrate( speed => 255 );

do vibrate. speed must be between 1 and 255.

255 is maximum vibration and 1 is stop vibration.

=head2 stop

  $vibe->stop;

stop vibration.

=head1 SUPPORTED PLATFORM

I checked on these environment:

  - Mac OS X, libusb
  - Linux 2.6, libusb
  - Windows XP, libusb-win32, on cygwin

=head1 SEE ALSO

L<Device::USB>,
L<http://libusb.wiki.sourceforge.net/>,
L<http://libusb-win32.sourceforge.net/>,
L<http://en.wikipedia.org/wiki/Rez#Trance_Vibrator>,
L<http://wiki.opendildonics.org/index.php?title=Rez_TranceVibrator>

=head1 AUTHOR

HIROSE Masaaki, C<< <hirose31@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-usb-trancevibrator@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
