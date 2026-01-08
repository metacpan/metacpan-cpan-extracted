=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin::XAttribute::Alias.

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
use Marlin foo => { ':Alias' => 'bar' };
my $class = __PACKAGE__;

package main;

my $x = $class->new( foo => 42 );
is( $x->foo, 42 );
is( $x->bar, 42 );

my $y = $class->new( bar => 42 );
is( $y->foo, 42 );
is( $y->bar, 42 );

like( dies { $class->new( foo => 4, bar => 2 ) }, qr/Superfluous alias/ );

use Marlin::Struct Point => [
	'x!' => { ':Alias' => 'horizontal' },
	'y!' => { ':Alias' => 'vertical' },
];

my $p1 = Point->new( x => 66, y => 99 );
my $p2 = Point[ horizontal => 66, vertical => 99 ];
my $p3 = Point[ 66, 99 ];

is( $p1, $p2 );
is( $p1, $p3 );

done_testing;
