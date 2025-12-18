=pod

=encoding utf-8

=head1 PURPOSE

Tests constants.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

{
	package Local::Person;
	use Marlin
		'name'     => { required => !!1 },
		'species'  => {
			constant    => 'Homo sapiens',
			handles_via => 'String',
			handles     => { species_length => 'length' },
		};
}

my $bob = Local::Person->new( name => 'Bob Dobalina' );

is( $bob->name, 'Bob Dobalina' );
is( $bob->species, 'Homo sapiens' );
is( $bob->species_length, 12 );
is( $bob, bless( { name => 'Bob Dobalina' }, 'Local::Person' ) );

done_testing;
