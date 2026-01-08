=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin can inherit from Mite-based classes.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Test2::Require::Module 'Moose';
use Data::Dumper;

use lib 't/lib';
use Local::Mitey;

BEGIN {
	package Local::Bar;
	use Marlin 'bar', -isa => \'Local::Mitey';
};

my $thing = Local::Bar->new( bar => 2 );

is( $thing->foo, 'Foo' );
is( $thing->bar, 2 );

my $thing2 = Local::Bar->new( foo => 1, bar => 2 );

is( $thing2->foo, 1 );
is( $thing2->bar, 2 );

done_testing;
