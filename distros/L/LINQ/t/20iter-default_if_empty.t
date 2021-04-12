
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<default_if_empty> method of L<LINQ::Iterator>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ qw( LINQ );

my $collection = LINQ [
	"Bee",
	"Cat",
	"Dog",
];

is_deeply(
	$collection->default_if_empty( "Fox" )->to_array,
	[qw/ Bee Cat Dog /],
	'default_if_empty on non-empty collection',
);

$collection = LINQ [];

is_deeply(
	$collection->default_if_empty( "Fox" )->to_array,
	[qw/ Fox /],
	'default_if_empty on empty collection',
);

done_testing;
