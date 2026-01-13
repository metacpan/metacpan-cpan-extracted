=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin::X.

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
	package Local::Foo;
	use Marlin qw( foo! quux :Clone );
}

{
	package Local::Bar;
	use Marlin bar => { ':Alias' => 'BAR' }, -extends => [ 'Local::Foo' ];
}

my $bar1 = Local::Bar->new( foo => 1, quux => 2, bar => 3 );
my $bar2 = $bar1->clone( bar => 4 );
my $bar3 = $bar1->clone( BAR => 4 );

is( $bar1, bless( { foo => 1, quux => 2, bar => 3 }, 'Local::Bar' ) ) or diag Dumper( $bar1 );
is( $bar2, bless( { foo => 1, quux => 2, bar => 4 }, 'Local::Bar' ) ) or diag Dumper( $bar2 );
is( $bar3, bless( { foo => 1, quux => 2, bar => 4 }, 'Local::Bar' ) ) or diag Dumper( $bar3 );

{
	my $e = do {
		local $@;
		eval { $bar1->clone( wibble => 'wobble' ) };
		$@;
	};
	like $e, qr/Unexpected keys in clone arguments/;
}

{
	my $e = do {
		local $@;
		eval { $bar1->clone( bar => 1, BAR => 2 ) };
		$@;
	};
	like $e, qr/Superfluous/;
}

{
	my $e = do {
		local $@;
		eval { bless( {}, 'Local::Foo' )->clone() };
		$@;
	};
	like $e, qr/Missing required attribute 'foo'/;
}

done_testing;
