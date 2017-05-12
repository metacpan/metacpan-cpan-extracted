#!/usr/bin/perl

use strict;
use warnings;
use vars qw(@MODULES);

use Test::More;

# Verify that the individual modules will load

@MODULES = qw(Env::Export);

plan tests => scalar(@MODULES);

use_ok($_) for (@MODULES);

exit 0;
