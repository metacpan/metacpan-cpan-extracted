#! /usr/bin/perl
# $Id: 13_synthetic.t,v 1.4 2009/01/08 15:23:27 dk Exp $

use strict;
use warnings;
use Test::More tests => 2;
use IO::Lambda qw(:all);

# dummy factory

my $a0 = 0;
my $b0 = 3;
sub f
{
	my @b = @_;
	return lambda {
		my @c = @_;
		return "$a0/@b/@c";
	};
}

# test synthetic conditions
sub new_condition(&)
{ 
	f($a0++)-> call($b0++)-> condition( shift, \&new_condition) 
}

my $a2 = 0;
this lambda {
	context 'a';
	new_condition { join('', @_, $a2++, context) }
};

ok(this-> wait eq '1/0/30a', 'synthetic condition 1');
this-> reset;
ok(this-> wait eq '2/1/41a', 'synthetic condition 2');
