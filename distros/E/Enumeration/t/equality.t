#!perl

# This unit tests that the various equality operations work.

use Test::More tests => 21;
use lib 't';
use Enumeration;
use SubClass;

# $e1 equals $e2; nothing else equals anything else.
my $e1 = new SubClass(SubClass::test);
my $e2 = new SubClass(SubClass::test);
my $x  = new SubClass(SubClass::a);
my $y  = new Enumeration (qw(this is a test));
$y->set('test');

ok $e1->is(SubClass::test),  'is, equal: subclass instance equals constant';
ok $e1->is($e2),             'is, equal: subclass instance equals subclass instance';
ok $y->is('test'),           'is, equal: free instance equals constant';
ok !$e1->is($x),             'is, not equal: same class, different value';
ok !$e2->is($y),             'is, not equal: different class, same value';

ok $e1 eq SubClass::test,    'eq, equal: subclass instance equals constant';
ok $e1 eq $e2,               'eq, equal: subclass instance equals subclass instance';
ok $y eq 'test',             'eq, equal: free instance equals constant';
ok !($e1 eq $x),             'eq, not equal: same class, different value';
ok !($e2 eq $y),             'eq, not equal: different class, same value';

ok !($e1 ne SubClass::test), 'ne, equal: subclass instance equals constant';
ok !($e1 ne $e2),            'ne, equal: subclass instance equals subclass instance';
ok !($y ne 'test'),          'ne, equal: free instance equals constant';
ok $e1 ne $x,                'ne, not equal: same class, different value';
ok $e2 ne $y,                'ne, not equal: different class, same value';

ok SubClass::test eq $e1,    'eq, equal: constant equals subclass instance';
ok 'test' eq $y,             'eq, equal: constant equals free instance';

ok !(SubClass::test ne $e1), 'ne, equal: constant equals subclass instance';
ok !('test' ne $y),          'ne, equal: constant equals free instance';

ok $e1->is_any($e2, $x, $y),   'is_any with various object arguments';
ok !$e1->is_none($e2, $x, $y), 'is_none with various object arguments';
