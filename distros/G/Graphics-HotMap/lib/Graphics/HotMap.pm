#!/usr/bin/perl -w

# Copyright (c) 2011 Mathieu Alorent
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

package Graphics::HotMap;
use strict;

=head1 NAME

Graphics::HotMap -- generate thermographic images.

=head1 SYNOPSIS

=for example

   use Graphics::HotMap;

   # Create a new HotMap
   my $hotMap = Graphics::HotMap->new(
         minValue => 1,
         maxValue => 50, 
         );  

   # Define scale
   $hotMap->scale(20);

   # Show legend
   $hotMap->legend(1);

   # Show CrossMarks and values
   $hotMap->crossMark(1,1);

   # Define a new size
   $hotMap->mapSize({ sizeX => 15, sizeY => 15 }); 

   # Add time
   $hotMap->addHorodatage(time, 15, 30);

   # Add layer
   $hotMap->addLayer({ layerName => '10_back', visibility => 1, sliceColor => 1 }); 

   # Add a zone
   $hotMap->addZone({
         zoneName => 'AllMap',
         layerName => '10_back',
         coordonates => [0,0,14,14],
         border => 1,
         }); 
   # And add some points
   $hotMap->addPoint({ layerName => '10_back', x => 2, y => 2,  value => 15 });
   $hotMap->addPoint({ layerName => '10_back', x => 1, y => 6,  value => 5  });
   $hotMap->addPoint({ layerName => '10_back', x => 9, y => 13, value => 25 });
   $hotMap->addLayer({ layerName => '20_inner' });

   # Add a zone
   $hotMap->addZone({
         zoneName => 'innerZone',
         layerName => '20_inner',
         coordonates => [4,0,9,6],
         border => 1,
         text => 'Inner Zone',
         });

   # And some points
   $hotMap->addPoint({ layerName => '20_inner', x => 5, y => 1, value => 1 });
   $hotMap->addPoint({ layerName => '20_inner', x => 6, y => 5, value => 9 });

   # You can also prepare conf as a Hash, ...
   my %other = (
      layers => {
         '30_anotherLayer' => {
            visibility  => 0,
            sliceColors => 1,
         },
         '40_anotherLayer' => {
            visibility  => 0,
            sliceColors => 0,
         },
      },
      zones => {
         anotherZone => {
            layerName => '30_anotherLayer',
            coordonates => [7,4,10,9],
            border => 1,
            text => 'other layer',
            textSize => 8,
            textColor => 'magenta',
         },
         zoneA => {
            layerName => '40_anotherLayer',
            coordonates => [0,10,1,12],
            border => 1,
            text => 'black',
            textSize => 8,
            textColor => 'white',
         },
         zoneB => {
            layerName => '40_anotherLayer',
            coordonates => [1,10,2,12],
            border => 1,
            text => 'blue',
            textSize => 8,
            textColor => 'white',
         },
         zoneC => {
            layerName => '40_anotherLayer',
            coordonates => [2,10,3,12],
            border => 1,
            text => 'green',
            textSize => 8,
            textColor => 'white',
         },
         zoneD => {
            layerName => '40_anotherLayer',
            coordonates => [3,10,4,12],
            border => 1,
            text => 'cyan',
            textSize => 8,
            textColor => 'white',
         },
      },
      points => {
         '30_anotherLayer' => [
            [8,5,46],
            [10,9,22],
         ],
         '10_back' => [
            [13,1,50],
         ],
         '40_anotherLayer' => [
            [0,10,1],
            [1,10,2],
            [2,10,3],
            [3,10,4],
         ],
      },
   );

   # ..., and import/add it
   $hotMap->addConfs(\%other);

   # Run the interpolation and generate and image
   $hotMap->genImage;

   # Save the image a a PNG file
   $hotMap->genImagePng('MyTest.png');

   # print the text representation of the map
   print $hotMap->toString('floor') if $hotMap->scale < 3;

=head1 DESCRIPTION

Generate thermographic images from a few know points. Others values are interpolated. Graphics::HotMap use PDL to work on matrix.
PDL can compute very very large matrix in a few seconds.

See L<http://kumy.org/HotMap/HotMap.png>

=head2 FUNCTIONS

=over 4

=cut

use Data::Dumper;
use Image::Magick;
use Math::Gradient qw(multi_array_gradient);
use PDL;
use PDL::NiceSlice;
use PDL::IO::Pic;
use POSIX qw(strftime);
use File::Temp qw/ :POSIX /;
use File::Temp qw/ tempfile tempdir /;

use constant {
   PALETTE_SLICE => 35,
};

our $VERSION = '0.0001';

=item new(<HASH>)

=for ref

Construct and return a new HotMap Object;

=for usage

   Graphics::HotMap->new(
      outfileGif        => <File path>, # file to write GIF
      outfilePng        => <File path>, # file to write PNG
      legend            => [0|1],       # activate lengend
      legendNbGrad      => <number>,    # Number a graduation
      cross             => <bool>,      # activate crossing of known values
      crossValues       => <bool>,      # activate values printing whith cross
      minValue          => <number>,    # minimum value
      maxValue          => <number>,    # maximum value
      font              => <path to font file>,
      fontSize          => <number>,    # font size
      scale             => <number>,    # scale values and coordonates
      sizeX             => <number>,    # X size
      sizeY             => <number>,    # Y size
   );

