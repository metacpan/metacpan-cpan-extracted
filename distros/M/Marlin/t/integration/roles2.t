=pod

=encoding utf-8

=head1 PURPOSE

Tests method modifiers in roles work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

my $n = 0;

{
	package Local::Wibble;
	use Marlin::Role -modifiers;
	after foo => sub { ++$n };
}

{
	package Local::Wobble;
	use Marlin::Role -with => 'Local::Wibble';
}

{
	package Local::Foo;
	use Marlin qw( foo );
}

{
	package Local::FooBar;
	use Marlin
		-extends => 'Local::Foo',
		-with => 'Local::Wobble',
		qw( bar );
}

my $x = Local::FooBar->new( foo => 2, bar => 3 );

is $x->foo, 2;
is $x->bar, 3;
is $n, 1;

done_testing;
