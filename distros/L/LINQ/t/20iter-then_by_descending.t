=pod

=encoding utf-8

=head1 PURPOSE

Test the C<then_by_descending> method of L<LINQ::Iterator>.

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

my $d = LINQ [ 8, 4, 5, 12 ];

object_ok(
	exception { $d->order_by( -numeric )->then_by_descending( -string )->to_list }, '$e',
	isa => 'LINQ::Exception::Unimplemented',
);

done_testing;
