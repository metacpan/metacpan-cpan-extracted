# Games::Go::SGF2misc::SVG
#
# Author: Orien Vandenbergh <orien@icecode.com>
# $Id: SVG.pm,v 1.1.1.1 2004/05/10 20:52:19 orien Exp $
# vi: fdm=marker fdl=0

package Games::Go::SGF2misc::SVG;

use 5.006;
use strict;
use warnings;

use Image::LibRSVG;
use XML::LibXML;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [qw( )] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '1.00';

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
    $self->{'imagesize'}    = '3in' unless $self->{'imagesize'};
    $self->{'boardsize'}    = 19    unless $self->{'boardsize'};
    $self->{'blocksize'}    = 50;
    $self->{'virtualsize'}  = $self->{'blocksize'} * $self->{'boardsize'};

    $self->{'border'}       = $self->{'blocksize'} / 2;
    $self->{'stonesize'}    = $self->{'border'} - 2;

    $self->{'gobanColor'}   = '#eeb14b'  unless $self->{'gobancolor'};
    $self->{'whiteColor'}   = 'white'    unless $self->{'whitecolor'};
    $self->{'blackColor'}   = 'black'    unless $self->{'blackcolor'};

    if (ref($self->{'gobanColor'}) eq 'ARRAY') {
        $self->{'gobanColor'} = sprintf('rgb(%d,%d,%d)', @{$self->{'gobanColor'}});
    }
    if (ref($self->{'whiteColor'}) eq 'ARRAY') {
        $self->{'whiteColor'} = sprintf('rgb(%d,%d,%d)', @{$self->{'gobanColor'}});
    }
    if (ref($self->{'blackColor'}) eq 'ARRAY') {
        $self->{'blackColor'} = sprintf('rgb(%d,%d,%d)', @{$self->{'gobanColor'}});
    }

    $self->{'document'}     = XML::LibXML->createDocument(1.0, "UTF-8");
    $self->{'svg'}          = $self->{'document'}->createElement("svg");
    $self->{'svg'}->setAttribute('xmlns','http://www.w3.org/2000/svg');
    $self->{'svg'}->setAttribute('xmlns:xlink','http://www.w3.org/1999/xlink');
    $self->{'svg'}->setAttribute('width',$self->{'imagesize'});
    $self->{'svg'}->setAttribute('height',$self->{'imagesize'});
    $self->{'svg'}->setAttribute('viewBox',sprintf('0 0 %d %d', $self->{'virtualsize'}, $self->{'virtualsize'}));
    $self->{'svg'}->setAttribute('preserveAspectRatio','xMidYMid meet');
    $self->{'document'}->setDocumentElement($self->{'svg'});

    my $node;
    my $grad;
    my $defs = $self->{'svg'}->addNewChild(undef,'defs');
    $defs->setAttribute('id','defs00001');

# Gradients {{{
    $grad = $defs->addNewChild(undef,'linearGradient');
    $grad->setAttribute('id','BlackLinearGradient');

    $node = $grad->addNewChild(undef,'stop');
    $node->setAttribute('offset', '0');
    $node->setAttribute('style', 'stop-color:#888888;stop-opacity:1;');

    $node = $grad->addNewChild(undef,'stop');
    $node->setAttribute('offset', '1');
    $node->setAttribute('style', 'stop-color:#000000;stop-opacity:1;');

    $grad = $defs->addNewChild(undef,'linearGradient');
    $grad->setAttribute('id','WhiteLinearGradient');

    $node = $grad->addNewChild(undef,'stop');
    $node->setAttribute('offset', '0');
    $node->setAttribute('style', 'stop-color:#ffffff;stop-opacity:1;');

    $node = $grad->addNewChild(undef,'stop');
    $node->setAttribute('offset', '1');
    $node->setAttribute('style', 'stop-color:#dddddd;stop-opacity:1;');

    $node = $defs->addNewChild(undef,'radialGradient');
    $node->setAttribute('id', 'BlackRadialGradient');
    $node->setAttribute('cx', '0.36437908');
    $node->setAttribute('cy', '0.335985');
    $node->setAttribute('fx', '0.36437908');
    $node->setAttribute('fy', '0.335985');
    $node->setAttribute('r', '0.55236467');
    $node->setAttribute('xlink:href','#BlackLinearGradient');

    $node = $defs->addNewChild(undef,'radialGradient');
    $node->setAttribute('id', 'WhiteRadialGradient');
    $node->setAttribute('cx', '0.36437908');
    $node->setAttribute('cy', '0.335985');
    $node->setAttribute('fx', '0.36437908');
    $node->setAttribute('fy', '0.335985');
    $node->setAttribute('r', '0.59236467');
    $node->setAttribute('xlink:href','#WhiteLinearGradient');
