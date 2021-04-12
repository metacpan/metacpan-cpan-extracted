
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<group_by> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );

my $c = LINQ [ map +{ i => $_ }, 1 .. 10 ];

object_ok(
	$c->group_by( sub { $_->{i} % 3 } ),
	'$groups',
	does => ['LINQ::Collection'],
	more => sub {
		my ( $g0, $g1, $g2 ) = @{ shift->order_by( sub { $_->key } )->to_array };
		
		object_ok(
			$g0,
			'$g0',
			does => ['LINQ::Grouping'],
			more => sub {
				my $g0 = shift;
				is( $g0->key, 0 );
				is_deeply(
					$g0->values->to_array,
					[
						{ i => 3 },
						{ i => 6 },
						{ i => 9 },
					],
				);
			},
		);
		
		object_ok(
			$g1,
			'$g1',
			does => ['LINQ::Grouping'],
			more => sub {
				my $g1 = shift;
				is( $g1->key, 1 );
				is_deeply(
					$g1->values->to_array,
					[
						{ i => 1 },
						{ i => 4 },
						{ i => 7 },
						{ i => 10 },
					],
				);
			},
		);
		
		object_ok(
			$g2,
			'$g2',
			does => ['LINQ::Grouping'],
			more => sub {
				my $g2 = shift;
				is( $g2->key, 2 );
				is_deeply(
					$g2->values->to_array,
					[
						{ i => 2 },
						{ i => 5 },
						{ i => 8 },
					],
				);
			},
		);
	},
);

done_testing;
