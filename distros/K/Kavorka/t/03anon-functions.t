=pod

=encoding utf-8

=head1 PURPOSE

Create anonymous functions with C<fun>.

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

my $foo = fun {
	return { '@_' => \@_ };
};

my ($bar, $baz) = (
	fun () {
		return { '@_' => \@_ };
	},
	fun ($x, $y) {
		return { '@_' => \@_, '$x' => \$x, '$y' => \$y };
	},
);

my $quux = fun ($x, $y, ...)
{
	return { '@_' => \@_, '$x' => \$x, '$y' => \$y };
}
;

is_deeply(
	$foo->(),
	{ '@_' => [] },
	'anon function with no signature; called with empty list',
);

is_deeply(
	$foo->(1..4),
	{ '@_' => [1..4] },
	'anon function with no signature; called with arguments',
);

is_deeply(
	$bar->(),
	{ '@_' => [] },
	'anon function with empty signature',
);

#line 68
like(
	exception { $bar->(1..4) },
	qr{\AExpected 0 parameters},
	'anon function with empty signature throws exception if passed arguments',
);

is_deeply(
	$baz->(1..2),
	{ '@_' => [1..2], '$x' => \1, '$y' => \2 },
	'anon function with positional parameters',
);

#line 81
like(
	exception { $baz->(1..4) },
	qr{\AExpected 2 parameters},
	'anon function with positional parameters throws exception if passed too many arguments',
);

#line 88
like(
	exception { $baz->(1) },
	qr{\AExpected 2 parameters},
	'anon function with positional parameters throws exception if passed too few arguments',
);

#line 95
is(
	exception { $baz->(undef, undef) },
	undef,
	'an explicit undef satisfies positional parameters',
);

is_deeply(
	$quux->(1..2),
	{ '@_' => [1..2], '$x' => \1, '$y' => \2 },
	'anon function with positional parameters and yadayada',
);

#line 108
is(
	exception { $quux->(1..4) },
	undef,
	'anon function with positional parameters and yadayada throws no exception if passed too many arguments',
);

#line 115
like(
	exception { $quux->(1) },
	qr{\AExpected at least 2 parameters},
	'anon function with positional parameters and yadayada throws exception if passed too few arguments',
);

#line 121
is(
	exception { $quux->(undef, undef) },
	undef,
	'an explicit undef satisfies positional parameters with yadayada',
);

is_deeply(
	[ (fun{})->(1..3) ],
	[],
	'an empty function body returns nothing',
);

my @functions;
my @subs;
for my $i (0..2) {
	push @functions, fun ($x) { $i };
	push @subs,      sub      { $i };
}

is_deeply(
	[ $functions[0]->(7), $functions[1]->(7), $functions[2]->(7) ],
	[ $subs[0]->(7),      $subs[1]->(7),      $subs[2]->(7) ],
	'closures work for anonymous functions',
);

done_testing;

