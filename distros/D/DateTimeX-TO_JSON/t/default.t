#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use JSON;
use DateTime;

use_ok('DateTimeX::TO_JSON');
my $dt   = DateTime->now();
my $json = JSON->new->convert_blessed(1)->utf8(0);
is(
    $json->encode([$dt]),
    $json->encode([$dt->datetime]),
    'DateTime can be serialized'
);

done_testing();

