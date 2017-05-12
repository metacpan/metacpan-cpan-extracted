package GD::Icons;

our $VERSION = '0.04';

# $Id: Icons.pm,v 1.8 2007/08/06 15:36:54 canaran Exp $

use warnings;
use strict;

use GD::Icons::Config;

use Carp;
use GD;

###############
# CONSTRUCTOR #
###############

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;

    my $config_file     = $params{config_file};
    my $gd_icons_config = GD::Icons::Config->new($config_file);
    $self->config($gd_icons_config->config);

    # Assign alpha
    my $alpha = $params{alpha} ? $params{alpha} : 0;
    if ($alpha =~ /[^0-9]/ or $alpha > 127) {
        croak("alpha must be a value between 0 and 127!");
    }
    $self->alpha($alpha);
    
    # Parse shapes keys
    my $shape_keys =
        $params{shape_keys}
      ? $params{shape_keys}
      : [":default"];
    $self->shape_keys($shape_keys);

    my $shape_values =
        $params{shape_values}
      ? $params{shape_values}
      : $self->all_shapes;
    $self->shape_values($shape_values);

    # Parse color keys
    my $color_keys =
        $params{color_keys}
      ? $params{color_keys}
      : [":default"];
    $self->color_keys($color_keys);

    my $color_values =
        $params{color_values}
      ? $params{color_values}
      : $self->all_colors;
    $self->color_values($color_values);

    # Parse sval keys
    my $sval_keys =
        $params{sval_keys}
      ? $params{sval_keys}
      : [":default"];
    $self->sval_keys($sval_keys);

    my $sval_values =
        $params{sval_values}
      ? $params{sval_values}
      : [map { $_ / (@$sval_keys) * 100 } (1 .. @$sval_keys)];    # ratio only
    $self->sval_values($sval_values);

    my $icon_dir = $params{icon_dir}
      or croak("A icon_dir is required!");
    $self->icon_dir($icon_dir);

    my $icon_prefix = $params{icon_prefix};
    if (!defined $icon_prefix) {
        croak("A icon_prefix is required!");
    }
    $self->icon_prefix($icon_prefix);

    return $self;
}

##################
# PUBLIC METHODS #
##################

# Function  : Get method that ignores _* names
# Arguments : None
# Returns   : \@all
# Notes     : None provided.

sub all_colors {
    my ($self) = @_;

    my $config = $self->config;

    my @all;
    foreach (sort keys %{$config->{color}}) {
        push @all, $_ unless /^_/;
    }

    return \@all;
}

# Function  : Get method that ignores _* names
# Arguments : None
# Returns   : \@all
# Notes     : None provided.

sub all_shapes {
    my ($self) = @_;

    my $config = $self->config;

    my @all;
    foreach (sort keys %{$config->{shape}}) {
        push @all, $_ unless /^_/;
    }

    return \@all;
}

# Function  : Get/set method for icon location
# Arguments : $shape_key, $color_key, $sval_key, $value
# Returns   : $value
# Notes     : None provided.

sub icon {
    my ($self, $shape_key, $color_key, $sval_key, $value) = @_;

    $self->{icons}->{$shape_key}->{$color_key}->{$sval_key} = $value
      if @_ > 4;

    return $self->{icons}->{$shape_key}->{$color_key}->{$sval_key};
}

# Function  : Make ...
# Arguments :
# Returns   :
# Notes     : None provided.

