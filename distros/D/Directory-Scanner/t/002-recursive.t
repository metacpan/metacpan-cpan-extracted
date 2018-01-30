#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

BEGIN {
	use_ok('Directory::Scanner');
}

my $ROOT = $FindBin::Bin.'/data/';

subtest '... basic recursive stream test' => sub {

	my $stream = Directory::Scanner->for( $ROOT )->recurse;
	isa_ok($stream, 'Directory::Scanner::Stream::Recursive');

	ok(!$stream->is_done, '... the stream is not done');
	ok(!$stream->is_closed, '... the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	my @all;
	while ( my $i = $stream->next ) {
		push @all => $i->relative( $ROOT );
		is($i, $stream->head, '... the head is the same as the value returned by next');
	}

	is_deeply(
		[ sort @all ],
		[qw[
			lib
			lib/Foo
			lib/Foo.pm
			lib/Foo/Bar
			lib/Foo/Bar.pm
			lib/Foo/Bar/Baz.pm
			t
			t/000-load.pl
			t/001-basic.pl
		]],
		'... got the list of directories'
	);

	ok($stream->is_done, '... the stream is done');
	ok(!$stream->is_closed, '... but the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	is(exception { $stream->close }, undef, '... closed stream successfully');

	ok($stream->is_closed, '... the stream is closed');
};

subtest '... basic recursive stream test using flatten' => sub {

	my $stream = Directory::Scanner->for( $ROOT )->recurse;
	isa_ok($stream, 'Directory::Scanner::Stream::Recursive');

	ok(!$stream->is_done, '... the stream is not done');
	ok(!$stream->is_closed, '... the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	my @all = map $_->relative( $ROOT ), $stream->flatten;

	is_deeply(
		[ sort @all ],
		[qw[
			lib
			lib/Foo
			lib/Foo.pm
			lib/Foo/Bar
			lib/Foo/Bar.pm
			lib/Foo/Bar/Baz.pm
			t
			t/000-load.pl
			t/001-basic.pl
		]],
		'... got the list of directories'
	);

	ok($stream->is_done, '... the stream is done');
	ok(!$stream->is_closed, '... but the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	is(exception { $stream->close }, undef, '... closed stream successfully');

	ok($stream->is_closed, '... the stream is closed');
};

done_testing;
