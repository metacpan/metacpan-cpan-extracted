=pod

=encoding utf-8

=head1 PURPOSE

Create anonymous methods with C<method>.

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

use Kavorka;

my $foo = method {
	return { '$self' => $self, '@_' => \@_ };
};

my ($bar, $baz) = (
	method () {
		return { '$self' => $self, '@_' => \@_ };
	},
	method ($x, $y) {
		return { '$self' => $self, '@_' => \@_, '$x' => \$x, '$y' => \$y };
	},
);

my $quux = method ($x, $y, ...)
{
	return { '$self' => $self, '@_' => \@_, '$x' => \$x, '$y' => \$y };
}
;

is_deeply(
	__PACKAGE__->$foo(),
	{ '$self' => 'main', '@_' => [] },
	'anon method with no signature; called with empty list',
);

is_deeply(
	__PACKAGE__->$foo(1..4),
	{ '$self' => 'main', '@_' => [1..4] },
	'anon method with no signature; called with arguments',
);

is_deeply(
	__PACKAGE__->$bar,
	{ '$self' => 'main', '@_' => [] },
	'anon method with empty signature',
);

#line 68
like(
	exception { __PACKAGE__->$bar(1..4) },
	qr{\AExpected 0 parameters},
	'anon method with empty signature throws exception if passed arguments',
);

is_deeply(
	__PACKAGE__->$baz(1..2),
	{ '$self' => 'main', '@_' => [1..2], '$x' => \1, '$y' => \2 },
	'anon method with positional parameters',
);

#line 81
like(
	exception { __PACKAGE__->$baz(1..4) },
	qr{\AExpected 2 parameters},
	'anon method with positional parameters throws exception if passed too many arguments',
);

#line 88
like(
	exception { __PACKAGE__->$baz(1) },
	qr{\AExpected 2 parameters},
	'anon method with positional parameters throws exception if passed too few arguments',
);

#line 95
is(
	exception { __PACKAGE__->$baz(undef, undef) },
	undef,
	'an explicit undef satisfies positional parameters',
);

is_deeply(
	__PACKAGE__->$quux(1..2),
	{ '$self' => 'main', '@_' => [1..2], '$x' => \1, '$y' => \2 },
	'anon method with positional parameters and yadayada',
);

#line 108
is(
	exception { __PACKAGE__->$quux(1..4) },
	undef,
	'anon method with positional parameters and yadayada throws no exception if passed too many arguments',
);

#line 115
like(
	exception { __PACKAGE__->$quux(1) },
	qr{\AExpected at least 2 parameters},
	'anon method with positional parameters and yadayada throws exception if passed too few arguments',
);

#line 121
is(
	exception { __PACKAGE__->$quux(undef, undef) },
	undef,
	'an explicit undef satisfies positional parameters with yadayada',
);

is_deeply(
	[ __PACKAGE__->${ \ method{} }(1..3) ],
	[],
	'an empty method body returns nothing',
);

done_testing;