=for exemple 

   my $hotMap = Graphics::HotMap->new(
      sizeX    => 10, 
      sizeY    => 10, 
      minValue => 1,
      maxvalue => 50,
   );


=cut

sub new {
   my ($class, %params) = (@_);
   my $self={};
   $self->{_outfileGif}   = $params{outfileGif}   || undef;
   $self->{_outfilePng}   = $params{outfilePng}   || undef;
   $self->{_legend}       = $params{legend}       || 0;
   $self->{_legendNbGrad} = $params{legendNbGrad} || 7;
   $self->{_crossMark}    = $params{cross}        || 0;
   $self->{_crossMarkTemp}= $params{crossTemp}    || 0;
   #$self->{_minValue}     = $params{minValue}     || 0;
   #$self->{_maxValue}     = $params{maxValue}     || 70;
   $self->{_font}         = $params{font}         || '/usr/share/fonts/truetype/freefont/FreeSans.ttf';
   $self->{_fontSize}     = $params{fontSize}     || 15;
   $self->{_text}         = ();
   $self->{_horodatage}   = $params{horodatage}   || [0, 0, 0];
   $self->{_scale}        = $params{echelle}      || 1;
   $self->{_verbose}      = $params{verbose}      || 0;
   $self->{_mapSize}{x}   = $params{sizeX}        || 30;
   $self->{_mapSize}{y}   = $params{sizeY}        || 20;
   $self->{_knownPoints}  = {};
   $self->{_mapPoints}    = PDL->zeroes(1);
   bless $self, $class;
   #$self->gradient(20, ([0,0,255],[0,255,255],[0,255,0],[255,255,0],[255,0,0]));
   return $self;
}

=item initKnownPoints()

=for ref

Reset all know points.

=cut

sub initKnownPoints {
   my $self = shift;

   $self->{_knownPoints} = {};
}

=item mapSize(<HASH>)

=for ref

Set or Return mapSize

=for exemple

   $hotMap->mapSize({sizeX => 15, sizeY => 15}); # Set map size
   @size = $hotMap->mapSize; # Return the actual map size

=cut

sub mapSize {
   my $self = shift;
   my ($dimentions) = @_;

   if (defined $dimentions) {
      die ("mapSize: You must set sizeX and sizeY.",$/)
         unless (defined $dimentions->{sizeX} && defined $dimentions->{sizeY});

      $self->{_mapSize}{x} = ($dimentions->{sizeX}  ) * $self->{_scale};
      $self->{_mapSize}{y} = ($dimentions->{sizeY}  ) * $self->{_scale};

      $self->{_mapPoints}  = PDL->zeroes($self->{_mapSize}{x}, $self->{_mapSize}{y});
      $self->initKnownPoints;
   } else {
      return [$self->{_mapSize}{x}, $self->{_mapSize}{y}];
   }
}

=item scale(<SCALAR>)

=for ref

Set or Return current scale factor.

=for exemple

   $hotMap->scale(2);
   $scale = hotMap->scale;

=cut

sub scale {
   my $self = shift;
   my ($scaleFactor) = @_;

   if (defined $scaleFactor) {
      die ("setScale: scaleFactor must be > 0. => '$scaleFactor'",$/)
         unless $scaleFactor > 0;
      $self->{_scale} = $scaleFactor;
   } else {
      return $self->{_scale};
   }
}

=for exemple
Internal function to scale point coordonates

=cut

sub _scalePoint {
   my $self = shift;
   my ($x, $y) = @_;

   return (
         (0.5+$x) * $self->{_scale} -0.5,
         (0.5+$y) * $self->{_scale} -0.5,
         );
}

=for exemple
Internal function to verify that point is inside matrix

=cut

sub _isPointInside {
   my $self = shift;
   my ($x, $y) = @_;

   return
      0 <= $x && $x <= $self->{_mapSize}{x} &&
      0 <= $y && $y <= $self->{_mapSize}{y};
}

=item addLayer(<HASH>)

=for ref

Define a new Layer to store values.

Layers are parsed by alphabetical order.

* visibility (default: 1) : allow crossMarks to be displayed for this layer.

* sliceColor (default: 1) : colors are looked up in the gradient. If set to 0, values between 0 to 16 are fixed colors (LUT).

=for exemple

   $hotMap->addLayer({ layerName => 'Layer1' });
   $hotMap->addLayer({ layerName => 'Layer2', visibility => 1, sliceColor => 1 });

=cut

