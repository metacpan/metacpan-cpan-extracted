package Imager::Barcode128;
$Imager::Barcode128::VERSION = '0.0101';
use strict;
use Moo;
use Imager;
use Ouch;
use Exporter;
use base 'Exporter';

use constant CodeA  => chr(0xf4);
use constant CodeB  => chr(0xf5);
use constant CodeC  => chr(0xf6);
use constant FNC1   => chr(0xf7);
use constant FNC2   => chr(0xf8);
use constant FNC3   => chr(0xf9);
use constant FNC4   => chr(0xfa);
use constant Shift  => chr(0xfb);
use constant StartA => chr(0xfc);
use constant StartB => chr(0xfd);
use constant StartC => chr(0xfe);
use constant Stop   => chr(0xff);

our @EXPORT_OK = qw(FNC1 FNC2 FNC3 FNC4 Shift);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our @ENCODING = qw(11011001100 11001101100 11001100110 10010011000 10010001100 10001001100 10011001000 10011000100 10001100100 11001001000 11001000100 11000100100 10110011100 10011011100 10011001110 10111001100 10011101100 10011100110 11001110010 11001011100 11001001110 11011100100 11001110100 11101101110 11101001100 11100101100 11100100110 11101100100 11100110100 11100110010 11011011000 11011000110 11000110110 10100011000 10001011000 10001000110 10110001000 10001101000 10001100010 11010001000 11000101000 11000100010 10110111000 10110001110 10001101110 10111011000 10111000110 10001110110 11101110110 11010001110 11000101110 11011101000 11011100010 11011101110 11101011000 11101000110 11100010110 11101101000 11101100010 11100011010 11101111010 11001000010 11110001010 10100110000 10100001100 10010110000 10010000110 10000101100 10000100110 10110010000 10110000100 10011010000 10011000010 10000110100 10000110010 11000010010 11001010000 11110111010 11000010100 10001111010 10100111100 10010111100 10010011110 10111100100 10011110100 10011110010 11110100100 11110010100 11110010010 11011011110 11011110110 11110110110 10101111000 10100011110 10001011110 10111101000 10111100010 11110101000 11110100010 10111011110 10111101110 11101011110 11110101110 11010000100 11010010000 11010011100 1100011101011);

our %CODE_CHARS = ( 
    A => [ (map { chr($_) } 040..0137, 000..037), FNC3, FNC2, Shift, CodeC, CodeB, FNC4, FNC1, StartA, StartB, StartC, Stop ], 
    B => [ (map { chr($_) } 040..0177), FNC3, FNC2, Shift, CodeC, FNC4, CodeA, FNC1, StartA, StartB, StartC, Stop ], 
    C => [ ("00".."99"), CodeB, CodeA, FNC1, StartA, StartB, StartC, Stop ]
);

# Provide string equivalents to the constants
our %FUNC_CHARS = ('CodeA'  => CodeA,
               'CodeB'  => CodeB,
               'CodeC'  => CodeC,
               'FNC1'   => FNC1,
               'FNC2'   => FNC2,
               'FNC3'   => FNC3,
               'FNC4'   => FNC4,
               'Shift'  => Shift,
               'StartA' => StartA,
               'StartB' => StartB,
               'StartC' => StartC,
               'Stop'   => Stop );

# Convert the above into a 2-dimensional hash
our %CODE = ( A => { map { $CODE_CHARS{A}[$_] => $_ } 0..106 },
          B => { map { $CODE_CHARS{B}[$_] => $_ } 0..106 },
          C => { map { $CODE_CHARS{C}[$_] => $_ } 0..106 } );


=head1 NAME

Imager::Barcode128 - Create GS1-128 compliant bar codes using Imager

=head1 VERSION

version 0.0101

=head1 SYNOPSIS

 use Imager::Barcode128;

 my $barcode = Imager::Barcode128->new( text => 'My cool barcode' );
 $barcode->draw;
 $barcode->image->save(file => 'barcode.png');

=head1 DESCRIPTION

If you want to generate GS1-128 compliant bar codes using L<Imager> then look no further!

=head1 EXPORTS

