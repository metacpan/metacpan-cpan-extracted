
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<Repeat> function exported by L<LINQ>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw(Repeat);

my $c1 = Repeat( "Foo", 7 );

is_deeply(
	$c1->to_array,
	[ ( "Foo" ) x 7 ],
	'Repeat("Foo", 7)',
);

my $c2 = Repeat( "Foo" );

is_deeply(
	$c2->take( 8 )->to_array,
	[ ( "Foo" ) x 8 ],
	'Repeat("Foo")',
);

done_testing;
