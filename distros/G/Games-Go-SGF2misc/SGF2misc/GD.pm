# Games::Go::SGF2misc::GD
#
# Author: Orien Vandenbergh <orien@icecode.com>

package Games::Go::SGF2misc::GD;

use 5.006;
use strict;
no warnings;

use GD;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [qw( )] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.96';

# sub new() {{{
sub new() {
    my $class = shift;
    my $self = bless( { @_ }, $class );
    $self->init();
    return $self;
}
# }}}
# sub init() {{{
sub init() {
    my ($self) = @_;
    $self->{'imagesize'}    = 64    unless $self->{'imagesize'};
    $self->{'boardsize'}    = 19    unless $self->{'boardsize'};
    $self->{'antialias'}    = 1     unless defined $self->{'antialias'};

    $self->{'stonesize'}    = int( $self->{'imagesize'} / $self->{'boardsize'} );
    $self->{'border'}       = int( ($self->{'imagesize'} - ($self->{'stonesize'} * $self->{'boardsize'})) /2 ) + int($self->{'stonesize'}/2);
    $self->{'image'}        = GD::Image->newTrueColor($self->{'imagesize'},$self->{'imagesize'});

    if ($self->{'gobanColor'}) {
        $self->{'gobanColor'}   = $self->{'image'}->colorAllocate(@{ $self->{'gobanColor'} });
    } else {
        $self->{'gobanColor'}   = $self->{'image'}->colorAllocate(0xee,0xb1,0x4b);
    }
    if ($self->{'whiteColor'}) {
        $self->{'whiteColor'}   = $self->{'image'}->colorAllocate(@{ $self->{'whiteColor'} });
    } else {
        $self->{'whiteColor'}   = $self->{'image'}->colorAllocate(0xff,0xff,0xff);
    }
    if ($self->{'blackColor'}) {
        $self->{'blackColor'}   = $self->{'image'}->colorAllocate(@{ $self->{'blackColor'} });
    } else {
        $self->{'blackColor'}   = $self->{'image'}->colorAllocate(0x00,0x00,0x00);
    }
}
# }}}
# sub gobanColor() {{{
sub gobanColor() {
    my $self = shift;

    $self->{'kaya'} = $self->{'image'}->colorAllocate(@_);
}
# }}}
# sub whiteColor() {{{
sub whiteColor() {
    my $self = shift;

    $self->{'white'} = $self->{'image'}->colorAllocate(@_);
}
# }}}
# sub blackColor() {{{
sub blackColor() {
    my $self = shift;

    $self->{'black'} = $self->{'image'}->colorAllocate(@_);
}
# }}}
# sub drawGoban() {{{
sub drawGoban() {
    my ($self) = shift;

    my $color = $self->{'image'}->colorAllocate(0,0,0);
    my $bottomright = $self->{'stonesize'} * $self->{'boardsize'} - ($self->{'stonesize'} - $self->{'border'});

    $self->{'image'}->fill(0,0,$self->{'kaya'});
    $self->{'image'}->setThickness(1);

    $self->{'image'}->rectangle($self->{'border'},$self->{'border'},$bottomright,$bottomright,$color);
    foreach my $x (($self->{'border'} + $self->{'stonesize'})..$bottomright) {
        next if (($x-$self->{'border'}) % $self->{'stonesize'});
        $self->{'image'}->line($x,$self->{'border'},$x,$bottomright,$color);
        $self->{'image'}->line($self->{'border'},$x,$bottomright,$x,$color);
    }
    if ($self->{'antialias'}) {
        $self->{'image'}->setAntiAliased($color);
        $color = gdAntiAliased;
    }
    my %hoshi = (   5   => [[2,2]                   ], 
                    7   => [[3,3]                   ], 
                    9   => [[2,2],          [6,2],
                                    [4,4],  
                            [2,6],          [6,6]   ], 
                    11  => [[3,3],          [7,3],
                                    [5,5],
                            [3,7],          [7,7]   ],
                    13  => [[2,2],  [6,2],  [10,2],
                            [2,6],  [6,6],  [10,6],
                            [2,10], [6,10], [10,10]   ],
                    19  => [[3,3],  [9,3],  [15,3],
                            [3,9],  [9,9],  [15,9],
                            [3,15], [9,15], [15,15] ],
                );
    foreach my $point (@{ $hoshi{$self->{'boardsize'}} }) {
        my $x = $self->{'border'}+($self->{'stonesize'}*$point->[0]);
        my $y = $self->{'border'}+($self->{'stonesize'}*$point->[1]);
        $self->{'image'}->filledEllipse($x,$y,$self->{'stonesize'}/4,$self->{'stonesize'}/4,$color)
    }
}
# }}}
# sub calcXY {{{
sub calcXY {
    my $self = shift;
    my ($pos) = @_;

    my ($x,$y);
    if (ref($pos) eq 'ARRAY') {
        ($x,$y) = @{ $pos };
    } else {
        $pos = lc($pos);
        $pos =~ /([a-z])([a-z])/;
        ($x,$y) = ((ord($1)-ord('a')),(ord($2)-ord('a')));
    }

    return ($self->{'border'}+($self->{'stonesize'}*$x),$self->{'border'}+($self->{'stonesize'}*$y));
}
# }}}

