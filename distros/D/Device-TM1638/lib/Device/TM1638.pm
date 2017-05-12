package Device::TM1638;

use 5.006;
use strict;
use warnings;
use Device::BCM2835;
use List::Util "min";


=head1 NAME

Device::TM1638 - The great new Device::TM1638!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Device::TM1638;

    my $foo = Device::TM1638->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut
my %FONT = (
        '!' => 0b10000110,
        '"' => 0b00100010,
        '#' => 0b01111110,
        '$' => 0b01101101,
        '%' => 0b00000000,
        '&' => 0b00000000,
        '(' => 0b00110000,
        ')' => 0b00000110,
        '*' => 0b00000000,
        '+' => 0b00000000,
        '' => 0b00000100,
        '-' => 0b01000000,
        '.' => 0b10000000,
        '/' => 0b01010010,
        '0' => 0b00111111,
        '1' => 0b00000110,
        '2' => 0b01011011,
        '3' => 0b01001111,
        '4' => 0b01100110,
        '5' => 0b01101101,
        '6' => 0b01111101,
        '7' => 0b00100111,
        '8' => 0b01111111,
        '9' => 0b01101111,
        ':' => 0b00000000,
        ';' => 0b00000000,
        '<' => 0b00000000,
        '=' => 0b01001000,
        '>' => 0b00000000,
        '?' => 0b01010011,
        '@' => 0b01011111,
        'A' => 0b01110111,
        'B' => 0b01111111,
        'C' => 0b00111001,
        'D' => 0b00111111,
        'E' => 0b01111001,
        'F' => 0b01110001,
        'G' => 0b00111101,
        'H' => 0b01110110,
        'I' => 0b00000110,
        'J' => 0b00011111,
        'K' => 0b01101001,
        'L' => 0b00111000,
        'M' => 0b00010101,
        'N' => 0b00110111,
        'O' => 0b00111111,
        'P' => 0b01110011,
        'Q' => 0b01100111,
        'R' => 0b00110001,
        'S' => 0b01101101,
        'T' => 0b01111000,
        'U' => 0b00111110,
        'V' => 0b00101010,
        'W' => 0b00011101,
        'X' => 0b01110110,
        'Y' => 0b01101110,
        'Z' => 0b01011011,
        '[' => 0b00111001,
        ']' => 0b00001111,
        '^' => 0b00000000,
        '_' => 0b00001000,
        '`' => 0b00100000,
        'a' => 0b01011111,
        'b' => 0b01111100,
        'c' => 0b01011000,
        'd' => 0b01011110,
        'e' => 0b01111011,
        'f' => 0b00110001,
        'g' => 0b01101111,
        'h' => 0b01110100,
        'i' => 0b00000100,
        'j' => 0b00001110,
        'k' => 0b01110101,
        'l' => 0b00110000,
        'm' => 0b01010101,
        'n' => 0b01010100,
        'o' => 0b01011100,
        'p' => 0b01110011,
        'q' => 0b01100111,
        'r' => 0b01010000,
        's' => 0b01101101,
        't' => 0b01111000,
        'u' => 0b00011100,
        'v' => 0b00101010,
        'w' => 0b00011101,
        'x' => 0b01110110,
        'y' => 0b01101110,
        'z' => 0b01000111,
        '{' => 0b01000110,
        '|' => 0b00000110,
        '}' => 0b01110000,
        '~' => 0b00000001
); 

sub new {
    my ($class, $dio, $clk, $stb) = @_;
    my $ret = Device::BCM2835::init() or die;
    return bless { dio => $dio,
                   clk => $clk,
                   stb => $stb,
                }, $class;
}

sub _write {
    my ($pin, $value) = @_;
    Device::BCM2835::gpio_write($pin, $value);
}

sub _read {
    my ($pin) = @_;
    return Device::BCM2835::gpio_lev($pin);
}

sub _gpio_fsel {
    my ($pin, $value) = @_;
    Device::BCM2835::gpio_fsel($pin, $value);
}

