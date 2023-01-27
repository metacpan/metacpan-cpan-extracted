=pod

=encoding utf-8

=head1 PURPOSE

Test based on documentation SYNOPSIS.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;

BEGIN {
	package Local::Package;
	use Exporter::Almighty -setup => {
		tag => {
			foo => [ 'foo1', 'foo2' ],
			bar => [ 'bar1' ],
		},
		const => {
			colours => { RED => 'red', BLUE => 'blue', GREEN => 'green' },
		},
		enum => {
			Status => [ 'dead', 'alive' ],
		},
		also => [
			'strict',
			'Scalar::Util' => [ 'refaddr' ],
			'warnings',
		],
	};
	sub foo1 { 'foo:foo1' }
	sub foo2 { 'foo:foo2' }
	sub bar1 { 'bar:bar1' }
	1;
};

{
	use Local::Package -all, -lexical;
	is( RED, 'red' );
	is( foo1(), 'foo:foo1' );
	isa_ok( Status, 'Type::Tiny' );
	is( STATUS_ALIVE, 'alive' );
	ok( is_Status( 'dead' ) );
	ok( not is_Status( 'bob' ) );
	ok( refaddr( [] ) );
}

ok !eval 'my $x = STATUS_ALIVE;';

done_testing;
