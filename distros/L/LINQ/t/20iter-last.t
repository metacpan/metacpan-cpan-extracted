
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<last> method of L<LINQ::Iterator>.

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
	people->last( sub { $_->name =~ /a$/ } ),
	'$rapunzel',
	isa  => [qw( Person )],
	can  => [qw( name )],
	more => sub { is( shift->name, 'Sophia' ) },
);

object_ok(
	people->last, '$people->last',
	isa   => 'Person',
	more  => sub {
		my $this = shift;
		is( $this->name, 'Rapunzel' );
	},
);

object_ok(
	exception {
		people->last( sub { $_->id < 0 } )
	},
	'$e',
	isa => [qw( LINQ::Exception LINQ::Exception::NotFound )],
	can => [qw( message collection )],
);

done_testing;
