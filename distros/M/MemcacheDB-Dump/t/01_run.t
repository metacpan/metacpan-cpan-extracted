use strict;
use Test::More 0.98;

use MemcacheDB::Dump;
use File::Basename;

my $path = dirname(__FILE__) . "/sample.db";

my $dumper = MemcacheDB::Dump->new($path);

is_deeply $dumper->run, {
    "str1" => "a_string",
    "bin1" => "\x00\x01\x02"
};
is $dumper->get("str1"), "a_string";
is $dumper->get("bin1"), "\x00\x01\x02";
is $dumper->get("no such key"), undef;

is_deeply [ sort $dumper->keys ], [ "bin1", "str1" ];

done_testing;
