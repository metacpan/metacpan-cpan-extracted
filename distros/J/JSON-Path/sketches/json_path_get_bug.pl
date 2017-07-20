#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use JSON::Path;

my $orig = { bar => 1 };

my $p = JSON::Path->new("\$foo");

my @res = $p->get($orig);

is_deeply ( \@res, [ ], "result array when no match" );

done_testing();
