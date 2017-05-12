#!/usr/bin/env perl

use warnings;
use strict;

use lib '../lib';

use Test::More qw(no_plan);

BEGIN { use_ok( 'Gwybodaeth::Escape' ); }

my $esc = new_ok( 'Gwybodaeth::Escape' );

my $str = " & ";

ok( $esc->escape($str) eq ' &amp; ', 'simple \'&\' escape');

$str = "This string & scalar contains an ampersand";

ok( $esc->escape($str) eq 'This string &amp; scalar contains an ampersand',
    '\'&\' in a sentence');

$str = " &amp; ";

ok( $esc->escape($str) eq ' &amp; ', '&amp; escaping');

