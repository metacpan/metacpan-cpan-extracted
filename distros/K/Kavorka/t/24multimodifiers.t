=pod

=encoding utf-8

=head1 PURPOSE

Test modifying multiple methods simultaneously.

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

package Parent {
	use Moo;
	use Kavorka qw( -default -modifiers );
	method foo {
		1;
	}
	method bar {
		2;
	}
	method baz {
		3;
	};
};

package Child {
	use Moo;
	use Kavorka qw( -default -modifiers );
	extends qw( Parent );
	around foo, bar, baz {
		$self->${^NEXT} + 39;
	}
};

is_deeply(
	[ map Child->$_, qw/ foo bar baz/ ],
	[ 40 .. 42 ],
);

done_testing;