# sub placeStone {{{
sub placeStone {
    my $self = shift;
    my ($player, $move) = @_;
    
    my ($x,$y) = $self->calcXY($move);

    my $color;
    if ( $player =~ /b/i ) {
        $color=$self->{'black'};
        if ($self->{'antialias'}) {
            $self->{'image'}->setAntiAliased($color);
            $color = gdAntiAliased
        }
        $self->{'image'}->filledEllipse($x,$y,$self->{'stonesize'},$self->{'stonesize'},$color);
    } else {
        $color=$self->{'white'};
        if ($self->{'antialias'}) {
            $self->{'image'}->setAntiAliased($color);
            $color = gdAntiAliased
        }
        $self->{'image'}->filledEllipse($x,$y,$self->{'stonesize'},$self->{'stonesize'},$color);
        if ($self->{'stonesize'} > 9) {
            $color=$self->{'black'};
            if ($self->{'antialias'}) {
                $self->{'image'}->setAntiAliased($color);
                $color = gdAntiAliased
            }
            $self->{'image'}->ellipse($x,$y,$self->{'stonesize'},$self->{'stonesize'},$color);
        }
    }
}
# }}}
# sub addCircle {{{
sub addCircle {
    my $self = shift;
    return unless ($self->{'stonesize'} > 5);
    my ($move,$stone) = @_;
    my $ratio = 1.5;
    
    my ($x,$y) = $self->calcXY($move);
    
    my @base = $self->{'image'}->rgb($self->{'image'}->getPixel($x,$y));
    my $color = $self->{'black'};
    if ( $stone ) {
        $color = $self->{'image'}->colorAllocate(255-$base[0], 255-$base[1], 255-$base[2]);
    }

    if ($self->{'antialias'}) {
        $self->{'image'}->setAntiAliased($color);
        $color = gdAntiAliased
    }
    $self->{'image'}->ellipse($x,$y,$self->{'stonesize'}/$ratio,$self->{'stonesize'}/$ratio,$color);
}
# }}}
# sub addLetter {{{
sub addLetter {
    my $self = shift;
    return unless ($self->{'stonesize'} > 5);
    my ($move,$letter,$stone) = @_;
    my $ratio = 1.3;
    my $font = $ENV{TTFONT} ? $ENV{TTFONT} : return;
    
    my ($x,$y) = $self->calcXY($move);
    
    my @base = $self->{'image'}->rgb($self->{'image'}->getPixel($x,$y));
    my $color = $self->{'black'};
    if ( $stone ) {
        $color = $self->{'image'}->colorAllocate(255-$base[0], 255-$base[1], 255-$base[2]);
    } else {
        my $d = ($self->{'stonesize'})/2;
        $self->{'image'}->filledRectangle($x-$d,$y-$d,$x+$d,$y+$d,$self->{'kaya'});
    }

    my $max = $self->{'stonesize'}/$ratio;
    my $points = $max+1;
    my ($width,$height);
    do {
        $points--;
        my @bounds = GD::Image->stringFT($color,$font,$points,0,$x,$y,$letter) or return;
        $height = $bounds[3] - $bounds[5];
        $width  = $bounds[2] - $bounds[0];
    } while (($height>$max) or ($width>$max));

    $self->{'image'}->stringFT($color,$font,$points,0,$x-($width/2),$y+($height/2),$letter);
}
# }}}
# sub addSquare {{{
sub addSquare {
    my $self = shift;
    return unless ($self->{'stonesize'} > 5);
    my ($move,$stone) = @_;
    my $ratio = 2;
    
    my ($x,$y) = $self->calcXY($move);
    
    my @base = $self->{'image'}->rgb($self->{'image'}->getPixel($x,$y));
    my $color = $self->{'black'};
    if ( $stone ) {
        $color = $self->{'image'}->colorAllocate(255-$base[0], 255-$base[1], 255-$base[2]);
    }

    my $d = ($self->{'stonesize'}/$ratio)/2;

    $self->{'image'}->rectangle($x-$d,$y-$d,$x+$d,$y+$d,$color);
}
# }}}
# sub addTriangle {{{
sub addTriangle {
    my $self = shift;
    return unless ($self->{'stonesize'} > 5);
    my ($move,$stone) = @_;
    my $ratio = 1.5;
    my $pi = 3.1415927;

    my ($x,$y) = $self->calcXY($move);

    my @base = $self->{'image'}->rgb($self->{'image'}->getPixel($x,$y));
    my $color = $self->{'black'};
    if ( $stone ) {
        $color = $self->{'image'}->colorAllocate(255-$base[0], 255-$base[1], 255-$base[2]);
    }

    my $b = ($self->{'stonesize'}/$ratio)*sin($pi/3);
    my $c = ($self->{'stonesize'}/$ratio)*cos($pi/3);
    
    my $tri = new GD::Polygon;
    $tri->addPt($x,$y-(2*$b/3));
    $tri->addPt($x-$c,$y+($b/3));
    $tri->addPt($x+$c,$y+($b/3));

    if ($self->{'antialias'}) {
        $self->{'image'}->setAntiAliased($color);
        $color = gdAntiAliased;
    }
    $self->{'image'}->polygon($tri,$color);
}
# }}}
# sub save {{{
sub save {
    my $self = shift;
    my ($filename,$format) = @_;

    open IMG, ">$filename" or die "Unable to open $filename: $!, stopped ";
    binmode IMG;

    $format = 'png' unless $format;
    
    if ( $format =~ /jp(e?)g/i ) {
        print IMG $self->{'image'}->jpeg;
    } elsif ( $format =~ /gd2/i ) {
        print IMG $self->{'image'}->gd2;
    } elsif ( $format =~ /gd/i ) {
        print IMG $self->{'image'}->gd;
    } else {
        print IMG $self->{'image'}->png;
    }
    close IMG;
}
# }}}
# sub dump {{{
sub dump {
    my $self = shift;
    my ($format) = @_;

    $format = 'png' unless $format;
    
    if ( $format =~ /jp(e?)g/i ) {
        return $self->{'image'}->jpeg;
    } elsif ( $format =~ /gd2/i ) {
        return $self->{'image'}->gd2;
    } elsif ( $format =~ /gd/i ) {
        return $self->{'image'}->gd;
    } else {
        return $self->{'image'}->png;
    }
}
# }}}

