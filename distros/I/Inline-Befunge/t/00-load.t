#!perl
#
# This file is part of Inline::Befunge.
# Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

#-------------------------------#
#          The basics.          #
#-------------------------------#

use strict;
use Inline "Befunge";
use Test;

# Vars.
my $tests;
BEGIN { $tests = 0 };

# Basic loading.
ok(1);
BEGIN { $tests +=1 };

BEGIN { plan tests => $tests };


__END__
__Befunge__
;:foo; < q,,,,"foo"a
