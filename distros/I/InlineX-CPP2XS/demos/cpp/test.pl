use Test;
use Math::Geometry::Planar::GPC::Inherit;

BEGIN { plan tests => 5 }

# If it works, it will print this. Otherwise it won't.
ok(1);

# Test Foo
my $o = new Foo;
ok($o->get_secret(), 0);
$o->set_secret(539);
ok($o->get_secret(), 539);

# Test Bar
my $p = new Bar(11);
ok($p->get_secret(), 11);
$p->set_secret(21);
ok($p->get_secret(), 42);
