=pod

=encoding utf-8

=head1 PURPOSE

Test that C<< @_ >> and C<< %_ >> work as slurpy parameters.

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
	
	method foo (@_) {
		+{ '$self' => $self, '@_' => \@_ }
	}
	
	method bar (%_) {
		+{ '$self' => $self, '@_' => \@_, '%_' => \%_ }
	}
	
	method baz ($x, %_) {
		+{ '$self' => $self, '@_' => \@_, '$x' => $x, '%_' => \%_ }
	}
	
	method quux (:$x, %_) {
		+{ '$self' => $self, '@_' => \@_, '$x' => $x, '%_' => \%_ }
	}
}

is_deeply(
	Example->foo(1, 2, 3),
	+{ '$self' => 'Example', '@_' => [1, 2, 3] },
);

is_deeply(
	Example->bar(y => 1, z => 2),
	+{ '$self' => 'Example', '@_' => [ y => 1, z => 2 ], '%_' => +{ y => 1, z => 2 } },
);

is_deeply(
	Example->baz(0, y => 1, z => 2),
	+{ '$self' => 'Example', '@_' => [ 0, y => 1, z => 2 ], '$x' => 0, '%_' => +{ y => 1, z => 2 } },
);

is_deeply(
	Example->quux(x => 0, y => 1, z => 2),
	+{ '$self' => 'Example', '@_' => [ x => 0, y => 1, z => 2 ], '$x' => 0, '%_' => +{ x => 0, y => 1, z => 2 } },
);

done_testing;
