#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Hash::Diff;

is_deeply(
Hash::Diff::diff(
    { a => 'a' },{ b => 'b' }
), { a => 'a', b => 'b' }, 'Diff ok');

is_deeply(
Hash::Diff::diff(
    { a => 'a', b => 'b' },{ b => 'b' }
), { a => 'a' }, 'Diff ok');

is_deeply(
Hash::Diff::diff(
    { a => 'a', b => { a => 'a', b => 'b' } },{ b => { a => 'a' } }
), { a => 'a', b => { b => 'b' } }, 'Diff ok');

is_deeply(
Hash::Diff::diff(
     { a=> 1, b => { c => 1}},  { a=> 1, b => { c => 1}}
), {}, 'Diff ok');