#! /usr/bin/perl
# $Id: 11_intercept.t,v 1.1 2008/08/05 19:44:26 dk Exp $

use strict;
use warnings;

use Test::More tests => 11;
use IO::Lambda qw(:all);

# intercept and pass
my $q = lambda {
	context lambda { 42 };
	&tail();
};

my $bypass = 0;
sub bypass
{
	$bypass++;
	this-> super(@_);
}

$q-> intercept( tail => \&bypass);
ok($q-> wait == 42 && $bypass == 1, 'single intercept pass');
$q-> intercept( tail => undef);

# override and deny
$bypass = 0;
$q-> reset;
$q-> intercept( tail => sub { 43 } );
ok($q-> wait == 43 && $bypass == 0, 'single intercept deny');
$q-> intercept( tail => undef);

# override and modify
$bypass = 0;
$q-> reset;
$q-> intercept( tail => sub { this-> super( 1 + shift ) });
ok($q-> wait(42) == 43 && $bypass == 0, 'single intercept modify');
$q-> intercept( tail => undef);

# clean intercept 
$bypass = 0;
$q-> reset;
ok( $q-> wait == 42, 'remove intercept');

# two intercept, order
$bypass = 0;
$q-> reset;
my $xls = '0';
$q-> intercept( tail => sub { $xls .= '2'; this-> super(@_) } );
$q-> intercept( tail => sub { $xls .= '1'; this-> super(@_) } );
$q-> wait;
ok($xls eq '012', 'order');
$q-> intercept( tail => undef);
$q-> intercept( tail => undef);

# two intercepts, both increment
$bypass = 0;
$q-> reset;
$q-> intercept( tail => \&bypass);
$q-> intercept( tail => \&bypass);
$q-> wait;
ok( $bypass == 2, 'two passing intercepts');
$q-> intercept( tail => undef);

# one leftover override
$bypass = 0;
$q-> reset;
$q-> wait;
ok( $bypass == 1, 'one leftover intercept');

# one deny, one pass intercept
$bypass = 0;
$q-> intercept( tail => sub { 43 } );
$q-> reset;
$q-> wait;
ok( $q-> wait == 43 && $bypass == 0, 'one deny, one pass');
$q-> intercept( tail => undef);

# one pass, one deny override
$bypass = 0;
$q-> intercept( tail => undef);
$q-> intercept( tail => sub { 43 } );
$q-> intercept( tail => \&bypass);
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
$q-> intercept( tail => sub {
	$states .= shift;
	this-> super;
});
$q-> wait;
ok( $states eq 'ABC', 'states');
$q-> intercept( tail => undef);

# named states
my %touch;
my $touch = sub {
	$touch{ $_[0] }++;
	this-> super;
};
$q-> intercept( tail => A => $touch);
$q-> intercept( tail => B => $touch);
$q-> intercept( tail => C => $touch);
$q-> intercept( tail => B => undef);
$q-> reset;
$q-> wait;
ok(( 'AC' eq join('', sort keys %touch)), 'named states');
