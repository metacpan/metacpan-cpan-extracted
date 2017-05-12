#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;

BEGIN {
    use_ok('Labyrinth::Plugin::Wiki');
    use_ok('Labyrinth::Plugin::Wiki::Text');
}