sub generate_icons {
    my ($self) = @_;

    my $config = $self->config;

    my $alpha = $self->alpha;
    
    my @shape_keys   = @{$self->shape_keys};
    my @shape_values = @{$self->shape_values};

    my @color_keys   = @{$self->color_keys};
    my @color_values = @{$self->color_values};

    my @sval_keys   = @{$self->sval_keys};
    my @sval_values = @{$self->sval_values};

    my $icon_dir    = $self->icon_dir;
    my $icon_prefix = $self->icon_prefix;

    foreach my $shape_i (0 .. $#shape_keys) {
        foreach my $color_i (0 .. $#color_keys) {
            foreach my $sval_i (0 .. $#sval_keys) {
                my $shape =
                  $config->{shape}->{$shape_values[$shape_i % @shape_values]
                  };    # @shape_values here, not $#shape_values

                my $color =
                  $self->_resolve_color(
                    $color_values[$color_i % @color_values])
                  ;     # @color_values here, not $#color_values

                my $sval = $sval_values[$sval_i];
                if (@sval_values > 1) {
                    $color = $self->_blend_in_sval($color, $sval);
                }

                my ($line_color) = $shape =~ /lc\[([^\[\]]+)\]/;
                if ($line_color eq ":fill") {
                    $line_color = [@$color];
                }
                $line_color = $self->_resolve_color($line_color);

                my ($line_thickness) = $shape =~ /lt\[(\d+)\]/;
                my ($side_length)    = $shape =~ /sl\[(\d+)\]/;

                my $image = new GD::Image($side_length, $side_length);

                my $white_color = $image->colorAllocateAlpha(255, 255, 255, $alpha);
                my $fill_color  = $image->colorAllocateAlpha(@$color, $alpha);
                my $draw_color  = $image->colorAllocateAlpha(@$line_color, $alpha);

                $image->transparent($white_color);

                $image->setThickness($line_thickness);

                while ($shape =~ /\s*(py|fl|nm)\[([0-9, ]+|:auto)\]\s*/g) {
                    my ($action, $values) = ($1, $2);

                    if ($action eq "py") {
                        my @points = split(" ", $values);

                        foreach my $i (0 .. $#points - 1) {
                            my ($x1, $y1) = split(",", $points[$i]);
                            my ($x2, $y2) = split(",", $points[$i + 1]);

                            $image->line($x1, $y1, $x2, $y2, $draw_color);
                        }
                    }

                    elsif ($action eq "fl") {
                        my ($x1, $y1) = split(",", $values);

                        $image->fill($x1, $y1, $fill_color);
                    }

                    elsif ($action eq "nm" && $values eq ":auto") {
                        my ($number) = $shape_keys[$shape_i] =~ /:(\d+)/;
                        if ($number && $number > 99) {
                            $number = 'M';
                        }    
                        if (!$number) {
                            $number = 'U';
                        }    
                        
                        my $x = int(($side_length - 5 * length($number)) / 2) + 1;
                        my $y = ($side_length - 8) / 2;
                        
                        $image->string(gdTinyFont, $x, $y, $number, $draw_color);
                    }
                    
                    else {
                        croak(
                            "Unrecognized action ($action) in shapes file!");
                    }
                }

                my $icon_file =
                  qq[$icon_dir/${icon_prefix}-${shape_i}-${color_i}-${sval_i}.png];
                my $icon_file_name =
                  qq[${icon_prefix}-${shape_i}-${color_i}-${sval_i}.png];

                $self->icon(
                    $shape_keys[$shape_i], $color_keys[$color_i],
                    $sval_keys[$sval_i],   $icon_file_name
                );

                open(PNG, ">$icon_file")
                  or croak("Cannot write file ($icon_file): $!");
                binmode PNG;
                print PNG $image->png;
                close PNG;
            }
        }

    }

    return 1;
}

###################
# GET/SET METHODS #
###################

sub alpha {
    my ($self, $value) = @_;
    $self->{alpha} = $value if @_ > 1;
    return $self->{alpha};
}

sub color_keys {
    my ($self, $value) = @_;
    $self->{color_keys} = $value if @_ > 1;
    return $self->{color_keys};
}

sub color_values {
    my ($self, $value) = @_;
    $self->{color_values} = $value if @_ > 1;
    return $self->{color_values};
}

sub config {
    my ($self, $value) = @_;
    $self->{config} = $value if @_ > 1;
    return $self->{config};
}

sub icon_dir {
    my ($self, $value) = @_;
    $self->{icon_dir} = $value if @_ > 1;
    return $self->{icon_dir};
}

sub icon_prefix {
    my ($self, $value) = @_;
    $self->{icon_prefix} = $value if @_ > 1;
    return $self->{icon_prefix};
}

sub shape_keys {
    my ($self, $value) = @_;
    $self->{shape_keys} = $value if @_ > 1;
    return $self->{shape_keys};
}

sub shape_values {
    my ($self, $value) = @_;
    $self->{shape_values} = $value if @_ > 1;
    return $self->{shape_values};
}

sub sval_keys {
    my ($self, $value) = @_;
    $self->{sval_keys} = $value if @_ > 1;
    return $self->{sval_keys};
}

sub sval_values {
    my ($self, $value) = @_;
    $self->{sval_values} = $value if @_ > 1;
    return $self->{sval_values};
}

###########################
# PRIVATE/UTILITY METHODS #
###########################

