use v5.12;
use warnings;

# check, convert and measure color values in HSV space

package Graphics::Toolkit::Color::Value::HSV;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $hsv_def = Graphics::Toolkit::Color::Space->new(qw/hue saturation value/);
   $hsv_def->add_converter('RGB', \&to_rgb, \&from_rgb );
   $hsv_def->change_delta_routine( \&delta );
   $hsv_def->change_trim_routine( \&trim );

########################################################################

sub check {
    my (@hsv) = @_;
    my $help = 'has to be an integer between 0 and';
    return carp "need exactly 3 positive integer between 0 and 359 or 100 for hsv input" unless $hsv_def->is_array( \@hsv );
    return carp "hue value $hsv[0] $help 359"        unless int $hsv[0] == $hsv[0] and $hsv[0] >= 0 and $hsv[0] < 360;
    return carp "saturation value $hsv[1] $help 100" unless int $hsv[1] == $hsv[1] and $hsv[1] >= 0 and $hsv[1] < 101;
    return carp "value value $hsv[2] $help 100"      unless int $hsv[2] == $hsv[2] and $hsv[2] >= 0 and $hsv[2] < 101;
    0;
}

sub trim { # cut values into 0 ..359, 0 .. 100, 0 .. 100
    my (@hsv) = @_;
    $hsv[0] += 360 while $hsv[0] <    0;
    $hsv[0] -= 360 while $hsv[0] >= 360;
    for (1 .. 2){
        $hsv[$_] =   0 if $hsv[$_] <   0;
        $hsv[$_] = 100 if $hsv[$_] > 100;
    }
    map {round($_)} @hsv;
}

sub delta { # \@hsl, \@hsl --> @delta
    my ($hsv1, $hsv2) = @_;
    my $delta_h = abs($hsv2->[0] - $hsv1->[0]);
    $delta_h = $delta_h + 360 if $delta_h < -180;
    $delta_h = $delta_h - 360 if $delta_h >  180;
    ($delta_h, ($hsv2->[1] - $hsv1->[1]), ($hsv2->[2] - $hsv1->[2]) );
}


sub _from_rgb { # float conversion
    my (@rgb) = @_;
    my ($maxi, $mini) = (0 , 1);   # index of max and min value in @rgb
    if    ($rgb[1] > $rgb[0])      { ($maxi, $mini ) = ($mini, $maxi ) }
    if    ($rgb[2] > $rgb[$maxi])  {  $maxi = 2 }
    elsif ($rgb[2] < $rgb[$mini])  {  $mini = 2 }
    my $delta = $rgb[$maxi] - $rgb[$mini];
    my $H = $delta ==           0  ?  0                                        :
                      ($maxi == 0) ? 60 * rmod( ($rgb[1]-$rgb[2]) / $delta, 6) :
                      ($maxi == 1) ? 60 * ( (($rgb[2]-$rgb[0]) / $delta ) + 2)
                                   : 60 * ( (($rgb[0]-$rgb[1]) / $delta ) + 4) ;

     my $S = ($rgb[$maxi] == 0) ? 0 : ($delta / $rgb[$maxi]);
    ($H, $S * 100, $rgb[$maxi] * 0.390625);
}
sub from_rgb { # convert color value triplet (int --> int), (real --> real) if $real
    my (@rgb) = @_;
    my $real = '';
    if (ref $rgb[0] eq 'ARRAY'){
        @rgb = @{$rgb[0]};
        $real = $rgb[1] // $real;
    }
    #check_rgb( @rgb ) and return unless $real;
    my @hsl = _from_rgb( @rgb );
    return @hsl if $real;
    ( round( $hsl[0] ), round( $hsl[1] ), round( $hsl[2] ) );
}

sub _to_rgb { # float conversion
    my (@hsv) = trim(@_);
    my $H = $hsv[0] / 60;
    my $C = $hsv[1]* $hsv[2] / 100 / 100;
    my $X = $C * (1 - abs(rmod($H, 2) - 1));
    my $m = ($hsv[2] / 100) - $C;
    my @rgb = ($H < 1) ? ($C + $m, $X + $m,      $m)
            : ($H < 2) ? ($X + $m, $C + $m,      $m)
            : ($H < 3) ? (     $m, $C + $m, $X + $m)
            : ($H < 4) ? (     $m, $X + $m, $C + $m)
            : ($H < 5) ? ($X + $m,      $m, $C + $m)
            :            ($C + $m,      $m, $X + $m);
    map { 256 * $_ } @rgb;
}
sub to_rgb { # convert color value triplet (int > int), (real > real) if $real
    my (@hsv) = @_;
    my $real = '';
    if (ref $hsv[0] eq 'ARRAY'){
        @hsv = @{$hsv[0]};
        $real = $hsv[1] // $real;
    }
    #check( @hsv ) and return unless $real;
    my @rgb = _to_rgb( @hsv );
    return @rgb if $real;
    ( int( $rgb[0] ), int( $rgb[1] ), int( $rgb[2] ) );
}

$hsv_def;
