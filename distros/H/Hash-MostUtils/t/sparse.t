#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(lkeys lvalues);

my @list = (0 .. 5);
$list[11] = 'hello';
$list[12] = 'world';

my @list_keys = lkeys @list;    # @list_keys = (0, 2, 4, 'hello')
my @list_vals = lvalues @list;  # @list_vals = (1, 3, 5, 'world')
is_deeply( \@list_keys, [0, 2, 4, undef, undef, undef, 'world'], 'we know our lkeys' );
is_deeply( \@list_vals, [1, 3, 5, undef, undef, 'hello'], 'we know our lvals' );

$list[10] = 'gwarsh';
@list_keys = lkeys @list;    # @list_keys = (0, 2, 4, 'gwarsh', 'world')
@list_vals = lvalues @list;  # @list_vals = (1, 3, 5, 'hello')
is_deeply( \@list_keys, [0, 2, 4, undef, undef, 'gwarsh', 'world'], 'world is now a key' );
is_deeply( \@list_vals, [1, 3, 5, undef, undef, 'hello'], 'hello is now a value' );