# Function  : Apply an S Value to color in RGB
# Arguments : (\@color, $sval_percent)
# Returns   : \@new_color
# Notes     : This is a private method.

sub _blend_in_sval {
    my ($self, $color, $sval_percent) = @_;

    my ($rval, $gval, $bval) = @$color;

    my ($hval, $sval, $vval) = $self->_RGBtoHSV($rval, $gval, $bval);

    $sval = int($sval * $sval_percent / 100);

    my @new_color = $self->_HSVtoRGB($hval, $sval, $vval);

    return \@new_color;
}

# Function  : Determine the type of color designation
# Arguments : $color
# Returns   : $rgb
# Notes     : This is a private method.

sub _resolve_color {
    my ($self, $color) = @_;

    my $rgb;

    if (ref $color) {
        $rgb = $color;
    }

    elsif ($color =~ /^#/) {
        $rgb = $self->_hex2rgb($color);
    }

    else {
        my $hex = $self->config->{color}->{$color};

        $rgb = $self->_hex2rgb($hex);
    }

    croak("Cannot resolve color ($color)!") unless $rgb;

    return $rgb;
}

# Function  : Convert hex to rgb
# Arguments : $hex
# Returns   : \@rgb
# Notes     : This is a private method.

sub _hex2rgb {
    my ($self, $hex) = @_;

    $hex =~ s/^#//;

    my @rgb = map { hex(substr($hex, $_, 2)); } qw[0 2 4];

    return \@rgb;
}

##################################################
# _HSVtoRGB and _RGBtoHSV subs incorporated from #
# GD::Simple module written by Lincoln Stein     #
##################################################

# ($red,$green,$blue) = GD::Simple->HSVtoRGB($hue,$saturation,$value)
#
# Convert a Hue/Saturation/Value (HSV) color into an RGB triple. The
# hue, saturation and value are integers from 0 to 255.

sub _HSVtoRGB {
    my $self = shift;
    @_ == 3
      or croak "Usage: _HSVtoRGB(\$hue,\$saturation,\$value)";

    my ($h, $s, $v) = @_;
    my ($r, $g, $b, $i, $f, $p, $q, $t);

    if ($s == 0) {
        ## achromatic (grey)
        return ($v, $v, $v);
    }
    $h %= 255;
    $s /= 255;    ## scale saturation from 0.0-1.0
    $h /= 255;    ## scale hue from 0 to 1.0
    $h *= 360;    ## and now scale it to 0 to 360

    $h /= 60;     ## sector 0 to 5
    $i = $h % 6;
    $f = $h - $i;                    ## factorial part of h
    $p = $v * (1 - $s);
    $q = $v * (1 - $s * $f);
    $t = $v * (1 - $s * (1 - $f));

    if ($i < 1) {
        $r = $v;
        $g = $t;
        $b = $p;
    }
    elsif ($i < 2) {
        $r = $q;
        $g = $v;
        $b = $p;
    }
    elsif ($i < 3) {
        $r = $p;
        $g = $v;
        $b = $t;
    }
    elsif ($i < 4) {
        $r = $p;
        $g = $q;
        $b = $v;
    }
    elsif ($i < 5) {
        $r = $t;
        $g = $p;
        $b = $v;
    }
    else {
        $r = $v;
        $g = $p;
        $b = $q;
    }
    return (int($r + 0.5), int($g + 0.5), int($b + 0.5));
}

# ($hue,$saturation,$value) = GD::Simple->RGBtoHSV($hue,$saturation,$value)
#
# Convert a Red/Green/Blue (RGB) value into a Hue/Saturation/Value (HSV)
# triple. The hue, saturation and value are integers from 0 to 255.

sub _RGBtoHSV {
    my $self = shift;
    my ($r, $g, $bl) = @_;
    my ($min, undef, $max) = sort { $a <=> $b } ($r, $g, $bl);
    return (0, 0, 0) unless $max > 0;

    my $v = $max;
    my $s = 255 * ($max - $min) / $max;
    my $h;
    my $range = $max - $min;

    if ($range == 0) {    # all colors are equal, so monochrome
        return (0, 0, $max);
    }

    if ($max == $r) {
        $h = 60 * ($g - $bl) / $range;
    }
    elsif ($max == $g) {
        $h = 60 * ($bl - $r) / $range + 120;
    }
    else {
        $h = 60 * ($r - $g) / $range + 240;
    }

    $h = int($h * 255 / 360 + 0.5);

    return ($h, $s, $v);
}

