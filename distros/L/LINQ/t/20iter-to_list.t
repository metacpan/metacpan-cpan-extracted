
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<to_list> method of L<LINQ::Iterator>.

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

is_deeply( [ LINQ( $_ )->to_list ], $_ )
	for [ 1 .. 7 ], [], [ 'a' .. 'z' ], [ { foo => 42 } ];
	
done_testing;
