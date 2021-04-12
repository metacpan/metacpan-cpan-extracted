
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<join> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );
use DisneyData qw( people pets );

my $smush = sub {
	my ( $person, $pet ) = @_;
	return [
		$person ? $person->id   : -1,
		$pet    ? $pet->id      : -1,
		$pet    ? $pet->species : undef,
	];
};

my $order = sub { join( ":", grep defined, @$_ ) };

{
	my $inner = people->join( pets, sub { $_ }, sub { $_->owner }, $smush );
	
	is_deeply(
		$inner->order_by( -string, $order )->to_array,
		[
			[qw/ 3 1 Reindeer /],
			[qw/ 4 3 Rabbit /],
			[qw/ 4 4 Robin /],
			[qw/ 4 5 Bluebird /],
			[qw/ 5 2 Chameleon /],
		],
		'inner join',
	);
}

{
	my $left = people->join( pets, -left, sub { $_ }, sub { $_->owner }, $smush );
	
	is_deeply(
		$left->order_by( -string, $order )->to_array,
		[
			[ 1, -1, undef ],    # Olaf doesn't count
			[ 2, -1, undef ],    # Marshmallow doesn't count
			[qw/ 3 1 Reindeer /],
			[qw/ 4 3 Rabbit /],
			[qw/ 4 4 Robin /],
			[qw/ 4 5 Bluebird /],
			[qw/ 5 2 Chameleon /],
		],
		'left outer join',
	);
}

{
	my $right = people->join( pets, -right, sub { $_ }, sub { $_->owner }, $smush );
	
	is_deeply(
		$right->order_by( -string, $order )->to_array,
		[
			[qw/ -1 6 Dog /],
			[qw/ 3 1 Reindeer /],
			[qw/ 4 3 Rabbit /],
			[qw/ 4 4 Robin /],
			[qw/ 4 5 Bluebird /],
			[qw/ 5 2 Chameleon /],
		],
		'right outer join',
	);
}

{
	my $outer = people->join( pets, -outer, sub { $_ }, sub { $_->owner }, $smush );
	
	is_deeply(
		$outer->order_by( -string, $order )->to_array,
		[
			[qw/ -1 6 Dog /],
			[ 1, -1, undef ],
			[ 2, -1, undef ],
			[qw/ 3 1 Reindeer /],
			[qw/ 4 3 Rabbit /],
			[qw/ 4 4 Robin /],
			[qw/ 4 5 Bluebird /],
			[qw/ 5 2 Chameleon /],
		],
		'outer join',
	);
}

done_testing;
