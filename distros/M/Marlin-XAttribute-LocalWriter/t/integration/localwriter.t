=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin::XAttribute::LocalWriter.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

package Local::Foo1;
use Marlin foo => { predicate => 1, ':LocalWriter' => 1 };
my $class = __PACKAGE__;

package main;

my $x = $class->new( foo => 42 );
is( $x->foo, 42 );

do {
	my $g = $x->local_foo( 666 );
	is( $x->foo, 666 );
};

is( $x->foo, 42 );

do {
	my $g = $x->local_foo;
	is( $x->foo, undef );
	ok !$x->has_foo;
	
	do {
		my $g = $x->local_foo( 999 );
		is( $x->foo, 999 );
		ok $x->has_foo;
	};
	
	is( $x->foo, undef );
	ok !$x->has_foo;
};

is( $x->foo, 42 );

done_testing;
