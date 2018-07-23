
use strict;
use warnings;
use Test::More tests => 27;

package THO::one;

use HO::class
  _rw => rw_scalar => '$',
  _rw => rw_array => '@',
  _rw => rw_hash => '%',
  _ro => ro_scalar => '$',
  _ro => ro_array => '@',
  _ro => ro_hash => '%';

package main;

my $obj = THO::one->new;

isa_ok($obj,'THO::one');

is($obj->ro_scalar,undef,'ro scalar default is undef');
is_deeply([$obj->ro_array],[],'ro array default is empty list');
is_deeply($obj->ro_hash,{},'ro hash dafult is empty list');
is($obj->rw_scalar,undef,'rw scalar default is undef');
is_deeply([$obj->rw_array],[],'rw array default is empty list');
is_deeply($obj->rw_hash,{},'rw hash dafult is empty list');

$obj->ro_scalar(1);
is($obj->ro_scalar,undef,'setting ro scalar is silently ignored');
is($obj->ro_array(0),undef,'accessing undefined index in ro array returns undef');
is($obj->rw_hash('1'),undef,'accessing undefined index in ro hash returns undef');

$obj->rw_scalar(1);
is($obj->rw_scalar,1,'rw scalar default is changeable');

$obj->rw_hash->{'u'} = 's';
is($obj->rw_hash('u'),'s','rw hash is changeable');

$obj->rw_array([1..3]);
is_deeply([$obj->rw_array],[1..3],'rw array set with array ref');

$obj->rw_array(0,0);
is_deeply([$obj->rw_array],[0,2,3],'rw array changed by index');

is($obj->rw_array(1),2,'rw array accessed with index');

$obj->rw_array('>',1);
is_deeply([$obj->rw_array],[1,0,2,3],'unshift alias > works');

$obj->rw_array('<',5);
is_deeply([$obj->rw_array],[1,0,2,3,5],'push alias < works');

my ($shifted,$poped);
is_deeply([$obj->rw_array(\$shifted,'<')->rw_array],[0,2,3,5],
    'shift "<" to scalar ref works with method chaining');
is($shifted,1,'correct shifted value');

is_deeply([$obj->rw_array(\$poped,'>')->rw_array],[0,2,3],
    'pop ">" to scalar ref works with method chaining');
is($poped,5,'correct poped value');

my @get;
is_deeply([$obj->rw_array(\@get,[])->rw_array],[],
   'splice with two array refs where second one is empty empties the array');
is_deeply(\@get,[0,2,3],'correct return from splice');

$obj->rw_array([0,2,3]);
is_deeply([$obj->rw_array(\@get,[1])->rw_array],[0],
   'splice with two array refs with one arg in the  second');
is_deeply(\@get,[2,3],'correct return from splice');

$obj->rw_array([7,5,3]);
is_deeply([$obj->rw_array(\@get,[1,1])->rw_array],[7,3],
   'splice with two array refs with two args in the second one');
is_deeply(\@get,[5],'correct return from splice');

