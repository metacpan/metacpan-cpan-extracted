use v5.12;
use warnings;

# check, convert and measure color values in CMYK space

package Graphics::Toolkit::Color::Value::CMYK;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $cmyk_def = Graphics::Toolkit::Color::Space->new(qw/cyan magenta yellow key/);
   $cmyk_def->add_converter('RGB', \&to_rgb, \&from_rgb );
   $cmyk_def->change_trim_routine( \&trim );

########################################################################

sub check {
    my (@cmyk) = @_;
    my $help = 'has to be a floating point value between 0 and 1';
    return carp "need exactly 4 floating point numbers between 0 and 1 for cmy input" unless @cmyk == $cmyk_def->dimensions;
    return carp "cyan value $cmyk[0] $help"    unless $cmyk[0] >= 0 and $cmyk[0] <= 1;
    return carp "magenta value $cmyk[1] $help" unless $cmyk[1] >= 0 and $cmyk[1] <= 1;
    return carp "yellow value $cmyk[2] $help"  unless $cmyk[2] >= 0 and $cmyk[2] <= 1;
    return carp "key value $cmyk[3] $help"     unless $cmyk[3] >= 0 and $cmyk[3] <= 1;
    0;
}

sub trim { # cut 4 values into 0 .. 1
    my (@cmyk) = @_;
    return (0,0,0,0) unless @cmyk == $cmyk_def->dimensions;
    for ($cmyk_def->iterator) {
        $cmyk[$_] = 0 if $cmyk[$_] < 0;
        $cmyk[$_] = 1 if $cmyk[$_] > 1;
    }
    @cmyk;
}

sub from_rgb { # convert color value triplet (int --> int), (real --> real) if $real
    my ($r, $g, $b) = @_;
    return unless defined $b;
    ($r, $g, $b) = map {$_ / 255} ($r, $g, $b);
    my $km = $r > $g ? $r : $g;
    $km = $km > $b ? $km : $b;
    return (0,0,0,1) unless $km; # prevent / 0

    my $k = 1 - $km;
    return ( ($km - $r) / $km,
             ($km - $g) / $km,
             ($km - $b) / $km,
              $k
    );
}

sub to_rgb { # convert color value triplet (int > int), (real > real) if $real
    my ($c, $m, $y, $k) = trim(@_);
    return (
        round( 255 * (1-$c) * (1-$k) ),
        round( 255 * (1-$m) * (1-$k) ),
        round( 255 * (1-$y) * (1-$k) ),
    );
}

$cmyk_def;
