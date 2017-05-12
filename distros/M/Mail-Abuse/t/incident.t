
# $Id: incident.t,v 1.3 2003/11/16 18:34:33 lem Exp $

# Test some basic Mail::Abuse::Incident functionality

use Test::More;
use Mail::Abuse::Incident;

plan tests => 17;

package myIncident;
use base 'Mail::Abuse::Incident';
package main;

my $i = new myIncident;

ok(defined $i, "defined myIncident");
isa_ok($i, 'myIncident');
isa_ok($i, 'Mail::Abuse::Incident');

$i->foo("bar");

is($i->items, 1, "->items return correct count");
is(($i->items)[0], 'foo', "->items return correct content");
is("$i", q{myIncident: foo=bar},
   "correctly serializes");

$i->baz("gurly");

is($i->items, 2, "->items return correct count");
is(($i->items)[0], 'baz', "->items return correct content");
is(($i->items)[1], 'foo', "->items return correct content");
is("$i", q{myIncident: baz=gurly foo=bar},
   "correctly serializes");

$i->hash({});
$i->hash->{foo} = 'bar';

is($i->items, 3, "->items return correct count");
is(($i->items)[0], 'baz', "->items return correct content");
is(($i->items)[1], 'foo', "->items return correct content");
is(($i->items)[2], 'hash', "->items return correct content");
is("$i", q/myIncident: baz=gurly foo=bar hash={ foo => bar }/,
   "correctly serializes");

$i->array([]);
$i->array->[0] = 'one';
$i->array->[1] = 'two';
$i->array->[3] = 'three';

$i->fail(undef);
is($i->items, 5, "->items return correct count");
is("$i", q/myIncident: array=[ 0 => one 1 => two 2 => undef 3 => three ]/
   . q/ baz=gurly fail=undef foo=bar hash={ foo => bar }/,
   "correctly serializes");




