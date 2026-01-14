=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin can inherit from Mouse.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Test2::Require::Module 'Mouse';
use Data::Dumper;

BEGIN {
	package Local::Quux;
	use Mouse::Role;
	has quux => ( is => 'ro' );
};

BEGIN {
	package Local::Foo;
	use Mouse;
	with 'Local::Quux';
	has foo => ( is => 'ro' );
	__PACKAGE__->meta->make_immutable;
};

BEGIN {
	package Local::Bar;
	use Marlin 'bar', -isa => \'Local::Foo';
};

my $thing = Local::Bar->new( foo => 1, bar => 2, quux => 3 );

is( $thing->foo, 1 );
is( $thing->bar, 2 );
is( $thing->quux, 3 );

BEGIN {
	package Local::Baz;
	use Marlin 'baz', -does => \'Local::Quux';
};

my $thing2 = Local::Baz->new( quux => 3, baz => 4 );
is( $thing2->quux, 3 );
is( $thing2->baz, 4 );

sub is_xs  {
	require B;
	!! B::svref_2object( shift )->XSUB;
}

ok is_xs(\&Local::Bar::new);
ok is_xs(\&Local::Baz::new);

done_testing;
