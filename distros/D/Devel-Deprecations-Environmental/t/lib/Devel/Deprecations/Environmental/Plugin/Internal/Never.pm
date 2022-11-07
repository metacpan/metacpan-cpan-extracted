package Devel::Deprecations::Environmental::Plugin::Internal::Never;

use strict;
use warnings;

use base 'Devel::Deprecations::Environmental';

sub reason { "never deprecated" }
sub is_deprecated { 0 }

1;
