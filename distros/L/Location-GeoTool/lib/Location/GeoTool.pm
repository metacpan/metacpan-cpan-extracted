package Location::GeoTool;

################################################################
#
#  Geometric Functions 
#  Location::GeoTool
#  

use 5.008;
use strict;
use warnings;
use vars qw($VERSION @ISA $AUTOLOAD %engines);
$VERSION = 2.000000;

################################################################
# Dependency                   #
################################

use Math::Trig qw(asin tan);
use Carp;
require Location::GeoTool::Direction;
require XSLoader;

my $enginename = 'pp';
eval {
    XSLoader::load('Location::GeoTool', $VERSION);
    $enginename = 'xs';
};

################################################################
# Initialize                   #
################################

__PACKAGE__->_make_accessors(
    qw(
        def_datum def_format out_datum out_format cache_lat cache_long alt
        changeMyself enableWantarray defaultDatum defaultFormat
    )
);

my $pi  = 4 * atan2(1,1); 								# PI
my $rd  = $pi / 180;      								# [radian/degree]

################################
# Use pureperl? or XS?

$engines{'v2p'} = \&{"v2p_$enginename"};
$engines{'p2v'} = \&{"p2v_$enginename"};
$engines{'mol'} = \&{"molodensky_$enginename"};

################################
# Default data

# Direction string
my %dirstr_master = (
  'jp' => [
    'ËÌ','ËÌÈùÅì','ËÌËÌÅì','ËÌÅìÈùËÌ','ËÌÅì','ËÌÅìÈùÅì','ÅìËÌÅì','ÅìÈùËÌ',
    'Åì','ÅìÈùÆî','ÅìÆîÅì','ÆîÅìÈùÅì','ÆîÅì','ÆîÅìÈùÆî','ÆîÆîÅì','ÆîÈùÅì',
    'Æî','ÆîÈùÀ¾','ÆîÆîÀ¾','ÆîÀ¾ÈùÆî','ÆîÀ¾','ÆîÀ¾ÈùÀ¾','À¾ÆîÀ¾','À¾ÈùÆî',
    'À¾','À¾ÈùËÌ','À¾ËÌÀ¾','ËÌÀ¾ÈùËÌ','ËÌÀ¾','ËÌÀ¾ÈùÀ¾','ËÌËÌÀ¾','ËÌÈùÀ¾'
  ],
  'en' => [
    'N','NbE','NNE','NEbN','NE','NEbE','ENE','EbN',
    'E','EbS','ESE','SEbE','SE','SEbS','SSE','SbE',
    'S','SbW','SSW','SWbS','SW','SWbW','WSW','WbS',
    'W','WbN','WNW','NWbN','NW','NWbW','NNW','NbW'
  ]
);
my $def_dirstr = 'jp';

# Format
my %format_sub = map { $_ => [\&_def_fmt_in,\&_def_fmt_out]} ('mapion','dmsn','second','degree','radian','gpsone','spacetag');

# Code
my %code_sub;

# Datum
my %ellip = (
  'wgs84' => [6378137,(1 / 298.257223),0,0,0],
  'tokyo' => [6377397.155,(1 / 299.152813),148,-507,-681]
);

# Constants
my $changeMyself    = 0;
my $enableWantarray = 0;
my $defaultDatum    = 'wgs84';
my $defaultFormat   = 'gpsone';

################################################################
# Class Methods                #
################################

# Import : set plugin 
sub import {
    my $class = shift;
    my $piname = '';
    foreach my $plugin (@_) {
        $piname = '';
        foreach my $type ('','Plugin') {
            my $name = __PACKAGE__.($type eq "" ? "" : "::$type")."::$plugin";
            eval "require $name;";
            unless ($@) {
                $piname = $name;
                last;
            }
        }
        croak "Can't find plugin named $plugin" unless ($piname);
        $piname->setup;
    }
}

# Set new format you like
sub set_original_format
{
  my $class = shift;
  $format_sub{$_[0]} = $_[1];
}

# Set new code you like
sub set_original_code
{
  my $class = shift;
  $code_sub{$_[0]} = $_[1];
}

# Set new datum you like
sub set_original_datum
{
  my $class = shift;
  $ellip{$_[0]} = $_[1];
}

