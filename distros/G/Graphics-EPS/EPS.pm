# =============================================================================
# Package EPS V 3.0                                     (W.Haager, 2003-10-18)
# Creation of Encapsulated Postscript Images
# =============================================================================

# New:
# setdash for dashed lines
# Font-reencoding
# textpath
# scale and rotate included images

package EPS;
use Carp;
use strict;
use vars('$AUTOLOAD', '$VERSION');
$VERSION='3.0';

our %colors=(
 'AliceBlue' => [0.941,0.973,1.000],
 'AlizarinCrimson' => [0.890,0.150,0.210],
 'Antique' => [0.981,0.922,0.845],
 'Aquamarine' => [0.498,1.000,0.831],
 'AquamarineMedium' => [0.400,0.804,0.667],
 'AureolineYellow' => [1.000,0.660,0.140],
 'Azure' => [0.942,1.000,1.000],
 'Banana' => [0.890,0.810,0.340],
 'Beige' => [0.640,0.580,0.500],
 'Bisque' => [1.000,0.898,0.772],
 'Black' => [0.000,0.000,0.000],
 'BlanchedAlmond' => [1.000,0.922,0.804],
 'Blue' => [0.000,0.000,1.000],
 'BlueLight' => [0.678,0.847,0.902],
 'BlueMedium' => [0.000,0.000,0.804],
 'BlueViolet' => [0.541,0.169,0.886],
 'Brick' => [0.610,0.400,0.120],
 'Brown' => [0.500,0.165,0.165],
 'BrownOadder' => [0.860,0.160,0.160],
 'BrownOchre' => [0.530,0.260,0.120],
 'Burlywood' => [0.871,0.722,0.529],
 'BurntSienna' => [0.540,0.210,0.060],
 'BurntUmber' => [0.540,0.200,0.140],
 'Cadet' => [0.372,0.620,0.628],
 'CadmiumLemon' => [1.000,0.890,0.010],
 'CadmiumOrange' => [1.000,0.380,0.010],
 'CadmiumRedDeep' => [0.890,0.090,0.050],
 'CadmiumRedLight' => [1.000,0.010,0.050],
 'CadmiumYellow' => [1.000,0.600,0.070],
 'CadmiumYellowLight' => [1.000,0.690,0.060],
 'Carrot' => [0.930,0.570,0.130],
 'Cerulean' => [0.020,0.720,0.800],
 'Chartreuse' => [0.498,1.000,0.000],
 'Chocolate' => [0.823,0.412,0.118],
 'ChromeOxideGreen' => [0.400,0.500,0.080],
 'CinnabarGreen' => [0.380,0.700,0.160],
 'Cobalt' => [0.240,0.350,0.670],
 'CobaltGreen' => [0.240,0.570,0.250],
 'CobaltVioletDeep' => [0.570,0.130,0.620],
 'ColdGray' => [0.500,0.540,0.530],
 'Coral' => [1.000,0.498,0.314],
 'CoralLight' => [0.941,0.502,0.502],
 'CornflowerBlue' => [0.392,0.584,0.929],
 'Cornsilk' => [1.000,0.973,0.863],
 'Cyan' => [0.000,1.000,1.000],
 'CyanWhite' => [0.878,1.000,1.000],
 'DarkOrange' => [1.000,0.549,0.000],
 'DeepPink' => [1.000,0.078,0.576],
 'DeepOchre' => [0.450,0.240,0.100],
 'DimGray' => [0.333,0.333,0.333],
 'DodgerBlue' => [0.118,0.565,1.000],
 'Eggshell' => [0.990,0.900,0.790],
 'EmeraldGreen' => [0.000,0.790,0.340],
 'EnglishRed' => [0.830,0.240,0.100],
 'Firebrick' => [0.698,0.133,0.133],
 'Flesh' => [1.000,0.490,0.250],
 'FleshOchre' => [1.000,0.340,0.130],
 'Floral' => [1.000,0.980,0.941],
 'ForestGreen' => [0.133,0.545,0.133],
 'Gainsboro' => [0.863,0.863,0.863],
 'GeraniumLake' => [0.890,0.070,0.190],
 'Ghost' => [0.973,0.973,1.000],
 'Gold' => [1.000,0.843,0.000],
 'GoldOchre' => [0.780,0.470,0.150],
 'Goldenrod' => [0.855,0.647,0.126],
 'GoldenrodDark' => [0.722,0.525,0.043],
 'GoldenrodLight' => [0.980,0.980,0.823],
 'GoldenrodPale' => [0.933,0.910,0.667],
 'Green' => [0.000,1.000,0.000],
 'GreenDark' => [0.000,0.392,0.000],
 'GreenPale' => [0.596,0.984,0.596],
 'GreenYellow' => [0.678,1.000,0.184],
 'GreenishUmber' => [1.000,0.240,0.050],
 'Gray' => [0.753,0.753,0.753],
 'Honeydew' => [0.941,1.000,0.941],
 'HotPink' => [1.000,0.412,0.706],
 'IndianRed' => [0.690,0.090,0.120],
 'Indigo' => [0.030,0.180,0.330],
 'Ivory' => [1.000,1.000,0.941],
 'IvoryBlack' => [0.160,0.140,0.130],
 'Khaki' => [0.941,0.902,0.549],
 'KhakiDark' => [0.741,0.718,0.420],
 'LampBlack' => [0.180,0.280,0.230],
 'Lavender' => [0.902,0.902,0.980],
 'LavenderBlush' => [1.000,0.941,0.961],
 'LawnGreen' => [0.486,0.988,0.000],
 'LemonChiffon' => [1.000,0.980,0.804],
 'LightBeige' => [0.961,0.961,0.863],
 'LightGoldenrod' => [0.933,0.867,0.510],
 'LightGray' => [0.667,0.667,0.667],
 'LightSalmon' => [1.000,0.628,0.478],
 'LimeGreen' => [0.196,0.804,0.196],
 'Linen' => [0.980,0.941,0.902],
 'MadderLakeDeep' => [0.890,0.180,0.190],
 'Magenta' => [1.000,0.000,1.000],
 'ManganeseBlue' => [0.010,0.660,0.620],
 'Maroon' => [0.690,0.188,0.377],
 'MarsOrange' => [0.590,0.270,0.080],
 'MarsYellow' => [0.890,0.440,0.100],
 'Melon' => [0.890,0.660,0.410],
 'MidnightBlue' => [0.098,0.098,0.439],
 'Mint' => [0.740,0.990,0.790],
 'MintCream' => [0.961,1.000,0.980],
 'MistyRose' => [1.000,0.894,0.882],
 'Moccasin' => [1.000,0.894,0.710],
 'NaplesYellowDeep' => [1.000,0.660,0.070],
 'Navajo' => [1.000,0.871,0.678],
 'Navy' => [0.000,0.000,0.502],
 'NavyBlue' => [0.000,0.000,0.502],
 'OldLace' => [0.992,0.961,0.902],
 'Olive' => [0.230,0.370,0.170],
 'OliveDrab' => [0.420,0.557,0.137],
 'OliveGreenDark' => [0.333,0.420,0.184],
 'Orange' => [1.000,0.500,0.000],
 'OrangeRed' => [1.000,0.271,0.000],
 'Orchid' => [0.855,0.439,0.839],
 'OrchidDark' => [0.600,0.196,0.800],
 'OrchidMedium' => [0.729,0.333,0.827],
 'PapayaWhip' => [1.000,0.937,0.835],
 'Peach' => [0.440,0.260,0.260],
 'PeachPuff' => [1.000,0.855,0.726],
 'Peacock' => [0.200,0.630,0.790],
 'PermanentGreen' => [0.040,0.790,0.170],
 'PermanentRedViolet' => [0.860,0.150,0.270],
 'Peru' => [0.804,0.522,0.247],
 'Pink' => [1.000,0.753,0.796],
 'PinkLight' => [1.000,0.714,0.757],
 'Plum' => [0.867,0.628,0.867],
 'PowderBlue' => [0.690,0.878,0.902],
 'PrussianBlue' => [0.180,0.180,0.310],
 'Purple' => [0.628,0.126,0.941],
 'PurpleMedium' => [0.576,0.439,0.859],
 'Raspberry' => [0.530,0.150,0.340],
 'RawSienna' => [0.780,0.380,0.080],
 'RawUmber' => [0.450,0.290,0.070],
 'Red' => [1.000,0.000,0.000],
 'RoseMadder' => [0.890,0.210,0.220],
 'RosyBrown' => [0.737,0.561,0.561],
 'RoyalBlue' => [0.255,0.412,0.882],
 'SaddleBrown' => [0.545,0.271,0.074],
 'Salmon' => [0.980,0.502,0.447],
 'SandyBrown' => [0.957,0.643,0.377],
 'SapGreen' => [0.190,0.500,0.080],
 'SeaGreen' => [0.180,0.545,0.341],
 'SeaGreenDark' => [0.561,0.737,0.561],
 'SeaGreenLight' => [0.126,0.698,0.667],
 'SeaGreenMedium' => [0.235,0.702,0.443],
 'Seashell' => [1.000,0.961,0.933],
 'Sepia' => [0.370,0.150,0.070],
 'Sienna' => [0.628,0.322,0.177],
 'SkyBlue' => [0.529,0.808,0.922],
 'SkyBlueDeep' => [0.000,0.749,1.000],
 'SkyBlueLight' => [0.529,0.808,0.980],
 'SlateBlue' => [0.416,0.353,0.804],
 'SlateBlueDark' => [0.282,0.2399,0.545],
 'SlateBlueLight' => [0.518,0.439,1.000],
 'SlateBlueMedium' => [0.482,0.408,0.933],
 'SlateGray' => [0.439,0.502,0.565],
 'SlateGrayDark' => [0.184,0.310,0.310],
 'SlateGrayLight' => [0.467,0.533,0.600],
 'Smoke' => [0.961,0.961,0.961],
 'Snow' => [1.000,0.980,0.980],
 'SpringGreen' => [0.000,1.000,0.498],
 'SpringGreenMedium' => [0.000,0.980,0.604],
 'SteelBlue' => [0.274,0.510,0.706],
 'SteelBlueLight' => [0.690,0.769,0.871],
 'TerreVerte' => [0.220,0.370,0.060],
 'Thistle' => [0.847,0.749,0.847],
 'Titanium' => [0.990,1.000,0.940],
 'Tomato' => [1.000,0.388,0.278],
 'Turquoise' => [0.251,0.878,0.816],
 'TurquoiseBlue' => [0.000,0.780,0.550],
 'TurquoiseDark' => [0.000,0.808,0.820],
 'TurquoiseMedium' => [0.282,0.820,0.800],
 'TurquoisePale' => [0.686,0.933,0.933],
 'Ultramarine' => [0.070,0.040,0.560],
 'UltramarineViolet' => [0.360,0.140,0.430],
 'VanDykeBrown' => [0.370,0.150,0.020],
 'VenetianRed' => [0.830,0.100,0.120],
 'Violet' => [0.560,0.370,0.600],
 'VioletDark' => [0.580,0.000,0.827],
 'VioletRed' => [0.816,0.126,0.565],
 'VioletRedMedium' => [0.780,0.082,0.522],
 'VioletRedPale' => [0.859,0.439,0.576],
 'ViridianLight' => [0.430,1.000,0.440],
 'WarmGray' => [0.500,0.500,0.410],
 'Wheat' => [0.961,0.871,0.702],
 'White' => [1.000,1.000,1.000],
 'Yellow' => [1.000,1.000,0.000],
 'YellowBrown' => [0.860,0.580,0.440],
 'YellowGreen' => [0.604,0.804,0.196],
 'YellowLight' => [1.000,1.000,0.878],
 'YellowOchre' => [0.890,0.510,0.090],
 'Zinc' => [0.990,0.970,1.000]);

