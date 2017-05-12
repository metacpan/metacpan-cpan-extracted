=pod

=encoding utf-8

=head1 PURPOSE

Create named functions with C<fun>.

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
	use Kavorka;
	
	method foo {
		return { '$self' => $self, '@_' => \@_ };
	}

	method bar () {
		return { '$self' => $self, '@_' => \@_ };
	}

	method Example2::baz ($x, $y) {
		return { '$self' => $self, '@_' => \@_, '$x' => \$x, '$y' => \$y };
	}

	method ::quux ($x, $y, ...) {
		return { '$self' => $self, '@_' => \@_, '$x' => \$x, '$y' => \$y };
	}
	
	method my $xyzzy ($x) {
		return { '$self' => $self, '$x' => \$x };
	}
	
	method XYZZY ($x) {
		return $self->$xyzzy($x);
	}
}

is_deeply(
	Example->foo(),
	{ '$self' => 'Example', '@_' => [] },
	'named method with no signature; called with empty list',
);

is_deeply(
	Example->foo(1..4),
	{ '$self' => 'Example', '@_' => [1..4] },
	'named method with no signature; called with arguments',
);

is_deeply(
	Example->bar(),
	{ '$self' => 'Example', '@_' => [] },
	'named method with empty signature',
);

#line 68
like(
	exception { Example->bar(1..4) },
	qr{\AExpected 0 parameters at \S+ line 69},
	'named method with empty signature throws exception if passed arguments',
);

is_deeply(
	Example2->baz(1..2),
	{ '$self' => 'Example2', '@_' => [1..2], '$x' => \1, '$y' => \2 },
	'named method with positional parameters',
);

#line 81
like(
	exception { Example2->baz(1..4) },
	qr{\AExpected 2 parameters at \S+ line 82},
	'named method with positional parameters throws exception if passed too many arguments',
);

#line 88
like(
	exception { Example2->baz(1) },
	qr{\AExpected 2 parameters at \S+ line 89},
	'named method with positional parameters throws exception if passed too few arguments',
);

#line 95
is(
	exception { Example2->baz(undef, undef) },
	undef,
	'an explicit undef satisfies positional parameters',
);

is_deeply(
	main->quux(1..2),
	{ '$self' => 'main', '@_' => [1..2], '$x' => \1, '$y' => \2 },
	'named method with positional parameters and yadayada',
);

#line 108
is(
	exception { main->quux(1..4) },
	undef,
	'named method with positional parameters and yadayada throws no exception if passed too many arguments',
);

#line 115
like(
	exception { main->quux(1) },
	qr{\AExpected at least 2 parameters at \S+ line 116},
	'named method with positional parameters and yadayada throws exception if passed too few arguments',
);

#line 121
is(
	exception { main->quux(undef, undef) },
	undef,
	'an explicit undef satisfies positional parameters with yadayada',
);

is_deeply(
	Example->XYZZY(42),
	{ '$self' => 'Example', '$x' => \42 },
	'lexical methods',
);

{ package Example3; use Kavorka; method xxx { } };

is_deeply(
	[ Example3->xxx(1..3) ],
	[],
	'an empty method body returns nothing',
);

{
	package Example4;
	use Kavorka;
	use namespace::sweep;
	method method { 42 }
}

is_deeply(
	Example4->method,
	42,
	'can define a method called "method"',
);

done_testing;

