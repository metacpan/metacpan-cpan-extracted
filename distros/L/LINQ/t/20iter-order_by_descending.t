
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<order_by_descending> method of L<LINQ::Iterator>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ qw( LINQ );

my $c = LINQ [
	{ foo => 9 },
	{ foo => 8 },
	{ foo => 7 },
	{ foo => 56 },
	{ foo => 1234 },
];

is_deeply(
	$c->order_by_descending( sub { $_->{foo} } )->to_array,
	[
		reverse { foo => 7 },
		{ foo => 8 },
		{ foo => 9 },
		{ foo => 56 },
		{ foo => 1234 },
	],
);

is_deeply(
	$c->order_by_descending( -string, sub { $_->{foo} } )->to_array,
	[
		reverse { foo => 1234 },
		{ foo => 56 },
		{ foo => 7 },
		{ foo => 8 },
		{ foo => 9 },
	],
);

is_deeply(
	$c->order_by_descending(
		sub { my $f = $_->{foo}; length( $f ) > 1 ? length( $f ) : $f }
	)->to_array,
	[
		reverse { foo => 56 },
		{ foo => 1234 },
		{ foo => 7 },
		{ foo => 8 },
		{ foo => 9 },
	],
);

done_testing;
