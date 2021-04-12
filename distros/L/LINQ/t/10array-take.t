
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<take> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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
	$collection->take( 3 )->to_array,
	[qw/ Aardvark Aardwolf Bee /],
	'take(3)',
);

is_deeply(
	$collection->take( 0 )->to_array,
	[],
	'take(0)',
);

is_deeply(
	$collection->take( -1 )->to_array,
	[],
	'take(-1)',
);

is_deeply(
	$collection->take( 1000 )->to_array,
	$collection->to_array,
	'take(0)',
);

done_testing;