1;

__END__

=head1 NAME

GD::Icons - Utility for generating series of icons of varying color and shapes

=head1 SYNOPSIS

 my $icon;

 $icon = GD::Icons->new(
     shape_keys  => ['accident', 'flooding', 'construction'],
     icon_dir    => '.',
     icon_prefix => 'test-set-A',
 );

 $icon->generate_icons;

 print $icon->icon('accident', ':default', ':default');

=head1 DESCRIPTION

GD::Icons generates an arbitrary number of icons that vary by shape, color and color intensity. This is intended to be used in cases for which a series of related icons are needed. For example, if you want to generate icons to represent traffic congestion on a geographical map, you can generate icons having shape of the icon represent the cause of congestion (accident, flooding and construction) and the color of the icon to represent the severity of the congestion (e.g. red for severe and blue for not severe congestion). In addition to these two dimensions of coding (shape and color) you can use a third dimension, intensity of color.

=head1 USAGE

To generate a series of icons, you first create a GD::Icons object and then call the "generate_icons" method on the object. This creates the images. Then you can call the "icon" method on the object to retrieve the file names of the icon generated for a given set of parameters.

When creating a GD::Icons object, the following needs to be provided:

 - the information on which the icons will be coded on
 - where to place the generated icons
 - a name prefix to use when generating icons

There are 3 dimensions that can be coded into the icons generated.

 - shape (represented by "shape_keys" & "shape_values")
 - color (represented by "color_keys" & "color_values")
 - color intensity (represented by "sval_keys" & "sval_values")

Let's use the traffic congestion example described earlier to experiment with different options provided by the module. We would like to represent 3 types of traffic congestion on a geographical map and generate 3 different icons to be used to represent each.

=head2 Example 1 - Basic data with keys coded by icon shape

Let's begin with the following code. As described earlier, we create a GD::Icon object and call its "generate_icons" method.

 my $icon = GD::Icons->new(
     shape_keys  => ['accident', 'flooding', 'construction'],
     icon_dir    => '.',
     icon_prefix => 'test-set-A',
 );

 $icon->generate_icons;

I<shape_keys>

In the example above, 3 keys that are to be coded by the shape of the icon are specified. No "shape_values" is specified so these are retrieved from the default configuration (configuration and default values are later described in more detail).

I<icon_dir>

This param specifies the directory in which the icons will be generated in. In this example, they are generated in the current directory ".".

I<icon_prefix (and file names)>

The file name of each icon is prefixed with "icon_prefix" and the rest of the file name contains the index of each of the dimensions it is coded on.

For example, an icon generated based on the 0th (this is the array index) shape index, 2nd color index and 0st sval (color intensity index) index,  would have a file name "<icon_prefix>-0-2-0.png".

In this example, 3 icons will be generated:

 - ./test-set-A-0-0-0.png (representing "accident")
 - ./test-set-A-1-0-0.png (representing "flooding")
 - ./test-set-A-2-0-0.png (representing "construction")

Please note that, in this example we have not specified any color or sval dimensions. These default to the special ':default' key.

Also, we have not specified any actual shape, color or sval values that correspond to our dimension keys. In this case, GD::Icons assigns values itself.

=head2 Example 2 - Adding explicit shape values

Let's extend the previous example and specify the shapes explicitly.

 my $icon = GD::Icons->new(
     shape_keys   => ['accident', 'flooding', 'construction'],
     shape_values => ['square', 'triangle', 'diamond'],
     icon_dir     => '.',
     icon_prefix  => 'test-set-B',
 );

 $icon->generate_icons;

I<shape_values>

We add "shape_values" parameter to explicitly specify shapes that we would like to use. The shape values must be available shape names (configuration and default values are later described in more detail). In this particular example, we specify 3 shape values, "square", "triangle" and "diamond", one for each shape key.

=head2 Example 3 - Additional keys coded on color

Let's now add a second dimension, the color of the icon to code for the severity of the congestion.

 my $icon = GD::Icons->new(
     shape_keys   => ['accident', 'flooding', 'construction'],
     shape_values => ['square', 'triangle', 'diamond'],
     color_keys   => ['not-severe', 'severe'],
     color_values => ['Blue', 'Orange'],
     icon_dir     => '.',
     icon_prefix  => 'test-set-D',
 );

 $icon->generate_icons;

I<color_keys & color_values>

