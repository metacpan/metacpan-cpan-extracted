
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<last_or_default> method of L<LINQ::Array>.

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

object_ok(
	people->last_or_default(
		sub { not $_->name =~ /a$/ },
		Person::->new( name => "Hans", id => 666 ),
	),
	'$rapunzel',
	isa  => [qw( Person )],
	can  => [qw( name )],
	more => sub { is( shift->name, 'Rapunzel' ) },
);

object_ok(
	people->last_or_default(
		sub { not $_->id > 0 },
		Person::->new( name => "Hans", id => 666 ),
	),
	'$hans',
	isa  => [qw( Person )],
	can  => [qw( name )],
	more => sub { is( shift->name, 'Hans' ) },
);

my $e = exception {
	people->last_or_default( sub { die "HAHA" }, 1 );
};
like( $e, qr/^HAHA/, 'unrelated exceptions not caught by default' );

done_testing;
