=pod

=encoding utf-8

=head1 PURPOSE

Test the C<order_by> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );

my $d = LINQ [ 8, 4, 5, 12 ];

is_deeply(
	[ $d->order_by->to_list ],
	[ 4, 5, 8, 12 ],
	'Defaults to numeric sort',
);

is_deeply(
	[ $d->order_by( -numeric )->to_list ],
	[ 4, 5, 8, 12 ],
	'Explicit numeric sort',
);

object_ok(
	exception { $d->order_by( -boop )->to_list }, '$e',
	isa   => 'LINQ::Exception::CallerError',
	more  => sub {
		my $e = shift;
		like( $e->message, qr/Expected '-numeric' or '-string'; got '-boop'/ );
	},
);

is_deeply(
	[ $d->order_by( -string )->to_list ],
	[ 12, 4, 5, 8 ],
	'Explicit string sort',
);

my $c = LINQ [
	{ foo => 9 },
	{ foo => 8 },
	{ foo => 7 },
	{ foo => 56 },
	{ foo => 1234 },
];

is_deeply(
	$c->order_by( sub { $_->{foo} } )->to_array,
	[
		{ foo => 7 },
		{ foo => 8 },
		{ foo => 9 },
		{ foo => 56 },
		{ foo => 1234 },
	],
);

is_deeply(
	$c->order_by( -string, sub { $_->{foo} } )->to_array,
	[
		{ foo => 1234 },
		{ foo => 56 },
		{ foo => 7 },
		{ foo => 8 },
		{ foo => 9 },
	],
);

is_deeply(
	$c->order_by( sub { my $f = $_->{foo}; length( $f ) > 1 ? length( $f ) : $f } )
		->to_array,
	[
		{ foo => 56 },
		{ foo => 1234 },
		{ foo => 7 },
		{ foo => 8 },
		{ foo => 9 },
	],
);

done_testing;
