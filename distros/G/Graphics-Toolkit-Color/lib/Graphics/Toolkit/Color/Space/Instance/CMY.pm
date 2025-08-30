
# CMY color space specific code

package Graphics::Toolkit::Color::Space::Instance::CMY;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

sub invert { [ map {1 - $_} @{$_[0]} ] }

Graphics::Toolkit::Color::Space->new (
       axis => [qw/cyan magenta yellow/],
    convert => {RGB => [\&invert, \&invert]},
);

