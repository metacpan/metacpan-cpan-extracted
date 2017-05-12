use strict;
use warnings;

use Test::More tests => 7;

use t::lib::Child1 'hi';

ok(t::lib::Child1->isa(t::lib::Child1::));
ok(t::lib::Child1->isa(t::lib::Mother::));
ok(t::lib::Child1->can('import'));
ok(t::lib::Child1->can('hello'));
ok(t::lib::Child1->can('hi'));

# Check that the import worked
ok(defined &main::hi, 'hi imported');
is(hi, 'Hi!');

done_testing;
