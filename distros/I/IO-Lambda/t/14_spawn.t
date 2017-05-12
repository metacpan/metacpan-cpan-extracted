#! /usr/bin/perl
# $Id: 14_spawn.t,v 1.2 2009/12/04 22:11:31 dk Exp $

use strict;
use warnings;
use Test::More;
use IO::Lambda qw(:lambda);
use IO::Lambda::Signal qw(:all);

plan tests => 2;

this lambda {
	context "$^X -v";
	spawn {
		my ( $buf, $exitcode, $error) = @_;
		return $buf;
	}
};

ok( this-> wait =~ /This is perl/s, 'good spawn');

this lambda {
	context "./nothere 2>&1";
	spawn {
		my ( $buf, $exitcode, $error) = @_;
		return not defined($buf);
	}
};

ok( this-> wait, 'bad spawn');
