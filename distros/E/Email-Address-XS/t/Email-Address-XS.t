#!/usr/bin/perl
# Copyright (c) 2015-2018 by Pali <pali@cpan.org>

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Email-Address-XS.t'

#########################

use strict;
use warnings;

# perl version which needs "use utf8;" for comparing utf8 and latin1 strings
BEGIN {
	require utf8 if $] < 5.006001;
	utf8->import() if $] < 5.006001;
};

use Carp;
$Carp::Internal{'Test::Builder'} = 1;
$Carp::Internal{'Test::More'} = 1;

use Test::More tests => 511;
use Test::Builder;

local $SIG{__WARN__} = sub {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	fail('following test does not throw warning');
	warn $_[0];
};

sub with_warning(&) {
	my ($code) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $warn;
	local $SIG{__WARN__} = sub { $warn = 1; };
	my @ret = wantarray ? $code->() : scalar $code->();
	ok($warn, 'following test throws warning');
	return wantarray ? @ret : $ret[0];
}

sub obj_to_hashstr {
	my ($self) = @_;
	my $out = "";
	foreach ( qw(user host phrase comment) ) {
		next unless exists $self->{$_};
		$out .= $_ . ':' . (defined $self->{$_} ? $self->{$_} : '(undef)') . ';';
	}
	return $out;
}

#########################

BEGIN {
	use_ok('Email::Address::XS', qw(parse_email_addresses parse_email_groups format_email_addresses format_email_groups));
};

#########################

require overload;
my $obj_to_origstr = overload::Method 'Email::Address::XS', '""';
my $obj_to_hashstr = \&obj_to_hashstr;

# set stringify and eq operators for comparision used in is_deeply
{
	local $SIG{__WARN__} = sub { };
	overload::OVERLOAD 'Email::Address::XS', '""' => $obj_to_hashstr;
	overload::OVERLOAD 'Email::Address::XS', 'eq' => sub { obj_to_hashstr($_[0]) eq obj_to_hashstr($_[1]) };
}

#########################

{

	{
		my $subtest = 'test method new() without arguments';
		my $address = Email::Address::XS->new();
		ok(!$address->is_valid(), $subtest);
		is($address->phrase(), undef, $subtest);
		is($address->user(), undef, $subtest);
		is($address->host(), undef, $subtest);
		is($address->address(), undef, $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), '', $subtest);
		is(with_warning { $address->format() }, '', $subtest);
	}

	{
		my $subtest = 'test method new() with one argument';
		my $address = Email::Address::XS->new('Addressless Outer Party Member');
		ok(!$address->is_valid(), $subtest);
		is($address->phrase(), 'Addressless Outer Party Member', $subtest);
		is($address->user(), undef, $subtest);
		is($address->host(), undef, $subtest);
		is($address->address(), undef, $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), 'Addressless Outer Party Member', $subtest);
		is(with_warning { $address->format() }, '', $subtest);
	}

	{
		my $subtest = 'test method new() with two arguments as array';
		my $address = Email::Address::XS->new(undef, 'user@oceania');
		ok($address->is_valid(), $subtest);
		is($address->phrase(), undef, $subtest);
		is($address->user(), 'user', $subtest);
		is($address->host(), 'oceania', $subtest);
		is($address->address(), 'user@oceania', $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), 'user', $subtest);
		is($address->format(), 'user@oceania', $subtest);
	}

	{
		my $subtest = 'test method new() with two arguments as hash';
		my $address = Email::Address::XS->new(address => 'winston.smith@recdep.minitrue');
		ok($address->is_valid(), $subtest);
		is($address->phrase(), undef, $subtest);
		is($address->user(), 'winston.smith', $subtest);
		is($address->host(), 'recdep.minitrue', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), 'winston.smith', $subtest);
		is($address->format(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method new() with two arguments as array';
		my $address = Email::Address::XS->new(Julia => 'julia@ficdep.minitrue');
		ok($address->is_valid(), $subtest);
		is($address->phrase(), 'Julia', $subtest);
		is($address->user(), 'julia', $subtest);
		is($address->host(), 'ficdep.minitrue', $subtest);
		is($address->address(), 'julia@ficdep.minitrue', $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), 'Julia', $subtest);
		is($address->format(), 'Julia <julia@ficdep.minitrue>', $subtest);
	}

	{
		my $subtest = 'test method new() with three arguments';
		my $address = Email::Address::XS->new('Winston Smith', 'winston.smith@recdep.minitrue', 'Records Department');
		ok($address->is_valid(), $subtest);
		is($address->phrase(), 'Winston Smith', $subtest);
		is($address->user(), 'winston.smith', $subtest);
		is($address->host(), 'recdep.minitrue', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
		is($address->comment(), 'Records Department', $subtest);
		is($address->name(), 'Winston Smith', $subtest);
		is($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)', $subtest);
	}

	{
		my $subtest = 'test method new() with four arguments user & host as hash';
		my $address = Email::Address::XS->new(user => 'julia', host => 'ficdep.minitrue');
		ok($address->is_valid(), $subtest);
		is($address->phrase(), undef, $subtest);
		is($address->user(), 'julia', $subtest);
		is($address->host(), 'ficdep.minitrue', $subtest);
		is($address->address(), 'julia@ficdep.minitrue', $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), 'julia', $subtest);
		is($address->format(), 'julia@ficdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method new() with four arguments phrase & address as hash';
		my $address = Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue');
		ok($address->is_valid(), $subtest);
		is($address->phrase(), 'Julia', $subtest);
		is($address->user(), 'julia', $subtest);
		is($address->host(), 'ficdep.minitrue', $subtest);
		is($address->address(), 'julia@ficdep.minitrue', $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), 'Julia', $subtest);
		is($address->format(), 'Julia <julia@ficdep.minitrue>', $subtest);
	}

	{
		my $subtest = 'test method new() with four arguments as array';
		my $address = with_warning { Email::Address::XS->new('Julia', 'julia@ficdep.minitrue', 'Fiction Department', 'deprecated_original_string') };
		ok($address->is_valid(), $subtest);
		is($address->phrase(), 'Julia', $subtest);
		is($address->user(), 'julia', $subtest);
		is($address->host(), 'ficdep.minitrue', $subtest);
		is($address->address(), 'julia@ficdep.minitrue', $subtest);
		is($address->comment(), 'Fiction Department', $subtest);
		is($address->name(), 'Julia', $subtest);
		is($address->format(), 'Julia <julia@ficdep.minitrue> (Fiction Department)', $subtest);
	}

	{
		my $subtest = 'test method new() with four arguments as hash (phrase is string "address")';
		my $address = Email::Address::XS->new(phrase => 'address', address => 'user@oceania');
		ok($address->is_valid(), $subtest);
		is($address->phrase(), 'address', $subtest);
		is($address->user(), 'user', $subtest);
		is($address->host(), 'oceania', $subtest);
		is($address->address(), 'user@oceania', $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), 'address', $subtest);
		is($address->format(), 'address <user@oceania>', $subtest);
	}

	{
		my $subtest = 'test method new() with copy argument';
		my $address = Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue');
		my $copy = Email::Address::XS->new(copy => $address);
		ok($address->is_valid(), $subtest);
		ok($copy->is_valid(), $subtest);
		is($copy->phrase(), 'Julia', $subtest);
		is($copy->user(), 'julia', $subtest);
		is($copy->host(), 'ficdep.minitrue', $subtest);
		is($copy->address(), 'julia@ficdep.minitrue', $subtest);
		is($copy->comment(), undef, $subtest);
		$copy->phrase('Winston Smith');
		$copy->address('winston.smith@recdep.minitrue');
		$copy->comment('Records Department');
		is($address->phrase(), 'Julia', $subtest);
		is($address->user(), 'julia', $subtest);
		is($address->host(), 'ficdep.minitrue', $subtest);
		is($address->address(), 'julia@ficdep.minitrue', $subtest);
		is($address->comment(), undef, $subtest);
		$address->phrase(undef);
		$address->address(undef);
		$address->comment(undef);
		is($copy->phrase(), 'Winston Smith', $subtest);
		is($copy->user(), 'winston.smith', $subtest);
		is($copy->host(), 'recdep.minitrue', $subtest);
		is($copy->address(), 'winston.smith@recdep.minitrue', $subtest);
		is($copy->comment(), 'Records Department', $subtest);
	}

	{
		my $subtest = 'test method new() with invalid email address';
		my $address = Email::Address::XS->new(address => 'invalid_address');
		ok(!$address->is_valid(), $subtest);
		is($address->phrase(), undef, $subtest);
		is($address->user(), undef, $subtest);
		is($address->host(), undef, $subtest);
		is($address->address(), undef, $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), '', $subtest);
		is(with_warning { $address->format() }, '', $subtest);
	}

	{
		my $subtest = 'test method new() with copy argument of invalid email address';
		my $address = Email::Address::XS->new(address => 'invalid_address');
		my $copy = Email::Address::XS->new(copy => $address);
		ok(!$address->is_valid(), $subtest);
		ok(!$copy->is_valid(), $subtest);
	}

	{
		my $subtest = 'test method new() with empty strings for user and non empty for host and phrase';
		my $address = Email::Address::XS->new(user => '', host => 'host', phrase => 'phrase');
		ok($address->is_valid(), $subtest);
		is($address->phrase(), 'phrase', $subtest);
		is($address->user(), '', $subtest);
		is($address->host(), 'host', $subtest);
		is($address->address(), '""@host', $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), 'phrase', $subtest);
		is($address->format(), 'phrase <""@host>', $subtest);
	}

	{
		my $subtest = 'test method new() with empty strings for host and non empty for user and phrase';
		my $address = Email::Address::XS->new(user => 'user', host => '', phrase => 'phrase');
		ok(!$address->is_valid(), $subtest);
		is($address->phrase(), 'phrase', $subtest);
		is($address->user(), 'user', $subtest);
		is($address->host(), undef, $subtest);
		is($address->address(), undef, $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), 'phrase', $subtest);
		is(with_warning { $address->format() }, '', $subtest);
	}

	{
		my $subtest = 'test method new() with all named arguments';
		my $address = Email::Address::XS->new(phrase => 'Julia', user => 'julia', host => 'ficdep.minitrue', comment => 'Fiction Department');
		ok($address->is_valid(), $subtest);
		is($address->phrase(), 'Julia', $subtest);
		is($address->user(), 'julia', $subtest);
		is($address->host(), 'ficdep.minitrue', $subtest);
		is($address->address(), 'julia@ficdep.minitrue', $subtest);
		is($address->comment(), 'Fiction Department', $subtest);
		is($address->name(), 'Julia', $subtest);
		is($address->format(), 'Julia <julia@ficdep.minitrue> (Fiction Department)', $subtest);
	}

	{
		my $subtest = 'test method new() that address takes precedence over user and host';
		my $address = Email::Address::XS->new(user => 'winston.smith', host => 'recdep.minitrue', address => 'julia@ficdep.minitrue' );
		is($address->user(), 'julia', $subtest);
		is($address->host(), 'ficdep.minitrue', $subtest);
		is($address->address(), 'julia@ficdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method new() with UNICODE characters';
		my $address = Email::Address::XS->new(phrase => "\x{2606} \x{2602}", user => "\x{263b} \x{265e}", host => "\x{262f}.\x{262d}", comment => "\x{2622} \x{20ac}");
		ok($address->is_valid(), $subtest);
		is($address->phrase(), "\x{2606} \x{2602}", $subtest);
		is($address->user(), "\x{263b} \x{265e}", $subtest);
		is($address->host(), "\x{262f}.\x{262d}", $subtest);
		is($address->address(), "\"\x{263b} \x{265e}\"\@\x{262f}.\x{262d}", $subtest);
		is($address->comment(), "\x{2622} \x{20ac}", $subtest);
		is($address->name(), "\x{2606} \x{2602}", $subtest);
		is($address->format(), "\"\x{2606} \x{2602}\" <\"\x{263b} \x{265e}\"\@\x{262f}.\x{262d}> (\x{2622} \x{20ac})", $subtest);
	}

	{
		my $subtest = 'test method new() with Latin1 characters';
		my $address = Email::Address::XS->new(user => "L\x{e1}tin1", host => "L\x{e1}tin1");
		ok($address->is_valid(), $subtest);
		is($address->phrase(), undef, $subtest);
		is($address->user(), "L\x{e1}tin1", $subtest);
		is($address->host(), "L\x{e1}tin1", $subtest);
		is($address->address(), "L\x{e1}tin1\@L\x{e1}tin1", $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), "L\x{e1}tin1", $subtest);
		is($address->format(), "L\x{e1}tin1\@L\x{e1}tin1", $subtest);
	}

	{
		my $subtest = 'test method new() with mix of Latin1 and UNICODE characters';
		my $address = Email::Address::XS->new(user => "L\x{e1}tin1", host => "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}");
		ok($address->is_valid(), $subtest);
		is($address->phrase(), undef, $subtest);
		is($address->user(), "L\x{e1}tin1", $subtest);
		is($address->host(), "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}", $subtest);
		is($address->address(), "L\x{e1}tin1\@\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}", $subtest);
		is($address->comment(), undef, $subtest);
		is($address->name(), "L\x{e1}tin1", $subtest);
		is($address->format(), "L\x{e1}tin1\@\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}", $subtest);
	}

}

