#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Devel::Events::Filter::Size';

use Devel::Events::Handler::Callback;

use Devel::Size;
my $has_size_report = eval { require Devel::Size::Report; 1 };

{
	my $f = Devel::Events::Filter::Size->new(
		fields => "foo",
		no_report => !$has_size_report,
		handler => Devel::Events::Handler::Callback->new(sub {}),
	);

	my ( $type, %fields ) = ( $f->filter_event( blah => foo => [ 1, 2, [ 3, 4 ] ], bar => [ 3, 4 ], gorch => { baz => [ 1, 2, 3 ] } ) );

	is( $fields{size}, Devel::Size::size($fields{foo}), "size" );

	is( $fields{total_size}, Devel::Size::total_size($fields{foo}), "total size" );

	SKIP: {
		skip "No Devel::Size::Report" => 1 unless $has_size_report;
		ok( length($fields{size_report}), "size report" );
	}
}

{
	my $f = Devel::Events::Filter::Size->new(
		fields => [qw/foo bar/],
		no_report => !$has_size_report,
		handler => Devel::Events::Handler::Callback->new(sub {}),
	);

	my ( $type, %fields ) = ( $f->filter_event( blah => foo => [ 1, 2, [ 3, 4 ] ], bar => [ 3, 4 ], gorch => { baz => [ 1, 2, 3 ] } ) );

	is( ref($fields{sizes}), "HASH", "sizes" );
	is( scalar( keys %{ $fields{sizes} } ), 2, "2 reports" );
	is( ref($fields{sizes}{bar}), "ARRAY", "size report for 'foo' fields" );
	is( $fields{sizes}{bar}[0]{size}, Devel::Size::size($fields{bar}), "size report" );
}

{
	my $f = Devel::Events::Filter::Size->new(
		no_report => !$has_size_report,
		handler => Devel::Events::Handler::Callback->new(sub {}),
	);

	my ( $type, %fields ) = ( $f->filter_event( blah => foo => [ 1, 2, [ 3, 4 ] ], bar => [ 3, 4 ], gorch => { baz => [ 1, 2, 3 ] } ) );

	is( ref($fields{sizes}), "HASH", "sizes" );
	is( scalar( keys %{ $fields{sizes} } ), 3, "3 reports" );
	is( ref($fields{sizes}{bar}), "ARRAY", "size report for 'foo' fields" );
	is( $fields{sizes}{bar}[0]{size}, Devel::Size::size($fields{bar}), "size report" );
}
