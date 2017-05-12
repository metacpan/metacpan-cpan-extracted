#!perl

# This unit tests that subclassing works as expected.

use Test::More tests => 14;
use lib 't';
use SubClass;

my $e = new SubClass;
$e->set('this');

ok  $e->is('this')  => 'is query';
ok !$e->is('test')  => 'is query mismatch';

ok  $e->is_any('IS', 'a', 'this') => 'is_any query';
ok !$e->is_any('IS', 'a', 'test') => 'is_any query mismatch';

ok  $e->is_none('IS', 'a', 'test') => 'is_none query';
ok !$e->is_none('IS', 'a', 'this') => 'is_none query mismatch';

eval {  $e->is('wonko');  };
like $@, qr/\A"wonko" is not an allowable value/, 'is (unallowed value)';

eval {  $e->is_any('wonko');  };
like $@, qr/\A"wonko" is not an allowable value/, 'is_any (unallowed value)';

eval {  $e->is_none('wonko');  };
like $@, qr/\A"wonko" is not an allowable value/, 'is_none (unallowed value)';

is $e->bare_value, 'this',           'bare_value';
is $e->value,      'SubClass::this', 'value';

$e->set('a');
is $e->value, 'SubClass::a', 'set';

eval {  $e->set('wonko');  };
like $@, qr/\A"wonko" is not an allowable value/, 'set (unallowed value)';

#  initialization at construction time.
my $i = new SubClass('IS');
ok  $i->is('IS')  => 'initialized ok';
