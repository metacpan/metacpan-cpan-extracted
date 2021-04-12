
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<contains> method of L<LINQ::Iterator>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );
use DisneyData qw( people );

ok(
	LINQ( [ 1 .. 7 ] )->contains( 6 ),
	'contains(6)',
);

ok(
	!LINQ( [ 1 .. 7 ] )->contains( 8 ),
	'contains(8)',
);

my $elsa        = Person::->new( name => "Elsa" );
my $hans        = Person::->new( name => "Hans" );
my $same_person = sub { $_[0]->name eq $_[1]->name };

ok(
	people->contains( $elsa, $same_person ),
	'contains($elsa)',
);

ok(
	!people->contains( $hans, $same_person ),
	'contains($hans)',
);

done_testing;
