#!perl

# This unit tests whether ad-hoc ("free") enumerations work as expected.

use Test::More tests => 13;

use Enumeration;

my $e = new Enumeration qw(this is a test);

$e->set('this');

ok  $e->is('this')  => 'is query';
ok !$e->is('test')  => 'is query mismatch';

ok  $e->is_any('is', 'a', 'this') => 'is_any query';
ok !$e->is_any('is', 'a', 'test') => 'is_any query mismatch';

ok  $e->is_none('is', 'a', 'test') => 'is_none query';
ok !$e->is_none('is', 'a', 'this') => 'is_none query mismatch';

eval {  $e->is('wonko');  };
like $@, qr/\A"wonko" is not an allowable value/, 'is (unallowed value)';

eval {  $e->is_any('wonko');  };
like $@, qr/\A"wonko" is not an allowable value/, 'is_any (unallowed value)';

eval {  $e->is_none('wonko');  };
like $@, qr/\A"wonko" is not an allowable value/, 'is_none (unallowed value)';

is $e->bare_value, 'this',       'bare_value';
is $e->value,      'Enumeration::this', 'value';

$e->set('a');
is $e->value, 'Enumeration::a', 'set';

eval {  $e->set('wonko');  };
like $@, qr/\A"wonko" is not an allowable value/, 'set (unallowed value)';
