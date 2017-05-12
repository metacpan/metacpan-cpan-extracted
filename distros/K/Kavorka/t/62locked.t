=pod

=encoding utf-8

=head1 PURPOSE

Test the C<locked> trait.

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
	
	fun foo ( $x is locked ) {
		$x->{foo} = 1;
	}
	
	fun bar ( %x but locked ) {
		$x{foo} = 1;
	}
	
	fun baz ( Dict[foo => Optional[Int], bar => Optional[ArrayRef]] $x is locked ) {
		$x->{foo} = 1;
		push @{ $x->{bar} ||= [] }, 1;
	}
	
	fun quux ( Dict[bar => Optional[ArrayRef]] $x does locked ) {
		$x->{foo} = 1;
		push @{ $x->{bar} ||= [] }, 1;
	}
}

like(
	exception { Example::foo({}) },
	qr{^Attempt to access disallowed key 'foo' in a restricted hash},
);

is(
	Example::foo({ foo => 42 }),
	1,
);

like(
	exception { Example::bar() },
	qr{^Attempt to access disallowed key 'foo' in a restricted hash},
);

is(
	Example::bar(foo => 42),
	1,
);

ok(
	!exception { Example::baz({}) },
);

like(
	exception { Example::quux({}) },
	qr{^Attempt to access disallowed key 'foo' in a restricted hash},
);

done_testing;

