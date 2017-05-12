#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use Mac::KeyboardMaestro qw(km_set km_get km_delete km_macro);

ok defined &{$_}, $_ foreach qw(km_set km_get km_delete km_macro);