sub addLayer {
   my $self = shift;
   my ($params) = @_;
   
   my $layerName    = $params->{layerName};
   my $visibility   = $params->{visibility};
   my $sliceColors  = $params->{sliceColors};
   my $gradientName = $params->{gradientName};
   my $maskIfNoValue= $params->{maskIfNoValue};

   $sliceColors   = 1 unless defined $sliceColors;
   $visibility    = 1 unless defined $visibility;
   $maskIfNoValue = 0 unless defined $maskIfNoValue;

   die ("addLayer: You must provide a layer name.",$/)
      unless defined $layerName;

   die ("addLayer: Gradient must be defined: '$gradientName'.",$/)
      unless (defined $gradientName && defined $self->{_gradient}{$gradientName});

   $self->{_layers}{$layerName}{sliceColors}  = $sliceColors;
   $self->{_layers}{$layerName}{visibility}   = $visibility;
   $self->{_layers}{$layerName}{gradientName} = $gradientName;
   $self->{_layers}{$layerName}{maskIfNoValue}= $maskIfNoValue;
   $self->{_knownPoints}{$layerName} = PDL->zeroes($self->{_mapSize}{x}, $self->{_mapSize}{y});
}

=item addZone(<HASH>)

=for ref

Define a new zone to interpolate over a layer.

=for exemple

   $hotMap->addZone({
      zoneName => 'AllMap',      # zone name
      layerName => 'Layer1',     # layer from which zone belongs
      coordonates => [0,0,9,9],  # coordonates [startX, startY, endX, endY]
      border => 1,               # border color (LUT) or undef for none
      text => "your text",       # 
      textSize => 10,            # 
      textColor => 'red',        # 
      noScale = 0,               # if true, coordonates will not be auto-scaled
   });

=cut

sub addZone {
   my $self = shift;
   my ($params) = @_;

   my $layerName   = $params->{layerName};
   my $zoneName    = $params->{zoneName};
   my $coordonates = $params->{coordonates};
   my $border      = $params->{border};
   my $text        = $params->{text};
   my $textSize    = $params->{textSize};
   my $textColor   = $params->{textColor};
   my $noScale     = $params->{noScale};

   if (!defined $noScale && !$noScale) {
      ($coordonates->[0], $coordonates->[1]) = $self->_scalePoint($coordonates->[0], $coordonates->[1]);
      ($coordonates->[2], $coordonates->[3]) = $self->_scalePoint($coordonates->[2], $coordonates->[3]);
   }

   die ("addZone: You must provide a layer name.",$/)
      unless defined $layerName;

   die ("addZone: You must provide a zone name.",$/)
      unless defined $zoneName;

   die ("addZone: Zone must not be over mapSize limits. '$coordonates->[0],$coordonates->[1];$coordonates->[2],$coordonates->[3]'",$/)
      unless (
            $self->_isPointInside($coordonates->[0], $coordonates->[1]) &&
            $self->_isPointInside($coordonates->[2], $coordonates->[3])
            );

   $self->{_zones}{$layerName}{$zoneName}{coordonates} = $coordonates;
   $self->{_zones}{$layerName}{$zoneName}{border}      = $border;

   $self->addText ( {
         x     => $coordonates->[0] + ($coordonates->[2] - $coordonates->[0])/2,
         y     => $coordonates->[1] + ($coordonates->[3] - $coordonates->[1])/2,
         text  => $text,
         size  => $textSize,
         align => 'center',
         color => $textColor,
         } )
   if (defined $text);
}

=item addPoint(<HASH>)

=for ref

Add a know point to a zone. Zone should first be declared with addZone.

=for exemple

   $hotMap->addPoint({
      layerName   => 'AllMap',
      x           => 7,
      y           => 8,
      value       => 25,
      noScale     => 0,
   });

=cut

sub addPoint {
   my $self = shift;
   my ($params) = @_;

   my $layerName = $params->{layerName};
   my $x         = $params->{x};
   my $y         = $params->{y};
   my $value     = $params->{value};
   my $noScale   = $params->{noScale};
   my $gradientName = $self->{_layers}{$layerName}{gradientName};

   ($x, $y) = $self->_scalePoint($x, $y)
      unless (defined $noScale && $noScale);

   if ( ! $value > 0) {
      warn ("addPoint: Only values > 0 accepted. => '$value'",$/);
      return;
   }
   #if ( ! $value <= ) {
   #   warn ("addPoint: Only values > 0 accepted. => '$value'",$/);
   #   return;
   #}
   die ("addPoint: Point should be inside ;) => '$x:$y' : '$self->{_mapSize}{x}:$self->{_mapSize}{y}' ($params->{x}, $params->{y}) $params->{layerName}",$/)
      unless $self->_isPointInside($x, $y);
   die ("addPoint: layer must exists. => '$layerName'",$/)
       unless defined $self->{_knownPoints}{$layerName};
   die ("addPoint: Value outside gradient Limits. Value => $value : Limits => ". $self->{_gradient}{$gradientName}{minValue} .' <=> '. $self->{_gradient}{$gradientName}{maxValue},$/)
       unless ($self->{_gradient}{$gradientName}{minValue} <= $value && $value <= $self->{_gradient}{$gradientName}{maxValue});

   $self->{_knownPoints}{$layerName}->set($x, $y, $value);
}

=item addHorodatage($timestamp, $x, $y)

=for ref

Timestamp on the image.

=for exemple

   $hotMap->addHorodatage(time, 10, 10);
   $hotMap->addHorodatage(1269122338, 10, 10);

=cut

sub addHorodatage {
   my $self = shift;
   my ($time, $x, $y) = @_;

   die ("You must set time and coordonates.",$/)
      unless (defined $time && defined $x && defined $y);

   $self->{_horodatage} = [$time, $x, $y];
}

