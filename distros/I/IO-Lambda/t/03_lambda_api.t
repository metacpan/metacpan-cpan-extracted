#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 17;
use IO::Lambda qw(:lambda);

alarm(10);

this lambda {};
this-> wait;
ok( this-> is_stopped, 'lambda api');

this lambda {42};
ok( 42 == this-> wait, 'simple lambda');

this lambda {
	context lambda { 42 };
	tail { 1 + shift };
};
ok( 43 == this-> wait, 'tail lambda');

my $i = 42;
this lambda {
	my $l = lambda {}; 
	context $l;
	tail { ( $i++ > 44) ? $i : ( $l-> reset, again ) };
};
ok( 46 == this-> wait, 'restart tail');

this-> reset;
ok( 47 == this-> wait, 'rerun lambda');

this lambda {
	context 0.01;
	timeout { 'moo' };
};
ok( 'moo' eq this-> wait, 'timeout');

this lambda {
	context lambda {};
	tail {
		context 0.01;
		timeout { 'moo' };
	};
};
ok( 'moo' eq this-> wait, 'tail timeout');

$i = 2;
this lambda {
	context 0.01;
	timeout { $i-- ? again : 'moo' };
};
ok(( 'moo' eq this-> wait && $i == -1), 'restart timeout');

this lambda {
    context lambda { 1 };
    tail {
        return 3 if 3 == shift;
    	my $frame = restartable;
        context lambda { 2 };
	tail {
	   again($frame, lambda { 3 });
	}
    }
};
ok( '3' eq this-> wait, 'frame restart');

this lambda {
	context 
		lambda { 1 }, 
		lambda { context 0.1; timeout { 2 }},
		lambda { 3 };
	tailo { join '', @_ }
};
ok( '123' eq this-> wait, 'tailo');

this lambda {
	context 
		0.1, 
		lambda { 1 }, 
		lambda { context 1.0; timeout { 2 }},
		lambda { 3 };
	any_tail { join '', sort map { $_-> peek } @_ };
};
ok( '13' eq this-> wait, 'any_tail');

SKIP: {
	skip "select(file) doesn't work on win32", 3 if $^O =~ /win32/i;
	skip "select(file) doesn't work with AnyEvent", 3 if $IO::Lambda::LOOP =~ /AnyEvent/;
	skip "cannot open $0:$!", 3 unless open FH, '<', $0;

this lambda {
	context \*FH;
	readable { 'moo' };
};
ok( 'moo' eq this-> wait, 'read');


this lambda {
	context lambda {};
	tail {
		context \*FH;
		readable { 'moo' };
	};
};
ok( 'moo' eq this-> wait, 'tail read');

$i = 2;
this lambda {
	context \*FH;
	readable { $i-- ? again : 'moo' };
};
ok(( 'moo' eq this-> wait && $i == -1), 'restart read');

}

ok( 0 == scalar(@_ = lambda { tails { @_ } }-> wait) , 'empty tails');

this lambda {
	context 2;
	catch { 'B' } timeout { 'A' }
};
this-> start;
this-> terminate('C');
ok('B' eq this-> wait, 'catch');

this lambda {
	context undef;
	tail { return 5 };
};
ok( 5 == this-> wait, 'no tail');