__END__

=head1 NAME

GD::SGF - Package to simplify SGF game rendering using GD::Image;

=head1 SYNOPSIS

    use Games::Go::SGF2misc::GD;

    my $image = new Games::Go::SGF2misc::GD('imagesize' => 256,
                                            'boardsize' => 19, 
                                            'antialias' => 1    );

    $image->gobanColor(127,127,127);
    $image->drawGoban();
    
    $image->placeStone('b','cd');
    $image->placeStone('w',[4,2]);
    $image->placeStone('b','db');
    $image->placeStone('w','dc');
    $image->placeStone('b','cc');
    $image->placeStone('w','eb');
    $image->placeStone('b','cb');

    $image->addCircle('cb',1);

    $image->save($filename);

=head1 DESCRIPTION

Games::Go::SGF2misc::GD is a Perl Wrapper for the GD.pm module.  It
simplifies the process of rendering an image from an SGF file.  It is
however still a primitive interface, in that it does not contain any
internal intellegence about how to process an SGF file, this is merely
designed to be used in conjunction with an SGF reader such as
L<Games::Go::SGF2misc> or L<Games::Go::SGF>.

    $image = Games::Go::SGF2misc::GD->new(['imagesize' => 64],['boardsize' => 19],['antialias' => 1])

To create a new image, call the new() function.  It's three
arguments are optional, but if specified will override the defaults.

