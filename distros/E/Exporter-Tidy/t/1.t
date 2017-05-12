use lib 't/lib';
use Test::More tests => 36;
BEGIN { require_ok('Exporter::Tidy') };

can_ok 'Exporter::Tidy', 'import';

ok(!defined(&import), 'We are clean');
Exporter::Tidy->import();
ok(defined(&import), 'We got an &import');

BEGIN {
    package ET_Test1;
    $INC{'ET_Test1.pm'} = 'dummy';
    use Exporter::Tidy default => [ qw(foo1 $foo1 %foo1 @foo1 *bar1) ];
    *foo1 = sub { 42 };
    *foo1 = \ 'forty-two';
    *foo1 = [ 1 .. 42 ];
    *foo1 = { 42 => 'forty-two' };
    *bar1 = sub { 'foo' };
    *bar1 = \ 'foo';
    *bar1 = [ 'foo' ];
    *bar1 = { foo => 1 };
}
use ET_Test1;
ok(foo1() == 42,             ':default CODE');
ok($foo1 eq 'forty-two',     ':default SCALAR');
ok(@foo1 == 42,              ':default ARRAY');
ok($foo1{42} eq 'forty-two', ':default HASH');
ok(bar1() eq 'foo',          ':default GLOB/CODE');
ok($bar1 eq 'foo',           ':default GLOB/SCALAR');
ok($bar1[0] eq 'foo',        ':default GLOB/ARRAY');
ok($bar1{foo},               ':default GLOB/HASH');

BEGIN {
    package ET_Test2;
    $INC{'ET_Test2.pm'} = 'dummy';
    use Exporter::Tidy tag => [ qw(foo2 $foo2 %foo2 @foo2 *bar2) ];
    *foo2 = sub { 42 };
    *foo2 = \ 'forty-two';
    *foo2 = [ 1 .. 42 ];
    *foo2 = { 42 => 'forty-two' };
    *bar2 = sub { 'foo' };
    *bar2 = \ 'foo';
    *bar2 = [ 'foo' ];
    *bar2 = { foo => 1 };
}
use ET_Test2 qw(:tag);
ok(foo2() == 42,             ':tag CODE');
ok($foo2 eq 'forty-two',     ':tag SCALAR');
ok(@foo2 == 42,              ':tag ARRAY');
ok($foo2{42} eq 'forty-two', ':tag HASH');
ok(bar2() eq 'foo',          ':tag GLOB/CODE');
ok($bar2 eq 'foo',           ':tag GLOB/SCALAR');
ok($bar2[0] eq 'foo',        ':tag GLOB/ARRAY');
ok($bar2{foo},               ':tag GLOB/HASH');

BEGIN {
    package ET_Test3;
    $INC{'ET_Test3.pm'} = 'dummy';
    use Exporter::Tidy
        _map => {
            'foo3'  => sub { 42 },
            '$foo3' => \ 'forty-two',
            '@foo3' => [ 1 .. 42 ],
            '%foo3' => { 42 => 'forty-two' },
            '*bar3' => \*bar3
        };
    *bar3 = sub { 'foo' };
    *bar3 = \ 'foo';
    *bar3 = [ 'foo' ];
    *bar3 = { foo => 1 };
}
use ET_Test3 qw(foo3 $foo3 @foo3 %foo3 *bar3);
ok(foo3() == 42,             '_map CODE');
ok($foo3 eq 'forty-two',     '_map SCALAR');
ok(@foo3 == 42,              '_map ARRAY');
ok($foo3{42} eq 'forty-two', '_map HASH');
ok(bar3() eq 'foo',          '_map GLOB/CODE');
ok($bar3 eq 'foo',           '_map GLOB/SCALAR');
ok($bar3[0] eq 'foo',        '_map GLOB/ARRAY');
ok($bar3{foo},               '_map GLOB/HASH');

BEGIN {
    package ET_Test4;
    $INC{'ET_Test4.pm'} = 'dummy';
    use Exporter::Tidy moo => [ qw(foo $foo %foo @foo *bar) ];
    *foo = sub { 42 };
    *foo = \ 'forty-two';
    *foo = [ 1 .. 42 ];
    *foo = { 42 => 'forty-two' };
    *bar = sub { 'foo' };
    *bar = \ 'foo';
    *bar = [ 'foo' ];
    *bar = { foo => 1 };
}
use ET_Test4
    _prefix => 'foo_', qw(foo $foo %foo @foo),
    _prefix => 'bar_', qw(*bar);
ok(foo_foo() == 42,             '_prefix CODE');
ok($foo_foo eq 'forty-two',     '_prefix SCALAR');
ok(@foo_foo == 42,              '_prefix ARRAY');
ok($foo_foo{42} eq 'forty-two', '_prefix HASH');
ok(bar_bar() eq 'foo',          '_prefix GLOB/CODE');
ok($bar_bar eq 'foo',           '_prefix GLOB/SCALAR');
ok($bar_bar[0] eq 'foo',        '_prefix GLOB/ARRAY');
ok($bar_bar{foo},               '_prefix GLOB/HASH');

# TODO
# Test failures

