
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<LINQ> function exported by L<LINQ>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw(LINQ);

my $c1 = LINQ [ 1 .. 7 ];

is_deeply(
	$c1->to_array,
	[ 1 .. 7 ],
	'LINQ(ARRAY)',
);

my $c2 = do {
	my @remaining = reverse( 1 .. 10 );
	LINQ sub { return LINQ::END unless @remaining; pop @remaining };
};

is_deeply(
	$c2->to_array,
	[ 1 .. 10 ],
	'LINQ(CODE)',
);

is( LINQ( $c1 ), $c1, 'LINQ(Collection)' );

my $e1 = exception {
	my $r = LINQ( {} );
};

ok(
	$e1 && $e1->isa( 'LINQ::Exception::CallerError' ),
	'LINQ({}) is a caller error.'
);

my $e2 = exception {
	my $r = LINQ( bless( {}, 'Dummy::Class' ) );
};

ok(
	$e2 && $e2->isa( 'LINQ::Exception::CallerError' ),
	'LINQ($random_object) is a caller error.'
);

done_testing;
