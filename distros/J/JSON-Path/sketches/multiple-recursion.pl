#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON::Path;

diag("This case worked as recently as v0.310");

my $to_find = '$..foo..value';
my $doc     = '{"foo":{"value":3}}';

my $jpath   = JSON::Path->new($to_find);

my @found   = $jpath->paths($doc);

is_deeply (
    \@found,
    [
        "\$['foo']['value']"
    ]
);

done_testing();
