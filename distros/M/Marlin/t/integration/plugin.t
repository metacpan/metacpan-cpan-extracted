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

use strict;
use warnings;
use Test::More;

{
	package Local::Foo;
	use Marlin qw( foo quux :Clone );
}

{
	package Local::Bar;
	use Marlin qw( bar ), -extends => [ 'Local::Foo' ];
}

my $bar1 = Local::Bar->new( foo => 1, quux => 2, bar => 3 );
my $bar2 = $bar1->clone( bar => 4 );

is_deeply( $bar1, bless( { foo => 1, quux => 2, bar => 3 }, 'Local::Bar' ) ) or diag explain( $bar1 );
is_deeply( $bar2, bless( { foo => 1, quux => 2, bar => 4 }, 'Local::Bar' ) ) or diag explain( $bar2 );

done_testing;
