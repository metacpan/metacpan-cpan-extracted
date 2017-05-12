package Device::Pertelian;

use warnings;
use strict;

use fields qw/device _fh/;

use IO::Handle;
use Time::HiRes qw/usleep/;

=head1 NAME

Device::Pertelian - a driver for the Pertelian X2040 USB LCD

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

If you have a Pertelian X2040 USB LCD screen, then you can do
things with it.

    use Device::Pertelian;

    my $lcd = Device::Pertelian->new('/dev/ttyUSB0');
    $lcd->clearscreen();

    # write to the top row
    $lcd->writeline(0, "Hello, world!");
    ...

=head1 METHODS

=head2 new

The constructor accepts one parameter, $device, which is a path in /dev.
You may find it out from your logs.

=cut

sub new {
    my $self = shift;
    my $device = shift;

    unless (ref $self) {
        $self = fields::new($self);
    }

    if ($device) {
        $self->_open($device);
    }

    return $self;
}

sub _open {
    my ($self, $device) = @_;

    open $self->{_fh}, '>', $device
        or return;

    $self->{_fh}->autoflush(1);

    foreach (0x38, 0x06, 0x10, 0x0c) {
        $self->_writeout(pack('CC', 0xfe, $_));
    }

    return 1;
}

sub _writeout {
    my ($self, $buf) = @_;

    if ($self->{_fh}) {
        print {$self->{_fh}} $buf;
        usleep(1000);
    }
}

=head2 clearscreen

This function does a simple thing -- clears all the 4 lines of the screen.

=cut

=head2 writeline

This function takes two parameters, $row and $text. The screen has 4 rows,
so you may pass a number from 0 to 3 as $row and the $text should be
under 20 characters, that is the width of the screen.

=cut

sub writeline {
    my $self = shift;

    my ($row, $text) = @_;
    my @rowvals = (
        0x80,
        0x80 + 0x40,
        0x80 + 0x14,
        0x80 + 0x54);
    my $buf = pack('CC', 0xfe, $rowvals[$row]);
    $self->_writeout($buf);

    foreach (split(//, $text)) {
        $self->_writeout($_);
    }

    return 1;
}

sub clearscreen {
    my $self = shift;

    $self->_writeout(pack('CC', 0xfe, 1));
    usleep(10000);
}

=head1 AUTHOR

Alex Kapranoff, C<< <alex at kapranoff.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-pertelian at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Pertelian>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::Pertelian

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Pertelian>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-Pertelian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-Pertelian>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-Pertelian>

=back

=head1 DOCUMENTATION

See L<http://www.ekenrooi.net/lcd/lcd.shtml>, 
L<http://web.archive.org/web/20100903020330/http://developer.pertelian.com/index.php?option=com_content&view=section&id=3&Itemid=9>
and the pertd software that vanished with the main website pertelian.com.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alex Kapranoff, all rights reserved.

This program is released under the following license: GPL version 3

In the included pertd.tgz archive there is code by:
Frans Meulenbroeks, Ron Lauzon, Pred S. Bundalo, Chmouel Boudjnah,
W. Richard Stevens.

The code in pertd.tgz is either in Public Domain or available for
distribution in unmodified form. See the relevant files.

=cut

1;
