=pod

=encoding utf-8

=head1 PURPOSE

Test that Marlin::Antlers compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use Test2::V0;
use Test2::Plugin::BailOnFail;

my $n = 0;

package Local::Wibble {
	use Marlin::Role::Antlers;
	after foo => sub ( $self ) { ++$n };
}

package Local::Wobble {
	use Marlin::Role::Antlers;
	with 'Local::Wibble';
}

package Local::Foo {
	use Marlin::Antlers;
	has foo => ();
}

package Local::FooBar {
	use Marlin::Antlers;
	extends 'Local::Foo';
	with 'Local::Wobble';
	has bar => Int;
}

my $x = Local::FooBar->new( foo => 2, bar => 3 );

is $x->foo, 2;
is $x->bar, 3;
is $n, 1;

done_testing;

