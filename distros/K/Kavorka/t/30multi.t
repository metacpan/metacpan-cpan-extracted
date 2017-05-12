=pod

=encoding utf-8

=head1 PURPOSE

Test multi methods.

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

{
	package Example;
	use Kavorka qw( multi fun method );
	
	multi method foo (HashRef $x)
	{
		return 'HashRef';
	}
	
	multi method foo (ArrayRef $y)
	{
		return 'ArrayRef';
	}
	
	multi fun bar (HashRef $x)
	{
		return 'bar:HashRef';
	}
}

{
	package Example2;
	use Kavorka qw( multi fun method );
	
	BEGIN { our @ISA = qw(Example) };
	
	multi method foo (ScalarRef $z)
	{
		return 'ScalarRef';
	}
	
	multi fun bar (ScalarRef $z) :long(bar_sr)
	{
		return 'bar:ScalarRef';
	}
}

is( Example->foo({}), 'HashRef' );
is( Example->foo([]), 'ArrayRef' );
like(
	exception { Example->foo(\1) },
	qr{^Arguments to Example::foo did not match any known signature for multi sub},
);

is( Example2->foo({}), 'HashRef' );
is( Example2->foo([]), 'ArrayRef' );
is( Example2->foo(\1), 'ScalarRef' );

is( Example2::bar(\1), 'bar:ScalarRef' );
like(
	exception{ Example2::bar({}) },
	qr{^Arguments to Example2::bar did not match any known signature for multi sub},
	'bar is a function; should not inherit multis',
);

is( Example2::bar_sr(\1), 'bar:ScalarRef', 'can call function via long name' );

done_testing;
