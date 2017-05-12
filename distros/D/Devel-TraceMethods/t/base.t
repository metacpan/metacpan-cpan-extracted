#!perl

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use warnings;

use Test::More tests => 6;

my $module = 'Devel::TraceMethods';
use_ok( $module );

package TraceMe;

sub foo {}

sub bar {}

package TraceMe2;

@TraceMe2::ISA = 'TraceMe';

sub new
{
	bless {}, $_[0];
}

sub bar {}

package main;

Devel::TraceMethods->import( 'TraceMe' );

# see what the logger does
my $result;
Devel::TraceMethods::callback(sub { $result = "Called $_[0]" });

# standard call
TraceMe::foo();
is( $result, 'Called TraceMe::foo',
	'calling a traced call should call callback' );

# neither logged nor inherited
$result = '';
TraceMe2::bar();
is( $result, '',  '... but only from traced package' );

my $t2 = TraceMe2->new();
$t2->foo();
is( $result, 'Called TraceMe::foo', '... or inherited method' );

$result = '';
$t2->bar();
is( $result, '', '... but not overridden method' );

# now log TraceMe2
Devel::TraceMethods->import( 'TraceMe2' );

# it should provide a result now
$result = '';
$t2->bar();
is( $result, 'Called TraceMe2::bar', '... unless tracking that class too' );