#########################

{

	my $address = Email::Address::XS->new();
	is($address->phrase(), undef, 'test method phrase()');

	is($address->phrase('Winston Smith'), 'Winston Smith', 'test method phrase()');
	is($address->phrase(), 'Winston Smith', 'test method phrase()');

	is($address->phrase('Julia'), 'Julia', 'test method phrase()');
	is($address->phrase(), 'Julia', 'test method phrase()');

	is($address->phrase(undef), undef, 'test method phrase()');
	is($address->phrase(), undef, 'test method phrase()');

}

#########################

{

	my $address = Email::Address::XS->new();
	is($address->user(), undef, 'test method user()');

	is($address->user('winston'), 'winston', 'test method user()');
	is($address->user(), 'winston', 'test method user()');

	is($address->user('julia'), 'julia', 'test method user()');
	is($address->user(), 'julia', 'test method user()');

	is($address->user(undef), undef, 'test method user()');
	is($address->user(), undef, 'test method user()');

}

#########################

{

	my $address = Email::Address::XS->new();
	is($address->host(), undef, 'test method host()');

	is($address->host('eurasia'), 'eurasia', 'test method host()');
	is($address->host(), 'eurasia', 'test method host()');

	is($address->host('eastasia'), 'eastasia', 'test method host()');
	is($address->host(), 'eastasia', 'test method host()');

	is($address->host(undef), undef, 'test method host()');
	is($address->host(), undef, 'test method host()');

}

#########################

{

	my $address = Email::Address::XS->new();
	is($address->address(), undef, 'test method address()');

	is($address->address('winston.smith@recdep.minitrue'), 'winston.smith@recdep.minitrue', 'test method address()');
	is($address->address(), 'winston.smith@recdep.minitrue', 'test method address()');
	is($address->user(), 'winston.smith', 'test method address()');
	is($address->host(), 'recdep.minitrue', 'test method address()');

	is($address->user('julia@outer"party'), 'julia@outer"party', 'test method address()');
	is($address->user(), 'julia@outer"party', 'test method address()');
	is($address->host(), 'recdep.minitrue', 'test method address()');
	is($address->address(), '"julia@outer\\"party"@recdep.minitrue', 'test method address()');

	is($address->address('julia@ficdep.minitrue'), 'julia@ficdep.minitrue', 'test method address()');
	is($address->address(), 'julia@ficdep.minitrue', 'test method address()');
	is($address->user(), 'julia', 'test method address()');
	is($address->host(), 'ficdep.minitrue', 'test method address()');

	is($address->address(undef), undef, 'test method address()');
	is($address->address(), undef, 'test method address()');
	is($address->user(), undef, 'test method address()');
	is($address->host(), undef, 'test method address()');

	is($address->address('julia@ficdep.minitrue'), 'julia@ficdep.minitrue', 'test method address()');
	is($address->address('invalid_address'), undef, 'test method address()');
	is($address->address(), undef, 'test method address()');

}

