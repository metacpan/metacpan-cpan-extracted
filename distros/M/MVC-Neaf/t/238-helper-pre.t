#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my $n = MVC::Neaf->new;

my @trace;
$n->set_helper( wee => sub { push @trace, $_[1] } );

$n->add_hook( pre_route => sub { $_[0]->wee( "pre_route" ) } );
$n->add_hook( pre_cleanup => sub { $_[0]->wee( "pre_cleanup" ) } );

my ($status, $head, $content) = $n->run_test( "/foo/bar" );
is $status, 404, "no route = no go";
is_deeply \@trace, [ "pre_route", "pre_cleanup" ], "But hooks worked & helper worked";

done_testing;
