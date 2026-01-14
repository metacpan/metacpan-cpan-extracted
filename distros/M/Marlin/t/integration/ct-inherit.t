=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin can inherit from Class::Tiny.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

BEGIN {
	package Local::Foo;
	use Class::Tiny qw( foo );
};

BEGIN {
	package Local::Bar;
	use Marlin 'bar', -isa => \'Local::Foo';
};

my $thing = Local::Bar->new( foo => 1, bar => 2 );

is( $thing->foo, 1 );
is( $thing->bar, 2 );

sub is_xs  {
	require B;
	!! B::svref_2object( shift )->XSUB;
}

ok is_xs(\&Local::Bar::new);

done_testing;
