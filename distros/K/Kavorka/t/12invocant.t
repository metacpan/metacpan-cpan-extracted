=pod

=encoding utf-8

=head1 PURPOSE

Test invocants: renaming default invocant for C<method> keyword;
lexical versus localized variables; multiple invocants.

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
	
	method foo ($x?) {
		return { '@_' => \@_, '$self' => $self, };
	}
	
	method bar ($foo: $x) {
		return { '@_' => \@_, '$foo' => $foo, '$x' => $x, };
	}
	
	method baz (${^FOO}: $x) {
		return +{ '@_' => \@_, '${^FOO}' => ${^FOO}, '$x' => $x, };
	}
	
	method quux ($self, $_: $x) {
		return { '@_' => \@_, '$self' => $self, '$_' => $_, '$x' => $x, };
	}
}

is_deeply(
	Example->foo(42),
	{ '@_' => [42], '$self' => 'Example', },
	'basic method with an invocant',
);

ok(
	exception { Example::foo() },
	'basic method called without invocant throws exception',
);
note "it would be nice if the exception mentioned a missing invocant!";

is_deeply(
	Example->bar(42),
	{ '@_' => [42], '$foo' => 'Example', '$x' => 42 },
	'renaming invocant',
);

is_deeply(
	Example->baz(42),
	{ '@_' => [42], '${^FOO}' => 'Example', '$x' => 42 },
	'renaming invocant to a localized global',
);

is_deeply(
	Example->quux({}, 42),
	{ '@_' => [42], '$self' => 'Example', '$_' => {}, '$x' => 42 },
	'two invocants',
);

{
	package Example2;
	use Kavorka;
	
	fun bar ($foo: $x) {
		return { '@_' => \@_, '$foo' => $foo, '$x' => $x, };
	}
}

is_deeply(
	Example2->bar(42),
	{ '@_' => [42], '$foo' => 'Example2', '$x' => 42 },
	'invocants work with `fun` keyword too',
);

done_testing;

