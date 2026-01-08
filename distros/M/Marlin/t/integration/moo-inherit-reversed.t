=pod

=encoding utf-8

=head1 PURPOSE

Tests Moo can inherit from Narlin.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Test2::Require::Module 'Moose';
use Data::Dumper;

BEGIN {
	package Local::Quux;
	use Marlin::Role 'quux';
};

BEGIN {
	package Local::Foo;
	use Marlin -with => 'Local::Quux', 'foo!';
};

BEGIN {
	package Local::Bar;
	use Moo;
	use MooX::Marlin;
	extends 'Local::Foo';
	has bar => ( is => 'ro' );
};

BEGIN {
	package Local::Baz;
	use Moo;
	use MooX::Marlin;
	has baz => ( is => 'ro' );
	with 'Local::Quux';
};

my $thing = Local::Bar->new( foo => 1, bar => 2, quux => 3 );
is( $thing->foo, 1 );
is( $thing->bar, 2 );
is( $thing->quux, 3 );

my $thing2 = Local::Baz->new( quux => 3, baz => 4 );
is( $thing2->quux, 3 );
is( $thing2->baz, 4 );

done_testing;
