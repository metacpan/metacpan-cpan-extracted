
=pod

=encoding utf-8

=head1 PURPOSE

Check the LINQ::Iterator constructor.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ ();
use LINQ::Iterator ();

my $CLASS = 'LINQ::Iterator';

my @c1 = qw( 3 5 2 );
my $c1 = $CLASS->new( sub {
	my $multiplier = shift;
	return LINQ::END unless @c1;
	$multiplier * shift( @c1 );
}, 4 );

object_ok(
	$c1, '$c1',
	isa  => $CLASS,
	does => 'LINQ::Collection',
	more => sub {

		is_deeply(
			$c1->to_array,
			[ 12, 20, 8 ],
			'->to_array',
		);

		is(
			$c1->to_array->[3],
			undef,
			'undef'
		);
		
		my $iter = $c1->to_iterator;
		my @calls;
		for ( 1 .. 5 ) {
			push @calls, [ $iter->() ];
		}
		is_deeply(
			\@calls,
			[
				[ 12 ],
				[ 20 ],
				[ 8 ],
				[],
				[],
			],
			'Calling exhausted iterator gives empty list.'
		);

		ok(
			$c1->_guts,
			'Iterator still has its guts',
		);

		is_deeply(
			[ $c1->to_list ],
			[ 12, 20, 8 ],
			'->to_list',
		);

		ok(
			! $c1->_guts,
			'Iterator lost its guts',
		);

		is_deeply(
			[ $c1->to_list ],
			[ 12, 20, 8 ],
			'->to_list',
		);
	},
);


object_ok(
	exception { $CLASS->new },
	'$e',
	isa    => 'LINQ::Exception::CallerError'
);

object_ok(
	exception { $CLASS->new( sub { LINQ::END, 1, 2, 3 } )->to_list },
	'$e',
	isa    => 'LINQ::Exception::CallerError',
	more   => sub {
		my $e = shift;
		like( $e->message, qr/Returned values after LINQ::END/i );
	},
);

{
	my @chunks = (
		[],
		[ 1, 2 ],
		[],
		[ 3 ],
		[ 4, 5, 6 ],
		[ LINQ::END() ],
		[ 99 ],
	);
	is_deeply(
		[ $CLASS->new( sub { @{ shift @chunks } } )->to_list ],
		[ 1 .. 6 ],
		'Weird chunky iterator',
	);
}

{
	my @chunks = (
		[],
		[ 1, 2 ],
		[],
		[ 3 ],
		[ 4, 5, 6 ],
		[ LINQ::END(), 7 ],
		[ 99 ],
	);
	my $e = exception {
		$CLASS->new( sub { @{ shift @chunks } } )->to_list;
	};
	like( $e, qr/Returned values after LINQ::END/, 'Weirder chunky iterator' );
}

done_testing;
