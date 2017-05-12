package Device::BlinkyTape::SimulationPort;
use strict;
BEGIN {
    our $AUTHORITY = 'cpan:OKKO'; # AUTHORITY
    our $VERSION = '0.004'; # VERSION
}
use Moose;
use Tk;

has 'baudrate' => (is => 'rw');
has 'databits' => (is => 'rw');
has 'parity' => (is => 'rw');
has 'stopbits' => (is => 'rw');

has 'simulate_window' => (is => 'rw');
has 'simulate_canvas' => (is => 'rw');
has 'port' => (is => 'rw');
has 'drawpixelpos' => (is => 'rw');
has 'pixels' => (is => 'rw');
has 'led_count' => (is => 'rw');

=for Pod::Coverage BUILD

=head1 Usage

This module replaces the Device::SerialPort device with a BlinkyTape simulator.
You can use it to develop for the BlinkyTape before actually getting the device.

=cut

sub BUILD {
    my $self = shift;
    my $pixelsize = 10;
    $self->simulate_window(MainWindow->new());
    $self->simulate_window()->title('BlinkyTape simulator');
    $self->simulate_window()->geometry($self->led_count()*$pixelsize . 'x' . ($pixelsize+200) . '-0+0'); # Canvas()->createRectangle(0,0,$self->led_count()*$pixelsize, $pixelsize);
    $self->simulate_window()->update();

    $self->simulate_canvas($self->simulate_window()->Canvas);
    $self->simulate_canvas()->pack(-expand=> 1, -fill => 'both');

    $self->simulate_canvas()->pack;
    $self->simulate_window()->update;

    my @pixel;
    for ($a=0; $a<=$self->led_count-1; $a++) {
        $pixel[$a] = $self->simulate_canvas()->createRectangle($a*$pixelsize,0,$a*$pixelsize+$pixelsize-1,$pixelsize, -fill => 'black', -width => 0);
    }
    $self->pixels(\@pixel);

    $self->drawpixelpos(0);
}

=head2 write

Write bytes to the simulated Port. These are interpreted as BlinkyTape colours and displayed on a Tk window.

=cut

sub write {
    my $self = shift;
    my $color = shift;
    my $r = unpack("x0 C1", $color);
    if ($r == 255) {
        $self->drawpixelpos(0);
        $self->simulate_window()->update();
        return 1;
    }
    my $g = unpack("x1 C1", $color);
    my $b = unpack("x2 C1", $color);
    my $rgbcolor = sprintf ("#%.2X%.2X%.2X", $r, $g, $b);
    my $pixel_rectangle_tkid = $self->pixels()->[$self->drawpixelpos];
    $self->simulate_canvas()->itemconfigure($pixel_rectangle_tkid, -fill => $rgbcolor);
    $self->drawpixelpos($self->drawpixelpos()+1);
    $self->simulate_canvas()->pack;
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