sub enable {
    my ($self, $intensity) = @_;
    $intensity ||= 7;
    _gpio_fsel($self->{dio}, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
    _gpio_fsel($self->{clk}, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
    _gpio_fsel($self->{stb}, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);

    $self->stb_high;
    _write($self->{clk}, 1);

    $self->send_command(0x40);
    $self->send_command(0x80 | 8 | min(7, $intensity));

    $self->stb_low;

    $self->send_byte(0xc0);

    foreach (1..16) {
        $self->send_byte(0x00);
    }

    $self->stb_high;

};

sub send_command {
    my ($self, $cmd) = @_;
    $self->stb_low;
    $self->send_byte($cmd);
    $self->stb_high;
}

sub send_data {
    my ($self, $addr, $data) = @_;
    $self->send_command(0x44);
    $self->stb_low;
    $self->send_byte(0xC0 | $addr);
    $self->send_byte($data);
    $self->stb_high;
}

sub send_byte {
    my ($self, $data) = @_;
    for (1..8) {
        _write($self->{clk}, 0);
        _write($self->{dio}, $data & 1);
        $data >>= 1;
        _write($self->{clk}, 1);
    };
}

sub set_led {
    my ($self, $n, $color) = @_;
    $self->send_data(($n << 1) + 1, $color);
}

sub _send_char {
    my ($self, $pos, $data, $dot) = @_;
    $dot ||= 0;
    $self->send_data($pos << 1, $data | ($dot ? 128 : 0));
}

sub send_char {
    my ($self, $pos, $char, $dot) = @_;
    $self->_send_char($pos, $FONT{$char}, $dot);
}

sub set_digit {
    my ($self, $pos, $digit, $dot) = @_;
    $dot ||= 0;
    for my $i (0..6) {
        $self->_send_char($i, $self->get_bit_mask($pos, $digit, $i), $dot);
    }
}

sub get_bit_mask {
    my ($self, $pos, $digit, $bit) = @_;
    return (($FONT{$digit} >> $bit) & 1) << $pos;
}

sub set_text {
    my ($self, $text) = @_;
    
    my $dots = 0b00000000;
    my $pos = index($text,'.');
    if ($pos != -1) {
        $dots = $dots | (128 >> $pos+(8-length($text)));
        $text =~ s/\.//g;
    }

    $self->_send_char(7, $self->rotate_bits($dots));
    $text = substr($text, 0,8);
    $text = reverse($text);
    $text .= " " x (8-length($text));

    for my $i (0..7) {
        my $byte = 0b00000000;
        for my $pos (0..7) {
            my $c = substr($text, $pos, 1);
            if ($c ne ' ') {
                $byte = ($byte | $self->get_bit_mask($pos, $c, $i));
            }
            $self->_send_char($i, $self->rotate_bits($byte));
        }
    }
}

sub receive {
    my ($self) = @_;
    my $temp = 0;
    _gpio_fsel($self->{dio}, &Device::BCM2835::BCM2835_GPIO_FSEL_INPT);
    Device::BCM2835::gpio_set_pud($self->{dio}, &Device::BCM2835::BCM2835_GPIO_PUD_UP);
    for my $i (0..7) {
        $temp >>= 1;
        _write($self->{clk}, 0);
        if ($self->_read($self->{clk})) {
            $temp |= 0x80;
        }
        _write($self->{clk}, 1);
        _gpio_fsel($self->{dio}, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
    }
    return $temp;
}

sub get_buttons {
    my ($self) = @_;
    my $keys = 0;
    _write($self->{stb}, 0);
    $self->send_byte(0x42);
    for my $i (0..3) {
        $keys |= $self->receive() << $i;
    }
    _write($self->{stb}, 1);
    return $keys;
}

sub rotate_bits {
    my ($self, $num) = @_;
    for my $i (0..4) {
        $num = $self->rotr($num, 8);
    }
    return $num;
}

sub rotr {
    my ($self, $num, $bits) = @_;
    $num &= (2**$bits-1);
    my $bit = $num & 1;
    $num >>= 1;
    if ($bit) {
        $num |= (1 << ($bits-1));
    }
    return $num
}

sub stb_low {
    my($self) = @_;
    _write($self->{stb}, 0);
}

sub stb_high {
    my($self) = @_;
    _write($self->{stb}, 1);
}

1;

=head1 AUTHOR

Adam Wien, C<< <awien at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-tm1638 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-TM1638>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::TM1638


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-TM1638>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-TM1638>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-TM1638>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-TM1638/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Adam Wien.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Device::TM1638
