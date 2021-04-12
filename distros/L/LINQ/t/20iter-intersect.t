
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<intersect> method of L<LINQ::Iterator>.

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
use DisneyData qw( pets );

my $begins_S = pets->where( sub { $_->name =~ /^S/ } );
my $ends_n   = pets->where( sub { $_->name =~ /n$/ } );
my $union    = $begins_S->intersect( $ends_n, sub { $_[0]->id == $_[1]->id } );

is_deeply(
	$union->select( sub { $_->name } )->order_by( -string, sub { $_ } )->to_array,
	[qw/ Sven /],
	'simple intersect',
);

is_deeply(
	LINQ( [ 1, 2, 3 ] )->intersect( LINQ( [ 1, 3, 5 ] ) )->to_array,
	[ 1, 3 ],
	'simple intersect with no callable',
);

done_testing;