# Set new direction string you like
sub set_original_dirstr
{
  my $arg = shift;
  if (ref($arg) eq "ARRAY")
  {
    $dirstr_master{'def_original'} = $arg;
    $def_dirstr = 'def_original';
  }
  else
  {
    $dirstr_master{$_[0]} = $_[1];
  }
}

################################################################
# Object Methods               #
################################

################################
# Constructor by 2D coordinates
sub create_coord
{
  shift->set_coord(@_);
}

sub set_coord
{
  my $self = shift;
  return $self->create_coord3d(@_[0..1],"+000000",@_[2..$#_]);
}

# Constructor by 3D coordinates ... it has no effect in this version
sub create_coord3d
{
  my $self = shift;
  $self = $self->new() unless (ref($self));
  @{$self}{qw(lat long alt def_datum def_format source)} = @_;
  $self->{def_datum} ||= 'wgs84';
  $self->{def_format} ||= 'spacetag';
  $self->_set_outsetting(@{$self}{qw(def_datum def_format)});
  return $self;
}

################################
# Accessor to 2D coordinates
sub array
{
  my $self = shift;
  return ($self->{lat},$self->{long}) if (($self->def_datum eq $self->out_datum) && ($self->def_format eq $self->out_format));
  ($self->{cache_lat},$self->{cache_long}) = $self->_exec_array($self->out_datum,$self->out_format) unless ($self->cache_lat && $self->cache_long);
  return ($self->cache_lat,$self->cache_long);
}

# Accessor to Latitude
sub lat
{
  my $self = shift;
  my @cache = $self->array;
  return $cache[0];
}

# Accessor to Longitude
sub long
{
  my $self = shift;
  my @cache = $self->array;
  return $cache[1];
}

# Accessor to 3D coordinates ... it has no effect in this version
sub array3d
{
  my $self = shift;
  return ($self->array,$self->alt);
}

################################
# Create Location::GeoTool::Direction object start from here, giving end point 
sub direction_point
{
  my $self = shift;
  return Location::GeoTool::Direction->new($self)->set_topoint(@_);
}

################################
# Create Location::GeoTool::Direction object start from here, giving direction and distance
sub direction_vector
{
  my $self = shift;
  return Location::GeoTool::Direction->new($self)->set_vector(@_);
}

################################
# For... changing datum or format method
sub AUTOLOAD 
{
  my $self = shift;
  my $method = $AUTOLOAD;
  $method =~ s/.+://;
  return if ($method eq "DESTROY");

  if ($method =~ /^format_(\w+)$/)	# changing format
  {
    croak qq{Not support this format : $1 at this version of Location::GeoTool}
      unless ($format_sub{$1});
      my $out_format = $1;
      no strict 'refs';
      *{$method} = sub {
         my $self = shift;
         $self->_exec_change($self->out_datum,$out_format,@_);
      };
    return $self->$method(@_);
  }
  elsif ($method =~ /^datum_(\w+)$/)	# changing datum
  {
    croak qq{Not support this datum : $1 at this version of Location::GeoTool}
      unless ($ellip{$1});
      my $out_datum = $1;
      no strict 'refs';
      *{$method} = sub {
         my $self = shift;
         $self->_exec_change($out_datum,$self->out_format,@_);
      };
    return $self->$method(@_);
  }
  elsif (($method =~ /^create_(\w+)$/) || ($method =~ /^set_(\w+)$/))
  {
    croak qq{Cannot create from this format : $1 at this version of Location::GeoTool}
      unless ($code_sub{$1});
      my $from_code = $code_sub{$1}->[0];
      no strict 'refs';
      *{$method} = sub {
         $from_code->(@_);
      };
    return $self->$method(@_);
  }
  elsif ($method =~ /^get_(\w+)$/)
  {
    croak qq{Cannot get from this format : $1 at this version of Location::GeoTool}
      unless ($code_sub{$1});
      my $to_code = $code_sub{$1}->[1];
      no strict 'refs';
      *{$method} = sub {
         $to_code->(@_);
      };
    return $self->$method(@_);
  }
  else
  {
    croak qq{Can't locate object method "$method" via package "Location::GeoTool"};
  }
}

################################################################
# Internal Methods for OO      #
################################

# Internal Constructor
sub new
{
    my $class = shift;
    my $opt = $_[0] && ref($_[0]) eq 'HASH' ? shift : {} ;
    return bless {
        changeMyself    => $changeMyself,
        enableWantarray => $enableWantarray,
        defaultDatum    => $defaultDatum,
        defaultFormat   => $defaultFormat,
        %{$opt},
    },$class;
}

# Construct accessor methods
sub _make_accessors 
{
    my($class, @attr) = @_;
    for my $attr (@attr) {
        no strict 'refs';
        *{"$class\::$attr"} = sub {
            $_[0]->{$attr} = $_[1] if (defined($_[1]));
            $_[0]->{$attr}
        };
    }
}

# Clone myself
sub _clone
{
  my $self = shift;
  return bless {%$self},ref($self);
}

# Set datum and format
sub _set_outsetting
{
  my $self = shift;
  @{$self}{qw(out_datum out_format cache_lat cache_long)} = @_;
}

# Create child object or return lat/long value
# They are in same function for future extension
sub _exec_change
{
    my $self = shift;
    my ($outdatum,$outformat) = @_;

    my $copy = $self->changeMyself ? $self : $self->_clone;
    $copy->_set_outsetting($outdatum,$outformat);
    return $copy->array if (wantarray && $self->enableWantarray);
    return $copy;
}

sub _exec_array {
    my $self = shift;

    my ($lat,$long) = @{$self}{qw(lat long)};
    return unless (defined($lat) && defined($long));
    if ($self->def_datum eq $self->out_datum)
    {
        ($lat,$long) = map { coordformat($_,$self->def_format,$self->out_format) } ($lat,$long) if ($self->def_format ne $self->out_format);      
    }
    else
    {
        ($lat,$long) = map { coordformat($_,$self->def_format,'degree') } ($lat,$long) unless ($self->def_format eq 'degree');
        ($lat,$long) = datumchange_degree($lat,$long,"+000000",$self->def_datum,$self->out_datum);
        ($lat,$long) = map { coordformat($_,'degree',$self->out_format) } ($lat,$long) unless ($self->out_format eq 'degree');
    }
    return ($lat,$long);
}

################################################################
# Basic functions             #
###############################

################################
# Get the name of direction from degree

sub direction_string
{
  my ($degree,$mother,$lang) = @_;
  my @master = @{$dirstr_master{ $lang || $def_dirstr }};

  my $masternum = @master;
  my @mothermaster;
  for (my $i = 0;$i < $masternum;$i += int($masternum/$mother))
  {
    push(@mothermaster,$master[$i]);
  }

  # Turn 45 degree
  $degree += int(360/($mother*2));
  while (($degree < 0) || ($degree >= 360))
  {
    $degree -= 360 if ($degree >= 360);
    $degree += 360 if ($degree < 0);
  }
  return $mothermaster[int($degree/360*$mother)];
}

################################
# Change the format of coordinate

sub coordformat
{
  my ($coord,$farg,$targ,$pon) = @_[0..3];
  my $s = ($coord =~ s/^(\+|-)//) ? $1 : "+";
  my ($dd, $mm, $ss) = &{$format_sub{$farg}->[0]}($coord,$farg);
  my $ret;
  ($ret,$pon) = &{$format_sub{$targ}->[1]}($dd, $mm, $ss, $targ, $pon);

  # Set Plus/Minus sign if wanted
  if ((($pon) && ($pon == 1)) || ($s eq '-'))
  {
    $ret = $s.$ret;
  }

  return $ret;
}

# Default engine for decode each format to degree,minute and second.
# You can add any original format by using set_original_format
sub _def_fmt_in
{
  my ($coord,$farg) = @_;
  my ($dd, $mm, $ss);

  if ($farg eq 'spacetag')
  {
    $coord =~ /(\d{3})(\d{2})(\d{2})(\d{3})$/;
    $dd = $1;
    $mm = $2;
    $ss = $3+$4/1000;
  } 
  elsif ($farg eq 'mapion') 
  {
    $coord =~ /(\d+)\/(\d+)\/(\d+(\.\d+)?)$/;
    $dd = $1;
    $mm = $2;
    $ss = $3;
  } 
  elsif ($farg eq 'dmsn')
  {
    $coord =~ /(\d+)(\d{2})(\d{2}(\.\d+)?)$/;
    $dd = $1;
    $mm = $2;
    $ss = $3;
  } 
  elsif (($farg eq 'second') || ($farg eq 'degree') || ($farg eq 'radian'))
  {
    if ($farg eq 'second') 
    {
      $ss = $coord;
    } 
    elsif ($farg eq 'degree') 
    {
      $ss = $coord * 3600;
    } 
    else 
    {
      $ss = $coord * 3600 / $rd;
    }
    $dd = int($ss/3600);
    $ss = $ss-$dd*3600;
    $mm = int($ss/60);
    $ss = $ss-$mm*60;
  } 
  elsif ($farg eq 'gpsone') 
  {
    $coord =~ /(\d+)\.(\d+)\.(\d+(\.\d+)?)$/;
    $dd = $1;
    $mm = $2;
    $ss = $3;
  }
  $dd += 0;

  return ($dd,$mm,$ss);
}

# Default engine for encode degree,minute and second to each format.
# You can add any original format by using set_original_format
sub _def_fmt_out
{
  my ($dd, $mm, $ss, $targ, $pon) = @_;
  my $ret;
  if ($targ eq 'spacetag')
  {
    $pon = 1;
    $ret = sprintf("%03d%02d%06.3f",$dd,$mm,$ss);
    $ret =~ s/\.//;
  } 
  elsif ($targ eq 'mapion') 
  {
    $ret = sprintf("%d/%02d/%06.3f",$dd,$mm,$ss);
  } 
  elsif ($targ eq 'dmsn')
  {
    $ret = sprintf("%d%02d%06.3f",$dd,$mm,$ss);
  } 
  elsif (($targ eq 'second') || ($targ eq 'degree') || ($targ eq 'radian'))
  {
    $ret = $dd * 3600 + $mm * 60 + $ss;
    if ($targ eq 'degree') 
    {
      $ret = $ret/3600;
    } 
    if ($targ eq 'radian') 
    {
      $ret = $ret*$rd/3600;
    } 
  } 
  elsif ($targ eq 'gpsone')
  {
    $ret = sprintf("%d.%02d.%06.3f",$dd,$mm,$ss);
  }

  return ($ret,$pon);
}

################################
# Calcurate a point that has the direction 
# and the distance from other point

sub vector2point_degree
{
  my ($lat,$lon,$dir,$dis) = @_[0..3];
  my $datum = $_[4] || 'wgs84';

  my $ellip = $ellip{$datum};
  my $a = $ellip->[0];									# Equatorial Radius
  my $f = $ellip->[1];									# Flattening

  return &{$engines{'v2p'}}($f,$a,$rd,$lat,$lon,$dir,$dis);
}

################################
# Calcurate distance and direction of points

sub point2vector_degree
{
  my ($lat,$lon,$tlat,$tlon) = map { $_ * $rd } @_[0..3];
  my $datum = $_[4] || 'wgs84';

  my $ellip = $ellip{$datum};
  my $a = $ellip->[0];								# Equatorial Radius
  my $f = $ellip->[1];								# Flattening

  return &{$engines{'p2v'}}($f,$a,$rd,$lat,$lon,$tlat,$tlon);
}

################################
# Change the coordinate to different datum

sub datumchange_degree
{
  my ($b,$l,$h,$from,$to) = @_;
  $h = eval($h)/100;
  ($from,$to) = map { $_ || 'wgs84' } ($from,$to);

  my $fellip = $ellip{$from};
  my $tellip = $ellip{$to};
  my @a = ($fellip->[0],$tellip->[0]);			# Equatorial Radius
  my @f = ($fellip->[1],$tellip->[1]);			# Flattening

  my $dx = $tellip->[2] - $fellip->[2];
  my $dy = $tellip->[3] - $fellip->[3];
  my $dz = $tellip->[4] - $fellip->[4];

  return ($b, $l, $h) = &{$engines{'mol'}}($b, $l, $h, $a[0], $f[0], $a[1], $f[1],$dx,$dy,$dz,$rd);
}

################################################################
# Pureperl Engine              #
################################

# Engine for vector2point
sub v2p_pp
{
  my ($f,$a,$rd,$lat,$lon,$dir,$dis) = @_;
  ($lat,$lon,$dir) = map{ $_ * $rd } ($lat,$lon,$dir);						# Change to radian

  my $r = 1 - $f;
  my $tu = $r * tan($lat);
  my $sf = sin($dir);
  my $cf = cos($dir);
  my $b = ($cf == 0) ? 0.0 : 2.0 * atan2($tu,$cf);

  my $cu = 1.0 / sqrt(1 + $tu**2);
  my $su = $tu * $cu;
  my $sa = $cu * $sf;
  my $c2a = 1 - $sa**2;
  my $x = 1.0 + sqrt(1.0 + $c2a * (1.0/($r**2)-1.0));
  $x = ($x - 2.0) / $x;

  my $c = 1.0 - $x;
  $c = ($x**2 / 4.0 + 1.0) / $c;
  my $d = (0.375 * $x**2 - 1.0)* $x;
  $tu = $dis / ($r * $a * $c);
  my $y = $tu;
  $c = $y + 1;

  my ($sy,$cy,$cz,$e) = ();
  while (abs($y - $c) > 0.00000000005)
  {
    $sy = sin($y);
    $cy = cos($y);
    $cz = cos($b + $y);
    $e = 2.0 * $cz**2 -1.0;
    $c = $y;
    $x = $e * $cy;
    $y = $e + $e - 1;
    $y = ((($sy**2 * 4.0 - 3.0) * $y * $cz * $d / 6.0 + $x) * $d / 4.0 - $cz) * $sy * $d + $tu;
  }
		
  $b = $cu * $cy * $cf - $su * $sy;
  $c = $r * sqrt($sa**2 + $b**2);
  $d = $su * $cy + $cu * $sy * $cf;
  my $rlat = atan2($d,$c);

  $c = $cu * $cy - $su * $sy * $cf;
  $x = atan2($sy * $sf, $c); 
  $c = ((-3.0 * $c2a + 4.0) * $f + 4.0) * $c2a * $f / 16.0;
  $d = (($e * $cy * $c + $cz) * $sy * $c + $y) * $sa;
  my $rlon = $lon + $x - (1.0 - $c) * $d * $f;

  return map { $_/$rd } ($rlat,$rlon);
}

# Engine for point2vector
sub p2v_pp
{
  my ($f,$a,$rd,$lat,$lon,$tlat,$tlon) = @_;

  return (180,0) if (($lat == $tlat) && ($lon == $tlon));

  my $e2  = 2*$f - $f*$f;   								# Square of Eccentricity
  my $r = 1 - $f;

  my $tu1 = $r * tan($lat);
  my $tu2 = $r * tan($tlat);

  my $cu1 = 1.0 / sqrt(1.0 + $tu1**2);
  my $su1 = $cu1 * $tu1;
  my $cu2 = 1.0 / sqrt(1.0 + $tu2**2); 
  my $s1 = $cu1 * $cu2;
  my $b1 = $s1 * $tu2;
  my $f1 = $b1 * $tu1;
  my $x = $tlon - $lon;
  my $d = $x + 1;									# Force one pass

  my $iter =1;
  my ($sx,$cx,$sy,$cy,$y,$sa,$c2a,$cz,$e,$c)=();

  while ((abs($d - $x) > 0.00000000005) && ($iter < 100))
  {
    $iter++;
    $sx = sin($x);
    $cx = cos($x);
    $tu1 = $cu2 * $sx;
    $tu2 = $b1 - $su1 * $cu2 * $cx;
    $sy = sqrt($tu1**2 + $tu2**2);
    $cy = $s1 * $cx + $f1;
    $y = atan2($sy,$cy);
    $sa = $s1 * $sx / $sy;
    $c2a = 1 - $sa**2;
    $cz = $f1 + $f1;
    if ($c2a > 0.0)
    {
      $cz = $cy - $cz / $c2a;
    }
    $e = $cz**2 * 2.0 - 1.0;
    $c = ((-3.0 * $c2a + 4.0) * $f + 4.0) * $c2a * $f / 16.0;
    $d = $x;
    $x = (($e * $cy * $c + $cz) * $sy * $c + $y) * $sa;
    $x = (1.0 - $c) * $x * $f + $tlon - $lon;
  }

  my $dir = atan2($tu1,$tu2) / $rd;
  $x = sqrt((1 / ($r**2) -1) * $c2a +1);
  $x += 1;
  $x = ($x - 2.0) / $x;
  $c = 1.0 - $x;
  $c = ($x**2 / 4.0 + 1.0) / $c;
  $d = (0.375 * $x**2 - 1.0) * $x;
  $x = $e * $cy;
  my $dis = (((($sy**2 * 4.0 - 3.0) * (1.0 - $e - $e) * $cz * $d / 6.0 - $x) * $d / 4.0 + $cz) * $sy * $d + $y) * $c * $a * $r;
  
  return ($dir,$dis);
}

# Engine for datumchange: Main procedure of Molodensky method
sub molodensky_pp
{
  my($b, $l, $h, $a, $f, $a_, $f_,$dx,$dy,$dz,$rd) = @_;
  my($bda, $e2, $da, $df, $db, $dl, $dh);
  my($sb, $cb, $sl, $cl, $rn, $rm);

  $b *= $rd;
  $l *= $rd;

  $e2 = 2*$f - $f*$f; 						# Square of Eccentricity
  $bda = 1- $f;       						# Polar Radius / Equatorial Radius
  ($da, $df) = ($a_-$a, $f_-$f);
  ($sb, $cb, $sl, $cl) = (sin($b), cos($b), sin($l), cos($l));

  $rn = 1 / sqrt(1 - $e2*$sb*$sb); 
  $rm = $a * (1 - $e2) * $rn * $rn * $rn;
  $rn *= $a;

  # Calcurating Delta Value
  $db = -$dx*$sb*$cl - $dy*$sb*$sl + $dz*$cb
    + $da*$rn*$e2*$sb*$cb/$a + $df*($rm/$bda+$rn*$bda)*$sb*$cb;
  $db /= $rm + $h;
  $dl = -$dx*$sl + $dy*$cl;
  $dl /= ($rn+$h) * $cb;
  $dh = $dx*$cb*$cl + $dy*$cb*$sl + $dz*$sb
    - $da*$a/$rn + $df*$bda*$rn*$sb*$sb;

  return (($b+$db)/$rd, ($l+$dl)/$rd, $h+$dh);
}


1;
__END__

=head1 NAME

Location::GeoTool - Perl extension for Geometry processing

=head1 SYNOPSIS

  use Location::GeoTool;
  
  # New constructor (Options can be set)
  my $oGeo = Location::GeoTool->new({changeMyself => 0,enableWantarray => 0});
  $oGeo->set_coord('35.39.24.491','139.40.10.478','tokyo','gpsone');

  # Old constructor
  my $oGeo = Location::GeoTool->create_coord('35.39.24.491','139.40.10.478','tokyo','gpsone');

  my @mapion = $oGeo->format_mapion->array;
   # => ("35/39/24.491","139/40/10.478")
  my $oGeoW = $oGeo->datum_wgs84;
  my @wgs84 = ($oGeoW->lat,$oGeoW->long);
   # => ("35.39.36.145","139.39.58.871")
  my @degree_wgs84 = $oGeoW->format_second;
   # => (128376.14524...,502798.87076...)

=head1 DESCRIPTION

=head2 Constructor

=head3 new

  my $obj = Location::GeoTool->new($option_hashref);

Creates Location::GeoTool object.
With this constructor, you can set some options.

=over 4

=item enableWantarray

With this option is 1 (default 0), you can get coordinates array from
"format_foo" or "datum_foo" type method in array context.

For example,

  # When enableWantarray = 0
  $obj_new = $obj->format_degree;           # object
  ($lat,$long) = $obj->format_degree;       # object,undef
  ($lat,$long) = $obj->format_degree->array;# latitude,longitude
  
  # When enableWantarray = 1
  $obj_new = $obj->format_degree;           # object
  ($lat,$long) = $obj->format_degree;       # latitude,longitude
  ($lat,$long) = $obj->format_degree->array;# latitude,longitude

=item changeMyself

With this option is 1 (default 0), "format_foo" or "datum_foo" type 
method won't make new object but change the original object itself.

For example,

  # When changeMyself = 0
  $obj_new = $obj->datum_tokyo;           
  # $obj_new != $obj 
  # $obj not change.
  
  # When changeMyself = 1
  $obj_new = $obj->datum_tokyo;
  # $obj_new == $obj 
  # $obj changes.

=back

With B<new> constructor, you can't set coordinates data.
You must set them by using B<set_coord> method.

=head3 create_coord

  my $obj = Location::GeoTool->create_coord($lat,$long,$datum,$format);

Creates Location::GeoTool object.
This method can not only create object but set coordinates, but cannot
set options. 

  $lat    : Latitude
  $long   : Longitude
  $datum  : Datum
  $format : Format

Default datum and format of object are same with given to constructor.
Give datum by string shown below:

  WGS84   : 'wgs84'
  TOKYO   : 'tokyo'

Give format by string shown below:

  MapionURL format (ddd/mm/ss.nnn) : 'mapion'
  gpsOne format    (ddd.mm.ss.nnn) : 'gpsone'
  SpaceTag format  (pddmmssnnn)    : 'spacetag'
  dddmmss.nnn·Á¼°                  : 'dmsn'
  Degree           (ddd.dddddd...) : 'degree'
  Second           (ssssss.sss...) : 'second'
  Radian                           : 'radian'

=head2 Methods for setting/changing latitude/longitude

=head3 set_coord

  $obj->set_coord($lat,$long,$datum,$format);

This method to be used when setting/changing object's cordinates data.
Argument is same with B<create_coord>.

=head2 Methods for setting/changing option 

=head3 enableWantarray

=head3 changeMyself

  $obj->enableWantarray(1);
  $obj->changeMyself(1);

This method to be used when setting/changing object's option value.
Option's meaning is same with B<new> method's option.

=head2 Methods for getting latitude/longitude

=head3 array

=head3 lat

=head3 long

Return the latitude/longitude value of object.

  ($lat,$long) = $obj->array;
    or
  $lat = $obj->lat;
  $long = $obj->long;

=head2 Methods for changing datum/format

=head3 format_B<foo>

=head3 datum_B<foo>

Create a new object which has new datum/format setting.
(With changeMyself option on, never create new object but change
original object)

  $newobj = $obj->datum_wgs84;
  $newobj = $obj->format_mapion;
  ($lat,$long) = $obj->datum_tokyo->format_radian->array;

etc. 

All methods belong to this category are shown below:

  Change to wgs84 datum      :  datum_wgs84
  Change to tokyo datum      :  datum_tokyo
  Change to MapionURL format :  format_mapion
  Change to gpsOne format    :  format_gpsone
  Change to SpaceTag format  :  format_spacetag
  Change to dddmmss.nnn      :  format_dmsn
  Change to degree           :  format_degree
  Change to second           :  format_second
  Change to radian           :  format_radian

=head2 Methods for create Location::GeoTool::Direction object

Create a object of B<Location::GeoTool::Direction>, which is handling
direction/distance data.
Parent object is automatically set to Start-point of 
B<Location::GeoTool::Direction> object.

  my $dirobj = $locobj->direction_point('40/36/14.307','141/01/33.022','tokyo','mapion');
  my ($dir,$dist) = ($dirobj->direction,$dirobj->distance);
    or
  my $direction = $locobj->direction_point($another_locobj)->direction;
    or
  my ($endlat,$endlong) = $locobj->direction_vector($dir,$dist)->to_point->array;

etc.

=head3 direction_point

Create Location::GeoTool::Direction object by giving End-point.

You can specify End-point by two-ways shown below:

  $locobj->direction_point($lat,$long,$datum,$format);
    or
  $locobj->direction_point($another_locobj);
      #$another_locobj is another Location::GeoTool object

=head3 direction_vector

Create Location::GeoTool::Direction object by giving direction and 
distance.

  $locobj->direction_point($direction,$distance);

Direction is given 0-360 degree, start from north, and east is positive.
Unit of distance is [m].

Create Location::GeoTool::Direction object by giving End-point.

=head1 PLUGINS

If you want to use plugin of this module, you use this module as below:

  use Location::GeoTool qw/Locapoint GridLocator/;

By above, you can use B<Location::GeoTool::Plugin::Locapoint> and 
B<Location::GeoTool::Plugin::GridLocator> plugin.

These two plugins are combined with this distribution.

=head1 DEPENDENCIES

Math::Trig

=head1 SEE ALSO

dir_dist2point, dir_dist2point function is based on javascript program
could be seen in
http://williams.best.vwh.net/gccalc.htm

datumchange and molodensly function is based on perl program could 
be seen in
http://member.nifty.ne.jp/Nowral/02_DATUM/Molodensky.html

Thanks for these site.

Support this module in Kokogiko! web site : http://kokogiko.net/

=head1 AUTHOR

OHTSUKA Ko-hei, E<lt>nene@kokogiko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2007 by Kokogiko!,

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut