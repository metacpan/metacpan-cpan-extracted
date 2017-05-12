#!/usr/bin/env perl

# test the text_ength() function

use Test::More;
use strict;
use utf8;

BEGIN
   {
   plan tests => 7;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Easy") or die($@);
   use_ok ("Graph::Easy::As_svg") or die($@);
   };

#############################################################################

my $l = 'Graph::Easy::As_svg::_text_length';

no strict 'refs';

is ($l->(14, 'ABCDE'), 3.6, 'ABCDE is 3.6 long');
is ($l->(14, 'WW'), 0.9*2, 'WW');
is ($l->(14, 'ii'), 0.33*2, 'ii');
is ($l->(14, '@@'), 1.15*2, '@@');
is ($l->(14, 'ææ'), 1.25*2, 'ææ');
