use Test::More tests=>4;

use Devel::Command::Tdump;
my @a = Devel::Command::Tdump::get_test_names();

ok(int @a, "Found some tests");

# We don't want to hard-code all of Test::More's subs in here, because
# it would make this test dependent on the exact implementation of Test::More.
# We'll test for a few of the documented tests and let it go at that.
ok((grep { /ok/ } @a), "Found ok tests");
ok((grep { /is/ } @a),  "Found is tests");
ok(!(grep { /^_/ } @a), "No leading underscore subs");
