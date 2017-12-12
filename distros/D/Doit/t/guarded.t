#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More 'no_plan';
use Doit;

my $d = Doit->init;
$d->add_component('guarded');

eval { $d->guarded_step };
like $@, qr{ERROR.*ensure is missing};

eval { $d->guarded_step("name", ensure => sub{}) };
like $@, qr{ERROR.*using is missing};

eval { $d->guarded_step("name", ensure => sub{}, using => sub{}, unhandled_option => 1) };
like $@, qr{ERROR.*Unhandled options: unhandled_option };

{
    my $var = 0;
    my $called = 0;

    $d->guarded_step(
	"var to zero",
	ensure => sub { $var == 1 },
	using  => sub { $var = 1; $called++  },
    );
    is $var, 1;
    is $called, 1, '1st time "using" called';

    $d->guarded_step(
	"var to zero (is already)",
	ensure => sub { $var == 1 },
	using  => sub { $var = 1; $called++ },
    );
    is $var, 1;
    is $called, 1, '2nd time "using" not called';
}

{
    my $var = 0;
    $d->guarded_step(
	"extern command",
	ensure => sub { $var == 3.14 },
	using  => sub {
	    my $d = shift;
	    $var = $d->qx($^X, '-e', 'print 3.14');
	},
    );
    is $var, 3.14, 'Doit method successfully run';
}

{
    my $var = 0;
    eval {
	$d->guarded_step(
	    "will fail",
	    ensure => sub { $var == 1 },
	    using  => sub { $var = 2 },
	);
    };
    like $@, qr{ERROR:.* 'ensure' block for 'will fail' still fails after running the 'using' block};
}

local @ARGV = ('--dry-run');
$d = Doit->init;

{
    my $var = 0;
    my $called = 0;

    $d->guarded_step(
	"var to zero",
	ensure => sub { $var == 1 },
	using  => sub { $var = 1; $called++  },
    );
    is $var, 0, 'not changed, dry-run';
    is $called, 0, 'not called, dry-run';
}
