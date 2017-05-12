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
	
	fun foo {
		return { '@_' => \@_ };
	}

	fun bar () {
		return { '@_' => \@_ };
	}

	fun Example2::baz (my $x, $y) {
		return { '@_' => \@_, '$x' => \$x, '$y' => \$y };
	}

	fun ::quux ($x, $y, ...) {
		return { '@_' => \@_, '$x' => \$x, '$y' => \$y };
	}
	
	fun my $xyzzy ($x) {
		return { '$x' => \$x };
	}
	
	fun XYZZY ($x) {
		return $xyzzy->($x);
	}
	
	::ok(
		::exception { $xyzzy = 42 },
		'cannot rebind the lexical function'
	);
	
	{
		fun my $xyzzy () { 42 };
		::is($xyzzy->(), 42, 'can redefine lexical function in another scope');
	}
}

is_deeply(
	Example::foo(),
	{ '@_' => [] },
	'named function with no signature; called with empty list',
);

is_deeply(
	Example::foo(1..4),
	{ '@_' => [1..4] },
	'named function with no signature; called with arguments',
);

is_deeply(
	Example::bar(),
	{ '@_' => [] },
	'named function with empty signature',
);

#line 68
like(
	exception { Example::bar(1..4) },
	qr{\AExpected 0 parameters at \S+ line 69},
	'named function with empty signature throws exception if passed arguments',
);

is_deeply(
	Example2::baz(1..2),
	{ '@_' => [1..2], '$x' => \1, '$y' => \2 },
	'named function with positional parameters',
);

#line 81
like(
	exception { Example2::baz(1..4) },
	qr{\AExpected 2 parameters at \S+ line 82},
	'named function with positional parameters throws exception if passed too many arguments',
);

#line 88
like(
	exception { Example2::baz(1) },
	qr{\AExpected 2 parameters at \S+ line 89},
	'named function with positional parameters throws exception if passed too few arguments',
);

#line 95
is(
	exception { Example2::baz(undef, undef) },
	undef,
	'an explicit undef satisfies positional parameters',
);

is_deeply(
	quux(1..2),
	{ '@_' => [1..2], '$x' => \1, '$y' => \2 },
	'named function with positional parameters and yadayada',
);

#line 108
is(
	exception { quux(1..4) },
	undef,
	'named function with positional parameters and yadayada throws no exception if passed too many arguments',
);

#line 115
like(
	exception { quux(1) },
	qr{\AExpected at least 2 parameters at \S+ line 116},
	'named function with positional parameters and yadayada throws exception if passed too few arguments',
);

#line 121
is(
	exception { quux(undef, undef) },
	undef,
	'an explicit undef satisfies positional parameters with yadayada',
);

is_deeply(
	Example::XYZZY(42),
	{ '$x' => \42 },
	'lexical subs',
);

{ package Example3; use Kavorka; fun xxx { } };

is_deeply(
	[ Example3::xxx(1..3) ],
	[],
	'an empty function body returns nothing',
);

done_testing;

