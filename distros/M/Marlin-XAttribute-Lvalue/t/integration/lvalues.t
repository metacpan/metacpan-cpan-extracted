=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin::XAttribute::Lvalue.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

sub is_xs {
	my $sub = $_[0];
	if ( Scalar::Util::blessed($sub) and $sub->isa( "Class::MOP::Method" ) ) {
		$sub = $sub->body;
	}
	elsif ( not ref $sub ) {
		no strict "refs";
		if ( not exists &{$sub} ) {
			my ( $pkg, $method ) = ( $sub =~ /\A(.+)::([^:]+)\z/ );
			if ( my $found = $pkg->can($method) ) {
				return lc(is_xs($found));
			}
			return "--";
		}
		$sub = \&{$sub};
	}
	require B;
	B::svref_2object( $sub )->XSUB ? 'XS' : 'PP';
}

{
	package Local::Foo1;
	use Marlin foo => { ':Lvalue' => 1 };
	my $class = __PACKAGE__;
	
	package main;

	my $x = $class->new( foo => 42 );
	is( $x->foo, 42 );

	$x->foo = 100;
	is( $x->foo, 100 );

	$x->foo++;
	is( $x->foo, 101 );

	is( is_xs("${class}::foo"), 'XS' ) if Marlin::Attribute::HAS_CXSA;
}

{
	package Local::Foo2;
	use Types::Common qw(Int);
	use Marlin foo => { isa => Int, ':Lvalue' => 1 };
	my $class = __PACKAGE__;
	
	package main;
	
	my $x = $class->new( foo => 42 );
	is( $x->foo, 42 );

	$x->foo = 100;
	is( $x->foo, 100 );

	$x->foo++;
	is( $x->foo, 101 );

	like( dies { $x->foo = "BAD" }, qr/did not pass type constraint/ );
}

done_testing;
