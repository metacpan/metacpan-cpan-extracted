=pod

=encoding utf-8

=head1 PURPOSE

Test positional parameters: required versus optional; lexical
versus localized versus anonymous; various types of defaults.

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
	
	fun foo ($x) {
		return { '@_' => \@_, '$x' => $x, };
	}
	
	fun bar ($, $x) {
		return { '@_' => \@_, '$x' => $x, };
	}

	fun baz ($x, $y) {
		return { '@_' => \@_, '$x' => $x, '$y' => $y, };
	}
	
	fun quux (${^ONE}, $_) {
		return { '@_' => \@_, '${^ONE}' => ${^ONE}, '$_' => $_ };
	}
}

is_deeply(
	Example::foo('A'),
	{ '@_' => ['A'], '$x' => 'A' },
	'function with one positional parameter'
);

is_deeply(
	Example::bar('A', 'B'),
	{ '@_' => ['A', 'B'], '$x' => 'B' },
	'function with two positional parameters, the first of which is anonymous'
);

is_deeply(
	Example::baz('A', 'B'),
	{ '@_' => ['A', 'B'], '$x' => 'A', '$y' => 'B' },
	'function with two positional parameters'
);

is_deeply(
	Example::quux('A', 'B'),
	{ '@_' => ['A', 'B'], '${^ONE}' => 'A', '$_' => 'B' },
	'function with two positional parameters using localized global variables'
);

{
	package Example2;
	use Kavorka;
	
	fun foo ($x?) {
		return { '@_' => \@_, '$x' => $x, };
	}
	
	fun bar ($x = 42) {
		return { '@_' => \@_, '$x' => $x, };
	}
	
	fun baz ($x //= 42) {
		return { '@_' => \@_, '$x' => $x, };
	}
	
	fun quux ($x ||= 42) {
		return { '@_' => \@_, '$x' => $x, };
	}
	
	fun xyzzy ($x=,$=,$y=) {
		return { '@_' => \@_, '$x' => $x, '$y' => $y };
	}
}

is_deeply(
	Example2::foo(666),
	{ '@_' => [666], '$x' => '666' },
	'optional positional parameter supplied'
);

is_deeply(
	Example2::foo(undef),
	{ '@_' => [undef], '$x' => undef },
	'optional positional parameter supplied undef'
);

is_deeply(
	Example2::foo(),
	{ '@_' => [], '$x' => undef },
	'optional positional parameter omitted'
);

is_deeply(
	Example2::bar(666),
	{ '@_' => [666], '$x' => '666' },
	'positional parameter with default supplied'
);

is_deeply(
	Example2::bar(undef),
	{ '@_' => [undef], '$x' => undef },
	'positional parameter with default supplied undef'
);

is_deeply(
	Example2::bar(),
	{ '@_' => [], '$x' => 42 },
	'positional parameter with default omitted'
);

is_deeply(
	Example2::baz(666),
	{ '@_' => [666], '$x' => '666' },
	'positional parameter with //=default supplied'
);

is_deeply(
	Example2::baz(undef),
	{ '@_' => [undef], '$x' => 42 },
	'positional parameter with //=default supplied undef'
);

is_deeply(
	Example2::baz(0),
	{ '@_' => [0], '$x' => 0 },
	'positional parameter with //=default supplied false'
);

is_deeply(
	Example2::baz(),
	{ '@_' => [], '$x' => 42 },
	'positional parameter with //=default omitted'
);

is_deeply(
	Example2::quux(666),
	{ '@_' => [666], '$x' => '666' },
	'positional parameter with ||=default supplied'
);

is_deeply(
	Example2::quux(undef),
	{ '@_' => [undef], '$x' => 42 },
	'positional parameter with ||=default supplied undef'
);

is_deeply(
	Example2::quux(0),
	{ '@_' => [0], '$x' => 42 },
	'positional parameter with ||=default supplied false'
);

is_deeply(
	Example2::quux(),
	{ '@_' => [], '$x' => 42 },
	'positional parameter with ||=default omitted'
);

is_deeply(
	Example2::xyzzy(42),
	{ '@_' => [42], '$x' => 42, '$y' => undef },
	'crazy bare =',
);

is_deeply(
	Example2::xyzzy(42, 4),
	{ '@_' => [42, 4], '$x' => 42, '$y' => undef },
	'crazy bare =',
);

is_deeply(
	Example2::xyzzy(42, 4, 2),
	{ '@_' => [42, 4, 2], '$x' => 42, '$y' => 2 },
	'crazy bare =',
);

{
	package Example3;
	use Kavorka;
	fun foo ($x, @) {
		return { '@_' => \@_, '$x' => $x, };
	}
	fun bar ($x, %) {
		return { '@_' => \@_, '$x' => $x, };
	}
	fun baz ($x, ...) {
		return { '@_' => \@_, '$x' => $x, };
	}
}

is_deeply(
	Example3::foo(42, quux => 'xyzzy'),
	{ '@_' => [42, quux => 'xyzzy'], '$x' => 42 },
	'Signature ($x, @) works',
);

is_deeply(
	Example3::bar(42, quux => 'xyzzy'),
	{ '@_' => [42, quux => 'xyzzy'], '$x' => 42 },
	'Signature ($x, %) works',
);

is_deeply(
	Example3::baz(42, quux => 'xyzzy'),
	{ '@_' => [42, quux => 'xyzzy'], '$x' => 42 },
	'Signature ($x, ...) works',
);

like(
	exception { Example3::bar(42, 'xyzzy') },
	qr/^Odd number of elements in anonymous hash/,
	'Signature ($x, %) can throw',
);

is(
	exception { Example3::baz(42, 'xyzzy') },
	undef,
	"Signature (\$x, ...) won't throw",
);

done_testing;
