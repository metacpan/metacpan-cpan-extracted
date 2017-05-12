=pod

=encoding utf-8

=head1 PURPOSE

Test slurpy parameters.

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
	
	fun foo ($x, $y?, @z) {
		return { '@_' => \@_, '$x' => $x, '$y' => $y, '@z' => \@z, };
	}
	
	fun bar ($, %z) {
		return { '@_' => \@_, '%_' => \%_, '%z' => \%z, };
	}
	
	fun baz (:$x, :$y, %z) {
		return { '@_' => \@_, '%_' => \%_, '$x' => $x, '$y' => $y, '%z' => \%z };
	}
	
	fun quux ($x, %) {
		return { '@_' => \@_, '%_' => \%_, '$x' => $x, };
	}
}

is_deeply(
	Example::foo(1..5),
	{ '@_' => [1..5], '$x' => 1, '$y' => 2, '@z' => [3..5] },
	'function with leading positional parameters and array slurpy'
);

is_deeply(
	Example::foo(1),
	{ '@_' => [1], '$x' => 1, '$y' => undef, '@z' => [] },
	'function with leading positional parameters and array slurpy - empty slurpy'
);

is_deeply(
	Example::foo(1,2),
	{ '@_' => [1,2], '$x' => 1, '$y' => 2, '@z' => [] },
	'function with leading positional parameters and array slurpy - empty slurpy'
);

is_deeply(
	Example::foo(1..3),
	{ '@_' => [1..3], '$x' => 1, '$y' => 2, '@z' => [3] },
	'function with leading positional parameters and array slurpy - only one item in slurpy'
);

is_deeply(
	Example::bar(0, 1..4),
	{ '@_' => [0..4], '%_' => +{1..4}, '%z' => +{1..4} },
	'function with leading positional parameter and hash slurpy'
);

like(
	exception { Example::bar(0, 1..5) },
	qr{^Odd number of elements},
	'exception passing odd number of items to slurpy hash',
);

is_deeply(
	Example::baz(x => 42, a => 1, b => 2, c => 3),
	{ '@_' => [qw/ x 42 a 1 b 2 c 3 /], '%_' => +{qw/ x 42 a 1 b 2 c 3 /}, '$x' => 42, '$y' => undef, '%z' => +{qw/ a 1 b 2 c 3 /} },
	'function with named parameters and slurpy hash'
);

is_deeply(
	Example::baz({x => 42, a => 1, b => 2, c => 3 }),
	{ '@_' => [{qw/ x 42 a 1 b 2 c 3 /}], '%_' => +{qw/ x 42 a 1 b 2 c 3 /}, '$x' => 42, '$y' => undef, '%z' => +{qw/ a 1 b 2 c 3 /} },
	'function with named parameters and slurpy hash (invoked with hashref)'
);

is_deeply(
	Example::quux(42, a => 1, b => 2, c => 3),
	{ '@_' => [qw/ 42 a 1 b 2 c 3 /], '%_' => +{qw/ a 1 b 2 c 3 /}, '$x' => 42, },
	'anon slurpy hash'
);

{
	package Example2;
	use Kavorka;
	
	fun foo ($x, $y?, slurpy ArrayRef $z) {
		return { '@_' => \@_, '$x' => $x, '$y' => $y, '$z' => $z, };
	}
	
	fun bar ($, slurpy HashRef $z) {
		return { '@_' => \@_, '%_' => \%_, '$z' => $z, };
	}
	
	fun baz (:$x, :$y, slurpy HashRef $z) {
		return { '@_' => \@_, '%_' => \%_, '$x' => $x, '$y' => $y, '$z' => $z };
	}
}

is_deeply(
	Example2::foo(1..5),
	{ '@_' => [1..5], '$x' => 1, '$y' => 2, '$z' => [3..5] },
	'function with leading positional parameters and arrayref slurpy'
);

is_deeply(
	Example2::bar(0, 1..4),
	{ '@_' => [0..4], '%_' => +{1..4}, '$z' => +{1..4} },
	'function with leading positional parameter and hashref slurpy'
);

like(
	exception { Example2::bar(0, 1..5) },
	qr{^Odd number of elements},
	'exception passing odd number of items to slurpy hashref',
);

is_deeply(
	Example2::baz(x => 42, a => 1, b => 2, c => 3),
	{ '@_' => [qw/ x 42 a 1 b 2 c 3 /], '%_' => +{qw/ x 42 a 1 b 2 c 3 /}, '$x' => 42, '$y' => undef, '$z' => +{qw/ a 1 b 2 c 3 /} },
	'function with named parameters and slurpy hashref'
);


{
	package Example3;
	use Kavorka;
	fun foo1 (:$x, :$y, %z) {
		$_{goop}++;
	}
	fun foo2 (:$x, :$y, slurpy HashRef $z) {
		$_{goop}++;
	}
}

my $goop = 40;
Example3::foo1(x => 1, y => 2, goop => $goop);
is($goop, 41, '%_ is an alias with slurpy hash');
Example3::foo2(x => 1, y => 2, goop => $goop);
is($goop, 42, '%_ is an alias with slurpy hashref');

done_testing;
