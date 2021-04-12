
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<distinct> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );

is_deeply(
	LINQ( [ 1, 4, 3, 4, 2 ] )->distinct->to_array,
	[ 1, 4, 3, 2 ],
	'simple distinct',
);

is_deeply(
	LINQ( [ map( +{ i => $_ }, 1, 4, 3, 4, 2, 6, 2, 9 ) ] )
		->distinct( sub { $_[0]{i} == $_[1]{i} } )
		->select( sub { $_->{i} } )
		->to_array,
	[ 1, 4, 3, 2, 6, 9 ],
	'simple distinct(CODE)',
);

done_testing;