# }}}

    $node = $defs->addNewChild(undef,'circle');
    $node->setAttribute('id','Stone');
    $node->setAttribute('r',$self->{'stonesize'});

    $node = $defs->addNewChild(undef,'circle');
    $node->setAttribute('id', 'Hoshi');
    $node->setAttribute('r',$self->{'blocksize'}/10);

    $node = $defs->addNewChild(undef,'circle');
    $node->setAttribute('id', 'MarkerCircle');
    $node->setAttribute('r',$self->{'stonesize'}/2);

    $node = $defs->addNewChild(undef,'rect');
    $node->setAttribute('id', 'MarkerRectangle');
    $node->setAttribute('x',0);
    $node->setAttribute('y',0);
    $node->setAttribute('width', $self->{'blocksize'}/2.5);
    $node->setAttribute('height',$self->{'blocksize'}/2.5);
    $node->setAttribute('transform',sprintf('translate(-%d,-%d)',$self->{'blocksize'}/5,$self->{'blocksize'}/5));

    my $pi = 3.1415927;
    my $b = ($self->{'blocksize'}/2) * sin($pi/3);
    my $c = ($self->{'blocksize'}/2) * cos($pi/3);

    $node = $defs->addNewChild(undef,'polygon');
    $node->setAttribute('id', 'MarkerTriangle');
    $node->setAttribute('points',sprintf('0,-%f, -%f,%f %f,%f', 2*($b/3), $c,($b/3), $c,($b/3)));
}
# }}}
# sub drawGoban() {{{
sub drawGoban() {
    my ($self) = shift;

    my $node;
    my $goban = $self->{'svg'}->addNewChild(undef,'g');
    $goban->setAttribute('id','Goban');

    $node = $goban->addNewChild(undef,'rect');
    $node->setAttribute('id','board');
    $node->setAttribute('x','0');
    $node->setAttribute('y','0');
    $node->setAttribute('width',$self->{'virtualsize'});
    $node->setAttribute('height',$self->{'virtualsize'});
    $node->setAttribute('style',sprintf('fill:%s;',$self->{'gobanColor'}));
    
    $node = $goban->addNewChild(undef,'rect');
    $node->setAttribute('id',       'border');
    $node->setAttribute('x',        $self->{'border'});
    $node->setAttribute('y',        $self->{'border'});
    $node->setAttribute('width',    $self->{'virtualsize'} - $self->{'blocksize'});
    $node->setAttribute('height',   $self->{'virtualsize'} - $self->{'blocksize'});
    $node->setAttribute('style',    'stroke:black;stroke-width:3;fill-opacity:0;');

    foreach my $x (($self->{'border'} + $self->{'blocksize'})..$self->{'virtualsize'}-$self->{'blocksize'}) {
        next if (($x-$self->{'border'}) % $self->{'blocksize'});
        $node = $goban->addNewChild(undef,'line');
        #$node->setAttribute('id',       'border');
        $node->setAttribute('x1',       $x);
        $node->setAttribute('y1',       $self->{'border'});
        $node->setAttribute('x2',       $x);
        $node->setAttribute('y2',       $self->{'virtualsize'} - $self->{'border'});
        $node->setAttribute('style',    'stroke:black;stroke-width:1;');

        $node = $goban->addNewChild(undef,'line');
        #$node->setAttribute('id',       'border');
        $node->setAttribute('x1',       $self->{'border'});
        $node->setAttribute('y1',       $x);
        $node->setAttribute('x2',       $self->{'virtualsize'} - $self->{'border'});
        $node->setAttribute('y2',       $x);
        $node->setAttribute('style',    'stroke:black;stroke-width:1;');
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
        my $x = $self->{'border'}+($self->{'blocksize'}*$point->[0]);
        my $y = $self->{'border'}+($self->{'blocksize'}*$point->[1]);
        $node = $goban->addNewChild(undef,'use');
        #$node->setAttribute('id',           'border');
        $node->setAttribute('x',            $x);
        $node->setAttribute('y',            $y);
        $node->setAttribute('xlink:href',   '#Hoshi');
        $node->setAttribute('style',        'fill:black;');
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

    return ($self->{'border'}+($self->{'blocksize'}*$x),$self->{'border'}+($self->{'blocksize'}*$y));
}
# }}}
# sub calcAA {{{
sub calcAA {
    my $self = shift;
    my ($pos) = @_;

    my ($x,$y);
    if (ref($pos) eq 'ARRAY') {
        ($x,$y) = @{ $pos };
        $x = chr(ord('a')+$x);
        $y = chr(ord('a')+$y);
        return ($x.$y);
    } else {
        return lc($pos);
    }
}
# }}}
# sub fetchGroup {{{
sub fetchGroup() {
    my $self = shift;
    my ($move) = @_;
    
    my $id = sprintf('pos_%s', $move);
    my $node = $self->{'document'}->getElementsById($id);

    if (not defined $node) {
        $node = $self->{'positions'}{$move};
    }
    if (not defined $node) {
        $node = $self->{'svg'}->addNewChild(undef,'g');
        $node->setAttribute('id',sprintf('pos_%s',$move));
        $node->setAttribute('transform',sprintf('translate(%d,%d)',$self->calcXY($move)));
        $self->{'positions'}{$move} = $node;
    }

    return $node;
}
#}}}
# sub setLastMove {{{
sub setLastMove() {
    my $self = shift;
    my ($group) = @_;
    
    my $node =  $self->{'document'}->getElementsById("LastMoveMarker");
    if ($node) {
        my $parent = $node->parentNode();
        $parent->removeChild($node);
    } else {
        $node = $self->{'document'}->createElement('use');
        $node->setAttribute('class','marker')
    }
    $group->addChild($node);

    return $node;
}
#}}}

# sub placeStone {{{
sub placeStone {
    my $self = shift;
    my ($player, $move) = @_;
    
    my ($x,$y) = $self->calcXY($move);
    my $loc    = $self->calcAA($move);
    my $group  = $self->fetchGroup($loc);

    $group->setAttribute('transform',sprintf('translate(%d,%d)',$self->calcXY($move)));
    my $node = $group->addNewChild(undef,'use');
    $node->setAttribute('xlink:href','#Stone');
    $node->setAttribute('class','stone');

    if ( $player =~ /b/i ) {
        $group->setAttribute('class','black');
        if ($self->{'useGradients'}) {
            $node->setAttribute('style','fill:url(#BlackRadialGradient);stroke:black;stroke-width:1;');
        } else {
            $node->setAttribute('style','fill:black;stroke:black;stroke-width:1;');
        }
    } else {
        $group->setAttribute('class','white');
        if ($self->{'useGradients'}) {
            $node->setAttribute('style','fill:url(#WhiteRadialGradient);stroke:black;stroke-width:1;');
        } else {
            $node->setAttribute('style','fill:white;stroke:black;stroke-width:1;');
        }
    }
}
# }}}
# sub addCircle {{{
sub addCircle {
    my $self = shift;
    my ($move) = @_;
    
    my $loc     = $self->calcAA($move);
    my $group   = $self->fetchGroup($loc);

    my $node = $group->addNewChild(undef,'use');
    $node->setAttribute('xlink:href','#MarkerCircle');
    $node->setAttribute('class', 'marker');

    my @attr = $group->attributes();
    my $color = 'white';
    foreach my $attr(@attr) {
        if (($attr->name() eq 'class') and ($attr->getValue() =~ /black/i)) {
                $color = 'black';
        }
    }
    if ($color eq 'black') {
        $node->setAttribute('style','stroke:white;stroke-width:2;fill-opacity:0;');
    } else {
        $node->setAttribute('style','stroke:black;stroke-width:1;fill-opacity:0;');
    }
}
# }}}
# sub addLetter {{{
sub addLetter {
    my $self = shift;
    my ($move,$text) = @_;
    
    my $loc     = $self->calcAA($move);
    my $group   = $self->fetchGroup($loc);

    my $node = $group->addNewChild(undef,'text');
    #$node->setAttribute('x','0');
    $node->setAttribute('class', 'marker');
    $node->setAttribute('text-anchor','middle');
    $node->setAttribute('alignment-baseline','middle');

    $text =~ /\s*(\w{1,3})/;
    my $letter = $1;

    $node->setAttribute('font-size', $self->{'blocksize'} * 0.5);
    $node->setAttribute('y',$self->{'stonesize'}*0.46);
    
    $node->appendText($letter);

    my @attr = $group->attributes();
    my $color = 'white';
    foreach my $attr(@attr) {
        if (($attr->name() eq 'class') and ($attr->getValue() =~ /black/i)) {
                $color = 'black';
        }
    }
    if ($color eq 'black') {
        $node->setAttribute('fill', 'white');
        #$node->setAttribute('style','stroke:white;stroke-width:2;fill-opacity:0;');
    } else {
        $node->setAttribute('fill', 'black');
        #$node->setAttribute('style','stroke:black;stroke-width:1;fill-opacity:0;');
    }
}
# }}}
# sub addSquare {{{
sub addSquare {
    my $self = shift;
    my ($move) = @_;
    
    my $loc     = $self->calcAA($move);
    my $group   = $self->fetchGroup($loc);

    my $node = $group->addNewChild(undef,'use');
    $node->setAttribute('xlink:href','#MarkerRectangle');
    $node->setAttribute('class', 'marker');

    my @attr = $group->attributes();
    my $color = 'white';
    foreach my $attr(@attr) {
        if (($attr->name() eq 'class') and ($attr->getValue() =~ /black/i)) {
                $color = 'black';
        }
    }
    if ($color eq 'black') {
        $node->setAttribute('style','stroke:white;stroke-width:2;fill-opacity:0;');
    } else {
        $node->setAttribute('style','stroke:black;stroke-width:1;fill-opacity:0;');
    }
}
# }}}
# sub addTriangle {{{
sub addTriangle {
    my $self = shift;
    my ($move) = @_;
    
    my $loc     = $self->calcAA($move);
    my $group   = $self->fetchGroup($loc);

    my $node = $group->addNewChild(undef,'use');
    $node->setAttribute('xlink:href','#MarkerTriangle');
    $node->setAttribute('class', 'marker');

    my @attr = $group->attributes();
    my $color = 'white';
    foreach my $attr(@attr) {
        if (($attr->name() eq 'class') and ($attr->getValue() =~ /black/i)) {
                $color = 'black';
        }
    }
    if ($color eq 'black') {
        $node->setAttribute('style','stroke:white;stroke-width:2;fill-opacity:0;');
    } else {
        $node->setAttribute('style','stroke:black;stroke-width:1;fill-opacity:0;');
    }
}
# }}}
# sub save {{{
sub save {
    my $self = shift;
    my ($filename) = @_;

    open IMG, ">$filename" or die "Unable to open $filename: $!, stopped ";

    print IMG $self->{'document'}->toString($self->{'pretty'});
    close IMG;
}
# }}}
# sub export {{{
sub export {
    my $self = shift;
    my ($filename) = @_;

    my $rsvg = new Image::LibRSVG();

    $rsvg->loadImageFromString( $self->{'document'}->toString() );
    $rsvg->saveAs($filename);
}
# }}}
# sub dump {{{
sub dump {
    my $self = shift;
    my ($format) = @_;

    $format = 'svg' unless $format;
    
    if ( $format =~ /png/i ) {
        return undef;
        # Image::LibRSVG doesn't support this yet.
        my $rsvg = new Image::LibRSVG;
        $rsvg->loadImageFromString( $self->{'document'}->toString() );
        return $rsvg->getImageBitmap();
    } else {
        return $self->{'document'}->toString($self->{'pretty'});
    }
}
# }}}

__END__

=head1 NAME

Games::Go::SGF2misc::SVG - Package to simplify SGF game rendering using Image::LibrSVG

=head1 SYNOPSIS

    use Games::Go::SGF2misc::SVG;

    my $image = new Games::Go::SGF2misc::SVG('imagesize' => '3in',
                                             'boardsize' => 19, 
                                             'gobanColor'=> 'white' );

    $image->drawGoban();
    
    $image->placeStone('b','cd');
    $image->placeStone('w',[4,2]);
    $image->placeStone('b','db');
    $image->placeStone('w','dc');
    $image->placeStone('b','cc');
    $image->placeStone('w','eb');
    $image->placeStone('b','cb');

    $image->addCircle('cb',1);

    $image->save($filename);    # As a .svg
    $image->export($filename);  # As a .png

=head1 ABSTRACT

This module provides and SVG rendering backend for Games::Go::SVG2misc and
other SGF parsers.

=head1 DESCRIPTION

Games::Go::SGF2misc::SVG is a Perl Wrapper for the Image::LibRSVG.pm module.
It simplifies the process of rendering an image from an SGF file.  It is
however still a primitive interface, in that it does not contain any
internal intellegence about how to process an SGF file, this is merely
designed to be used in conjunction with an SGF reader such as
L<Games::Go::SGF2misc> or L<Games::Go::SGF>.

B<$image = Games::Go::SGF2misc::SVG->new(['imagesize' => 1in],['boardsize' => 19],['gobanColor' => 'white'])>

    To create a new image, call the new() function.  It's three
    arguments are optional, but if specified will override the defaults.

    B<imagesize> is the width and height of the image created and
    defaults to 2in if not specified.  B<boardsize> is the number of
    lines horizontally and vertically across the board, with a default
    of 19.  
    
    B<gobanColor>, b<whiteColor> and b<blackColor> are either an array of 
    integers between 0 and 255, and SVG color keyword name, or an SVG
    hextriplet in the form #FFFFFF, much like html.

B<$image->drawGoban()>

    This command does all the initial setup of rendering the Goban.  It
    sets the background color, and draws lines and star points.  If you
    don't call this before any of the other drawing functions, you can
    expect your output to be a little weird.

B<$image->placeStone($color,$position)>

    This command puts a stone into the image at the position specified.
    B<$color> is one of /[BbWw]/ and controls whether a black or white
    stone is added. B<$position> is either an array of x,y coordinates
    with 0,0 in the upper left corner, or a string of letters
    representing coordinates at which the stone should be placed, in
    standard SGF format. 'aa' is the upper left corner, and 'ss' is the
    lower right (of a 19x19 game).

B<$image->addCircle($position)>
B<$image->addSquare($position)>
B<$image->addTriangle($position)>

    This command adds either a circle, square or triange around the
    coordinates specified by B<$position>.

B<$image->addLetter($position,$letter)>

    This command renders a letter above the coordinates specified by
    B<$position>.  The processing performed is very similar to the other
    add* functions defined above.

B<$image->save($filename)>

    Saves the in memory image into the filename specified in
    B<$filename>.  The image will be saved as an uncompressed SVG file.

B<$image->export($filename)>

    Exports the in memory image into the filename specified in
    B<$filename> as an image in PNG format.

B<$png = $image->dump($format)>

    Converts the in memory image into an image of the format specified
    in B<$format>.  If no format is specified the module defaults to
    SVG.  The image is then returned to the calling function for
    storage.  The possible formats are 'SVG', and 'PNG'.

    ** dump as PNG Not currently supported **
    This function will be supported once it is supported by Image::LibRSVG
    which is, in turn, waiting for necessary support from gdk-pixbuf.

=head1 TODO

Presently the hoshi points are defined in a massive hash struct.  I know
the 19x19 hoshi's are correct but similarly I am sure that that rest are
wrong, or simply not listed.  Check with someone to find the correct
hoshi points for oddball goban sizes.

=head1 AUTHOR

Orien Vandenbergh C<orien@icecode.com>

=head1 SEE ALSO

L<Games::Go::SGF2misc>, L<Image::LibRSVG>, L<XML::LibXML>

=cut