By default this module exports nothing. However, there are a number of constants that represent special characters used in the CODE 128 symbology that you may wish to include. For example if you are using the EAN-128 or UCC-128 code, the string to encode begins with the FNC1 character. To encode the EAN-128 string "00 0 0012345 555555555 8", you would do the following:

 my $barcode = Imager::Barcode128->new(text => FNC1.'00000123455555555558');

To have this module export one or more of these characters, specify them on the use statement or use the special token ':all' instead to include all of them. Examples:

 use Imager::Barcode128 qw(FNC1 Shift);
 use Imager::Barcode128 qw(:all);

Here is the complete list of the exportable characters. They are assigned to high-order ASCII characters purely arbitrarily for the purposes of this module; the values used do not reflect any part of the GS1-128 standard.

 FNC1   0xf7
 FNC2   0xf8
 FNC3   0xf9
 FNC4   0xfa
 Shift  0xfb

=head1 METHODS

=head2 new(text => 'Product #45')

Constructor.

=over

=item image

The L<Imager> object to draw the bar code on to. Required.

=item text

The text to be encoded into the bar code. Required.

=item x

The x coordinate of the top left corner to start drawing the bar code. Defaults to 0.

=item y

The y coordinate of the top left corner to start drawing the bar code. Defaults to 0.

=back

=cut

=head2 x()

Get or set the x coordinate of the top left corner of where to start drawing the bar code.

=cut

has x => (
    is          => 'rw',
    default     => sub { 0 },
);

=head2 y()

Get or set the y coordinate of the top left corner of where to start drawing the bar code.

=cut

has y => (
    is          => 'rw',
    default     => sub { 0 },
);

=head2 color()

Get or set the color of the bar code. Defaults to C<black>. You can also pass an L<Imager::Color> object.

=cut

has color => (
    is          => 'rw',
    default     => sub { 'black' },
);

=head2 scale()

Get or set the scale of the bar code. Defaults to C<2>. Not recommended to set it to less than 2.

A bar in the bar code is 1 pixel wide per unit of scale.

=cut

has scale => (
    is          => 'rw',
    default     => sub { 2 },
);

=head2 height()

Get or set the height of the bar code. Defaults to the height of the C<image>. 

=cut

has height => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->has_image ? $self->image->getheight : 100;
    },
);

=head2 image()

Get or set the L<Imager> object. Defaults to a 100px tall image with a white background. The image will be however long it needs to be to contain the bar code.

=cut

has image => (
    is          => 'rw',
    lazy        => 1,
    predicate   => 1,
    default     => sub {
        my $self = shift;
        my $x = length($self->_barcode) * $self->scale;
        my $image = Imager->new(xsize => $x, ysize => $self->height);
        $image->box(color => 'white', filled => 1);
        return $image;
    },
);

=head2 text()

Get or set the text to be encoded into the bar code.

=cut

has text => (
    is          => 'rw',
    required    => 1,
);

has _code => ( # private
    is          => 'rw',
    default     => sub { '' },
    isa         => sub {
            ouch('invalid code', 'Code must be one of A, B, or C.') unless ($_[0] eq 'A' || $_[0] eq 'B' || $_[0] eq 'C' || $_[0] eq '');
    },
);

has _encoded => ( # private
    is          => 'rw',
    default     => sub { [] },
);

has _barcode => ( # private
    is          => 'rw',
    lazy        => 1,
    default     => sub { 
        my $self = shift;
        return $self->barcode 
    },
);

=head2 draw()

Draws a barcode on the image. Returns C<$self> for method chaining.

=cut

sub draw {
    my $self = shift;
    my @barcode = split //, $self->barcode;
    my $x = $self->x;
    my $y = $self->y;
    my $scale = $self->scale;
    my $image = $self->image;
    my $height = $self->height;
    my $color = $self->color;
    foreach my $element (@barcode) {
        $x += $scale;
        next unless $element eq '#';
        $image->box(
            color   => $color,
            xmin    => $x - $scale,
            ymin    => $y,
            xmax    => $x,
            ymax    => $y + $height,
            filled  => 1,
        );
    }
    return $self;
}

