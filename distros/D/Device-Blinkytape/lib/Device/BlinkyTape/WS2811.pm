package Device::BlinkyTape::WS2811;
use strict;
BEGIN {
    our $AUTHORITY = 'cpan:OKKO'; # AUTHORITY
    our $VERSION = '0.004'; # VERSION
}
use Moose;
use utf8;
use Time::HiRes qw(usleep);

extends 'Device::BlinkyTape';

=for Pod::Coverage send_pixel show gamma

=head1 NAME

Device::BlinkyTape:WS2811 - Control a WS2811-based BlinkyTape

=head1 SYNOPSIS

    use Device::BlinkyTape::WS2811;
    my $bb = Device::BlinkyTape::WS2811->new(dev => '/dev/tty.usbmodem');

See Device::BlinkyTape for documentation.

=cut

sub send_pixel {
    my $self = shift;
    my ($r, $g, $b) = (shift, shift, shift);
    $r = 254 if ($r == 255); # The 255 means end of led line and applies the colors. Drop that value by one. Blinkyboard.py does this.
    $g = 254 if ($g == 255);
    $b = 254 if ($b == 255);
    $self->port->write(chr($r));
    usleep($self->sleeptime);
    $self->port->write(chr($g));
    usleep($self->sleeptime);
    $self->port->write(chr($b));
    usleep($self->sleeptime);
    my $string_in = $self->port->input; # flush input to prevent slowing down
}



sub show {
    my $self = shift;
    $self->port->write(chr(0));
    usleep($self->sleeptime);
    $self->port->write(chr(0));
    usleep($self->sleeptime);
    $self->port->write(chr(255));
    usleep($self->sleeptime);
    my $string_in = $self->port->input; # flush input to prevent slowing down
}

sub gamma {
    my $self = shift;
    my $input = shift;
    my $tweak = shift;
    return $input if not $self->gamma;
    return int(($input/256 ** $tweak) * 256);
}

1;

=head1 AUTHOR

Oskari Okko Ojala E<lt>okko@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Oskari Okko Ojala 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl you may have available.

=cut
