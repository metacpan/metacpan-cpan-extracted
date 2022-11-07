package Devel::Deprecations::Environmental::Plugin::Internal::Int64;

use strict;
use warnings;

use base 'Devel::Deprecations::Environmental';

use Devel::CheckOS qw(os_is);

sub reason { "64 bit integers" }

sub is_deprecated { os_is('HWCapabilities::Int64') }

1;
