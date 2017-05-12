#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use Devel::Main 'main';

main {
	ok(1, "Called the main routine");
};

# If we got here we didn't exit
fail(1);

