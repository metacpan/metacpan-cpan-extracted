use strict;
use warnings;
use utf8;

use Test::More tests => 6;
BEGIN { use_ok('JSON::Parser::Regexp') };

my $json = JSON::Parser::Regexp->new();
my $hash = $json->decode('{"foo" : [-1.2, -2, 3, 4, ౮], "buz": "a string ఈ వారపు వ్యాసం with spaces", "more": {"3" : [8, 9]} , "1" : 41, "array": [1, 23]}');

ok($hash->{"more"}->{3}->[0] == 8);
ok($hash->{1} == 41);
ok($hash->{"buz"} = "a string ఈ వారపు వ్యాసం with spaces");
ok($hash->{"array"}->[0] == 1);
ok($hash->{"foo"}->[1] == -2);
