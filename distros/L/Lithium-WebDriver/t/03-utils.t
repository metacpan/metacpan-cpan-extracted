#!/usr/bin/perl -T

use strict;
use warnings;

use Test::More;
use Test::Output;

use Lithium::WebDriver::Utils; 


stderr_is(
	sub {
		error('Testing error msgs')
	},
	"\e[0;31mERROR> Testing error msgs\e[0m\n",
	"Ensure default error output");

stderr_is(
	sub {
		debug('Testing error msgs');
	},
	"",
	"Ensure default debug output is off unless ENV set");

stderr_is(
	sub {
		$ENV{DEBUG} = 1;
		debug('Testing error msgs');
	},
	"DEBUG> Testing error msgs\n",
	"Ensure default debug output");


stderr_is(
	sub {
		$ENV{DEBUG} = 1;
		dump(\{
			test1 => "test string 1",
			test2 => "test string 2"
		})
	},
	q/DEBUG> $VAR1 = \{
DEBUG>             'test1' => 'test string 1',
DEBUG>             'test2' => 'test string 2'
DEBUG>           };
/,
	"Ensure default dump output");

BIND_LOGGING
	error => sub {
		print "ERROR IS BAD> $_[0]\n";
	};

stdout_is(
	sub { error 'new error function' },
	"ERROR IS BAD> new error function\n",
	"Rebinding error function");

DISABLE_MSGS;

stderr_is(
	sub {
		error('Testing error msgs')
	},
	"",
	"Ensure error output is off after DISABLING_MSGS");

stderr_is(
	sub {
		$ENV{DEBUG} = 1;
		debug('Testing error msgs');
		$ENV{DEBUG} = 0;
	},
	"",
	"Ensure debug output is off after DISABLING_MSGS");


done_testing;
