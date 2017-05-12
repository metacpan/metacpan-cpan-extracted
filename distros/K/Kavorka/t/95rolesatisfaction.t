=pod

=encoding utf-8

=head1 PURPOSE

Test that Kavorka methods satisfy role requirements.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

my $e;

package MyRole {
	use Moo::Role;
	requires qw(my_method);
}

package MyClass {
	use Moo;
	use Kavorka;
	$e = ::exception { with qw(MyRole) };
	method my_method () but begin {
		return 42;
	}
}

is($e, undef);

done_testing;

