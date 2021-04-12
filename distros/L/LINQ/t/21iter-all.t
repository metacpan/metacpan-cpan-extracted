
=pod

=encoding utf-8

=head1 PURPOSE

Can sometime check C<all> on an infinite collection.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ qw( Range Repeat );

# An infinite collection
my $collection = Repeat( "Hello" );

ok(
	!$collection->all( qr/Goodbye/ ),
	"Repeated 'Hello' are not all 'Goodbye'",
);

done_testing;
