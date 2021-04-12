
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<element_at_or_default> method of L<LINQ::Iterator>.

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
use DisneyData qw( people );

my $default = Person::->new( name => "Hans", id => 666 );

for my $idx ( -5, -4, -3, -2, -1, 0, 1, 2, 3, 4 ) {
	is(
		people->element_at_or_default( $idx, $default ),
		people->to_array->[$idx],
		"element_at_or_default($idx)",
	);
}

for my $idx ( -6, 5 ) {
	is(
		people->element_at_or_default( $idx, $default ),
		$default,
		"element_at_or_default($idx)",
	);
}

done_testing;
