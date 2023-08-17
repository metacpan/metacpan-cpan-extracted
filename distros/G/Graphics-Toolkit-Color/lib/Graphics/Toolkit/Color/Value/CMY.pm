use v5.12;
use warnings;

# check, convert and measure color values in CMY space

package Graphics::Toolkit::Color::Value::CMY;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $cmy_def = Graphics::Toolkit::Color::Space->new(qw/cyan magenta yellow/);
   $cmy_def->add_converter('RGB', \&to_rgb, \&from_rgb );

########################################################################

sub check {
    my (@cmy) = @_;
    my $help = 'has to be a floating point value between 0 and 1';
    return carp "need exactly 3 floating point numbers between 0 and 1 for cmy input" unless @cmy == $cmy_def->dimensions;
    return carp "cyan value $cmy[0] $help"    unless $cmy[0] >= 0 and $cmy[0] <= 1;
    return carp "magenta value $cmy[1] $help" unless $cmy[1] >= 0 and $cmy[1] <= 1;
    return carp "yellow value $cmy[2] $help"  unless $cmy[2] >= 0 and $cmy[2] <= 1;
    0;
}

sub trim { # cut values into 0 .. 1, 0 .. 1, 0 .. 1
    my (@cmy) = @_;
    return (0,0,0) unless @cmy == $cmy_def->dimensions;
    for ($cmy_def->iterator) {
        $cmy[$_] =   0 if $cmy[$_] < 0;
        $cmy[$_] =   1 if $cmy[$_] > 1;
    }
    @cmy;
}

sub from_rgb { #
    trim( map { 1 - ($_ / 256)} @_ );
}

sub to_rgb { # convert color value triplet
    map {round(255 * (1 - $_))} trim(@_);
}

$cmy_def;

