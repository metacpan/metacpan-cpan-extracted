#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;
neaf->set_forced_view("Dumper");

get '/js' => sub { +{ -view => "JS", foo => 42 } };

my ($code, $head, $content) = neaf->run_test( '/js' );
note $content;

is $code, 200, "Request worked";
like $content, qr#\$VAR1\s*=\s*{#s, "Dumper instead of JSON";
like $content, qr#["']?foo["']?\s*=>\s*["']?42["']?#s, "Dat round trip";

done_testing;
