#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Hash::Diff;

is_deeply(
Hash::Diff::diff(
    { a => undef },{ a => undef }
), { }, 'Undef 1 ok');

is_deeply(
Hash::Diff::diff(
    { a => undef },{  }
), { a => undef }, 'Undef 2 ok');

is_deeply(
Hash::Diff::diff(
    { a => undef },{ b => undef }
), { a => undef, b => undef }, 'Undef 3 ok');

is_deeply(
Hash::Diff::diff(
    { a => undef },{ a => 'foo' }
), { a => undef, }, 'Undef 4 ok');

