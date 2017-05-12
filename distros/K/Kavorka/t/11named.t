=pod

=encoding utf-8

=head1 PURPOSE

Test named parameters: required versus optional; various types of
defaults; long names.

Tests that C<< %_ >> reflects named parameters.

Checks that named parameters work with an odd or even number of leading
positional parameters and/or invocants.

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
	
	our $zzz = 'package variable';
	
	fun foo ($x, :$y) {
		return { '@_' => \@_, '%_' => \%_, '$x' => $x, '$y' => $y, };
	}
	
	fun bar ($, $x, :$y) {
		return { '@_' => \@_, '%_' => \%_, '$x' => $x, '$y' => $y, };
	}

	fun baz (:$x, :$y!) {
		return { '@_' => \@_, '%_' => \%_, '$x' => $x, '$y' => $y, };
	}
	
	fun quux (:zzz($z)) {
		return { '@_' => \@_, '%_' => \%_, '$zzz' => $zzz, '$z' => $z };
	}
}

#diag explain( Kavorka->info(\&Example::baz) );

is_deeply(
	Example::foo(666, y => 42),
	{ '@_' => [666, y => 42], '%_' => { y => 42 }, '$x' => 666, '$y' => 42  },
	'single positional followed by a named parameter',
);

is_deeply(
	Example::foo(666),
	{ '@_' => [666], '%_' => { }, '$x' => 666, '$y' => undef  },
	'single positional followed by a named parameter - named parameters are optional',
);

is_deeply(
	Example::bar(999, 666, y => 42),
	{ '@_' => [999, 666, y => 42], '%_' => { y => 42 }, '$x' => 666, '$y' => 42  },
	'two positionals followed by a named parameter',
);

is_deeply(
	Example::bar(999, 666),
	{ '@_' => [999, 666], '%_' => { }, '$x' => 666, '$y' => undef  },
	'two positionals followed by a named parameter - named parameters are optional',
);

is_deeply(
	Example::baz(x => 666, y => 42),
	{ '@_' => [x => 666, y => 42], '%_' => { x => 666, y => 42 }, '$x' => 666, '$y' => 42  },
	'two named parameters',
);

is_deeply(
	Example::baz({ x => 666, y => 42 }),
	{ '@_' => [{ x => 666, y => 42 }], '%_' => { x => 666, y => 42 }, '$x' => 666, '$y' => 42  },
	'two named parameters (passed as hashref)',
);

is_deeply(
	Example::baz(y => 42),
	{ '@_' => [y => 42], '%_' => { y => 42 }, '$x' => undef, '$y' => 42  },
	'two named parameters - omit the optional one',
);

like(
	exception { Example::baz(x => 666) },
	qr{^Named parameter .y. is required},
	'two named parameters - omit the required one; throws',
);

is_deeply(
	Example::quux(zzz => 42),
	{ '@_' => [zzz => 42], '%_' => { zzz => 42 }, '$z' => 42, '$zzz' => 'package variable' },
	'long named parameter',
);

like(
	exception { Example::quux(z => 666) },
	qr{^Unknown named parameter: z},
	'long named parameter cannot be invoked with its short name',
);

{
	package Example2;
	use Kavorka;
	
	fun xxx ( :foo( :bar(:baz($x) )) , ... )
	{
		return $x;
	}
	
	fun yyy ( :foo( :bar(:baz(:$x) )) , ... )
	{
		return $x;
	}
	
	fun zzz ( :foo :bar :baz :$x, ... )
	{
		return $x;
	}
	
	fun www ( :foo :bar :baz $x, ... )
	{
		return $x;
	}
}

is_deeply(
	[ Example2::www(foo => 40), Example2::www(bar => 41), Example2::www(baz => 42), Example2::www(x => 43) ],
	[ 40 .. 42, undef ],
	'multi-named parameters'
);

is_deeply(
	[ Example2::xxx(foo => 40), Example2::xxx(bar => 41), Example2::xxx(baz => 42), Example2::xxx(x => 43) ],
	[ 40 .. 42, undef ],
	'multi-named parameters'
);

is_deeply(
	[ Example2::yyy(foo => 40), Example2::yyy(bar => 41), Example2::yyy(baz => 42), Example2::yyy(x => 43) ],
	[ 40 .. 42, 43 ],
	'multi-named parameters'
);

is_deeply(
	[ Example2::zzz(foo => 40), Example2::zzz(bar => 41), Example2::zzz(baz => 42), Example2::zzz(x => 43) ],
	[ 40 .. 42, 43 ],
	'multi-named parameters'
);

done_testing;