=item addText(<HASH>)

=for ref

Add text on the image.

=for exemple

   $hotMap->addText({
      text        => "your text",
      x           => $x,
      y           => $y,
      font        => <path to font file>
      pointsize   => 10,
      fill        => 'black',
      align       => '[left|center|right],
   });

=cut

sub addText {
   my $self = shift;
   my ($params) = @_;

   push (@{$self->{_text}}, $params);

}

=item addConfs(<HASH>)

=for ref

Add Layers/Zones/Point from a hash config.

=for exemple

   my %other = (
      layers => {
         '30_anotherLayer' => {
            visibility  => 0,
            sliceColors => 1,
         },
      },
      zones => {
         anotherZone => {
            layerName => '30_anotherLayer',
            coordonates => [7,4,10,9],
            border => 1,
            text => 'other layer',
            textSize => 8,
            textColor => 'magenta',
         },
      },
      points => {
         '30_anotherLayer' => [
            [8,5,46],
            [10,9,22],
         ],
      },
   );
   
   $hotMap->addConfs(\%other);

=cut

sub addConfs {
   my $self = shift;
   my ($params) = @_;

   foreach my $layerName (keys %{$params->{layers}}) {
      $self->addLayer({
         layerName    => $layerName,
         visibility   => $params->{layers}{$layerName}{visibility},
         sliceColors  => $params->{layers}{$layerName}{sliceColors},
         gradientName => $params->{layers}{$layerName}{gradientName},
         maskIfNoValue=> $params->{layers}{$layerName}{maskIfNoValue},
      });
   }

   foreach my $zoneName (keys %{$params->{zones}}) {
      $self->addZone({
         layerName   => $params->{zones}{$zoneName}{layerName},
         zoneName    => $zoneName,
         coordonates => $params->{zones}{$zoneName}{coordonates},
         border      => $params->{zones}{$zoneName}{border},
         text        => $params->{zones}{$zoneName}{text},
         textSize    => $params->{zones}{$zoneName}{textSize},
         textColor   => $params->{zones}{$zoneName}{textColor},
         noScale     => $params->{zones}{$zoneName}{noScale},
      });
   }

   foreach my $layerName (keys %{$params->{points}}) {
      foreach my $point (@{$params->{points}{$layerName}}) {
         $self->addPoint({
               layerName   => $layerName,
               x           => $point->[0],
               y           => $point->[1],
               value       => $point->[2],
               noScale     => $point->[3],
               });
      }
   }
}

=item getPoint()

=for ref

Return a point value at coordonate x/y.
Without a zone name, it returns a point from the interpolated table.
With zone name, it returns a point from that zone.

=for exemple

   $hotMap->getPoint(6, 2, 'Zone1')
   $hotMap->getPoint(6, 2)

=cut

sub getPoint {
   my $self = shift;
   my ($x, $y, $layerName) = @_;

   if (defined $layerName) {
      die ("getPoint: layer must be defined. => '$layerName'",$/)
         unless defined $self->{_knownPoints}{$layerName};

      return $self->{_knownPoints}{$layerName}->at($x,$y);
   }

   return $self->{_mapPoints}->at($x,$y);
}

=item fusionLayers()

=for ref

Fusion the second layer to the first one.

=for exemple

   $hotMap->fusionLayers('AllMap', 'Zone1');

=cut

sub fusionLayers {
   my $self = shift;
   my ($dest, $orig) = @_;

   die ("fusionLayers: layers must be defined. => '$dest, $orig'",$/)
      unless (defined $self->{_knownPoints}{$dest} && defined $self->{_knownPoints}{$orig});

   $self->{_knownPoints}{$dest}->inplace->or2($self->{_knownPoints}{$orig}, 0);
   #$self->{_knownPoints}{$dest} += $self->{_knownPoints}{$orig};
}

=item getLayer()

=for ref

Return all values from a layer.

=for exemple

   my $piddleVal = $hotMap->getLayer('AllMap');

=cut

sub getLayer {
   my $self = shift;
   my ($layer) = @_;

   die ("getLayer: layer must be defined. => '$layer'",$/)
       unless (defined $self->{_knownPoints}{$layer});

   return $self->{_knownPoints}{$layer};
}

=item setLayer()

=for ref

Define all values from a layer.

=for exemple

   $hotMap->setLayer('AllMap', $piddleVal);

=cut

sub setLayer {
   my $self = shift;
   my ($dest, $values) = @_;

   die ("setLayer: layers must be defined. => '$dest'",$/)
       unless (defined $self->{_knownPoints}{$dest});

   $self->{_knownPoints}{$dest} += $values;
}

=item toString()

=for ref

Convert the interpolated table to text.
The parameter 'floor' can be added to return rounded values.