B<imagesize> is the width and height of the image created and defaults to 64 if
not specified.  B<boardsize> is the number of lines horizontally and vertically
across the board, with a default of 19.  B<antialias> is a boolean value which
controls whether the resulting image is fed through a slight blur filter to
remove jaggies.  B<antialias> defaults to on, but can be overly slow on very
large renders.

    $image->gobanColor($red,$green,$blue)
    $image->whiteColor($red,$green,$blue)
    $image->blackColor($red,$green,$blue)

These functions set the colors used for rendering the game.
B<$red>, B<$green>, and B<$blue> are integers between 0 and 255;

    $image->drawGoban()

This command does all the initial setup of rendering the Goban.  It sets the
background color, and draws lines and star points.  If you don't call this
before any of the other drawing functions, you can expect your output to be a
little weird.

    $image->placeStone($color,$position)

This command puts a stone into the image at the position specified.
B<$color> is one of /[BbWw]/ and controls whether a black or white
stone is added. B<$position> is either an array of x,y coordinates
with 0,0 in the upper left corner, or a string of letters
representing coordinates at which the stone should be placed, in
standard SGF format. 'aa' is the upper left corner, and 'ss' is the
lower right (of a 19x19 game).

    $image->addCircle($position,[$onStone])
    $image->addSquare($position,[$onStone])
    $image->addTriangle($position,[$onStone])

This command adds either a circle, square or triange around the
coordinates specified by B<$position>. Be default GD::SGF renders
the shape in black.  If you want to render the shape on top of a
stone, supply a true value for B<$onStone>, to tell the module to
render the shape in an inverse color from what is below it.

    $image->addLetter($position,$letter,[$onStone])

This command renders a letter above the coordinates specified by
B<$position>.  The processing performed is very similar to the other
add* functions defined above, with one major difference.  If
B<$onStone> does not evaluate to true, then the area under the
letter will also be cleared (to removed the intersection of the two
lines) before rendering.

    $image->save($filename)

Saves the in memory image into the filename specified in
B<$filename>.  The module will attempt to guess the format of the
output image based upon the extension of the filename.  Supported
file formats are [ PNG, JPEG, GD2, GD ].  If the module is unable to
determine the desired output format, the image will be output as a
PNG.

    $png = $image->dump($format)

Converts the in memory image into an image of the format specified
in B<$format>.  If no format is specified the module defaults to
PNG.  The image is then returned to the calling function for
storage.

=head1 TODO

Remove the need to specify whether the marks are being rendered above a
stone or not.  Probably by implementing some sort of in memory array of
C<placed> stones, and checking position of the mark against that.

Presently the hoshi points are defined in a massive hash struct.  I know
the 19x19 hoshi's are correct but similarly I am sure that that rest are
wrong, or simply not listed.  Check with someone to find the correct
hoshi points for oddball goban sizes.

=head1 AUTHOR

Orien Vandenbergh C<< <orien@icecode.com> >>

=head1 SEE ALSO

L<Games::Go::SGF2misc>, L<GD>, L<GD::Image>

=cut