#########################

{

	my $address = Email::Address::XS->new();
	is($address->comment(), undef, 'test method comment()');

	is($address->comment('Fiction Department'), 'Fiction Department', 'test method comment()');
	is($address->comment(), 'Fiction Department', 'test method comment()');

	is($address->comment('Records Department'), 'Records Department', 'test method comment()');
	is($address->comment(), 'Records Department', 'test method comment()');

	is($address->comment(undef), undef, 'test method comment()');
	is($address->comment(), undef, 'test method comment()');

	is($address->comment('(comment)'), '(comment)', 'test method comment()');
	is($address->comment(), '(comment)', 'test method comment()');

	is($address->comment('string (comment) string'), 'string (comment) string', 'test method comment()');
	is($address->comment(), 'string (comment) string', 'test method comment()');

	is($address->comment('string (comment (nested ()comment)another comment)()'), 'string (comment (nested ()comment)another comment)()', 'test method comment()');
	is($address->comment(), 'string (comment (nested ()comment)another comment)()', 'test method comment()');

	is($address->comment('string (comment \(not nested ()comment\)\)(nested\(comment()))'), 'string (comment \(not nested ()comment\)\)(nested\(comment()))', 'test method comment()');
	is($address->comment(), 'string (comment \(not nested ()comment\)\)(nested\(comment()))', 'test method comment()');

	is($address->comment('string\\\\()'), 'string\\\\()', 'test method comment()');
	is($address->comment(), 'string\\\\()', 'test method comment()');

	is($address->comment('string\\\\\\\\()'), 'string\\\\\\\\()', 'test method comment()');
	is($address->comment(), 'string\\\\\\\\()', 'test method comment()');

	is($address->comment('string ((not balanced comment)'), undef, 'test method comment()');
	is($address->comment(), undef, 'test method comment()');

	is($address->comment('string )(()not balanced'), undef, 'test method comment()');
	is($address->comment(), undef, 'test method comment()');

	is($address->comment('string \()not balanced'), undef, 'test method comment()');
	is($address->comment(), undef, 'test method comment()');

	is($address->comment('string(\)not balanced'), undef, 'test method comment()');
	is($address->comment(), undef, 'test method comment()');

	is($address->comment('string(\\\\\)not balanced'), undef, 'test method comment()');
	is($address->comment(), undef, 'test method comment()');

	is($address->comment("string\x00string"), undef, 'test method comment()');
	is($address->comment(), undef, 'test method comment()');

	is($address->comment("string\\\x00string"), "string\\\x00string", 'test method comment()');
	is($address->comment(), "string\\\x00string", 'test method comment()');

}

#########################

{

	my $address = Email::Address::XS->new();
	is($address->name(), '', 'test method name()');

	$address->user('user1');
	is($address->name(), 'user1', 'test method name()');

	$address->user('user2');
	is($address->name(), 'user2', 'test method name()');

	$address->host('host');
	is($address->name(), 'user2', 'test method name()');

	$address->address('winston.smith@recdep.minitrue');
	is($address->name(), 'winston.smith', 'test method name()');

	$address->comment('Winston');
	is($address->name(), 'Winston', 'test method name()');

	$address->phrase('Long phrase');
	is($address->name(), 'Long phrase', 'test method name()');

	$address->phrase('Long phrase 2');
	is($address->name(), 'Long phrase 2', 'test method name()');

	$address->user('user3');
	is($address->name(), 'Long phrase 2', 'test method name()');

	$address->comment('winston');
	is($address->name(), 'Long phrase 2', 'test method name()');

	$address->phrase(undef);
	is($address->name(), 'winston', 'test method name()');

	$address->comment(undef);
	is($address->name(), 'user3', 'test method name()');

	$address->address(undef);
	is($address->name(), '', 'test method name()');

	$address->phrase('Long phrase 3');
	is($address->phrase(), 'Long phrase 3', 'test method name()');

}

#########################

{

	# set original stringify operator
	{
		local $SIG{__WARN__} = sub { };
		overload::OVERLOAD 'Email::Address::XS', '""' => $obj_to_origstr;
	}

	my $address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue');
	is("$address", '"Winston Smith" <winston.smith@recdep.minitrue>', 'test object stringify');

	$address->phrase('Winston');
	is("$address", 'Winston <winston.smith@recdep.minitrue>', 'test object stringify');

	$address->address('winston@recdep.minitrue');
	is("$address", 'Winston <winston@recdep.minitrue>', 'test object stringify');

	$address->phrase(undef);
	is("$address", 'winston@recdep.minitrue', 'test object stringify');

	$address->address(undef);
	is(with_warning { "$address" }, '', 'test object stringify');

	# revert back
	{
		local $SIG{__WARN__} = sub { };
		overload::OVERLOAD 'Email::Address::XS', '""' => $obj_to_hashstr;
	}

}

#########################

{

	my $address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue');
	is($address->format(), '"Winston Smith" <winston.smith@recdep.minitrue>', 'test method format()');

	$address->phrase('Julia');
	is($address->format(), 'Julia <winston.smith@recdep.minitrue>', 'test method format()');

	$address->address('julia@ficdep.minitrue');
	is($address->format(), 'Julia <julia@ficdep.minitrue>', 'test method format()');

	$address->phrase(undef);
	is($address->format(), 'julia@ficdep.minitrue', 'test method format()');

	$address->address(undef);
	is(with_warning { $address->format() }, '', 'test method format()');

	$address->user('julia');
	is(with_warning { $address->format() }, '', 'test method format()');

	$address->host('ficdep.minitrue');
	is($address->format(), 'julia@ficdep.minitrue', 'test method format()');

	$address->user(undef);
	is(with_warning { $address->format() }, '', 'test method format()');

}

#########################