our @fontlist =();  # stores names of used fonts;

# ---------------------------------------------------------------------------
# Object counter (idea from Conway: Object Oriented Perl)
# ---------------------------------------------------------------------------

{
   my $_count = 0;
   sub _incr_count{++$_count;}
   sub _decr_count{--$_count;}
   sub _get_count{$_count;}
}

# ---------------------------------------------------------------------------
# Defining default values
# ---------------------------------------------------------------------------

my  %_default_values = (
number              => 0,
x_size              => 120,
y_size              => 90,
background          => '',
gradient            => [2,'Yellow','Black',[0,0],[0,75],1],
verbose             => 0,
psverbose           => 0,
unit_length         => "mm",
reencode            => 0,
space_width         => 0,
x_position          => undef,
y_position          => undef,
scale               => 1,
height              => undef,
width               => undef,
align               => 'lb',
angle               => 0,
frame               => 0,
framewidth          => 0,
framecolor          => 'Black',
framebehind         => 0,
clip                => 1,
);

# ---------------------------------------------------------------------------
# definecolor - define named colors
# ---------------------------------------------------------------------------
sub definecolor
{
   my ($class, %args)=@_;
   foreach (keys(%args)) {$colors{$_} = [_color($args{$_})]};
}

# ---------------------------------------------------------------------------
# set_default - set default properties of the image
# ---------------------------------------------------------------------------
sub set_default
{
   my ($class, %args)=@_;
   foreach (keys(%args)) {$_default_values{$_} = $args{$_}};
}

# ---------------------------------------------------------------------------
# set - set properties of an image
# ---------------------------------------------------------------------------
sub set
{
   my ($self,%args)=@_;
   foreach (keys(%args)) {$self -> {$_} = $args{$_}};
}

# ---------------------------------------------------------------------------
# get - get properties of an image
# ---------------------------------------------------------------------------
sub get
{
   my ($self,@args)=@_;
   my @list=();
  return(map($self ->{$_},@args));
}

# ---------------------------------------------------------------------------
# set_default - set default properties of the image
# ---------------------------------------------------------------------------
sub set_default
{
   my ($class, %args)=@_;
   foreach (keys(%args)) {$_default_values{$_} = $args{$_}};
}

# ---------------------------------------------------------------------------
# set - set properties of an image
# ---------------------------------------------------------------------------
sub set
{
   my ($self,%args)=@_;
   foreach (keys(%args)) {$self -> {$_} = $args{$_}};
}

