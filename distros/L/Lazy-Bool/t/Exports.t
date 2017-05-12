use Test::More tests => 2;

use Lazy::Bool qw(lzb);
use Lazy::Bool::Cached qw(lzbc);

ok( lzb { 1 }, "lzb should be true" );
ok( lzbc { 1 }, "lzbc should be true" );