Similar to "shape_keys" and "shape_values" parameters, with "color_keys" and "color_values" parameters, we specify that the color of the icon will represent one of "not-severe" and "severe".

This example generates the following files

 - test-set-D-0-0-0.png (accident     - square   & not-severe - Blue  )
 - test-set-D-0-1-0.png (accident     - square   & severe     - Orange)
 - test-set-D-1-0-0.png (flooding     - triangle & not-severe - Blue  )
 - test-set-D-1-1-0.png (flooding     - triangle & severe     - Orange)
 - test-set-D-2-0-0.png (construction - diamond  & not-severe - Blue  )
 - test-set-D-2-1-0.png (construction - diamond  & severe     - Orange)

=head2 Example 4 - Incorporating sval (color intensity) values

In this example, we are going to demonstrate incorporation of sval (color intensity).

Let's say that you would like to code the severity of the congestion by the color intensity of the icon. For example, a square icon to describe an accident with a light orange color to indicate a "not-severe", medium orange color to indicate "medium-severe" and orange color to indicate "severe" congestions.

 my $icon = GD::Icons->new(
     shape_keys   => ['accident', 'flooding', 'construction'],
     shape_values => ['square', 'triangle', 'diamond'],
     color_keys   => ['severity'],
     color_values => ['Orange'],
     sval_keys    => ['not-severe', 'medium', 'severe'],
     sval_values  => [20, 50, 100],
     icon_dir     => '.',
     icon_prefix  => 'test-set-F',
 );

 $icon->generate_icons;

In this example, we reduce the number of color_keys to one. Please note that there may be cases that call for a complete 3-dimensional matrix (shape x color x sval). However, in this example, 2 dimensions would be sufficient.

I<sval_keys & sval_values>

In this example, we provide 3 "sval_keys" values for each congestion level and corresponding 3 "sval_values" values.

"sval_values" values are integers between 0-100. When a sval variation of a color is to be generated (in this case the color "Orange"), the color is converted into HSV and the "sval_values" value is applied as the S value in HSV triplet.

An implication of this is that, in cases that two colors are specified as "color_keys" and these two color differ only by their V value, their sval-transformed forms will not be distinguishable. This is unlikely to happen intentionally  as it wouldn't be applicable to specify for example a light and a darker shade of the same color and try to apply a color gradient on each of them. However, this should be taken into consideration when specifying multiple "color_values" values.

Similar to "shape_values" and "color_values", if "sval_values" is not specified in the constructor, it is automatically calculated based on the number of available "sval_keys" values.

With this example, the following files are generated:

 - test-set-F-0-0-0.png (accident     - square   & not-severe - light Orange (20/100) )
 - test-set-F-0-0-1.png (accident     - square   & not-severe - light Orange (20/100) )
 - test-set-F-0-0-2.png (accident     - square   & not-severe - light Orange (20/100) )
 - test-set-F-1-0-0.png (flooding     - square   & medium     - med.  Orange (50/100) )
 - test-set-F-1-0-1.png (flooding     - square   & medium     - med.  Orange (50/100) )
 - test-set-F-1-0-2.png (flooding     - square   & medium     - med.  Orange (50/100) )
 - test-set-F-2-0-0.png (construction - square   & severe     - dark  Orange (100/100))
 - test-set-F-2-0-1.png (construction - square   & severe     - dark  Orange (100/100))
 - test-set-F-2-0-2.png (construction - square   & severe     - dark  Orange (100/100))

=head2 Retrieving file names for icons

Running the "generate_icons" method on th GD::Icons object, creates the icons in the specified directory.

You can run the "icon" method on the object to retrieve file names. This is particularly useful if you are creating transient icon images interactively. You can then create the icons, use them in your application and then remove/override them as needed.

For example:

 my $file_name = $icon->icon('accident', 'severe',  ':default');

will get back the file name of the icon coded for shape on 'accident' and color on 'severe'. The third parameter stands for the default for sval coding.

By adding a 4th parameter. you can use icon method as a set method. This is mainly used internally.

=head1 CONFIGURATION AND DEFAULT VALUES

The icon generation requires a set of shapes and a set of colors.

The shapes are provided as a set of instructions, separated by spaces, to create an image.

