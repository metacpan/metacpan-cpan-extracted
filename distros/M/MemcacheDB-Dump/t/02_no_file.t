use strict;
use Test::More 0.98;
use Test::Warn;

use MemcacheDB::Dump;
use File::Basename;

warning_is {
    MemcacheDB::Dump->new(dirname(__FILE__) . "/no_such_file.db")
} "open t/no_such_file.db failed", "no_such_file";

warning_is {
    MemcacheDB::Dump->new(dirname(__FILE__) . "/sample.db")
} "", "no warning";

done_testing;