=for exemple

   print $hotMap->toString('floor');
   
   [
    [ 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1]
    [ 1 14 14 14 14 13 13 13 13 13 14 14 14 15  1]
    [ 1 14 15 14 13 13 13 13 13 13 14 14 15 15  1]
    [ 1 13 14 13 13 12 12 13 13 14 14 15 15 15  1]
    [ 1  9 10 11 11 12 12 13 13 14 15 15 16 16  1]
    [ 1  6  7  8 10 11 12 13 14 15 15 16 16 17  1]
    [ 1  5  5  7  9 11 12 13 14 15 16 17 17 17  1]
    [ 1  5  6  7  9 11 13 14 16 17 17 18 18 18  1]
    [ 1  6  7  8 10 12 14 16 17 18 19 19 19 19  1]
    [ 1  8  8 10 11 14 16 18 19 20 21 21 20 20  1]
    [ 1  9 10 11 13 16 18 20 21 22 22 22 21 21  1]
    [ 1 11 12 13 15 17 20 22 23 23 23 23 22 22  1]
    [ 1 12 13 15 17 19 21 23 24 24 24 24 23 22  1]
    [ 1 13 15 16 18 20 22 23 24 25 24 24 23 22  1]
    [ 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1]
   ]

=cut

sub toString {
   my $self = shift;
   my $function = shift;

   my $tmpPiddle = $self->{_mapPoints};
   #$tmpPiddle->where($tmpPiddle > PALETTE_SLICE) -= PALETTE_SLICE;

   if (defined $function) {
      return scalar (floor($tmpPiddle)) if ($function eq 'floor');
      die "toString: Unknown Function. => '$function'",$/;
   }
   return scalar ($tmpPiddle);
}

=item legend()

=for ref

Set or Return legend status. When enabled, the legend gradient will be drawn on the image.

=cut

sub legend {
   my $self = shift;
   my ($value) = @_;

   if (defined $value) {
      $self->{_legend} = 1;
   } else {
      return $self->{_legend};
   }
}

=item crossMark()

=for ref

Set or Return cross marks status. When enabled, a cross will be drawn on the image where points have been defined.

=cut

sub crossMark {
   my $self = shift;
   my ($mark, $value) = @_;

   if (defined $mark) {
      $self->{_crossMark} = 1;
      $self->{_crossMarkTemp} = 1 if defined $value;
   } else {
      return $self->{_crossMark};
   }
}

=for exemple
Internal function for base colors table

=cut

sub _genLut {
   my $self = shift;
   my ($lut) = @_;

   $lut = [
      [255, 255, 255], # 0 white
      [  0,   0,   0], # 1 black
      [  0,   0, 255], # 2 blue
      [  0, 255,   0], # 3 green
      [  0, 255, 255], # 4 cyan
      [255,   0,   0], # 5 red
      [255,   0, 255], # 6 magenta
      [255, 255,   0], # 7 yellow
      [153, 204,   0], # 8 Green 1
      [128, 128,   0], # 9 Green 2
      [128,   0, 128], # 10 purple
      [255, 255, 153], # 11 light yellow
      [204, 153, 255], # 12 light purple
      [  0, 204, 255], # 13 cool blue
      [228, 109,  10], # 14 orange
      [255, 204, 153], # 15 peal
      [246,  96, 134], # 16 rose1
      [ 96, 118, 246], # 17 blue2
      [152,  18,  13], # 18 red2
      [153, 102, 204], # 19 violet2
      [123, 160,  91], # 20 asperge
      ]
      unless defined $lut;

   for (@$lut..PALETTE_SLICE-1) {
      push (@{$lut}, [100+$_, 100+$_, 100+$_]);
   }

   return $lut;
}

=for item gradient(<ARRAYREF>)

Set the gradient.

Parameter must be an array of RGB array.

See Math::Gradient::multi_array_gradient()

=cut

sub gradient {
   my $self = shift;
   my ($params) = @_;

   my $nbColors     = $params->{nbColors};
   my $colorsPoints = $params->{colorsPoints};
   my $gradientName = $params->{gradientName};
   my $minValue     = $params->{minValue};
   my $maxValue     = $params->{maxValue};
   my $unit         = $params->{unit};
   my $visibility   = $params->{visibility};

   $self->{_gradient}{$gradientName}{colorsPoints} = $colorsPoints;
   $self->{_gradient}{$gradientName}{nbColors}     = $nbColors;
   $self->{_gradient}{$gradientName}{minValue}     = $minValue;
   $self->{_gradient}{$gradientName}{maxValue}     = $maxValue;
   $self->{_gradient}{$gradientName}{unit}         = $unit;
   $self->{_gradient}{$gradientName}{visibility}   = $visibility;
}

=for comment
Internal function for generation LUT

=cut

sub _genGradient {
   my $self = shift;

   my $nextPaletteStart = PALETTE_SLICE;
   my @gradients = ();

   foreach my $gradientName (sort keys %{$self->{_gradient}}) {
      my $nbColors = 1+$self->{_gradient}{$gradientName}{nbColors};
      my @grad = multi_array_gradient($nbColors, @{$self->{_gradient}{$gradientName}{colorsPoints}});
      push (@gradients, @grad);
      $self->{_gradient}{$gradientName}{start} = $nextPaletteStart;
      $nextPaletteStart += $nbColors;
   }

   my $lut = byte pdl((@{$self->_genLut}, @gradients));
   $self->{_gradient}{colors} = PDL::cat ($lut);
}

=for item getColor($level)
Return the lut color from the specified level

