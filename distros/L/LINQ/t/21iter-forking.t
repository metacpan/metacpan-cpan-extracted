
=pod

=encoding utf-8

=head1 PURPOSE

Given an iterator LINQ, creates more iterators based on it, forces the original
iterator to be exhaused but checks the other iterators still have values.

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

my $counter = 0;
my $numbers = LINQ(
	sub {
		return LINQ::END if $counter > 100;
		++$counter;
	}
);

my $evens  = $numbers->where( sub { $_ % 2 == 0 } );
my $dozens = $numbers->where( sub { $_ % 12 == 0 } );

is(
	$counter,
	0,
	"Initial creation of new iterators hasn't called original iterator coderef yet."
);

is_deeply(
	$evens->element_at( 3 ),
	8,
	'$evens->element_at( 3 )'
);

is(
	$counter,
	8,
	"Reading from one of the child iterators hasn't advanced counter more than necessary."
);

is_deeply(
	$evens->element_at( 5 ),
	12,
	'$evens->element_at( 5 )'
);

is(
	$counter,
	12,
	"Reading more one of the child iterators hasn't advanced counter more than necessary."
);

is_deeply(
	$dozens->element_at( 3 ),
	48,
	'$dozens->element_at( 3 )'
);

is(
	$counter,
	48,
	"From the other child iterator hasn't advanced counter more than necessary."
);

ok(
	$numbers->contains( 100 ),
	'$numbers->contains( 100 )'
);

ok(
	$evens->contains( 100 ),
	'$evens->contains( 100 )'
);

ok(
	!$dozens->contains( 100 ),
	'! $dozens->contains( 100 )'
);

is_deeply(
	$dozens->to_array,
	[ 12, 24, 36, 48, 60, 72, 84, 96 ],
	'$dozens->to_array'
);

done_testing;
