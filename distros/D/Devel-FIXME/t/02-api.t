#!/usr/bin/perl -T
# taint mode is to override idiomatic PERL5OPT=-MFIXME, and other attrocities

use strict;
use warnings;

use Test::Most tests => 31;
use Test::NoWarnings;

my @orig = @INC;
local @INC = @INC;
	
require_ok("Devel::FIXME");

is_deeply(\@INC, \@orig, "\@INC isn't yet changed");

my (@shouts,@readfiles);

{
	package Devel::FIXME::Test;
	use base qw/Devel::FIXME/;

	sub shout {
		push @shouts, \@_;
	}

	sub readfile {
		push @readfiles, \@_;
	}

	our @rules;
	sub rules { @rules };
}

	
Devel::FIXME::Test->import;

is(ref $INC[0], "CODE", "\$INC[0] is a CODE ref");
my $code = $INC[0];
is_deeply([ grep { ref } @INC[1 .. $#INC] ], [], "no other refs in \@INC (relying on taint mode to ensure this)");

is_deeply([ map { $_->[1] } @readfiles ], [ $0, sort grep { $_ ne $INC{'Devel/FIXME.pm'} } values %INC ], "\%INC files were read on import");

@readfiles = ();


Devel::FIXME::Test->import;

is_deeply($INC[0], $code, "\$INC[0] is the same as it was before the second import");
is_deeply([ grep { ref } @INC[1 .. $#INC] ], [], "still no other refs in \@INC");

is_deeply([ map { $_->[1] } @readfiles ], [], "did not read all of \%INC a second time");

@readfiles = ();


{
	no warnings 'redefine';

	package foo;

	use Test::Most;
	
	ok(!$::{SHOUT}, "SHOUT has not yet been imported");
	Devel::FIXME->import(qw/SHOUT/);
	is(\&SHOUT, \&Devel::FIXME::SHOUT, "SHOUT was imported");

	ok(!$::{DROP}, "DROP has not yet been imported");
	Devel::FIXME->import(qw/SHOUT DROP/);
	is(\&DROP, \&Devel::FIXME::DROP, "DROP was imported");

	ok(!$::{CONT}, "CONT has not yet been imported");
	Devel::FIXME->import(qw/:constants/);
	is(\&CONT, \&Devel::FIXME::CONT, "CONT was imported");
}

@shouts = ();

Devel::FIXME::Test->FIXME("foo");
@shouts = grep { $_->[0]{file} eq __FILE__ } @shouts; # generates one from AutoLoader
is_deeply(\@shouts, [ [ Devel::FIXME::Test->new({
	text => "foo",
	file => __FILE__,
	line => __LINE__ - 5,
	package => __PACKAGE__,
	script => $0,
	time => $shouts[0][0]{time},
}) ] ], "->FIXME('foo') object is shouted");

@shouts = ();


Devel::FIXME::Test->import({ text => "glunk" });
is_deeply(\@shouts, [ [ Devel::FIXME::Test->new({
		text => "glunk",
		file => __FILE__,
		line => __LINE__ - 4,
		package => __PACKAGE__,
		script => $0,
		time => $shouts[0][0]{time},
	}) ] ], "use Devel::FIXME 'laadi'; object is shouted using import interface");

@shouts = ();


Devel::FIXME::Test->import("laadi");
is_deeply(\@shouts, [ [ Devel::FIXME::Test->new({
		text => "laadi",
		file => __FILE__,
		line => __LINE__ - 4,
		package => __PACKAGE__,
		script => $0,
		time => $shouts[0][0]{time},
	}) ] ], "use Devel::FIXME 'laadi'; object is shouted using import interface");

@shouts = ();

{
	no warnings qw/redefine/;
	local *Devel::FIXME::shout = \&Devel::FIXME::Test::shout;


	Devel::FIXME::FIXME(5);
	is_deeply(\@shouts, [ [ Devel::FIXME::Test->new({
			text => 5,
			file => __FILE__,
			line => __LINE__ - 4,
			package => __PACKAGE__,
			script => $0,
			time => $shouts[0][0]{time},
		}) ] ], "::FIXME(5) object is shouted");

	@shouts = ();


	Devel::FIXME::FIXME("Scalar::Util");
	is_deeply(\@shouts, [ [ Devel::FIXME::Test->new({
			text => "Scalar::Util",
			file => __FILE__,
			line => __LINE__ - 4,
			package => __PACKAGE__,
			script => $0,
			time => $shouts[0][0]{time},
		}) ] ], "::FIXME('Scalar::Util') object is shouted");

	@shouts = ();


	Devel::FIXME::FIXME("Some::Class");
	is_deeply(\@shouts, [ [ Devel::FIXME::Test->new({
			text => "Some::Class",
			file => __FILE__,
			line => __LINE__ - 4,
			package => __PACKAGE__,
			script => $0,
			time => $shouts[0][0]{time},
		}) ] ], "::FIXME('Some::Class') object is shouted");

	@shouts = ();


	Devel::FIXME::FIXME("blart");
	is_deeply(\@shouts, [ [ Devel::FIXME::Test->new({
			text => "blart",
			file => __FILE__,
			line => __LINE__ - 4,
			package => __PACKAGE__,
			script => $0,
			time => $shouts[0][0]{time},
		}) ] ], "::FIXME('blart') object is shouted");

	@shouts = ();


	Devel::FIXME::FIXME("Devel::FIXME::Test", "bloog");
	is_deeply(\@shouts, [ [ Devel::FIXME::Test->new({
			text => "bloog",
			file => __FILE__,
			line => __LINE__ - 4,
			package => __PACKAGE__,
			script => $0,
			time => $shouts[0][0]{time},
		}) ] ], "::FIXME('Devel::FIXME::Test', 'blart') object is shouted");

	@shouts = ();


	Devel::FIXME::FIXME(text => "yaap");
	is_deeply(\@shouts, [ [ Devel::FIXME::Test->new({
			text => "yaap",
			file => __FILE__,
			line => __LINE__ - 4,
			package => __PACKAGE__,
			script => $0,
			time => $shouts[0][0]{time},
		}) ] ], "::FIXME(text => 'yaap') object is shouted");

	@shouts = ();

}

@shouts = ();

my $called;
my $uncalled = 1; 
@Devel::FIXME::Test::rules = (sub { $called = 1; Devel::FIXME::DROP() }, sub { $uncalled = undef; Devel::FIXME::SHOUT() });

Devel::FIXME::Test->FIXME("moose");
ok($called, "Rule 1 was evaluated");
ok($uncalled, "Rule 2 was not evaluated, because Rule 1 DROPped");
is_deeply(\@shouts, [ ], "FIXME wasn't shouted due to rule");


@shouts = ();
$called = undef;

@Devel::FIXME::Test::rules = (sub { $called = 1; Devel::FIXME::SHOUT() });
Devel::FIXME::Test->FIXME("bargorch");
ok($called, "Rule was evaluated");
is_deeply(\@shouts, [ [ Devel::FIXME::Test->new(
		text => "bargorch",
		file => __FILE__,
		line => __LINE__ - 5,
		package => __PACKAGE__,
		script => $0,
		time => $shouts[0][0]{time},
	) ] ], "FIXME object is shouted, due to rule");

@shouts = ();
$called = undef;

@Devel::FIXME::Test::rules = (
	sub { $called++; Devel::FIXME::CONT() },
	sub { $called++; Devel::FIXME::CONT() },
);

Devel::FIXME::Test->msg("quxxly");
is($called, 2, "Rule was evaluated");
is_deeply(\@shouts, [ [ Devel::FIXME::Test->new(
		text => "quxxly",
		file => __FILE__,
		line => __LINE__ - 5,
		package => __PACKAGE__,
		script => $0,
		time => $shouts[0][0]{time},
	) ] ], "FIXME object is shouted, due to default fall back");
