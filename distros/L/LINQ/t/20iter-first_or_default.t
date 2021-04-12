
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<first_or_default> method of L<LINQ::Iterator>.

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

object_ok(
	people->first_or_default(
		sub { not $_->name =~ /a$/ },
		Person::->new( name => "Hans", id => 666 ),
	),
	'$kristoff',
	isa  => [qw( Person )],
	can  => [qw( name )],
	more => sub { is( shift->name, 'Kristoff' ) },
);

object_ok(
	people->first_or_default(
		sub { not $_->id > 0 },
		Person::->new( name => "Hans", id => 666 ),
	),
	'$hans',
	isa  => [qw( Person )],
	can  => [qw( name )],
	more => sub { is( shift->name, 'Hans' ) },
);

my $e = exception {
	people->first_or_default( sub { die "HAHA" }, 1 );
};
like( $e, qr/^HAHA/, 'unrelated exceptions not caught by default' );

done_testing;
