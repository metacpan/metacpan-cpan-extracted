#!/usr/bin/perl -w
use strict;

use Test::More tests => 1+6;
use Test::NoWarnings;
use File::Tools;

is_deeply( [File::Tools::uniq(qw(a b c))], [qw(a b c)], "uniq originally" );
is_deeply( [File::Tools::uniq(qw(a b c a))], [qw(a b c)] );
is_deeply( [File::Tools::uniq(qw(b b a a b c a))], [qw(b a c)] );

is_deeply( [File::Tools::uniqunix(qw(a b c))], [qw(a b c)], "uniq originally" );
is_deeply( [File::Tools::uniqunix(qw(a b c a))], [qw(a b c a)] );
is_deeply( [File::Tools::uniqunix(qw(b b a a b c a))], [qw(b a b c a)] );


