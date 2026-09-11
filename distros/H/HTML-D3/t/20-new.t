#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 10;

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

# Regression test for RT#0011 / 0.11 fix: before adding "use Carp qw(carp)" to
# HTML::D3, calling ::new() with a defined undef first arg and any keyword args
# would die with "Undefined subroutine &HTML::D3::carp".  It must instead carp
# (emit a warning) and return undef.
my $bad;
warnings_like { $bad = HTML::D3::new(undef, width => 100) }
	qr/use ->new\(\) not ::new\(\)/,
	'::new() with undef class and args carps instead of dying';
ok(!defined($bad), '::new() with undef class and args returns undef');
