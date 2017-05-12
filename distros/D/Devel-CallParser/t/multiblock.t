use warnings;
use strict;

BEGIN {
	if("$]" < 5.013007) {
		require Test::More;
		Test::More::plan(skip_all =>
			"parse_block not available on this Perl");
	}
}

use Test::More tests => 17;
use t::LoadXS ();
use t::WriteHeader ();

t::WriteHeader::write_header("callparser0", "t", "multiblock");
ok 1;
require_ok "Devel::CallParser";
t::LoadXS::load_xs("multiblock", "t",
	[Devel::CallParser::callparser_linkable()]);
ok 1;

my @events;

sub my_if($$$) { $_[0]->() ? $_[1]->() : $_[2]->() }
t::multiblock::cv_set_call_parser_multiblock(\&my_if);

@events = ();
eval q{
	push @events, "a";
	my $x = "x".my_if({
		1;
	} {
		"c";
	} {
		"d";
	})."z";
	push @events, $x;
	push @events, "e";
};
is $@, "";
is_deeply \@events, [ qw(a xcz e) ];

@events = ();
eval q{
	push @events, "a";
	my $x = "x".my_if({
		0;
	} {
		"c";
	} {
		"d";
	})."z";
	push @events, $x;
	push @events, "e";
};
is $@, "";
is_deeply \@events, [ qw(a xdz e) ];

@events = ();
eval q{
	push @events, "a";
	my_if {
		push @events, "b";
		1;
	} {
		push @events, "c";
	} {
		push @events, "d";
	}
	package main;
	push @events, "e";
};
is $@, "";
is_deeply \@events, [ qw(a b c e) ];

@events = ();
eval q{
	push @events, "a";
	my_if {
		push @events, "b";
		0;
	} {
		push @events, "c";
	} {
		push @events, "d";
	}
	package main;
	push @events, "e";
};
is $@, "";
is_deeply \@events, [ qw(a b d e) ];

@events = ();
eval q{
	push @events, "a";
	my $x = "x".my_if {
		1;
	} {
		"c";
	} {
		"d";
	}."z";
	push @events, $x;
	push @events, "e";
};
isnt $@, "";
is_deeply \@events, [];

@events = ();
eval q{
	push @events, "a";
	my_if {
		push @events, "b";
		0;
	} {
		push @events, "c";
	} {
		push @events, "d";
	} {
		123;
	}
	package main;
	push @events, "e";
};
isnt $@, "";
is_deeply \@events, [];

@events = ();
eval q{
	push @events, "a";
	my_if {
		push @events, "b";
		0;
	} {
		push @events, "c";
	}
	package main;
	push @events, "e";
};
isnt $@, "";
is_deeply \@events, [];

1;
