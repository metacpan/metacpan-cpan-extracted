=pod

=encoding utf-8

=head1 PURPOSE

Test method modifiers in L<Moo>.

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

package Parent {
	use Moo;
	use Kavorka qw( -default -modifiers );
	method process ( ScalarRef $n ) {
		$$n *= 3;
	}
};

package Sibling {
	use Moo::Role;
	use Kavorka qw( -default -modifiers );
	after process ( ScalarRef $n ) {
		$$n += 2;
	}
};

package Child {
	use Moo;
	use Kavorka qw( -default -modifiers );
	extends qw( Parent );
	with qw( Sibling );
	before process ( ScalarRef[Num] $n ) {
		$$n += 5;
	}
};

my $thing_one = Child->new;

my $n = 1;
$thing_one->process(\$n);
is($n, 20);

package Grandchild {
	use Moo;
	use Kavorka qw( -default -modifiers );
	extends qw( Child );
	around process ( ScalarRef $n ) {
		my ($int, $rest) = split /\./, $$n;
		$rest ||= 0;
		$self->${^NEXT}(\$int);
		$$n = "$int\.$rest";
	}
};

my $thing_two = Grandchild->new;

my $m = '1.2345';
$thing_two->process(\$m);
is($m, '20.2345');

done_testing;
