#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';
BEGIN { use_ok( 'GD::Graph::radar' ) }
diag("Testing GD::Graph::radar $GD::Graph::radar::VERSION, Perl $], $^X");
