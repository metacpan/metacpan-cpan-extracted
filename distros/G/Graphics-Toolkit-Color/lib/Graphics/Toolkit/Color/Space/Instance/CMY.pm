use v5.12;
use warnings;

# CMY color space specific code

package Graphics::Toolkit::Color::Space::Instance::CMY;
use Graphics::Toolkit::Color::Space;

my $cmy_def = Graphics::Toolkit::Color::Space->new( axis => [qw/cyan magenta yellow/] );
   $cmy_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb { map { 1 - $_} @_ }
sub to_rgb   { map { 1 - $_} @_ }

$cmy_def;

