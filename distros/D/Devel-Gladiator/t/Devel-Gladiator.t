use strict;
use warnings;

use Test::More tests => 5;
use Scalar::Util qw(weaken refaddr);
use Devel::Gladiator;
use Devel::Peek;

my $found;
my $foo = "blah";

my $array = Devel::Gladiator::walk_arena();
ok($array, "walk returned");
is(ref $array, "ARRAY", ".. with an array");
$found = undef;
foreach my $value (@$array) {
    next unless refaddr($value) == refaddr(\$foo);
    $found = $value;
}
is($$found, $foo, 'found foo');
@$array = ();

# make a circular reference
my $ptr;
{
    my $foo = ["missing!"];
    my $bar = \$foo;
    $foo->[1] = $bar;
    $ptr = $foo;
    weaken($ptr);
}
ok($ptr, "foo went missing");

$array = Devel::Gladiator::walk_arena();
$found = undef;
foreach my $value (@$array) {
    next unless refaddr($value) == refaddr($ptr);
    $found = $value;
}
is($found->[0], "missing!", "found missing item");
@$array = ();
