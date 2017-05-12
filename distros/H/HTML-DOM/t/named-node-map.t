#!/usr/bin/perl -T

# This script tests both the NodeList interface and the Perl overload
# interface of both NodeList classes.

use strict; use warnings; use lib 't';

use Scalar::Util qw'blessed refaddr';
use Test::More tests => 0x21;


# -------------------------#
# Test 1: load the modules

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Tests 2-4: constructors

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';
my $elem = createElement $doc 'div';
isa_ok $elem, 'HTML::DOM::Element';
my $map = attributes $elem;
isa_ok $map, 'HTML::DOM::NamedNodeMap';

$elem->setAttribute('attr1' => 'attr value');

# -------------------------#
# Tests 5-10: getNamedItem & item

is_deeply [$map->getNamedItem('blahblahblah')],[],
	'getNamedItem returns null'; 
isa_ok my $attr = $map->getNamedItem('attr1'), 'HTML::DOM::Attr',
	'result of getNamedItem';
is $attr->nodeName, 'attr1',
	'name of attribute retrieved by getNamedItem';
is nodeValue $attr, 'attr value',
	'value of attribute retrieved by getNamedItem';

is refaddr $attr, refaddr(item $map 0), 'item';
$elem->setAttribute('attr2' => 'attr value'); # store a simple scalar
                                              # rather than an attr
ok defined blessed $map->item(1), 'item turns a scalar into a node';
$elem->attr(attr2 => undef);

# -------------------------#
# Test 11: length

is $map->length, 1, 'length';

# -------------------------#
# Tests 12-15: setNamedItem

is_deeply [$map->setNamedItem(my $attr2 = createAttribute $doc 'attr2')],
	[], 'setNamedItem returns null';
is refaddr $attr2,
	refaddr $map->setNamedItem($attr2 = createAttribute $doc 'attr2'),
	'setNamedItem returns the attributed that is replaced';

$attr2->nodeValue('value 2');
is $elem->getAttribute('attr2'), 'value 2',
	'changes made by setNamedItem are reflected in the element';
is $map->length, 2, 'length is correct after setNamedItem';

# -------------------------#
# Tests 16-19: removeNamedItem

is refaddr $map->removeNamedItem('attr1'), refaddr $attr,
	'removeNamedItem';
is $map->length, 1, 'length is correct after removeNamedItem';
is refaddr $map->item(0), refaddr $attr2,
	'removeNamedItem removes the right one';
is $elem->getAttribute('attr1'), '',
	'changes made by removeNamedItem are reflected in the element';

# -------------------------#
# Tests 20-33: tie/overload interface

$elem->setAttribute('attr1' => 'attr value');
$elem->setAttribute('attr2' => 'attr2 value');

is refaddr $map->[0], refaddr $map->item(0), '->[0]';
is refaddr $map->[1], refaddr $map->item(1), '->[1]';
is "@$map", $map->item(0) . ' ' . $map->item(1), '@{...}';
ok exists $map->[0], 'exists ->[0]';
ok exists $map->[1], 'exists ->[1]';
ok exists $map->[-1], 'exists ->[-1]';
ok !exists $map->[2], '!exists ->[2] (length==2)';
is refaddr $map->{attr1}, refaddr $map->getNamedItem('attr1'), '->{...}';
is_deeply [sort keys %$map], ['attr1', 'attr2'], 'keys %{...}';
ok exists $map->{attr1}, 'exists ->{...}';
ok !exists $map->{a}, '!exists ->{...}';
ok !exists $map->{_parent}, '!exists ->{_private}';
delete $map->{attr2};
is $elem->attr('attr2'),undef, 'delete';
%$map = ();
is +()=$elem->all_external_attr_names, 0, '%$map=...';
