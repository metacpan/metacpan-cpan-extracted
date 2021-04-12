
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<skip> method of L<LINQ::Iterator>.

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

my $collection = LINQ [
	"Aardvark",
	"Aardwolf",
	"Bee",
	"Cat",
	"Dog",
	"Elephant",
];

is_deeply(
	$collection->skip( 3 )->to_array,
	[qw/ Cat Dog Elephant /],
	'skip(3)',
);

is_deeply(
	$collection->skip( 0 )->to_array,
	$collection->to_array,
	'skip(0)',
);

is_deeply(
	$collection->skip( -1 )->to_array,
	$collection->to_array,
	'skip(-1)',
);

is_deeply(
	$collection->skip( 1000 )->to_array,
	[],
	'skip(1000)',
);

done_testing;
