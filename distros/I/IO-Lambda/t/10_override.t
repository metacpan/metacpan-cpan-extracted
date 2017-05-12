#! /usr/bin/perl
# $Id: 10_override.t,v 1.4 2008/08/05 19:44:26 dk Exp $

use strict;
use warnings;

use Test::More tests => 10;
use IO::Lambda qw(:all);

# override and pass
my $q = lambda {
	context lambda { 42 };
	&tail();
};

my $bypass = 0;
sub bypass
{
	$bypass++;
	shift-> super;
}

$q-> override( tail => \&bypass);
ok($q-> wait == 42 && $bypass == 1, 'single override pass');

# override and deny
$bypass = 0;
$q-> reset;
$q-> override( tail => undef);
$q-> override( tail => sub { 43 } );
ok($q-> wait == 43 && $bypass == 0, 'single override deny');

# clean override 
$bypass = 0;
$q-> reset;
$q-> override( tail => undef);
ok( $q-> wait == 42, 'remove override');

# two overrides, order
$bypass = 0;
$q-> reset;
my $xls = '0';
$q-> override( tail => sub { $xls .= '2'; shift-> super } );
$q-> override( tail => sub { $xls .= '1'; shift-> super } );
$q-> wait;
ok($xls eq '012', 'order');
$q-> override( tail => undef);
$q-> override( tail => undef);

# two overrides, both increment
$bypass = 0;
$q-> reset;
$q-> override( tail => undef);
$q-> override( tail => \&bypass);
$q-> override( tail => \&bypass);
$q-> wait;
ok( $bypass == 2, 'two passing overrides');

# one leftover override
$bypass = 0;
$q-> override(tail => undef);
$q-> reset;
$q-> wait;
ok( $bypass == 1, 'one leftover override');

# one deny, one pass override
$bypass = 0;
$q-> override( tail => sub { 43 } );
$q-> reset;
$q-> wait;
ok( $q-> wait == 43 && $bypass == 0, 'one deny, one pass');

# one pass, one deny override
$bypass = 0;
$q-> override( tail => undef);
$q-> override( tail => undef);
$q-> override( tail => sub { 43 } );
$q-> override( tail => \&bypass);
$q-> reset;
$q-> wait;
ok( $q-> wait == 43 && $bypass == 1, 'one pass, one deny');

# state
$q = lambda {
	context lambda { 'A' };
	state A => tail {
	context lambda { 'B' };
	state B => tail {
	context lambda { 'C' };
	state C => tail {
	}}}
};
my $states = '';
$q-> override( tail => sub {
	$states .= this-> state;
	this-> super;
});
$q-> wait;
ok( $states eq 'ABC', 'states');
$q-> override( tail => undef);

# named states
my %touch;
my $touch = sub {
	$touch{ this-> state }++;
	this-> super;
};
$q-> override( tail => A => $touch);
$q-> override( tail => B => $touch);
$q-> override( tail => C => $touch);
$q-> override( tail => B => undef);
$q-> reset;
$q-> wait;
ok(( 'AC' eq join('', sort keys %touch)), 'named states');
