
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<single> method of L<LINQ::Array>.

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
	people->single( sub { $_->id == 2 } ),
	'$elsa',
	isa  => [qw( Person )],
	can  => [qw( name )],
	more => sub { is( shift->name, 'Elsa' ) },
);

object_ok(
	people->where( sub { $_->id == 2 } )->single,
	'$elsa',
	isa  => [qw( Person )],
	can  => [qw( name )],
	more => sub { is( shift->name, 'Elsa' ) },
);

object_ok(
	exception {
		people->single( sub { $_->id < 0 } )
	},
	'$e',
	isa => [qw( LINQ::Exception LINQ::Exception::NotFound )],
	can => [qw( message collection )],
);

object_ok(
	exception {
		people->single( sub { $_->id > 0 } )
	},
	'$e',
	isa => [qw( LINQ::Exception LINQ::Exception::MultipleFound )],
	can => [qw( message collection )],
);

done_testing;
