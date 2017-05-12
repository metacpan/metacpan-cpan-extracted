#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Devel::Events::Generator::SubTrace;

use Devel::Events::Handler::Callback;

my @events;

my $h = Devel::Events::Handler::Callback->new(sub {
	my ( $type, %args ) = @_;
	push @events, [ $type => $args{name}, ( $type eq 'enter_sub' ? $args{args}[0] : $args{ret} ) ];
});

my $o = Devel::Events::Generator::SubTrace->new( handler => $h );

sub bar { 42 + shift }
sub foo { bar(2) + bar(5) + shift }

$o->enable;

my $v = foo(3);

$o->disable;

is( $v, ( 42 + 2 + 42 + 5 + 3 ), "values unchanged" );

is_deeply(
	\@events,
	[
		[ enter_sub => 'main::foo' => 3 ],
			[ enter_sub => 'main::bar' => 2 ],
			[ leave_sub => 'main::bar' => 44 ],
			[ enter_sub => 'main::bar' => 5 ],
			[ leave_sub => 'main::bar' => 47 ],
		[ leave_sub => 'main::foo' => ( 47 + 44 + 3 ) ],
	],
	"call chain events",
);