# ---------------------------------------------------------------------------
# get - get properties of an image
# ---------------------------------------------------------------------------
sub get
{
   my ($self,@args)=@_;
   my @list=();
  return(map($self ->{$_},@args));
}

# ---------------------------------------------------------------------------
# setcolor - sets the drawing color
# ---------------------------------------------------------------------------
sub setcolor
{
   my ($self,@params)=@_;

#print "EPS setcolor @_\n";
   {$self -> setrgbcolor(_color(@params));}
}

# ---------------------------------------------------------------------------
# _unit_length - internal subroutine, sets the unit length
# ---------------------------------------------------------------------------
sub _unit_length
{
   my $self = shift;
   return 1 if $self->{unit_length} eq 'pt';
   return 72 if $self->{unit_length} eq 'in';
   return 72/25.4 if $self->{unit_length} eq 'mm';
   return 720/25.4 if $self->{unit_length} eq 'cm';
   return $self->{unit_length} if $self->{unit_length} > 0;
   return 1;
}

# ---------------------------------------------------------------------------
# _color - internal subroutine, transformation into RGB-values
# ---------------------------------------------------------------------------
sub _color
{
   my ($r, $g, $b);
   my $patt = '[0-9a-fA-F][0-9a-fA-F]';
   {
      if (scalar(@_) == 3 and ($_[0]<=1 and $_[1]<=1 and $_[2]<=1)) # list
         {$r=$_[0]; $g=$_[1]; $b=$_[2]; last;}
      if (scalar(@_) == 3 and ($_[0]>1 or $_[1]>1 or $_[2]>1)) # list
         {$r=$_[0]/255; $g=$_[1]/255; $b=$_[2]/255; last;}
      if (ref $_[0] and scalar(@{$_[0]}) == 3 and
            ($_[0]->[0]<=1 and $_[0]->[1]<=1 and $_[0]->[2]<=1)) # reference
         {$r=$_[0]->[0]; $g=$_[0]->[1]; $b=$_[0]->[2]; last;}
      if (ref $_[0] and scalar(@{$_[0]}) == 3 and
            ($_[0]->[0]>1 or $_[0]->[1]>1 or $_[0]->[2]>1)) # reference
         {$r=$_[0]->[0]/255; $g=$_[0]->[1]/255; $b=$_[0]->[2]/255; last;}
      if ($_[0]=~/\#($patt)($patt)($patt)/) # hex-values
         { $r=hex('0x'.$3)/255; $g=hex('0x'.$2)/255; $b=hex('0x'.$1)/255;}
      if ($_[0]=~/^\w+$/)
      {
         if (exists($colors{$_[0]})) # color name exists
            {($r, $g, $b) = @{$colors{$_[0]}};}
         else # black if color name does not exist
            {($r, $g, $b) = (0,0,0);}
      }
   }
   return($r, $g, $b);
}

# ---------------------------------------------------------------------------
# _make_background -  internal subroutine, drawing background
# ---------------------------------------------------------------------------

sub _make_background
{
#   $shadintype==2 ... axial shading
#   $shadintype==3 ... radial shading

my $self=shift;
my $background;
my $xsize = $self->{x_size};
my $ysize = $self->{y_size};

if ($self->{background} =~ /^GRADIENT/i) #     color gradient
{
   my $shadingtype = $self ->{gradient}->[0];
   unless ($shadingtype==2 or $shadingtype==3)
         {croak "** ERROR ** Invalid Shading type".(caller 1)[3];}

   my ($r1, $g1, $b1) = _color($self ->{gradient}->[1]);
   my ($r2, $g2, $b2) = _color($self ->{gradient}->[2]);
   my ($x1, $y1, $a1) = @{$self ->{gradient}->[3]};
   my ($x2, $y2, $a2) = @{$self ->{gradient}->[4]};
   my $exp = $self ->{gradient}->[5];

   if ($shadingtype==2) {$a1=''; $a2='';} # eliminate radii (if present)

   $background = <<EOT;
%Background:
gsave
<</ShadingType $shadingtype /ColorSpace  /DeviceRGB
/Coords [$x1 $y1 $a1 $x2 $y2 $a2]
/Extend [true true] /Function
<< /FunctionType 2 /Domain [0 1]
/C0 [$r1 $g1 $b1]
/C1 [$r2 $g2 $b2] /N $exp>> >>
0 0 $xsize $ysize rectclip
shfill grestore
EOT
}
else
{
   if ($self->{background}) #     single-color background
   {
      my ($r, $g, $b) = _color($self->{background});
      $background = <<EOT;
% Background:
gsave
newpath
$r $g $b setrgbcolor
0 0 $xsize $ysize rectfill
grestore
EOT
   }
}
chomp $background;
return $background;
} # end _make_background

# ---------------------------------------------------------------------------
# _make_frame - internal subroutine, drawing frame
# ---------------------------------------------------------------------------

sub _make_frame
{
   my $self=shift;
   my $frame;
   my ($r, $g, $b) = _color($self->{framecolor});
   my $framewidth = $self->{framewidth};
   my $xsize = $self->{x_size};
   my $ysize = $self->{y_size};

   $frame = "gsave\n" .
            "newpath\n" .
            "$r $g $b setrgbcolor\n" .
            "$framewidth setlinewidth\n" .
            "0 0 $xsize $ysize rectstroke\n" .
            "grestore";
   if ($self ->{psverbose} >0)
   {
      $frame  = "% Drawing frame for EPS \#$self->{number}\n$frame";
      $frame .= "\n% End of drawing frame for EPS \#$self->{number} ";
   }
   return $frame;
} # end _make_frame

# ---------------------------------------------------------------------------
# new - create a new image
# ---------------------------------------------------------------------------
sub new
{
   my $class = shift;
   my $self = {%_default_values};

   if (scalar(@_)==1) # parameter is a color
      {$self -> {background} = $_[0];}

   elsif (exists($self -> {$_[0]})) # parameter list is a hash
   {
      my %settings = @_;
      foreach (keys(%settings)) {$self -> {$_} = $settings{$_};}
   }

   else  # parameter list is an array of values: x_size, y_size, background
   {
      if ($_[0]) {$self -> {x_size} = $_[0]};
      if ($_[1]) {$self -> {y_size} = $_[1]};
      if ($_[2]) {$self -> {background} = $_[2]};
   }

   bless ($self, $class);
   $class -> _incr_count();
   $self -> {number} = $self->_get_count();
   $self -> {_p_code}               # receives the Postscript code
         = "\% Begin of EPS  \#$self->{number}...";
   if ($self->{verbose}>0)
      {print "EPS    - Image \#${\($self->{number})} created\n";}
   return $self;
}

# ---------------------------------------------------------------------------
# DESTROY
# ---------------------------------------------------------------------------
sub DESTROY
{
   my $self = shift;
   if ($self->{verbose}>0)
      {print "EPS    - Image \#$self->{number} died\n";}
}

# ---------------------------------------------------------------------------
# destroy
# ---------------------------------------------------------------------------
sub destroy
{
   my $self = shift;
   if ($self->{verbose}>0)
      {print "EPS    - Image \#$self->{number} destroyed\n";}
   undef %$self;
}

# ---------------------------------------------------------------------------
# clone - clone an image
# ---------------------------------------------------------------------------
sub clone
{
   my $to_be_cloned = $_[0];
   my $cloned = {$to_be_cloned};
   my $class = ref($to_be_cloned);
   bless ($cloned, $class);
   return $cloned;
}

# ---------------------------------------------------------------------------
# AUTOLOAD  - translate Perl-subroutines into Postscript code
# ---------------------------------------------------------------------------
sub AUTOLOAD
{
   my ($self,@args)=@_;
   my $string='';
   foreach (@args) {$string.=$_; $string.=' ';}
#  $AUTOLOAD=~s/EPS:://;  # Haa, 28.9.2003
   $AUTOLOAD=~s/.*:://;   # Haa, 28.9.2003
   $self -> {_p_code} .= "\n$string$AUTOLOAD ";
   if ($self->{verbose}>1)
      {print "EPS    - \#${\($self->{number})} AUTOLOAD $string$AUTOLOAD\n";}
}

# ---------------------------------------------------------------------------
# draw - draw the EPS image into another EPS image
# ---------------------------------------------------------------------------
sub draw
{
   my ($self,$picture,@args)=@_;

# Make a copy of all properties (in order not to change them permanentely):
   my $prop = {%$self};

   if (exists($prop -> {$args[0]})) # parameter list is a hash
   {
      my %settings = @args;
      if (exists $settings{width}
          or exists $settings{height}
          or exists $settings{scale})
      {
          $prop -> {width} = undef;
          $prop -> {height} = undef;
          $prop -> {scale} = undef;
      }
      foreach (keys(%settings)) {$prop -> {$_} = $settings{$_};}
   }

   else  # parameter list is an array of values: x_position, y_position, scale
   {
      if (defined $args[0]) {$prop -> {x_position} = $args[0]};
      if (defined $args[1]) {$prop -> {y_position} = $args[1]};
      if (defined $args[2])
      {
         $prop -> {scale} = $args[2];
         $prop -> {height} = undef;
         $prop -> {width} = undef;
      }
   }

   my $from = $prop->{number};
   my $to = $picture->{number};
   my $x_size = $prop -> {x_size};
   my $y_size = $prop -> {y_size};
   my $x_position = $prop->{x_position};
   my $y_position = $prop->{y_position};
   my $scale = $prop->{scale};
   my $height = $prop->{height};
   my $width = $prop->{width};
   my $angle = $prop->{angle};
   my $scalefactor = 1;  # final scale factor for drawed image

# Alignment:
   my $align = $prop->{align};
   my $xshift = -$x_size/2;
   my $yshift = -$y_size/2;
   $xshift = 0 if $align=~/l/i;
   $yshift = 0 if $align=~/b/i;
   $yshift = -$y_size if $align=~/t/i;
   $xshift = -$x_size if $align=~/r/i;

# Calculate scale factor for drawn image:
   if ($width or $height or $scale!=1)
   {
      my ($scalex, $scaley);
      if ($width ) {$scalex = $width  / $x_size;}
      if ($height) {$scaley = $height / $y_size;}

      if ($scale) {$scalefactor = $scale;}
      elsif ($height) {$scalefactor = $scaley;}
      elsif ($width) {$scalefactor = $scalex;}

      if ($width)
         {$scalefactor = $scalex < $scalefactor ? $scalex : $scalefactor;}
      if ($height)
         {$scalefactor = $scaley < $scalefactor ? $scaley : $scalefactor;}
   }

   if ($prop->{psverbose}>0)
      {$picture -> rawcode("% Begin drawing EPS \#$from into EPS \#$to ");}
   if ($prop->{verbose}>0)
      {print "EPS    - Drawing EPS \#$from into EPS \#$to ... ";}

# draw object:
# ------------
  $picture -> rawcode("gsave ");
  if (defined($x_position) and defined($y_position))
     {$picture -> rawcode("$x_position $y_position translate ");}
  else
     {$picture -> rawcode("currentpoint translate ");}
  $picture -> rawcode("$scalefactor dup scale ") if $scalefactor-1;
  $picture -> rawcode("$angle rotate ") if $angle;
  $picture -> rawcode("$xshift $yshift translate ") if $xshift or $yshift;
  if ($prop ->{clip}) {$picture -> rawcode("0 0 $x_size $y_size rectclip ");}
  if ($prop ->{background}) {$picture -> rawcode($self -> _make_background);}
  if ($prop->{frame} and $prop->{framebehind})
    {$picture -> rawcode($self -> _make_frame);}
  $picture -> rawcode($prop ->{_p_code});
  if ($prop->{frame} and !$prop->{framebehind})
    {$picture -> rawcode($self -> _make_frame);}
  $picture -> rawcode("grestore ");
  if ($prop->{psverbose}>0)
     {$picture -> rawcode("% End of drawing EPS \#$from into EPS \#$to ");}
  if ($prop->{verbose}>0)
     {print "finished\n";}
}

# ---------------------------------------------------------------------------
# include - include an EPS image in another EPS image (opposite of draw)
# ---------------------------------------------------------------------------
sub include
{
   my ($picture,$self,@args)=@_;

# Make a copy of all properties (in order not to change them permanentely):
   my $prop = {%$self};

   if (exists($prop -> {$args[0]})) # parameter list is a hash
   {
      my %settings = @args;
      if (exists $settings{width}
          or exists $settings{height}
          or exists $settings{scale})
      {
          $prop -> {width} = undef;
          $prop -> {height} = undef;
          $prop -> {scale} = undef;
      }
      foreach (keys(%settings)) {$prop -> {$_} = $settings{$_};}
   }

   else  # parameter list is an array of values: x_position, y_position, scale
   {
      if (defined $args[0]) {$prop -> {x_position} = $args[0]};
      if (defined $args[1]) {$prop -> {y_position} = $args[1]};
      if (defined $args[2])
      {
         $prop -> {scale} = $args[2];
         $prop -> {height} = undef;
         $prop -> {width} = undef;
      }
   }

   my $from = $prop->{number};
   my $to = $picture->{number};
   my $x_size = $prop -> {x_size};
   my $y_size = $prop -> {y_size};
   my $x_position = $prop->{x_position};
   my $y_position = $prop->{y_position};
   my $scale = $prop->{scale};
   my $height = $prop->{height};
   my $width = $prop->{width};
   my $angle = $prop->{angle};
   my $scalefactor = 1;  # final scale factor for drawed image

# Alignment:
   my $align = $prop->{align};
   my $xshift = -$x_size/2;
   my $yshift = -$y_size/2;
   $xshift = 0 if $align=~/l/i;
   $yshift = 0 if $align=~/b/i;
   $yshift = -$y_size if $align=~/t/i;
   $xshift = -$x_size if $align=~/r/i;

# Calculate scale factor for drawed image:
   if ($width or $height or $scale!=1)
   {
      my ($scalex, $scaley);
      if ($width ) {$scalex = $width  / $x_size;}
      if ($height) {$scaley = $height / $y_size;}

      if ($scale) {$scalefactor = $scale;}
      elsif ($height) {$scalefactor = $scaley;}
      elsif ($width) {$scalefactor = $scalex;}

      if ($width)
         {$scalefactor = $scalex < $scalefactor ? $scalex : $scalefactor;}
      if ($height)
         {$scalefactor = $scaley < $scalefactor ? $scaley : $scalefactor;}
   }

   if ($prop->{psverbose}>0)
      {$picture -> rawcode("% Begin drawing EPS \#$from into EPS \#$to ");}
   if ($prop->{verbose}>0)
      {print "EPS    - Drawing EPS \#$from into EPS \#$to ... ";}

# draw object:
# ------------
  $picture -> rawcode("gsave ");
  if (defined($x_position) and defined($y_position))
     {$picture -> rawcode("$x_position $y_position translate ");}
  else
     {$picture -> rawcode("currentpoint translate ");}
  $picture -> rawcode("$scalefactor dup scale ") if $scalefactor-1;
  $picture -> rawcode("$angle rotate ") if $angle;
  $picture -> rawcode("$xshift $yshift translate ") if $xshift or $yshift;
  if ($prop ->{clip}) {$picture -> rawcode("0 0 $x_size $y_size rectclip ");}
  if ($prop ->{background}) {$picture -> rawcode($self -> _make_background);}
  if ($prop->{frame} and $prop->{framebehind})
    {$picture -> rawcode($self -> _make_frame);}
  $picture -> rawcode($prop ->{_p_code});
  if ($prop->{frame} and !$prop->{framebehind})
    {$picture -> rawcode($self -> _make_frame);}
  $picture -> rawcode("grestore ");
  if ($prop->{psverbose}>0)
     {$picture -> rawcode("% End of drawing EPS \#$from into EPS \#$to ");}
  if ($prop->{verbose}>0)
     {print "finished\n";}
}

# ---------------------------------------------------------------------------
# line - draw concatenated lines
# ---------------------------------------------------------------------------
sub line
{
   my ($self,@args)=@_;
   my $point = shift(@args);
   my $x = $point->[0];
   my $y = $point->[1];
   $self -> {_p_code} .= "\nnewpath\n$x $y moveto ";
   while (@args)
   {
      $point = shift(@args);
      $x = $point->[0];
      $y = $point->[1];
      $self -> {_p_code} .= "\n$x $y lineto ";
   }
   $self -> {_p_code} .= "\nstroke ";
}

# ---------------------------------------------------------------------------
# path - draw a path
# ---------------------------------------------------------------------------
sub path
{
   my ($self,@args)=@_;
   my $point = shift(@args);
   my $x = $point->[0];
   my $y = $point->[1];
#  $self -> {_p_code} .= "\nnewpath\n$x $y moveto ";
   $self -> {_p_code} .= "\n$x $y moveto";
   while (@args)
   {
      $point = shift(@args);
      $x = $point->[0];
      $y = $point->[1];
      $self -> {_p_code} .= "\n$x $y lineto ";
   }
   $self -> {_p_code} .= "\nclosepath ";
}

# ---------------------------------------------------------------------------
# gfill - filling a path with a color gradient
# ---------------------------------------------------------------------------
sub gfill
{
   my ($self,@args)=@_;

# Take all values from the property "gradient":
# ---------------------------------------------
   my $shadingtype = $self ->{gradient}->[0];
   unless ($shadingtype==2 or $shadingtype==3)
         {croak "** ERROR ** Invalid Shading type".(caller 1)[3];}
   my ($r1, $g1, $b1) = _color($self ->{gradient}->[1]);
   my ($r2, $g2, $b2) = _color($self ->{gradient}->[2]);
   my ($x1, $y1, $a1) = @{$self ->{gradient}->[3]};
   my ($x2, $y2, $a2) = @{$self ->{gradient}->[4]};
   my $exp = $self ->{gradient}->[5];

# Overwrite values with provided arguments:
# -----------------------------------------
   $shadingtype = $args[0] if ($args[0]);
   ($r1, $g1, $b1) = _color($args[1]) if ($args[1]);
   ($r2, $g2, $b2) = _color($args[2]) if ($args[2]);
   ($x1, $y1, $a1) = @{$args[3]} if ($args[3]);
   ($x2, $y2, $a2) = @{$args[4]} if ($args[4]);
   $exp = $args[5] if ($args[5]);

   if ($shadingtype==2) {$a1=''; $a2='';} # eliminate radii (if present)

   my $code = <<EOT;
gsave clip newpath
<</ShadingType $shadingtype /ColorSpace  /DeviceRGB
/Coords [$x1 $y1 $a1 $x2 $y2 $a2]
/Extend [true true] /Function
<< /FunctionType 2 /Domain [0 1]
/C0 [$r1 $g1 $b1]
/C1 [$r2 $g2 $b2] /N $exp>> >>
shfill grestore
EOT

   $self -> {_p_code} .= $code;
}

# ---------------------------------------------------------------------------
# polygon - draw an outlined polygon
# ---------------------------------------------------------------------------
sub polygon
{
   my ($self,@args)=@_;
   $self -> path(@args);
   $self -> {_p_code} .= "\nstroke ";
}

# ---------------------------------------------------------------------------
# filled_polygon - draw a filled polygon
# ---------------------------------------------------------------------------
sub filled_polygon
{
   my ($self,@args)=@_;
   $self -> path(@args);
   $self -> {_p_code} .= "\nfill ";
}

# ---------------------------------------------------------------------------
# circle - draw an outlined circle
# ---------------------------------------------------------------------------
sub circle
{
   my ($self,@args)=@_;
   my ($x,$y,$r) = @args;
   defined($x) or croak "** ERROR ** Missing point".(caller 1)[3];
   defined($y) or croak "** ERROR ** Missing point".(caller 1)[3];
   defined($r) or croak "** ERROR ** Missing radius".(caller 1)[3];
   $self -> {_p_code} .= "\nnewpath $x $y $r 0 360 arc stroke ";
}

# ---------------------------------------------------------------------------
# filled_circle - draw a filled circle
# ---------------------------------------------------------------------------
sub filled_circle
{
   my ($self,@args)=@_;
   my ($x,$y,$r) = @args;
   defined($x) or croak "** ERROR ** Missing point".(caller 1)[3];
   defined($y) or croak "** ERROR ** Missing point".(caller 1)[3];
   defined($r) or croak "** ERROR ** Missing radius".(caller 1)[3];
   $self -> {_p_code} .= "\nnewpath $x $y $r 0 360 arc closepath fill ";
}

# ---------------------------------------------------------------------------
# rawcode - include Postscript Code
# ---------------------------------------------------------------------------
sub rawcode
{
   my ($self,@args)=@_;
   while (@args)
   {
      $self -> {_p_code} .= "\n".shift(@args)." ";
   }
}

# ---------------------------------------------------------------------------
# setdash - setting lengths for dashed lines
# ---------------------------------------------------------------------------
sub setdash
{
   my ($self,@args)=@_;
   unless (defined(@args) and scalar(@args)>1) # no dash
      {$self -> {_p_code} .= "\n[] 0 setdash ";}
   else
   {
      my $temp = $";
      $" =' ';
      $self -> {_p_code} .= "\n[@args] 0 setdash ";
      $" = $temp;
   }
}

# ---------------------------------------------------------------------------
# font - setting the font and size (in pt)
# ---------------------------------------------------------------------------
my $fontsize;
sub font
{
   my ($self,@args)=@_;
   my $fontname=$args[0];
   my $reencode = '';

#  Reencode the font to ISOLatin1Encoding:
#  (other reencodings are not yet implemented)
   if ($self->{reencode}=~/^iso$/i)
   {
      $reencode = "\n/$fontname findfont dup length dict begin";
      $reencode .= "\n{1 index /FID ne {def} {pop pop} ifelse} forall";
      $reencode .= "\n/Encoding ISOLatin1Encoding def currentdict end";
      $reencode .= "\n/$fontname exch definefont pop ";
   }

#  unless (grep {$_ eq $fontname} @{$self->{fontlist}}) # first use of font
   unless (grep {$_ eq $fontname} @fontlist) # first use of font
   {
#     push @{$self->{fontlist}}, $fontname;
      push @fontlist, $fontname;
      $self -> rawcode($reencode);
   }

   $fontsize = $self->{fontsize} / EPS::_unit_length($self);
   if ($args[1]) {$fontsize=$args[1] / EPS::_unit_length($self);}
   $self -> {_p_code} .= "\n/$fontname findfont $fontsize scalefont setfont ";
}

# ---------------------------------------------------------------------------
# textpath - drawing a character path
# ---------------------------------------------------------------------------
my $text_or_textpath = "show";
sub textpath  # just like "text", but replaces "show" by "true charpath"
{
   my ($self,@args)=@_;
   $text_or_textpath = "true charpath";
   $self -> text(@args);
   $text_or_textpath = "show";
}

# ---------------------------------------------------------------------------
# text - writing text
# ---------------------------------------------------------------------------
sub text
{
   my ($self,@args)=@_;
   my ($string,$align)=@args;

# translating umlauts into octal codes:
# -------------------------------------
   $string =~ s/\"a/\\344/g;
   $string =~ s/\"A/\\304/g;
   $string =~ s/\"o/\\366/g;
   $string =~ s/\"O/\\326/g;
   $string =~ s/\"u/\\374/g;
   $string =~ s/\"U/\\334/g;
   $string =~ s/\"s/\\337/g;

# break up text into words and spaces (because TeX-fonts dont have spaces):
# -------------------------------------------------------------------------
   my $pstring;
   my @words;     # list of words and spaces
   my $spacewidth = $self -> {space_width};
   my $spw = 0;
   if ($self -> {space_width})   # computed spaces
   {
      $spw = $spacewidth * $fontsize;
      @words = split /(?<! )(?= )|(?<= )(?! )|(?<= )(?= )/, $string;
      $pstring ='';
      foreach (@words)
      {
         if (/ /) # space
            {$pstring .= "\n$spw 0 rmoveto ";}
         else # word
            {$pstring .= "\n($_) $text_or_textpath ";}
      }
   }
   else  # normal spaces
   {
      $pstring = "\n($string) $text_or_textpath ";
   }

# Left aligned text:
# ------------------
   $align="l" unless $align;
   if ($align=~/l/i) # left aligned text
   {
      $self -> {_p_code} .= "\n$pstring ";
   }
# Centered text:
# --------------
   if ($align=~/c/i and !$spw) # centered text, normal spaces
   {
      $self -> {_p_code} .= "\n($string) stringwidth exch neg 2 div ";
      $self -> {_p_code} .= "\nexch rmoveto $pstring ";
   }
   if ($align=~/c/i and $spw) # centered text, computed spaces
   {
      $self -> {_p_code} .= "0 ";
      foreach (@words)
      {
         if (/ /) # space
            {$self -> {_p_code} .= "\n$spw add ";}
         else  # word
            {$self -> {_p_code} .= "\n($_) stringwidth pop add ";}
      }
      $self -> {_p_code} .= "\nneg 2 div 0 rmoveto $pstring ";
   }
# Right aligned text:
# -------------------
   if ($align=~/r/i and !$spw) # right aligned text, normal spaces
   {
      $self -> {_p_code} .= "\n($string) stringwidth exch neg exch ";
      $self -> {_p_code} .= "\nrmoveto $pstring ";
   }
   if ($align=~/r/i and $spw) # right aligned text, computed spaces
   {
      $self -> {_p_code} .= "0 ";
      foreach (@words)
      {
         if (/ /) # space
            {$self -> {_p_code} .= "\n$spw add ";}
         else  # word
            {$self -> {_p_code} .= "\n($_) stringwidth pop add ";}
      }
      $self -> {_p_code} .= "\nneg 0 rmoveto $pstring";
   }
}

# ---------------------------------------------------------------------------
# textp - writing positioned text
# ---------------------------------------------------------------------------
sub textp
{
   my ($self,@args)=@_;
   my ($x,$y,$string,$align)=@args;
   $self -> rawcode("gsave $x $y moveto ");
   $self -> text($string,$align);
   $self -> rawcode("grestore ");
}

# ---------------------------------------------------------------------------
# writepdf - write to file and invoking epstopdf
# ---------------------------------------------------------------------------
sub writepdf
{
   my ($self,$filename)=@_;
   unless ($filename) {$filename = $0;}   #if no filename specified
   $filename =~ s/(.*)\..*/\1/;
   $filename .= '.eps';
   $self -> write($filename);
   if ($self->{verbose}>0)
      {print "EPS    - Invoke epstopdf for image \#$self->{number} ...";}
   system ("epstopdf $filename");
   if ($self->{verbose}>0) {print " done\n";}
}

# ---------------------------------------------------------------------------
# write - write to file
# ---------------------------------------------------------------------------
sub write
{
   my ($self,$filename)=@_;
   my $x_size = $self -> {x_size};
   my $y_size = $self -> {y_size};
   my $bbx = ($x_size * EPS::_unit_length($self));
   my $bby = ($y_size * EPS::_unit_length($self));

   unless ($filename) #if no filename specified
          {$filename = $0; $filename =~ s/(.*)\..*/\1.eps/;}

   if ($self->{verbose}>0)
      {print "EPS    - Write image \#$self->{number} to file $filename ...";}
   my @lt=localtime(time);
   my $year=$lt[5]+1900;
   my $month=substr("0".($lt[4]+1), -2);
   my $day=substr("0".$lt[3], -2);
   my $date="$year-$month-$day";

# EPS-File Header:
# ----------------
my $header = <<EOT;
\%!PS-Adobe-3.0 EPSF-3.0
\%\%BoundingBox: 0 0 ${\int($bbx)} ${\int($bby)}
\%\%HiResBoundingBox: 0 0 $bbx $bby
\%\%Title:
\%\%Creator: Perl-Module EPS.pm V$VERSION, (c) Wilhelm Haager 2003
\%\%For: everyone
\%\%CreationDate: $date
\%\%EndComments
save ${\EPS::_unit_length($self)} dup scale
EOT

# EPS-File Trailer:
# -----------------
my $trailer = <<EOT;
\nshowpage
\%\%Trailer
restore
\%\%DocumentFonts:
\%\%DocumentNeededFonts:
EOT

   open (OUTFILE, ">$filename") or croak
        "** ERROR ** Cannot open File $filename".(caller 1)[3];

   print OUTFILE $header;
   print OUTFILE "0 0 $x_size $y_size rectclip " if $self ->{clip};
   print OUTFILE "\n".$self->_make_background if $self->{background};
   if ($self->{frame} and $self->{framebehind})
      {print OUTFILE "\n".$self->_make_frame;}
   print OUTFILE "\n$self->{_p_code}";
   if ($self->{frame} and !$self->{framebehind})
      {print OUTFILE "\n".$self->_make_frame;}
   print OUTFILE $trailer;
   close OUTFILE;
   if ($self->{verbose}>0) {print " done\n";}
}

1;
__END__

=head1 NAME

EPS - Routines for creating Encapsulated-Postscript Images

=head1 SYNOPSIS

  use EPS;
  $p = EPS -> new(x_size=>150, y_size=>100); # new image with 150x100 mm size
  $p -> set_default(unit_length=>"cm", verbose=>1);
  $p -> set (background=>"Blue");       # blue background
  $p -> set (gradient=>[2,"Blue","Black",[0,0],[10,50],1]); # color gradient
  $p -> set (background=>"gradient");   # gradient background
  $p -> setcolor("Green");
  $p -> line([10,10],[20,10],[30,20]);
  $p -> circle(50,20,15);
  $p -> filled_circle(50,20,15);
  $p -> polygon([20,20],[30,20],[40,40],[20,50]);
  $p -> filled_polygon([20,20],[30,20],[40,40],[20,50]);
  $p -> rawcode("0 0 moveto 20 10 lineto stroke");
  $p -> font('Helvetica',10); # setting font (10 pt size)
  $p -> text('This is a left justified text','l');
  $p -> text('This is a centered text','c');
  $p -> text('This is a right justified text','r');
  $p -> draw($p1, $x_position=>10,y_position=>20);
  $p -> any_postscript_command($a,$b,$c,$d);
  $p -> write("image.eps");

=head1 INTRODUCTION

This Perl package supports the creation of Encapsulated Postscript images
(level 3) with a single color or a color gradient as background,
containing simple shapes (as lines, polygons, circles etc.) and text.
Additionally, any Postscript code can be included verbatim.

The unit length for all dimensions can be set with the property
C<unit_length>, initially it is set to millimeters.
Nevertheless, the fontsize is always given in Postscript points.

=head2 Colors:

Any color can be given in the following ways:

=over 1

=item List of RGB-values:

List or reference to a list of the red-, green- and blue-values
ranging either from 0 to 1 or from 0 to 255

Examples: C<(0, 0.5, 0.7)>, C<[$rvalue, $gvalue, $bvalue]>, C<[255,0,0]>

=item RGB-values hexadecimal:

a string representing the hex values blue, green, and red
ranging from 00 to ff

Examples: C<"#0000ff"> (red), C<"#009900"> (dark green)

=item Named Colors:

a string representing an named color. Initially all the
colors names from Mathematica are defined; additionally to those,
new color names can be defined with

  $p -> definecolor(color_name -> [$r, $g, $b]);

Examples: C<"Red">, C<"BlueViolet">, C<"color_name">

=back 1

=head1 PROPERTIES

An image object has the following properties which can be set with
the methods
C<new> (for a new image),
C<set> (for an existing image) or
C<set_default> (for all subsequently created images):

=head2 Basic Properties:

=over 1

=item background

Background color (default: no background)

=item clip

If set to 1, all drawings are confined to the bounding box of the image,
determined by C<x_size> and C<y_size>, objects outside are clipped;
if set to 0, no clipping is performed; default: 1.

=item frame

Specifies whether a frame is drawn around the image
(0...no frame, 1...frame), default: 0

=item framecolor, framewidth

Color and width of the frame, default: 'Black' and 0, respectively.

=item gradient

Contains an array of several values which control the generation of
a shaded background or a shaded fill, consisting of the following values:

=over 2

=item *

Shading Type: an integer representing the type of shading
according to the Adobe Postscript recerence manual.
Currently only two shading types are supported:
axial shading (shading type 2) and radial shading(shading type 3).

=item *

starting color

=item *

final color

=item *

reference to an array containing the coordinates for the statring
point of the color axis (shading type 2) or the coordinates for the center
and the radius for the starting circle (shading type 3).

=item *

same as above, for the final point and the final circle, respectively

=item *

Exponent of the interpolation function for the color-gradient

=back 2

Examples:

  gradient => [2, 'Blue', 'Black', [0,0], [20,90], 1]
  gradient => [3, '#0000ff', '#001234', [60,45,0], [80,50,100], 1]

=item reencode

If set to C<iso> when a font is used for the first time,
that font will be reencoded to ISO-Latin 1 encoding;
this allows the use of umlauts and other language specific characters.
If set to 0 (or empty string), subsequently introduced
fonts are used with their original encoding.

=item space_width

When set to a positive value, spaces in text are replaced by direct
positioning of the particular words.
That value (in relation to the font size) specifies the widths of
the gaps between words (proper values are 0.3 to 0.5).
That property is useful for fonts which are designed for TeX
(such as the CM- and the EC-fonts), as those do not have a real space
character which is blank.

=item unit_length

Unit length for all dimensions;
can be set with a string
(C<"pt">...Postscipt points, C<"mm">...millimeters,
C<"cm">...centimeters, C<"in">...inch) or a number representing
a multiple of Postscript points (default C<"mm">).

=item verbose

Controls the output of messages:
A value of 0 supresses all messages;  at 1
the creation and vanishing of images is reported,
as well as writing to file, 2 causes (additional to 1) reporting
all calls of C<AUTOLOAD>, which translate any methods, which are not
declared explicitely, into Postsript commands.

=item psverbose

Controls writing comments into the EPS file:
when set to one, some actions as the begin and end of drawing an image
into another image are commented.

=item x_size

Horizontal size of the image (default 120).

=item y_size

Vertical size of the image (default 90).

=back 1

=head2 Properties for merging images:

The following properties are only significant, if images (i.e. EPS objects)
are drawn into other images using the methods C<draw> or C<include>.

=over 1

=item align

Specifies the alignment for the included image
(with respect to C<x_position> and C<y_position>); its value is a string
containing one or an appropriate combination of the following letters
(default: C<'lb'>):

=over 2

=item *

C<l>...left

=item *

C<r>...right

=item *

C<c>...center

=item *

C<t>...top

=item *

C<b>...bottom

=back 2

=item angle

Specifies the angle of the included image in degrees, default:0

=item width, height, scale

These parameters specify the actual size of an image when drawn
into another image; the image to be drawn is resized accordingly
in order not to exceed any of the specified parameters.
Default for C<scale>: 1 (which means no resizing), C<width> and C<height>
are initially undefined

=item x_position, y_position

Specifies the position of the image to be included;
unless specified, the image is included at the actual drawing position
(of the receiving image).

=back 1

All properties stated above, usually are set be set by the user,
it is therefore hardly necessary to read them out;
nevertheless a C<get>-method exists to read them out.
Besides, an image consists of the following additional properties,
which are not set by the user directly.

=head2 Additional properties:

=over 1

=item _p_code

A string receiving all the Postscript code generated by the
methods; that string is written to the image-file with the method C<write>.

=item number

An integer number (begining with 1) for every created image.

=back 1

=head1 METHODS

=over 1

=item circle

Draws an outlined circle, requires three parameters:
the x- and y-coordinate of the center point and the radius. Example:

 $img -> circle($x0, $y0, $radius);

=item clone

Clones an image; example:

  $newimg = $img -> clone;

=item definecolor

Defines additional color names for the C<EPS> class, example:

  $EPS -> definecolor("Gelb"=>"Yellow", "Lila"=>[0.4,0.7,0]);

=item destroy

Destructor of an image; releases memory when an object is not needed any more:

 $img -> destroy:

=item draw

Draws an image into another image.
All properties of the drawn image can be set
temporarily in the parameter list as key-value pairs,
which is primarily useful for the properties  regarding the drawing
(e.g. C<x_position>, C<y_position>, C<scale>, C<width>, C<height>, C<align>, C<angle>).
The properties are not set permanently (as done by C<set>).
Example:

 $img -> draw($another_img, x_position=>10, y_position=>20, scale=>0.5);

If only C<x_position>, C<y_position> (and C<scale>) need to be specified,
a short form without specifying key-value pairs but only
specifying the values, exists for sake of conveniency:

 $img -> draw($another_img,10,20,0.5);

=item filled_circle

Draws a filled circle, example:

 $img -> filled_circle($x0, $y0, $radius);

=item filled_polygon

Draws a filled polygon, exaple;

 $img -> filled_polygon([0,0],[0,100],[50,50]);

=item font

Setting the font and fontsize (in Postscript points), example:

 $img -> font("Helvetica", 12);

=item get

Reads out properties of an image object, arguments are strings containing
the property names, an array containing the property values is returned.
Example:

 ($width, $height) = $img -> get("x_size", "y_size");

=item gfill

Fills a path with a color gradient, which is either defined in the
property B<gradient> or given as a parameter. Example:

 $img -> set(gradient => [2,"Blue","Black",[0,0],[0,50],1]);
 $img -> path([0,0],[0,100],[50,50]);
 $img -> gfill;

=item include

On principle the same as C<draw> but from the point of view of the image
which is receiving the other image.
The following example do exactly the same as the previous examples:

 $another_img -> include($img, x_position=>10, y_position=>20, scale=>0.5);
 $another_img -> include($img,10,20,0.5);

=item line

Draws concatenated lines, the points are given as list references
containing the x- and y-coordinates. Example:

 $img -> line([10,10], [55,10], [10,60], [55,60]);

=item new

Creation a new image object;
arbitrary properties can be passed to the object like in the C<set>-method.
Example:

  $img = EPS -> new(x_size=>150, y_size=>100, background=>"Black");

If only C<x_size>, C<y_size> (and C<background>) need to be specified,
a short form without specifying key-value pairs but only
specifying the values, exists for sake of conveniency:

  $img = EPS -> new(150,100,"Black");

=item path

Makes a drawing path defined by points, but
does not actually put any color on that path (like C<polygon>)
or into the surrounded region (like C<filled_polygon>),
that method is just a prerequisite for C<gfill>
(but can also be used in a very general way to make drawing paths for
subsequent stroking or filling).

=item polygon

Draws an outlined polygon with arbitrary verticees,
the vertices are given as list references
its containing x- and y-coordinates. Example:

 $img -> polygon([0,0],[0,100],[50,50]);

=item rawcode

Includes Postscript Code, which is given as a string, verbatim in the image.
Example:

 $img -> rawcode("gsave 50 50 moveto 45 rotate");

=item set

Sets and changes the properties of an image;
arguments are key-values pairs of the properties.
Example:

  $img -> set(background=>[0,0,1], verbose=>1);

=item setcolor

Sets the drawing color, which can be given in any of the above stated ways.
Examples:

 $img -> setcolor(1,1,0);
 $img -> setcolor([1,1,0]);
 $img -> setcolor("Yellow");
 $img -> setcolor("#00ffff");

=item setdash

Sets dash patterns for lines; the parameter values are the lengths of the
line segments and the gaps between. The value 0 turns off dashing. Example:

 $img -> setdash(6,1,2,1);

=item set_default

Sets default values of the properties for all subsequently created image
objects. Example:

  $EPS -> set_default(x_size=>50, x_size=>50);

=item text

Writes a textstring (which is given as th first parameter) at the current
plot position, an alignment can be given as second parameter:
'l'...left aligned (default), 'c'...centered, 'r'...right aligned.
Example:

 $img -> text('This is a centered text!','c');

=item textp

Similar to C<text>, but specifies the insertion point as the first two
parameters, example:

 $img -> textp(25,50,'This is a centered text!','c');

=item textpath

Similar to C<Text>, but only prepares a character path for subsequent
filling (preferably with a color gradient) or stroking, example:

 $img -> textpath('This is a centered text!','c');
 $img -> gfill;

=item write

Writes the Postscript code which is contained in C<_p_code>
(additional to an EPS header and trailer) to a file, which is given as
an argument.
If no filename is given, the EPS-file gets the same name
as the calling Perl-file (with the extension changed to C<.eps>).
The filename extension C<.eps> is assumed (unless given explicitely);
an existing file with the same name will be overwritten without mention.
Example:

  $img -> write("picture1.eps");

=item writepdf

Like C<write>, additional to that, the program I<epstopdf>
(which is part of Ghostscript) is invoked to produce a C<PDF>-file;
the file-extension C<.pdf> is appended automatically.
Example:

  $img -> writepdf("picture1");

=back 1

=head2 Translation of methods into Postscript commands

Additional to the methods listed above,
any Postscript command can be declared as a method,
which will be translated via AUTOLOAD into the respective
Postscript command in the following way:

  $p -> any_postscript_command($a,$b,$c,$d,...)

is translated to

  $a $b $c $d ... any_postscript_command

Thus, basic knowledge of the Postscript language is helpful;
see Postscript Language Reference Manual ("Red Book") for further details.

Beware: Perl will not complain about a method like

  $img -> totally_nonsense("blah-blah")

but very likely the Postscript interpreter will produce an error message.

Examples:

  $p -> newpath;          # begins a new drawing path
  $p -> closepath;        # finishes a the current drawing path
  $p -> gsave;            # saves the graphic state
  $p -> grestore;         # restores the graphic state
  $p -> moveto(10,10);    # moves the drawing cursor to the point (10,20)
  $p -> lineto(10,20);    # draws a line to the point (10,20)
  $p -> stroke;           # fills the path with color
  $p -> fill;             # fills the region wihthin the path with color
  $p -> setlinewidth(0.3);# sets the linewidth
  $p -> setlinecap(0);    # sets the type of line endings
  $p -> setlinejoin(0);   # sets the type of line joins
  $p -> translate(100,20);# moves the origin of the coordinate system
  $p -> scale(2,2);       # scales the x- and y-axis of the coordinate system
  $p -> rotate(45);       # rotates the coordinate system by 45 degrees
  $p -> rectfill(10,10,70,50);     # draws a filled rectangle
  $p -> rectstroke(10,10,70,50);   # draws an outlined rectangle

=head1 VERSION

EPS 3.0 (2003-11-03)

=head1 AUTHOR

Wilhelm Haager, HTL St.Poelten, Austria C<(wilhelm.haager@htlstp.ac.at)>

=head1 COPYRIGHT

  Copyright 2003, Wilhelm Haager

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
