#! /usr/bin/perl
# $Id: 09_signal.t,v 1.8 2010/01/17 22:52:22 dk Exp $

use strict;
use warnings;

use Time::HiRes;
use Test::More;
use IO::Lambda qw(:all);
use IO::Lambda::Signal qw(:all);
	
plan skip_all => "Time::HiRes fails on dragonfly and noone cares" if $^O eq 'dragonfly';
plan tests    => 2;

# alarm expires
this lambda {
	alarm(1.0);
	context 'ALRM', 0.1;
	signal {
		alarm(0) unless $_[0];
		$_[0];
	}
};
ok( not(this-> wait), 'signal timed out');

# alarm NOT expires
SKIP: {
	skip "SIGALRM doesn't break select() on $^O", 1 if $^O =~ /win32|^gnu$/i;

	# check for buggy alarm()
	{
		my $alrm;
		local $SIG{ALRM} = sub { $alrm++ };
		Time::HiRes::alarm(0.1);
		Time::HiRes::sleep(0.3);
		Time::HiRes::alarm(0);
		skip "Your Time::HiRes is buggy, see #35899 on rt.cpan.org", 1 unless $alrm;
	}

	this lambda {
		Time::HiRes::alarm(0.5);
		context 'ALRM', 1.0;
		signal {
			alarm(0) unless $_[0];
			$_[0];
		}
	};
	ok( this-> wait, 'signal caught');
}

