=pod

=encoding utf-8

=head1 PURPOSE

Check that type constraint expressions may return MooseX::Types type
constraint objects.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Test::Requires { 'MooseX::Types::Moose' => 0 };

{
	package Example;
	use Kavorka;
	use MooseX::Types::Moose qw(Int);
	
	fun foo ( (__PACKAGE__->can('Int')->()) $x ) { return $x }
}

is( Example::foo(42), 42 );

like(
	exception { Example::foo(3.14159) },
	qr{^Value "3.14159" did not pass type constraint "Int"},
);

done_testing;

