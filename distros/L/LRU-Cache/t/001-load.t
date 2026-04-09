use strict;
use warnings;
use Test::More;

use LRU::Cache;

diag("Testing LRU::Cache $LRU::Cache::VERSION, Perl $], $^X");

ok(1, 'LRU::Cache loaded');

done_testing;
