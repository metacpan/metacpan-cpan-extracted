#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use Test::More qw{no_plan};

# Write.pm is meant to be subclassed.
# The only public method is new().

BEGIN { use_ok( 'Gwybodaeth::Write' ); }

my $write = new_ok( 'Gwybodaeth::Write' );
