package Devel::Deprecations::Environmental::Plugin::Internal::Always;

use strict;
use warnings;

use base 'Devel::Deprecations::Environmental';

sub reason { "always deprecated" }
sub is_deprecated { 1 }

1;