=cut

sub getColor {
   my $self = shift;
   my ($level) = @_;
   my $lut = $self->{_gradient}{colors};

   return '#'.
        sprintf("%02x",$lut->at(0,$level,0)).
        sprintf("%02x",$lut->at(1,$level,0)).
        sprintf("%02x",$lut->at(2,$level,0));
}

=for comment
Internal function for writing text on the image

=cut

sub _printText {
   my $self = shift;
   my ($im, $textHash) = @_;

   my $text    = $textHash->{text};
   my $x       = $textHash->{x};
   my $y       = $textHash->{y};
   my $color   = $textHash->{color}  || 'black';
   my $align   = $textHash->{align}  || 'left';
   my $size    = $textHash->{size}   || $self->{_fontSize};
   my $font    = $textHash->{font}   || $self->{_font};
   my $rotate  = $textHash->{rotate} || 0;

   $im->Annotate(
         font=>$self->{_font},
         pointsize=>$size,
         fill=>$color,
         text=>$text,
         align=>$align,
         x=>$x,
         y=>$y,
         rotate=>$rotate,
         );
}

=for comment
Internal function for generating legend bar on the image

=cut

sub _drawLegendBar {
   my $self = shift;
   my ($gradientName, $i, $im) = @_;
   my $repere = 10;

   my $legendBar = Graphics::HotMap->new(
      wall     => 1,
   );
   $legendBar->{_gradient} = $self->{_gradient};
   $legendBar->mapSize({
      sizeX => 10,
      sizeY => 500,
      });
   
   $legendBar->addLayer({ layerName => '_Legend'.$gradientName, visibility => 1, gradientName => $gradientName });

   my $nbGrad = $self->{_gradient}{$gradientName}{nbColors}; #$self->{_legendNbGrad}-1;
   my $min    = $self->{_gradient}{$gradientName}{minValue};
   my $max    = $self->{_gradient}{$gradientName}{maxValue};

   for (0..$nbGrad) {
      my $x = $legendBar->{_mapSize}{x}-1;
      my $y = $_/$nbGrad*($legendBar->{_mapSize}{y}-1);
      my $valeur = $max-(int(($nbGrad-$_)/$nbGrad*($max-$min)));
      my $unit   = $legendBar->{_gradient}{$gradientName}{unit};
      $legendBar->addPoint({
            layerName => '_Legend'.$gradientName,
            #x => $_/$nbGrad*($legendBar->{_mapSize}{x}-1),
            #y => $legendBar->{_mapSize}{y}-1-$repere*$i,
            x => $x,
            y => $y,
            value => $valeur,
            noScale => 1,
            unit => $unit,
            });
      $legendBar->addText ( {
              x => $x+15,
              y => $y+10,
              text => int($valeur).$unit,
              size => 10,
              align => 'center'
              } ) if ($nbGrad < 11 || $_%5 == 0);
   }

   $legendBar->addZone({
         layerName =>'_Legend'.$gradientName,
         zoneName => '_Legend'.$gradientName,
         coordonates => [
         1,
         1,
         $legendBar->{_mapSize}{x}-1,
         $legendBar->{_mapSize}{y}-1,
         ],
         noScale => 1 });
   $legendBar->_genDegradZone('_Legend'.$gradientName, $legendBar->{_zones}{'_Legend'.$gradientName}{'_Legend'.$gradientName}, 1);

   my $imag =  byte $legendBar->{_mapPoints};
   my $tmpName = new File::Temp( TEMPLATE => 'generated-XXXXX',
                                 DIR => '/tmp/',
                                 SUFFIX => '.png',
                                 OPEN => 0);
   #my $tmpName = tmpnam().'.png';
   my $cptLoop = 0;
   do {
      eval {$imag->wpic($tmpName, { LUT => $legendBar->{_gradient}{colors} }); };
   #        $imag->wpic($tmpName, { LUT => $legendBar->{_gradient}{colors} });
      ++$cptLoop;
   } while ($@ && $cptLoop < 10);

   if ($cptLoop > 2) {
   	print "ARgh ! Function: _saveImage ; nbErr for wpic:$cptLoop\n";
	exit;
   }

# read the temporary File in PerlMagick
   my $status = $im->ReadImage($tmpName);
   warn $status if $status;
   #unlink $tmpName;

# Flip the image
   $im->[$i+1]->Flip;
   $im->[$i+1]->Border(fill=>'black', width=>-1, height=>-1);
   $im->[$i+1]->Extent(
           background => 'white',
           geometry   => ($legendBar->{_mapSize}{x}+35).'x'.($legendBar->{_mapSize}{y}+15),
           gravity    => 'West',
           );
   $legendBar->_genText($im->[$i+1]);
   $im->[$i+1]->Extent(
           background => 'white',
           geometry   => ($legendBar->{_mapSize}{x}+35).'x'.$self->{_mapSize}{y},
           gravity    => 'Center',
           );

   $im->[$i+1]->Extent(
           background => 'white',
           geometry   => ($legendBar->{_mapSize}{x}+35+20).'x'.$self->{_mapSize}{y},
           gravity    => 'East',
           );
   $im->[$i+1]->Annotate(
         font=>$self->{_font},
         pointsize=>10,
         fill=>'black',
         text=>$gradientName,
         align=>'right',
         x=>10,
         y=>35,
         rotate=>270,
         );
   $self->{_im} = $im->Append(stack=>'false');
}

