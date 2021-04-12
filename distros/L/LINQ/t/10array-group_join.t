
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<group_join> method of L<LINQ::Array>.

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
	my ( $person, $pets ) = @_;
	return [
		$person->id,
		$pets->count ? [ sort( map $_->id, $pets->to_list ) ] : undef,
	];
};

my $order = sub { $_->[0] };

{
	my $inner = people->group_join( pets, sub { $_ }, sub { $_->owner }, $smush );
	
	is_deeply(
		$inner->order_by( -numeric, $order )->to_array,
		[
			[ 3, [1] ],            # Kristoff just has Sven
			[ 4, [ 3, 4, 5 ] ],    # Sophia has three pets
			[ 5, [2] ],            # Rapunzel just has Pascal
		],
		'inner group join',
	);
}

{
	my $left =
		people->group_join( pets, -left, sub { $_ }, sub { $_->owner }, $smush );
		
	is_deeply(
		$left->order_by( -numeric, $order )->to_array,
		[
			[ 1, undef ],          # Anna has no pets
			[ 2, undef ],          # Elsa has no pets
			[ 3, [1] ],            # Kristoff just has Sven
			[ 4, [ 3, 4, 5 ] ],    # Sophia has three pets
			[ 5, [2] ],            # Rapunzel just has Pascal
		],
		'left outer group join',
	);
}

note
	"The behaviour of right outer group join and full outer group join is currently undefined.";
note "For now, they result in exceptions.";

{
	my $e = exception {
		people->group_join( pets, -right, sub { $_ }, sub { $_->owner }, $smush );
	};
	
	isa_ok( $e, 'LINQ::Exception::CallerError', '$e' );
}

{
	my $e = exception {
		people->group_join( pets, -outer, sub { $_ }, sub { $_->owner }, $smush );
	};
	
	isa_ok( $e, 'LINQ::Exception::CallerError', '$e' );
}

done_testing;
