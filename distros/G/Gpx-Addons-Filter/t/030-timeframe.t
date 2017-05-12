#!/usr/bin/perl -T

# $Id: --- $
# Created by Ingo Lantschner on 2009-06-24.
# Copyright (c) 2009 Ingo Lantschner. All rights reserved.
# ingo@boxbe.com, http://ingo@lantschner.name

use warnings;
use strict;
#use lib '/Users/ingolantschner/Perl/lib';

use Test::More tests => 7 - 3;  # see TODO

use Gpx::Addons::Filter qw( first_and_last_second_of );

# TODO: Test for dieing functions (former version returned undef)
#is(first_and_last_second_of('209-11-11'), undef, 'Wrong format of day-strg ==> return undef');

my ($start_of_day, $end_of_day) = first_and_last_second_of("2009-07-10");
is($start_of_day, 1247184000,  	'start of timeframe for 10.7.2009');
is($end_of_day,   1247270399,  	'end of timeframe for 10.7.2009');

#is(first_and_last_second_of('2009-31-11'), undef, 'Wrong format of day-strg (2009-31-11) ==> return undef');
#is(first_and_last_second_of('99-11-01'), undef, 'Wrong format of day-strg ==> return undef');
is(first_and_last_second_of('1980-11-01'),  341971199, 'Format of day-strg OK (1980-11-01)');
is(first_and_last_second_of('2030-11-01'), 1919807999, 'Format of day-strg OK (2030-11-01)');