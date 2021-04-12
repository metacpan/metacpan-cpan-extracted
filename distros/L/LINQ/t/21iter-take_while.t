
=pod

=encoding utf-8

=head1 PURPOSE

Given an iterator LINQ, checks exceptions get rethrown correctly.

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

my $c1 = LINQ( sub { die "My error" } )->take_while( sub { 1 } );
my $e1 = exception { $c1->to_list };

like(
	$e1,
	qr/My error/,
	'Stringy exception'
);

my $c2 = LINQ( sub { die bless( {}, 'My::Error' ) } )->take_while( sub { 1 } );
my $e2 = exception { $c2->to_list };

is(
	ref( $e2 ),
	'My::Error',
	'Blessed exception'
);

my $c3 = LINQ( sub { 4 } );
is(
	$c3->take(5)->count,
	5,
	'Taking five elements from an infinite iterator',
);
ok(
	$c3->_guts->current_extension > 4,
	'$collection->_guts->current_extension as expected',
);
ok(
	$c3->_guts->current_extension <= 6,
	'$collection->_guts->current_extension as expected',
);
ok(
	! $c3->_guts->is_fully_extended,
	'$collection->_guts->is_fully_extended as expected',
);

done_testing;
