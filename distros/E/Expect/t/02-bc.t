
use strict;
use warnings;

use Test::More;
use Expect;
plan skip_all => 'See https://rt.cpan.org/Ticket/Display.html?id=98495';

my $bc = '/usr/bin/bc';
if ( not -x $bc ) {
	diag "Could not find bc in $bc";
	my $which = `which bc`;
	diag "which bc: '$which'";
	plan skip_all => "Need to have $bc installed to run this test";
}

plan tests => 2;

if ($^O !~ /^(openbsd|solaris|midnightbsd|dragonfly)$/) {
	my $bc_version = `$bc -v`;
	diag "--------- bc version on $^O";
	diag $bc_version;
	diag '---------';
	# just some notes:
	# on the systems with the above 'osname', bc does not have any banner (the warranty stuff)
	# and the also don't have a -v flag
}

subtest raw_pty_bc => sub {

	if ($^O =~ /^(openbsd|netbsd|freebsd|solaris|darwin|midnightbsd|dragonfly)$/) {
		plan skip_all => "This test fails on \$^O == \$Config{'osname'} == '$^O'";
	}

	#if ($^O =~ /^(darwin)$/) {
	#	diag "This test will almost certainly fail on \$^O == \$Config{'osname'} == '$^O'. You can install the module skipping this test, but please report the failure.";
	#	#plan skip_all => "This test fails on $^O";
	#}

	plan tests => 3;

	my $e = Expect->new;
	$e->raw_pty(1);

	$e->spawn($bc) or die "Cannot run bc\n";
	my $warranty;
	$e->expect( 1, [qr/warranty'\./ => sub { $warranty = 1 } ] );
	ok $warranty, 'warranty found' or do {
		diag $e->before;
		return;
	};
	$e->send("23+7\n");
	my $num;
	$e->expect( 1, [qr/\d+/ => sub { $num = 1 }] );
	ok $num, 'number found' or do {
		diag $e->before;
		return;
	};
	my $match = $e->match;
	is $match, 30, 'the number';
	$e->send("quit\n");
};

subtest pty_bc => sub {
	plan tests => 6;

	my $e = Expect->new;

	$e->spawn($bc) or die "Cannot run bc\n";
	my $warranty;
	$e->expect( 1, [qr/warranty'\./ => sub { $warranty = 1 } ] );

	SKIP: {
		skip "No banner on $^O ", 1 if $^O =~ /^(openbsd|freebsd|netbsd|solaris|midnightbsd|dragonfly)$/;
		ok $warranty, 'warranty found' or do {
			diag $e->before;
			return;
		};
	}

	$e->send("23+7\n");
	my $expr;
	$e->expect( 1, [qr/23\+7/ => sub { $expr = 1 }] );
	ok $expr, 'echo input';

	my $num;
	$e->expect( 1, [qr/\d+/ => sub { $num = 1 }] );
	ok $num, 'number found' or do {
		diag $e->before;
		return;
	};
	my $match = $e->match;
	is $match, 30, 'the number';
	my $EMPTY = qr/^[\r\n]*$/;
	like $e->before, $EMPTY, 'before';
	like $e->after,  $EMPTY, 'after';
	$e->send("quit\n");
};