sub barcode {
    my $self = shift;
    $self->encode;
    my @encoded = @{ $self->_encoded };
    ouch('no encoded text',"No encoded text found") unless @encoded;
    return $self->_barcode(join '', map { $_ = $ENCODING[$_]; tr/01/ \#/; $_ } @encoded); # cache it in case we need it for other things
}

sub encode {
    my ($self, $preferred_code) = @_;
    ouch('invalid preffered code',"Invalid preferred code ``$preferred_code''") if defined $preferred_code && !exists $CODE{$preferred_code};
    my $text = $self->text;
    $self->_code('');
    my $encoded = $self->_encoded([]);
    my $sanity = 0;
    while (length $text) {
        ouch('overflow',"Sanity Check Overflow") if $sanity++ > 1000;
        my @chars;
        if (defined $preferred_code && $preferred_code && (@chars = _encodable($preferred_code, $text))) {
            $self->start($preferred_code);
            push @$encoded, map { $CODE{$preferred_code}{$_} } @chars;
        }
        elsif (@chars = _encodable('C', $text)) {
            $self->start('C');
            push @$encoded, map { $CODE{C}{$_} } @chars;
        }
        else {
            my %x = map { $_ => [ _encodable($_, $text) ] } qw(A B); 
            my $code = (@{$x{A}} >= @{$x{B}} ? 'A' : 'B'); # prefer A if equal 
            $self->start($code); 
            @chars = @{ $x{$code} }; 
            push @$encoded, map { $CODE{$code}{$_} } @chars; 
        } 
        ouch('no encoding', "Unable to find encoding for ``$text''") unless @chars; 
        substr($text, 0, length join '', @chars) = ''; 
    }
    $self->stop;
}

sub start {
    my ($self, $new_code) = @_;
    my $old_code = $self->_code;
    if ($old_code ne '') { 
        my $func = $FUNC_CHARS{"Code$new_code"} or ouch('cannot switch codes', "Unable to switch from ``$old_code'' to ``$new_code''");
        push @{ $self->_encoded }, $CODE{$old_code}{$func};
    } 
    else { 
        my $func = $FUNC_CHARS{"Start$new_code"} or ouch('bad start code',"Unable to start with ``$new_code''");
        @{ $self->_encoded } = $CODE{$new_code}{$func};
    }
    $self->_code($new_code);
}

sub stop {
    my ($self) = @_;
    my $encoded = $self->_encoded;
    my $sum = $encoded->[0];
    for (my $i = 1; $i < @{ $encoded }; ++$i) {
        $sum += $i * $encoded->[$i];
    }
    my $stop = Stop;
    push @{ $encoded }, ($sum % 103), $CODE{C}{$stop};
}

sub _encodable {
    my ($code, $string) = @_;
    my @chars;
    while (length $string) { 
        my $old = $string; 
        push @chars, $1 while($code eq 'C' && $string =~ s/^(\d\d)//); 
        my $char; 
        while (defined($char = substr($string, 0, 1))) { 
            last if $code ne 'C' && $string =~ /^\d\d\d\d\d\d/; 
            last unless exists $CODE{$code}{$char}; 
            push @chars, $char; 
            $string =~ s/^\Q$char\E//; 
        } 
        last if $old eq $string; # stop if no more changes made to $string 
    } 
    return @chars;
}

=head1 EXCEPTIONS

This module will throw an L<Ouch> if anything goes wrong. Under normal circumstances you should not expect to need to handle exceptions.

=head1 TODO

None that I can think of at this time.

=head2 SEE ALSO

Most of the logic of this module was stolen from an older module called L<Barcode::Code128>. I build this because I wanted to generate the bar codes with L<Imager> rather than L<GD>.

=head1 PREREQS

L<Moo>
L<Imager>
L<Ouch>

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/Imager-Barcode128>

=item Bug Reports

L<http://github.com/rizen/Imager-Barcode128/issues>

=back


=head1 AUTHOR

=over

=item JT Smith <jt_at_plainblack_dot_com>

=back

=head1 LEGAL

Imager::Barcode128 is Copyright 2015 Plain Black Corporation (L<http://www.plainblack.com>) and is licensed under the same terms as Perl itself.

=cut

1;
