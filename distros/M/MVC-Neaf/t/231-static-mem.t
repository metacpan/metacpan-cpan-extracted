#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

neaf static => '/foo' => [ 'Food Bard', 'text/lame' ];

my ($status, $head, $content) = neaf->run_test( '/foo' );

is   $status,   200,        "Found file";
is   $content, 'Food Bard', "Content survived";

like $head->header("content-type"), qr(text/lame), "Type survived";

done_testing;
