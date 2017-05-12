use strict;
use warnings;

use Test::More tests => 4;

use t::lib::Mother 'hello';

ok(t::lib::Mother->can('import'));
ok(t::lib::Mother->can('hello'));

# Check that the import worked
ok(defined &main::hello, 'hello imported');
is(hello(), 'Hello!');

done_testing;