=for comment
Internal function for generating legend on the image

=cut

sub _genLegende {
   my $self = shift;
   my ($im) = @_;

   my $i=0;
   #print "Printing Gradient Bars",$/;
   foreach my $gradientName (sort keys %{$self->{_gradient}}) {
      #print "* $gradientName",$/;
      next if $gradientName eq 'colors';
      next if defined $self->{_gradient}{$gradientName}{visibility} && !$self->{_gradient}{$gradientName}{visibility};
      $self->_drawLegendBar($gradientName, $i, $im);
      $i++;
   }
}

=for comment
Internal function for generating one mark on the image

=cut

sub _drawMark {
   my $self = shift;
   my ($im, $x, $y, $valeur, $unit) = @_;
   my $red = '#FF0000';
   my $white = '#FFFFFF';

   my %cross = (
         -2   => { 0   => $red,    },
         -1   => { 0   => $white,  },
          0   => {-2   => $red,
         -1   =>          $white,
          0   =>          $white,
          1   =>          $white,
          2   =>          $red,    },
          1   => { 0   => $white,  },
          2   => { 0   => $red,    },
         );

   foreach my $i (sort keys %cross) {
      foreach my $j (sort keys %cross) {
         for (0..2) {
            next unless defined $cross{$i}{$j};
            my $ix = $i * $_ + $x;
            my $jy = $j * $_ + $y;
            next unless (0 < $ix && $ix < $self->{_mapSize}{x}-1);
            next unless (0 < $jy && $jy < $self->{_mapSize}{y}-1);
            $im->Set("pixel[$ix,$jy]" => $cross{$i}{$j});
         }
      }
   }

   $self->addText ( {
         x => $x,
         y => $y,
         text => int($valeur).$unit,
         size => 10,
         align => 'center'
         } );
}

=for comment
Internal function for generating all marks on the image

=cut

sub _genCrossMark {
   my $self = shift;
   my $im = shift;

   foreach my $layer (sort keys %{$self->{_knownPoints}}) {
      my ($d0,$d1) = whichND $self->{_knownPoints}{$layer};
      my $nbValues = nelem($d0);
      for (0..$nbValues-1) {
         next unless (
               defined $self->{_layers}{$layer}{visibility} && 
               $self->{_layers}{$layer}{visibility}
               );
         $self->_drawMark(
               $im,
               $d0(($_)),
               $d1(($_)),
               $self->{_knownPoints}{$layer}->at($d0(($_)),$d1(($_))),
               $self->{_gradient}{$self->{_layers}{$layer}{gradientName}}{unit}
               );
      }
   }
}

=for comment
Internal function for writing timestamp on the image

=cut

sub _drawTime {
   my $self = shift;
   my $im = shift;

   my ($time, $x, $y) = @{$self->{_horodatage}};
   return unless $time;
   $self->addText ( {
         x => $x,
         y => $y,
         text => strftime ("%d-%m-%Y %H:%M:%S", localtime $time),
         } );
}

=for comment
generate text on the image

=cut

sub _genText {
   my $self = shift;
   my ($im) = @_;

   foreach my $text (@{$self->{_text}}) {
      $self->_printText($im, $text);
   }

}

=for comment
generate the image from the interpolated map.

=cut

sub _genPicture {
   my $self = shift;
   my $image = $self->{_im} = new Image::Magick();

# write a temporary image of the piddle
   my $imag =  byte $self->{_mapPoints};
   my $tmpName = tmpnam().'.png';
   #eval { $self->{_hotMap}->genImage };
   #print STDERR "error: _genTemperatureImage: $@" if $@;
   my $cptLoop = 0;
   do {
      eval {$imag->wpic($tmpName, { LUT => $self->{_gradient}{colors} }); };
      ++$cptLoop;
   } while ($@ && $cptLoop < 10);

   if ($cptLoop > 2) {
   	print "ARgh ! Function: _genPicture; nbErr for wpic:$cptLoop\n";
	exit;
   }

# read the temporary File in PerlMagick
   my $status = $image->ReadImage($tmpName);
   warn $status if $status;
   unlink $tmpName;

# Flip the image
   my $im = $image;
   #my $im = $image->[0];
   $im->Flip;

# Gen CrossMarks
   $self->_genCrossMark($im) if $self->{_crossMark};
# Draw time on image
   $self->_drawTime($im) if $self->{_horodatage}[0];
# Draw texts
   $self->_genText($im);

# Gen legend in piddle
   $self->_genLegende($im) if $self->{_legend};
}

=for comment
Really compute the interpolation from known points.

=cut

