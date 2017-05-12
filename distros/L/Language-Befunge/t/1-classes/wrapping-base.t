#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

#
# Language::Befunge::Wrapping
#

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

use Language::Befunge::Wrapping;

#-- constructor

#- new()
my $w = Language::Befunge::Wrapping->new;
isa_ok($w, 'Language::Befunge::Wrapping');
can_ok($w, 'wrap');
throws_ok(sub { $w->wrap }, qr/not implemented in LBW/, "stub wrap method");