For example, the instructions for creating a triangle are as follows:

 sl[11] lt[1] lc[_Black] py[0,0 10,0 10,10 0,10 0,0] fl[5,5]

 sl[11] instructs to create the image as a 11x11 square.
        "sl" stands for "side length".

 lt[1] indicates that the thickness of the line used for drawing
       the icon will be 1 pixel.
       "lt" stands for "line thickness".

 lc[_Black] indicates that the color of the line used for drawing the
            icon is the color labeled as "_Black".
            "lc" stands for "line color".

 py[0,0 10,0 10,10 0,10 0,0] draws a polygon with the points listed
                             in brackets. Points are in the format (x,y),
                             upper-left corner being (0,0), increasing
                             to the right in X axis and to the bottom in
                             Y axis.
                             "py" stands for "polygon".

 fl[5,5] instructs the image to be filled by the color
         (from "color_values") at point (5,5).
         "fl" stands for "fill".

The colors are provided by their RGB values as a string of hexadecimals.

A few examles are provided below:

 Blue                 => '#0000FF'
 BlueViolet           => '#8A2BE2'
 Brown                => '#A52A2A'

By default, GD::Icons retrieves colors and shapes from GD::Icons::Config. All colors and shapes are provided as an array. If the number of keys is are more than the number of shapes/colors, shapes/colors are rotated and used in the same order until all keys are assigned.

The default values can be obtained by:

 perl -MGD::Icons::Config -e GD::Icons::Config::list

Note: "sval_values" values, if not provided to the constructor, are calculated automatically based on number of keys.

When values for shape, color or sval are provided to the constructor, the same rotation rule applies as it applies to default values for shapes and keys.

You can also pass a custom config file to the constructor and override default configuration. A sample config file is shown below:

 <shape>
     square         sl[11] lt[1] lc[_Black] py[0,0 10,0 10,10 0,10 0,0]         fl[5,5]
     triangle       sl[11] lt[1] lc[_Black] py[5,0 10,10 0,10 5,0]              fl[5,5]
     diamond        sl[11] lt[1] lc[_Black] py[5,0 0,5 5,10 10,5 5,0]           fl[5,5]
     sand-clock     sl[11] lt[1] lc[_Black] py[0,0 10,0 5,5 10,10 0,10 5,5 0,0] fl[5,2]   fl[5,8]
     _padded-square sl[11] lt[1] lc[:fill]  py[0,0 0,9 9,9 0,9 0,0]             fl[5,5]
     _letter-m      sl[11] lt[1] lc[_Black] py[0,1 3,1 5,3 7,1 10,1 10,9 7,9 7,4 5,6 3,4 3,9 0,9 0,1] fl[2,2]
 </shape> 

 <color>
     Blue           \#0000FF
     BlueViolet     \#8A2BE2
     Brown          \#A52A2A
     BurlyWood      \#DEB887
     CadetBlue      \#5F9EA0
     Chartreuse     \#7FFF00
     _Black         \#000000
 </color> 

Color and shape names that start with an underscore (_) are special names. These can be used in drawing shapes as any other one. However, they are not considered for icon generation by default.

The special color name ":fill" means the same color as the icon.

=head1 QUICK REFERENCE

The constructor parameters and their descriptions follow:

 Parameter           Description                          Format
 ---------           -----------                          ------
 alpha               Alpha level of icon (0-127)          scalar
 color_keys          Keys to code by color                arrayref
 color_values        Values for color coding              arrayref
 config              External configuration file          scalar
 icon_dir            Directory to create icons            scalar
 icon_prefix         Prefix to name icon files            scalar
 shape_keys          Keys to code by shape                arrayref
 shape_values        Values for shape coding              arrayref
 sval_keys           Keys to code by color intensity      arrayref
 sval_values         Values for color intensity coding    arrayref

Methods:

 Parameter           Description            Parameters                Returns
 ---------           -----------            ----------                -------
 all_colors          Get all colors excl.   None                      hashref
                     private ones
 all_shapes          Get all shapes excl.   None                      hashref
                     private ones
 generate_icons      Generate icons         None                      1
 icon                Get/set file name for  ($shape_key, $color_key,  scalar
                     an icon                 $sval_key, $value)
                                             * $value for set only 

=head1 AUTHOR

Payan Canaran <pcanaran@cpan.org>

=head1 BUGS

=head1 VERSION

Version 0.04

=head1 ACKNOWLEDGEMENTS

This module incorporates two subroutines from GD::Simple (written by Lincoln Stein) for RGB to HSV conversion and vice versa.

Thanks to Sheldon McKay for recommending to use HSV color space instead of RGB color space for color transitions.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2006-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut

