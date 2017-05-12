#!/usr/bin/perl -T
# Copyright (c) 2015-2017 by Pali <pali@cpan.org>

#########################

use strict;
use warnings FATAL => 'all';

use Carp;
$Carp::Internal{'Test::Builder'} = 1;
$Carp::Internal{'Test::More'} = 1;

use Test::More tests => 113;

#########################

sub is_tainted {
	local $@;   # Don't pollute caller's value.
	return ! eval { eval("#" . substr(join("", @_), 0, 0)); 1 };
}

sub test_tainted {
	my ($got, $expected, $subtest) = @_;
	ok(is_tainted($got), $subtest);
	is($got, $expected, $subtest);
}

sub test_not_tainted {
	my ($got, $expected, $subtest) = @_;
	ok(!is_tainted($got), $subtest);
	is($got, $expected, $subtest);
}

sub taint {
	my ($str) = @_;
	return substr($ENV{PATH}, 0, 0) . $str;
}

#########################

BEGIN {
	use_ok('Email::Address::XS');
};

#########################

my $address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue', comment => 'Records Department');

{
	my $subtest = 'no tainted arguments';
	test_not_tainted($address->phrase(), 'Winston Smith', $subtest);
	test_not_tainted($address->user(), 'winston.smith', $subtest);
	test_not_tainted($address->host(), 'recdep.minitrue', $subtest);
	test_not_tainted($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	test_not_tainted($address->comment(), 'Records Department', $subtest);
	test_not_tainted($address->name(), 'Winston Smith', $subtest);
	test_not_tainted($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)', $subtest);
}

$address->phrase(taint('Winston Smith'));

{
	my $subtest = 'tainted phrase argument';
	test_tainted($address->phrase(), 'Winston Smith', $subtest);
	test_not_tainted($address->user(), 'winston.smith', $subtest);
	test_not_tainted($address->host(), 'recdep.minitrue', $subtest);
	test_not_tainted($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	test_not_tainted($address->comment(), 'Records Department', $subtest);
	test_tainted($address->name(), 'Winston Smith', $subtest);
	test_tainted($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)', $subtest);
}

$address->phrase('Winston Smith');

$address->user(taint('winston.smith'));

{
	my $subtest = 'tainted user argument';
	test_not_tainted($address->phrase(), 'Winston Smith', $subtest);
	test_tainted($address->user(), 'winston.smith', $subtest);
	test_not_tainted($address->host(), 'recdep.minitrue', $subtest);
	test_tainted($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	test_not_tainted($address->comment(), 'Records Department', $subtest);
	test_not_tainted($address->name(), 'Winston Smith', $subtest);
	test_tainted($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)', $subtest);
}

$address->user('winston.smith');

$address->host(taint('recdep.minitrue'));

{
	my $subtest = 'tainted host argument';
	test_not_tainted($address->phrase(), 'Winston Smith', $subtest);
	test_not_tainted($address->user(), 'winston.smith', $subtest);
	test_tainted($address->host(), 'recdep.minitrue', $subtest);
	test_tainted($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	test_not_tainted($address->comment(), 'Records Department', $subtest);
	test_not_tainted($address->name(), 'Winston Smith', $subtest);
	test_tainted($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)', $subtest);
}

$address->host('recdep.minitrue');

$address->address(taint('winston.smith@recdep.minitrue'));

{
	my $subtest = 'tainted address argument';
	test_not_tainted($address->phrase(), 'Winston Smith', $subtest);
	test_tainted($address->user(), 'winston.smith', $subtest);
	test_tainted($address->host(), 'recdep.minitrue', $subtest);
	test_tainted($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	test_not_tainted($address->comment(), 'Records Department', $subtest);
	test_not_tainted($address->name(), 'Winston Smith', $subtest);
	test_tainted($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)', $subtest);
}

$address->address('winston.smith@recdep.minitrue');

$address->comment(taint('Records Department'));

{
	my $subtest = 'tainted address argument';
	test_not_tainted($address->phrase(), 'Winston Smith', $subtest);
	test_not_tainted($address->user(), 'winston.smith', $subtest);
	test_not_tainted($address->host(), 'recdep.minitrue', $subtest);
	test_not_tainted($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	test_tainted($address->comment(), 'Records Department', $subtest);
	test_not_tainted($address->name(), 'Winston Smith', $subtest);
	test_tainted($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)', $subtest);
}

undef $address;

$address = Email::Address::XS->parse('"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)');

{
	my $subtest = 'no tainted parse';
	test_not_tainted($address->phrase(), 'Winston Smith', $subtest);
	test_not_tainted($address->user(), 'winston.smith', $subtest);
	test_not_tainted($address->host(), 'recdep.minitrue', $subtest);
	test_not_tainted($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	test_not_tainted($address->comment(), 'Records Department', $subtest);
	test_not_tainted($address->name(), 'Winston Smith', $subtest);
	test_not_tainted($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)', $subtest);
}

undef $address;

$address = Email::Address::XS->parse(taint('"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)'));

{
	my $subtest = 'tainted parse';
	test_tainted($address->phrase(), 'Winston Smith', $subtest);
	test_tainted($address->user(), 'winston.smith', $subtest);
	test_tainted($address->host(), 'recdep.minitrue', $subtest);
	test_tainted($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	test_tainted($address->comment(), 'Records Department', $subtest);
	test_tainted($address->name(), 'Winston Smith', $subtest);
	test_tainted($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)', $subtest);
}