sub _pdlDegrad {
   my $self = shift;
   my ($input, $output, $sliceColors, $gradientName) = @_;

   my ($d0,$d1) = whichND $input;
   my $nbValues = nelem($d0);
   my $norm = pdl->zeroes($input->dims);
   $output .= 0;

   my $t0r2;
   my $t0r2inv;

   if ($nbValues > 1) {
       for (0..$nbValues-1) {
           my $indice = $_;
           $t0r2 = $input->rvals({ center=>[$d0($indice), $d1($indice)], squared=>1 } );
           $t0r2->where($t0r2==0) .= -1;
           $t0r2inv = 1/$t0r2;
           $norm += $t0r2inv;
           $output += $input($d0($indice), $d1($indice);-)*$t0r2inv;
       }

       $output->where($output < 0) .= 0;
       $output /= $norm;
       $output += $input;
   } elsif ($nbValues == 1) {
       $output->where($output==0) .= $input->at($d0->at(0),$d1->at(0));
   } else {
       # do not slice if there is no values
       return;
   }

   if (defined $sliceColors && $sliceColors) {
       my $minValue = $self->{_gradient}{$gradientName}{minValue};
       my $maxValue = $self->{_gradient}{$gradientName}{maxValue};
       my $ratio = $self->{_gradient}{$gradientName}{nbColors}/(1+$maxValue-$minValue);
       $output *= $ratio;
       $output += $self->{_gradient}{$gradientName}{start}-$minValue*$ratio;

   }
}

=for comment
Fetch zones, get a slice from coordonates, then generate the interpolation.
If border is defined, place the points too.

=cut

sub _genDegradZone {
   my $self = shift;
   my ($layerName, $zoneHash) = @_;

   my ($sX, $sY, $eX, $eY) = @{$zoneHash->{coordonates}};

   my $sliceColors = $self->{_layers}{$layerName}{sliceColors};
   my $gradientName= $self->{_layers}{$layerName}{gradientName};

# define slices from zones
   my $mapPointsSlice   = $self->{_mapPoints}->($sX:$eX,$sY:$eY);
   my $knownPointsSlice = $self->{_knownPoints}{$layerName}->($sX:$eX,$sY:$eY);

# don't show invisible layers if no points inside
   return if ($self->{_layers}{$layerName}{maskIfNoValue} && !$knownPointsSlice->max);

# generate gradient interpolation
   $self->_pdlDegrad($knownPointsSlice, $mapPointsSlice, $sliceColors, $gradientName);

# draw walls
   if (defined $zoneHash->{border}) {
       $mapPointsSlice->(0)    .= $zoneHash->{border};
       $mapPointsSlice->(-1)   .= $zoneHash->{border};
       $mapPointsSlice->(:,0)  .= $zoneHash->{border};
       $mapPointsSlice->(:,-1) .= $zoneHash->{border};
   }

   #$mapPointsSlice = byte($mapPointsSlice);
}

=for comment
Fetch zone

=cut

sub _genDegrad {
   my $self = shift;

   $self->_genGradient;

   foreach my $layerName (sort keys %{$self->{_zones}}) {
      foreach my $zoneName (sort keys %{$self->{_zones}{$layerName}}) {
         $self->_genDegradZone($layerName, $self->{_zones}{$layerName}{$zoneName});
      }
   }
}

=item genImage()

=for ref

Calculate the interpolation of all Zones.

=cut

sub genImage {
   my $self = shift;

   $self->{_mapPoints}  = PDL->zeroes($self->{_mapSize}{x}, $self->{_mapSize}{y});
   $self->_genDegrad;
   $self->_genPicture;
}

=for comment

This function will write image to disk.

=cut

sub _saveImg {
   my $self = shift;
   my ($outfile, $im) = @_;

   print $im->Write(filename=>$outfile); #, compression=>'JPEG', type => 'Palette');
}

=item genImagePng()

=for ref 

Write a PNG image from the interpolated table.

=for exemple

   $hotMap->genImagePng('<path_to_png'>);

=cut

sub genImagePng {
   my $self = shift;
   my $fileName = shift || $self->{_outfilePng} || die "No output PNG specified";
   $self->_saveImg($fileName,$self->{_im});
   return {
        width    => $self->{_im}->Get('width'),
        height   => $self->{_im}->Get('height'),
        filesize => $self->{_im}->Get('filesize'),
        mime     => $self->{_im}->Get('mime'),
        image    => $self->{_im},
        };
}

=item genImageGif()

=for ref 

Add a GIF image to the annimation from the interpolated table.

=for exemple

   $hotMap->genImageGif('<path_to_gif'>);

=cut

sub genImageGif {
   my $self = shift;
   my $fileName = shift || $self->{_outfileGif} || die "No output GIF specified";
   my $image = shift;
   my $im = $self->{_im};

   unless (defined $image) {
      $image = new Image::Magick(size => "$self->{_mapSize}{x}x$self->{_mapSize}{y}");
      $image->Read($fileName);
   }
   $image->Set(magick=>'GIF', loop=> 100);
   $im->Set(magick=>'GIF', delay=>100);
   push (@$image, $im);
   $self->_saveImg($fileName, $image);
   return {
        width    => $image->Get('width'),
        height   => $image->Get('height'),
        filesize => $image->Get('filesize'),
        mime     => $image->Get('mime'),
        image    => $image,
        };
}

=back

=head1 SEE ALSO

PDL

Math::Gradient

=head1 AUTHOR

Mathieu Alorent (cpan@kumy.net)

=cut

1;
