#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 8;

BEGIN {
	use_ok('HTML::D3')
}

isa_ok(HTML::D3->new(), 'HTML::D3', 'Creating HTML::D3 object');
isa_ok(HTML::D3::new(), 'HTML::D3', 'Creating HTML::D3 object');
isa_ok(HTML::D3->new()->new(), 'HTML::D3', 'Cloning HTML::D3 object');
# ok(!defined(HTML::D3::new()));

# Create a new object with direct key-value pairs
my $obj = HTML::D3->new(width => 50, height => 100);
cmp_ok($obj->{'width'}, '==', 50, 'direct key-value pairs');
cmp_ok($obj->{'height'}, '==', 100, 'direct key-value pairs');

# Test cloning behaviour by calling new() on an existing object
my $obj2 = $obj->new({ height => 200 });
cmp_ok($obj2->{'width'}, '==', 50, 'clone keeps old args');
cmp_ok($obj2->{'height'}, '==', 200, 'clone adds new args');
