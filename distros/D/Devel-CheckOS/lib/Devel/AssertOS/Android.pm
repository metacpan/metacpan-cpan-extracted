package Devel::AssertOS::Android;

use Devel::CheckOS;
use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '1.2';

sub os_is { $^O =~ /^android$/i ? 1 : 0; }

Devel::CheckOS::die_unsupported() unless(os_is());

1;