{

	is_deeply(
		[ with_warning { Email::Address::XS->parse() } ],
		[],
		'test method parse() without argument',
	);

	is_deeply(
		[ with_warning { Email::Address::XS->parse(undef) } ],
		[],
		'test method parse() with undef argument',
	);

	is_deeply(
		[ Email::Address::XS->parse('') ],
		[],
		'test method parse() on empty string',
	);

	{
		my $subtest = 'test method parse() on invalid not parsable line';
		my @addresses = Email::Address::XS->parse('invalid_line');
		is_deeply(
			\@addresses,
			[ Email::Address::XS->new(phrase => 'invalid_line') ],
			$subtest,
		) and do {
			ok(!$addresses[0]->is_valid(), $subtest);
			is($addresses[0]->original(), 'invalid_line', $subtest);
		};
	}

	{
		my $subtest = 'test method parse() on string with valid addresses';
		my @addresses = Email::Address::XS->parse('"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, user@oceania');
		is_deeply(
			\@addresses,
			[
				Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'),
				Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'),
				Email::Address::XS->new(address => 'user@oceania')
			],
			$subtest,
		) and do {
			ok($addresses[0]->is_valid(), $subtest);
			ok($addresses[1]->is_valid(), $subtest);
			ok($addresses[2]->is_valid(), $subtest);
			is($addresses[0]->original(), '"Winston Smith" <winston.smith@recdep.minitrue>', $subtest);
			is($addresses[1]->original(), 'Julia <julia@ficdep.minitrue>', $subtest);
			is($addresses[2]->original(), 'user@oceania', $subtest);
		};
	}

	{
		my $subtest = 'test method parse() in scalar context on empty string';
		my $address = Email::Address::XS->parse('');
		ok(!$address->is_valid(), $subtest);
		is($address->original(), '', $subtest);
		is($address->phrase(), undef, $subtest);
		is($address->address(), undef, $subtest);
	}

	{
		my $subtest = 'test method parse() in scalar context with one address';
		my $address = Email::Address::XS->parse('"Winston Smith" <winston.smith@recdep.minitrue>');
		ok($address->is_valid(), $subtest);
		is($address->original(), '"Winston Smith" <winston.smith@recdep.minitrue>', $subtest);
		is($address->phrase(), 'Winston Smith', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse() in scalar context with more addresses';
		my $address = Email::Address::XS->parse('"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, user@oceania');
		ok(!$address->is_valid(), $subtest);
		is($address->original(), '"Winston Smith" <winston.smith@recdep.minitrue>', $subtest);
		is($address->phrase(), 'Winston Smith', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse() in scalar context with invalid, but parsable angle address';
		my $address = Email::Address::XS->parse('"Winston Smith" <winston.smith.@recdep.minitrue>');
		ok(!$address->is_valid(), $subtest);
		is($address->original(), '"Winston Smith" <winston.smith.@recdep.minitrue>', $subtest);
		is($address->phrase(), 'Winston Smith', $subtest);
		is($address->user(), 'winston.smith.', $subtest);
		is($address->host(), 'recdep.minitrue', $subtest);
		is($address->address(), '"winston.smith."@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse() in scalar context with invalid, but parsable bare address';
		my $address = Email::Address::XS->parse('winston.smith.@recdep.minitrue');
		ok(!$address->is_valid(), $subtest);
		is($address->original(), 'winston.smith.@recdep.minitrue', $subtest);
		is($address->user(), 'winston.smith.', $subtest);
		is($address->host(), 'recdep.minitrue', $subtest);
		is($address->address(), '"winston.smith."@recdep.minitrue', $subtest);
	}

}

#########################

{

	{
		my $subtest = 'test method parse_bare_address() without argument';
		my $address = with_warning { Email::Address::XS->parse_bare_address() };
		ok(!$address->is_valid(), $subtest);
		is($address->original(), undef, $subtest);
		is($address->address(), undef, $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() with undef argument';
		my $address = with_warning { Email::Address::XS->parse_bare_address(undef) };
		ok(!$address->is_valid(), $subtest);
		is($address->original(), undef, $subtest);
		is($address->address(), undef, $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on empty string';
		my $address = Email::Address::XS->parse_bare_address('');
		ok(!$address->is_valid(), $subtest);
		is($address->original(), '', $subtest);
		is($address->address(), undef, $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on invalid not parsable address';
		my $address = Email::Address::XS->parse_bare_address('invalid_line');
		ok(!$address->is_valid(), $subtest);
		is($address->original(), 'invalid_line', $subtest);
		is($address->address(), undef, $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on invalid input string - address with angle brackets';
		my $address = Email::Address::XS->parse_bare_address('<winston.smith@recdep.minitrue>');
		ok(!$address->is_valid(), $subtest);
		is($address->original(), '<winston.smith@recdep.minitrue>', $subtest);
		is($address->address(), undef, $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on invalid input string - phrase with address';
		my $address = Email::Address::XS->parse_bare_address('Winston Smith <winston.smith@recdep.minitrue>');
		ok(!$address->is_valid(), $subtest);
		is($address->original(), 'Winston Smith <winston.smith@recdep.minitrue>', $subtest);
		is($address->address(), undef, $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on invalid input string - two addresses';
		my $address = Email::Address::XS->parse_bare_address('winston.smith@recdep.minitrue, julia@ficdep.minitrue');
		ok(!$address->is_valid(), $subtest);
		is($address->original(), 'winston.smith@recdep.minitrue, julia@ficdep.minitrue', $subtest);
		is($address->address(), undef, $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on valid input string';
		my $address = Email::Address::XS->parse_bare_address('winston.smith@recdep.minitrue');
		ok($address->is_valid(), $subtest);
		is($address->original(), 'winston.smith@recdep.minitrue', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on valid input string with comment';
		my $address = Email::Address::XS->parse_bare_address('winston.smith@recdep.minitrue(comment)');
		ok($address->is_valid(), $subtest);
		is($address->original(), 'winston.smith@recdep.minitrue(comment)', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on valid input string with comment';
		my $address = Email::Address::XS->parse_bare_address('winston.smith@recdep.minitrue (comment)');
		ok($address->is_valid(), $subtest);
		is($address->original(), 'winston.smith@recdep.minitrue (comment)', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on valid input string with comment';
		my $address = Email::Address::XS->parse_bare_address('(comment)winston.smith@recdep.minitrue');
		ok($address->is_valid(), $subtest);
		is($address->original(), '(comment)winston.smith@recdep.minitrue', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on valid input string with comment';
		my $address = Email::Address::XS->parse_bare_address('(comment) winston.smith@recdep.minitrue');
		ok($address->is_valid(), $subtest);
		is($address->original(), '(comment) winston.smith@recdep.minitrue', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on valid input string with two comments';
		my $address = Email::Address::XS->parse_bare_address('(comment)winston.smith@recdep.minitrue(comment)');
		ok($address->is_valid(), $subtest);
		is($address->original(), '(comment)winston.smith@recdep.minitrue(comment)', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on valid input string with two comments';
		my $address = Email::Address::XS->parse_bare_address('(comment) winston.smith@recdep.minitrue (comment)');
		ok($address->is_valid(), $subtest);
		is($address->original(), '(comment) winston.smith@recdep.minitrue (comment)', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

	{
		my $subtest = 'test method parse_bare_address() on valid input string with lot of comments';
		my $address = Email::Address::XS->parse_bare_address('(comm(e)nt) (co(m)ment) winston (comment) . smith@recdep.minitrue (c(o)mment) (comment)');
		ok($address->is_valid(), $subtest);
		is($address->original(), '(comm(e)nt) (co(m)ment) winston (comment) . smith@recdep.minitrue (c(o)mment) (comment)', $subtest);
		is($address->address(), 'winston.smith@recdep.minitrue', $subtest);
	}

}

#########################

{

	is(
		format_email_addresses(),
		'',
		'test function format_email_addresses() with empty list of addresses',
	);

	is(
		with_warning { format_email_addresses('invalid string') },
		'',
		'test function format_email_addresses() with invalid string argument',
	);

	is(
		format_email_addresses(Email::Address::XS::Derived->new(user => 'user', host => 'host')),
		'user_derived_suffix@host',
		'test function format_email_addresses() with derived object class',
	);

	is(
		with_warning { format_email_addresses(Email::Address::XS::NotDerived->new(user => 'user', host => 'host')) },
		'',
		'test function format_email_addresses() with not derived object class',
	);

	is(
		with_warning { format_email_addresses(bless([], 'invalid_object_class')) },
		'',
		'test function format_email_addresses() with invalid object class',
	);

	is(
		format_email_addresses(
			Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'),
			Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'),
			Email::Address::XS->new(phrase => "O'Brien", user => "o'brien", host => 'thought.police.oceania'),
			Email::Address::XS->new(phrase => 'Mr. Charrington', user => 'charrington"@"shop', host => 'thought.police.oceania'),
			Email::Address::XS->new(phrase => 'Emmanuel Goldstein', address => 'goldstein@brotherhood.oceania'),
			Email::Address::XS->new(address => 'user@oceania'),
			Email::Address::XS->new(phrase => 'Escape " also , characters ;', address => 'user2@oceania'),
			Email::Address::XS->new(phrase => 'user5@oceania" <user6@oceania> , "', address => 'user4@oceania'),
			Email::Address::XS->new(user => '.user7', host => 'oceania'),
			Email::Address::XS->new(user => 'user8.', host => 'oceania'),
			Email::Address::XS->new(phrase => '"', address => 'user9@oceania'),
			Email::Address::XS->new(phrase => "Mr. '", address => 'user10@oceania'),
		),
		q("Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, O'Brien <o'brien@thought.police.oceania>, "Mr. Charrington" <"charrington\"@\"shop"@thought.police.oceania>, "Emmanuel Goldstein" <goldstein@brotherhood.oceania>, user@oceania, "Escape \" also , characters ;" <user2@oceania>, "user5@oceania\" <user6@oceania> , \"" <user4@oceania>, ".user7"@oceania, "user8."@oceania, "\"" <user9@oceania>, "Mr. '" <user10@oceania>),
		'test function format_email_addresses() with list of different type of addresses',
	);

}

#########################

{

	is_deeply(
		[ with_warning { parse_email_addresses(undef) } ],
		[],
		'test function parse_email_addresses() with undef argument',
	);

	is_deeply(
		[ parse_email_addresses('') ],
		[],
		'test function parse_email_addresses() on empty string',
	);

	is_deeply(
		[ parse_email_addresses('incorrect') ],
		[ Email::Address::XS->new(phrase => 'incorrect') ],
		'test function parse_email_addresses() on incorrect string',
	);

	is_deeply(
		[ parse_email_addresses('Winston Smith <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with unquoted phrase',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with quoted phrase',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" "suffix" suffix2 <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'Winston Smith suffix suffix2', address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with more words in phrase',
	);

	is_deeply(
		[ parse_email_addresses('winston.smith@recdep.minitrue') ],
		[ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with just address',
	);

	is_deeply(
		[ parse_email_addresses('winston.smith@recdep.minitrue (Winston Smith)') ],
		[ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue', comment => 'Winston Smith') ],
		'test function parse_email_addresses() on string with comment after address',
	);

	is_deeply(
		[ parse_email_addresses('<winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with just address in angle brackets',
	);

	is_deeply(
		[ parse_email_addresses('"user@oceania" : winston.smith@recdep.minitrue') ],
		[ Email::Address::XS->new(address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with character @ inside group name',
	);

	is_deeply(
		[ parse_email_addresses('"user@oceania" <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'user@oceania', address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with character @ inside phrase',
	);

	is_deeply(
		[ parse_email_addresses('"User <user@oceania>" <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'User <user@oceania>', address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with email address inside phrase',
	);

	is_deeply(
		[ parse_email_addresses('"julia@outer\\"party"@ficdep.minitrue') ],
		[ Email::Address::XS->new(user => 'julia@outer"party', host => 'ficdep.minitrue') ],
		'test function parse_email_addresses() on string with quoted and escaped mailbox part of address',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>') ],
		[
			Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'),
			Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'),
		],
		'test function parse_email_addresses() on string with two items',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, user@oceania') ],
		[
			Email::Address::XS->new('Winston Smith', 'winston.smith@recdep.minitrue'),
			Email::Address::XS->new('Julia', 'julia@ficdep.minitrue'), Email::Address::XS->new(address => 'user@oceania'),
		],
		'test function parse_email_addresses() on string with three items',
	);

	is_deeply(
		[ parse_email_addresses('(leading comment)"Winston (Smith)" <winston.smith@recdep.minitrue(.oceania)> (comment after), Julia (Unknown) <julia(outer party)@ficdep.minitrue> (additional comment)') ],
		[
			Email::Address::XS->new(phrase => 'Winston (Smith)', address => 'winston.smith@recdep.minitrue', comment => 'comment after'),
			Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue', comment => 'additional comment'),
		],
		'test function parse_email_addresses() on string with a lots of comments',
	);

	is_deeply(
		[ parse_email_addresses('Winston Smith( <user@oceania>, Julia) <winston.smith@recdep.minitrue>') ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with comma in comment',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" ( <user@oceania>, (Julia) <julia(outer(.)party)@ficdep.minitrue>, ) <winston.smith@recdep.minitrue>' ) ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue') ],
		'test function parse_email_addresses() on string with nested comments',
	);

	is_deeply(
		[ parse_email_addresses('Winston Smith <winston   .smith  @  recdep(comment).      minitrue>' ) ],
		[ Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue', comment => 'comment') ],
		'test function parse_email_addresses() on string with obsolate white spaces',
	);

	is_deeply(
		[ parse_email_addresses("\302\257\302\257`\302\267.\302\245\302\253P\302\256\303\216\303\221\303\247\342\202\254\303\230fTh\342\202\254\303\220\303\205\302\256K\302\273\302\245.\302\267`\302\257\302\257 <email\@example.com>, \"(> \\\" \\\" <)                              ( ='o'= )                              (\\\")___(\\\")  sWeEtAnGeLtHePrInCeSsOfThEsKy\" <email2\@example.com>, \"(i)cRiStIaN(i)\" <email3\@example.com>, \"(S)MaNu_vuOLeAmMazZaReNimOe(*)MiAo(\@)\" <email4\@example.com>\n") ],
		[
			Email::Address::XS->new(phrase => "\302\257\302\257`\302\267.\302\245\302\253P\302\256\303\216\303\221\303\247\342\202\254\303\230fTh\342\202\254\303\220\303\205\302\256K\302\273\302\245.\302\267`\302\257\302\257", user => 'email', host => 'example.com'),
			Email::Address::XS->new(phrase => '(> " " <)                              ( =\'o\'= )                              (")___(")  sWeEtAnGeLtHePrInCeSsOfThEsKy', user => 'email2', host => 'example.com'),
			Email::Address::XS->new(phrase => '(i)cRiStIaN(i)', user => 'email3', host => 'example.com'),
			Email::Address::XS->new(phrase => '(S)MaNu_vuOLeAmMazZaReNimOe(*)MiAo(@)', user => 'email4', host => 'example.com'),
		],
		'test function parse_email_addresses() on CVE-2015-7686 string',
	);

	is_deeply(
		[ parse_email_addresses('aaaa@') ],
		[ Email::Address::XS->new(user => 'aaaa') ],
		'test function parse_email_addresses() on CVE-2017-14461 string',
	);

	is_deeply(
		[ parse_email_addresses('a(aa') ],
		[ Email::Address::XS->new() ],
		'test function parse_email_addresses() on CVE-2017-14461 string',
	);

	is_deeply(
		[ parse_email_addresses('"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, O\'Brien <o\'brien@thought.police.oceania>, "Mr. Charrington" <"charrington\"@\"shop"@thought.police.oceania>, "Emmanuel Goldstein" <goldstein@brotherhood.oceania>, user@oceania, "Escape \" also , characters ;" <user2@oceania>, "user5@oceania\" <user6@oceania> , \"" <user4@oceania>') ],
		[
			Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'),
			Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'),
			Email::Address::XS->new(phrase => "O'Brien", user => "o'brien", host => 'thought.police.oceania'),
			Email::Address::XS->new(phrase => 'Mr. Charrington', user => 'charrington"@"shop', host => 'thought.police.oceania'),
			Email::Address::XS->new(phrase => 'Emmanuel Goldstein', address => 'goldstein@brotherhood.oceania'),
			Email::Address::XS->new(address => 'user@oceania'),
			Email::Address::XS->new(phrase => 'Escape " also , characters ;', address => 'user2@oceania'),
			Email::Address::XS->new(phrase => 'user5@oceania" <user6@oceania> , "', address => 'user4@oceania'),
		],
		'test function parse_email_addresses() on string with lots of different types of addresses',
	);

	is_deeply(
		[ parse_email_addresses('winston.smith@recdep.minitrue', 'Email::Address::XS::Derived') ],
		[ bless({ phrase => undef, user => 'winston.smith', host => 'recdep.minitrue', comment => undef }, 'Email::Address::XS::Derived') ],
		'test function parse_email_addresses() with second derived class name argument',
	);

	is_deeply(
		[ with_warning { parse_email_addresses('winston.smith@recdep.minitrue', 'Email::Address::XS::NotDerived') } ],
		[],
		'test function parse_email_addresses() with second not derived class name argument',
	);

}

#########################

{

	my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue');
	my $julias_address = Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue');
	my $obriens_address = Email::Address::XS->new(phrase => "O'Brien", user => "o'brien", host => 'thought.police.oceania');
	my $charringtons_address = Email::Address::XS->new(phrase => 'Mr. Charrington', user => 'charrington"@"shop', host => 'thought.police.oceania');
	my $goldsteins_address = Email::Address::XS->new(phrase => 'Emmanuel Goldstein', address => 'goldstein@brotherhood.oceania');
	my $users_address = Email::Address::XS->new(address => 'user@oceania');
	my $user2s_address = Email::Address::XS->new(phrase => 'Escape " also , characters', address => 'user2@oceania');
	my $user3s_address = Email::Address::XS->new(address => 'user3@oceania');
	my $user4s_address = Email::Address::XS->new(phrase => 'user5@oceania" <user6@oceania> , "', address => 'user4@oceania');

	my $winstons_mime_address = Email::Address::XS->new(phrase => '=?US-ASCII?Q?Winston?= Smith', address => 'winston.smith@recdep.minitrue');
	my $julias_mime_address = Email::Address::XS->new(phrase => '=?US-ASCII?Q?Julia?=', address => 'julia@ficdep.minitrue');

	my $derived_object = Email::Address::XS::Derived->new(user => 'user', host => 'host');
	my $not_derived_object = Email::Address::XS::NotDerived->new(user => 'user', host => 'host');

	my $nameless_group = '';
	my $brotherhood_group = 'Brotherhood';
	my $minitrue_group = 'Ministry of "Truth"';
	my $thoughtpolice_group = 'Thought Police';
	my $users_group = 'users@oceania';
	my $undisclosed_group = 'undisclosed-recipients';
	my $mime_group = '=?US-ASCII?Q?MIME?=';

	is(
		with_warning { format_email_groups('first', 'second', 'third') },
		undef,
		'test function format_email_groups() with odd number of arguments',
	);

	is(
		with_warning { format_email_groups('name', undef) },
		'name:;',
		'test function format_email_groups() with invalid type second argument (undef)',
	);

	is(
		with_warning { format_email_groups('name', 'string') },
		'name:;',
		'test function format_email_groups() with invalid type second argument (string)',
	);

	is(
		format_email_groups(),
		'',
		'test function format_email_groups() with empty list of groups',
	);

	is(
		format_email_groups(undef() => []),
		'',
		'test function format_email_groups() with empty list of addresses in one undef group',
	);

	is(
		format_email_groups(undef() => [ $users_address ]),
		'user@oceania',
		'test function format_email_groups() with one email address in undef group',
	);

	is(
		format_email_groups($nameless_group => [ $users_address ]),
		'"": user@oceania;',
		'test function format_email_groups() with one email address in nameless group',
	);

	is(
		format_email_groups($undisclosed_group => []),
		'undisclosed-recipients:;',
		'test function format_email_groups() with empty list of addresses in one named group',
	);

	is(
		format_email_groups(undef() => [ $derived_object ]),
		'user_derived_suffix@host',
		'test function format_email_groups() with derived object class',
	);

	is(
		with_warning { format_email_groups(undef() => [ $not_derived_object ]) },
		'',
		'test function format_email_groups() with not derived object class',
	);

	is(
		format_email_groups($brotherhood_group => [ $winstons_address, $julias_address ]),
		'Brotherhood: "Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>;',
		'test function format_email_groups() with two addresses in one named group',
	);

	is(
		format_email_groups(
			$brotherhood_group => [ $winstons_address, $julias_address ],
			undef() => [ $users_address ]
		),
		'Brotherhood: "Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>;, user@oceania',
		'test function format_email_groups() with addresses in two groups',
	);

	is(
		format_email_groups(
			$mime_group => [ $winstons_mime_address, $julias_mime_address ],
		),
		'=?US-ASCII?Q?MIME?=: =?US-ASCII?Q?Winston?= Smith <winston.smith@recdep.minitrue>, =?US-ASCII?Q?Julia?= <julia@ficdep.minitrue>;',
		'test function format_email_groups() that does not quote MIME encoded strings',
	);

	is(
		format_email_groups("\x{2764} \x{2600}" => [ Email::Address::XS->new(phrase => "\x{2606} \x{2602}", user => "\x{263b} \x{265e}", host => "\x{262f}.\x{262d}", comment => "\x{2622} \x{20ac}") ]),
		"\"\x{2764} \x{2600}\": \"\x{2606} \x{2602}\" <\"\x{263b} \x{265e}\"\@\x{262f}.\x{262d}> (\x{2622} \x{20ac});",
		'test function format_email_groups() that preserves unicode characters and UTF-8 status flag',
	);

	is(
		format_email_groups("ASCII" => [], "L\x{e1}tin1" => []),
		"ASCII:;, L\x{e1}tin1:;",
		'test function format_email_groups() that correctly compose Latin1 string from ASCII and Latin1 parts',
	);

	is(
		format_email_groups("ASCII" => [ Email::Address::XS->new(user => "L\x{e1}tin1", host => "L\x{e1}tin1") ]),
		"ASCII: L\x{e1}tin1\@L\x{e1}tin1;",
		'test function format_email_groups() that correctly compose Latin1 string from Latin1 parts',
	);

	is(
		format_email_groups("ASCII" => [ Email::Address::XS->new(user => "L\x{e1}tin1", host => "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}") ]),
		"ASCII: L\x{e1}tin1\@\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404};",
		'test function format_email_groups() that correctly compose UNICODE string from ASCII, Latin1 and UNICODE parts',
	);

	is(
		format_email_groups(
			$minitrue_group => [ $winstons_address, $julias_address ],
			$thoughtpolice_group => [ $obriens_address, $charringtons_address ],
			undef() => [ $users_address, $user2s_address ],
			$undisclosed_group => [],
			undef() => [ $user3s_address ],
			$brotherhood_group => [ $goldsteins_address ],
			$users_group => [ $user4s_address ],
		),
		'"Ministry of \\"Truth\\"": "Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>;, "Thought Police": O\'Brien <o\'brien@thought.police.oceania>, "Mr. Charrington" <"charrington\\"@\\"shop"@thought.police.oceania>;, user@oceania, "Escape \" also , characters" <user2@oceania>, undisclosed-recipients:;, user3@oceania, Brotherhood: "Emmanuel Goldstein" <goldstein@brotherhood.oceania>;, "users@oceania": "user5@oceania\\" <user6@oceania> , \\"" <user4@oceania>;',
		'test function format_email_groups() with different type of addresses in more groups',
	);

}

#########################

{
	tie my $str1, 'TieScalarCounter', 'str1';
	tie my $str2, 'TieScalarCounter', 'str2';
	tie my $str3, 'TieScalarCounter', 'str3';
	tie my $str4, 'TieScalarCounter', 'str4';
	tie my $str5, 'TieScalarCounter', undef;
	my $list1 = [ Email::Address::XS->new(), Email::Address::XS->new() ];
	my $list2 = [ Email::Address::XS->new(), Email::Address::XS->new() ];
	my $list3 = [ Email::Address::XS->new() ];
	my $list4 = [ Email::Address::XS->new() ];
	tie $list1->[0]->{user}, 'TieScalarCounter', 'ASCII';
	tie $list1->[0]->{host}, 'TieScalarCounter', 'ASCII';
	tie $list1->[0]->{phrase}, 'TieScalarCounter', 'ASCII';
	tie $list1->[0]->{comment}, 'TieScalarCounter', 'ASCII';
	tie $list1->[1]->{user}, 'TieScalarCounter', 'ASCII';
	tie $list1->[1]->{host}, 'TieScalarCounter', "L\x{e1}tin1";
	tie $list1->[1]->{phrase}, 'TieScalarCounter', "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}";
	tie $list1->[1]->{comment}, 'TieScalarCounter', 'ASCII';
	tie $list2->[0]->{user}, 'TieScalarCounter', "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}";
	tie $list2->[0]->{host}, 'TieScalarCounter', "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}";
	tie $list2->[0]->{phrase}, 'TieScalarCounter', "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}";
	tie $list2->[0]->{comment}, 'TieScalarCounter', "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}";
	tie $list2->[1]->{user}, 'TieScalarCounter', "L\x{e1}tin1";
	tie $list2->[1]->{host}, 'TieScalarCounter', "L\x{e1}tin1";
	tie $list2->[1]->{phrase}, 'TieScalarCounter', "L\x{e1}tin1";
	tie $list2->[1]->{comment}, 'TieScalarCounter', "L\x{e1}tin1";
	tie $list3->[0]->{user}, 'TieScalarCounter', "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}";
	tie $list3->[0]->{host}, 'TieScalarCounter', "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}";
	tie $list3->[0]->{phrase}, 'TieScalarCounter', "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}";
	tie $list3->[0]->{comment}, 'TieScalarCounter', "\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}";
	tie $list4->[0]->{user}, 'TieScalarCounter', "L\x{e1}tin1";
	tie $list4->[0]->{host}, 'TieScalarCounter', "L\x{e1}tin1";
	tie $list4->[0]->{phrase}, 'TieScalarCounter', "L\x{e1}tin1";
	tie $list4->[0]->{comment}, 'TieScalarCounter', "L\x{e1}tin1";
	is(
		format_email_groups($str1 => $list1, $str2 => $list2),
		"str1: ASCII <ASCII\@ASCII> (ASCII), \x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404} <ASCII\@L\x{e1}tin1> (ASCII);, str2: \x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404} <\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}\@\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}> (\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}), L\x{e1}tin1 <L\x{e1}tin1\@L\x{e1}tin1> (L\x{e1}tin1);",
		'test function format_email_groups() with magic scalars in ASCII, Latin1 and UNICODE',
	);
	is(
		format_email_groups($str3 => $list3),
		"str3: \x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404} <\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}\@\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404}> (\x{1d414}\x{1d40d}\x{1d408}\x{1d402}\x{1d40e}\x{1d403}\x{1d404});",
		'test function format_email_groups() with magic scalars in UNICODE',
	);
	is(
		format_email_groups($str4 => $list4),
		"str4: L\x{e1}tin1 <L\x{e1}tin1\@L\x{e1}tin1> (L\x{e1}tin1);",
		'test function format_email_groups() with magic scalars in Latin1',
	);
	is(
		format_email_groups($str5 => []),
		'',
		'test function format_email_groups() with magic scalar which is undef',
	);
	is(tied($str1)->{fetch}, 1, 'test function format_email_groups() that called GET magic exacly once');
	is(tied($str2)->{fetch}, 1, 'test function format_email_groups() that called GET magic exacly once');
	is(tied($str3)->{fetch}, 1, 'test function format_email_groups() that called GET magic exacly once');
	is(tied($str4)->{fetch}, 1, 'test function format_email_groups() that called GET magic exacly once');
	is(tied($str1)->{store}, 0, 'test function format_email_groups() that did not call SET magic');
	is(tied($str2)->{store}, 0, 'test function format_email_groups() that did not call SET magic');
	is(tied($str3)->{store}, 0, 'test function format_email_groups() that did not call SET magic');
	is(tied($str4)->{store}, 0, 'test function format_email_groups() that did not call SET magic');
	is(tied($str5)->{fetch}, 1, 'test function format_email_groups() that called GET magic exacly once');
	is(tied($str5)->{store}, 0, 'test function format_email_groups() that did not call SET magic');
	foreach ( @{$list1}, @{$list2}, @{$list3}, @{$list4} ) {
		is(tied($_->{user})->{fetch}, 1, 'test function format_email_groups() that called GET magic exacly once');
		is(tied($_->{host})->{fetch}, 1, 'test function format_email_groups() that called GET magic exacly once');
		is(tied($_->{phrase})->{fetch}, 1, 'test function format_email_groups() that called GET magic exacly once');
		is(tied($_->{comment})->{fetch}, 1, 'test function format_email_groups() that called GET magic exacly once');
		is(tied($_->{user})->{store}, 0, 'test function format_email_groups() that did not call SET magic');
		is(tied($_->{host})->{store}, 0, 'test function format_email_groups() that did not call SET magic');
		is(tied($_->{phrase})->{store}, 0, 'test function format_email_groups() that did not call SET magic');
		is(tied($_->{comment})->{store}, 0, 'test function format_email_groups() that did not call SET magic');
	}
}

#########################

{

	is_deeply(
		[ with_warning { parse_email_groups(undef) } ],
		[],
		'test function parse_email_groups() with undef argument',
	);

	is_deeply(
		[ parse_email_groups('') ],
		[],
		'test function parse_email_groups() on empty string',
	);

	is_deeply(
		[ parse_email_groups('incorrect') ],
		[
			undef() => [
				Email::Address::XS->new(phrase => 'incorrect'),
			],
		],
		'test function parse_email_groups() on incorrect string',
	);

	is_deeply(
		[ parse_email_groups('winston.smith@recdep.minitrue', 'Email::Address::XS::Derived') ],
		[
			undef() => [
				bless({ phrase => undef, user => 'winston.smith', host => 'recdep.minitrue', comment => undef }, 'Email::Address::XS::Derived'),
			],
		],
		'test function parse_email_groups() with second derived class name argument',
	);

	is_deeply(
		[ with_warning { parse_email_groups('winston.smith@recdep.minitrue', 'Email::Address::XS::NotDerived') } ],
		[],
		'test function parse_email_groups() with second not derived class name argument',
	);

	is_deeply(
		[ parse_email_groups('=?US-ASCII?Q?MIME=3A=3B?= : =?US-ASCII?Q?Winston=3A_Smith?= <winston.smith@recdep.minitrue>, =?US-ASCII?Q?Julia=3A=3B_?= <julia@ficdep.minitrue> ;') ],
		[
			'=?US-ASCII?Q?MIME=3A=3B?=' => [
				Email::Address::XS->new(phrase => '=?US-ASCII?Q?Winston=3A_Smith?=', address => 'winston.smith@recdep.minitrue'),
				Email::Address::XS->new(phrase => '=?US-ASCII?Q?Julia=3A=3B_?=', address => 'julia@ficdep.minitrue'),
			],
		],
		'test function parse_email_groups() on MIME string with encoded colons and semicolons',
	);

	is_deeply(
		[ parse_email_groups("\"\x{2764} \x{2600}\": \"\x{2606} \x{2602}\" <\"\x{263b} \x{265e}\"\@\x{262f}.\x{262d}> (\x{2622} \x{20ac});") ],
		[ "\x{2764} \x{2600}" => [ Email::Address::XS->new(phrase => "\x{2606} \x{2602}", user => "\x{263b} \x{265e}", host => "\x{262f}.\x{262d}", comment => "\x{2622} \x{20ac}") ] ],
		'test function parse_email_groups() that preserve unicode characters and UTF-8 status flag',
	);

	is_deeply(
		[ parse_email_groups('"Ministry of \\"Truth\\"": "Winston Smith" ( <user@oceania>, (Julia _ (Unknown)) <julia_(outer(.)party)@ficdep.minitrue>, ) <winston.smith@recdep.minitrue>, (leading comment) Julia <julia@ficdep.minitrue>;, "Thought Police" (group name comment) : O\'Brien <o\'brien@thought.police.oceania>, Mr. (c)Charrington <(mr.)"charrington\\"@\\"shop"@thought.police.oceania> (junk shop);, user@oceania (unknown_display_name in comment), "Escape \" also , characters" <user2@oceania>, undisclosed-recipients:;, user3@oceania (nested (comment)), Brotherhood(s):"Emmanuel Goldstein"<goldstein@brotherhood.oceania>; , "users@oceania" : "user5@oceania\\" <user6@oceania> , \\"" <user4@oceania>;, "":;' ) ],
		[
			'Ministry of "Truth"' => [
				Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue'),
				Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue'),
			],
			'Thought Police' => [
				Email::Address::XS->new(phrase => "O'Brien", user => "o'brien", host => 'thought.police.oceania'),
				Email::Address::XS->new(phrase => 'Mr. Charrington', user => 'charrington"@"shop', host => 'thought.police.oceania', comment => 'junk shop'),
			],
			undef() => [
				Email::Address::XS->new(address => 'user@oceania', comment => 'unknown_display_name in comment'),
				Email::Address::XS->new(phrase => 'Escape " also , characters', address => 'user2@oceania'),
			],
			'undisclosed-recipients' => [],
			undef() => [
				Email::Address::XS->new(address => 'user3@oceania', comment => 'nested (comment)'),
			],
			Brotherhood => [
				Email::Address::XS->new(phrase => 'Emmanuel Goldstein', address => 'goldstein@brotherhood.oceania'),
			],
			'users@oceania' => [
				Email::Address::XS->new(phrase => 'user5@oceania" <user6@oceania> , "', address => 'user4@oceania'),
			],
			"" => [],
		],
		'test function parse_email_groups() on string with nested comments and quoted characters',
	);

}

#########################

{
	is_deeply(
		[ parse_email_groups("\"string1\\\x00string2\"") ],
		[ undef() => [ Email::Address::XS->new(phrase => "string1\x00string2") ] ],
		'test function parse_email_groups() on string with nul character',
	);
	is_deeply(
		[ parse_email_groups("\"\\\x00string1\\\x00string2\"") ],
		[ undef() => [ Email::Address::XS->new(phrase => "\x00string1\x00string2") ] ],
		'test function parse_email_groups() on string which begins with nul character',
	);
	is_deeply(
		[ parse_email_groups("\"string1\\\x00string2\\\x00\"") ],
		[ undef() => [ Email::Address::XS->new(phrase => "string1\x00string2\x00") ] ],
		'test function parse_email_groups() on string which ends with nul character',
	);
	is_deeply(
		[ parse_email_groups(qq("\\\t" <"\\\t"\@host>)) ],
		[ undef() => [ Email::Address::XS->new(phrase => "\t", user => "\t", host => 'host') ] ],
		'test function parse_email_groups() on string with TAB characters',
	);
	is(
		format_email_groups(undef() => [ Email::Address::XS->new(phrase => "string1\x00string2", user => 'user', host => 'host') ]),
		"\"string1\\\x00string2\" <user\@host>",
		'test function format_email_groups() with nul character in phrase',
	);
	is(
		format_email_groups(undef() => [ Email::Address::XS->new(phrase => "\x00string1\x00string2\x00", user => 'user', host => 'host') ]),
		"\"\\\x00string1\\\x00string2\\\x00\" <user\@host>",
		'test function format_email_groups() with nul character in phrase',
	);
	is(
		format_email_groups(undef() => [ Email::Address::XS->new(user => "string1\x00string2", host => 'host') ]),
		"\"string1\\\x00string2\"\@host",
		'test function format_email_groups() with nul character in user part of address',
	);
	is(
		format_email_groups(undef() => [ Email::Address::XS->new(user => "\x00string1\x00string2\x00", host => 'host') ]),
		"\"\\\x00string1\\\x00string2\\\x00\"\@host",
		'test function format_email_groups() with nul character in user part of address',
	);
	is(
		with_warning { format_email_groups(undef() => [ Email::Address::XS->new(user => 'user', host => "string1\x00string2") ]) },
		'',
		'test function format_email_groups() with nul character in host part of address',
	);
	is(
		with_warning { format_email_groups(undef() => [ Email::Address::XS->new(user => 'user', host => "\x00string1\x00string2\x00") ]) },
		'',
		'test function format_email_groups() with nul character in host part of address',
	);
	is(
		format_email_groups(undef() => [ Email::Address::XS->new(user => 'user', host => 'host', comment => "string1\\\x00string2") ]),
		"user\@host (string1\\\x00string2)",
		'test function format_email_groups() with nul character in comment',
	);
	is(
		format_email_groups(undef() => [ Email::Address::XS->new(user => 'user', host => 'host', comment => "\\\x00string1\\\x00string2\\\x00") ]),
		"user\@host (\\\x00string1\\\x00string2\\\x00)",
		'test function format_email_groups() with nul character in comment',
	);
	is(
		format_email_groups(undef() => [ Email::Address::XS->new(user => qq("\\\x00\t\n\r), host => 'host') ]),
		qq("\\"\\\\\\\x00\\\t\\\n\\\r"\@host),
		'test function format_email_groups() with lot of non-qtext characters in user part of address'
	);
}

#########################

{
	tie my $input, 'TieScalarCounter', 'winston.smith@recdep.minitrue';
	is_deeply(
		[ parse_email_groups($input) ],
		[
			undef() => [
				bless({ phrase => undef, user => 'winston.smith', host => 'recdep.minitrue', comment => undef }, 'Email::Address::XS::Derived'),
			],
		],
		'test function parse_email_groups() with magic scalar',
	);
	is(tied($input)->{fetch}, 1, 'test function parse_email_groups() that called GET magic exacly once');
	is(tied($input)->{store}, 0, 'test function parse_email_groups() that did not call SET magic');
}

#########################

{

	my $undef = undef;
	my $str = 'str';
	my $str_ref = \$str;
	my $address = Email::Address::XS->new();
	my $address_ref = \$address;
	my $derived = Email::Address::XS::Derived->new();
	my $not_derived = Email::Address::XS::NotDerived->new();

	ok(!Email::Address::XS->is_obj(undef), 'test method is_obj() on undef');
	ok(!Email::Address::XS->is_obj('string'), 'test method is_obj() on string');
	ok(!Email::Address::XS->is_obj($undef), 'test method is_obj() on undef variable');
	ok(!Email::Address::XS->is_obj($str), 'test method is_obj() on string variable');
	ok(!Email::Address::XS->is_obj($str_ref), 'test method is_obj() on string reference');
	ok(Email::Address::XS->is_obj($address), 'test method is_obj() on Email::Address::XS object');
	ok(!Email::Address::XS->is_obj($address_ref), 'test method is_obj() on reference of Email::Address::XS object');
	ok(Email::Address::XS->is_obj($derived), 'test method is_obj() on Email::Address::XS derived object');
	ok(!Email::Address::XS->is_obj($not_derived), 'test method is_obj() on Email::Address::XS not derived object');

}

#########################

package Email::Address::XS::Derived;

use base 'Email::Address::XS';

sub user {
	my ($self, @args) = @_;
	$args[0] .= "_derived_suffix" if @args and defined $args[0];
	return $self->SUPER::user(@args);
}

package Email::Address::XS::NotDerived;

sub new {
	return bless {};
}

sub user {
	return 'not_derived';
}

#########################

package TieScalarCounter;

sub TIESCALAR {
	my ($class, $value) = @_;
	return bless { fetch => 0, store => 0, value => $value }, $class;
}

sub FETCH {
	my ($self) = @_;
	$self->{fetch}++;
	return $self->{value};
}

sub STORE {
	my ($self, $value) = @_;
	$self->{store}++;
	$self->{value} = $value;
}
