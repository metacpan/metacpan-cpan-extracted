=pod

=encoding utf-8

=head1 PURPOSE

Test method modifiers in L<Class::Tiny> plus L<Role::Tiny>.

=head1 DEPENDENCIES

Requires Class::Tiny, Role::Tiny and Class::Method::Modifiers.

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

# Some of these export stuff that conflict with each other, so
# do it in dummy namespaces.
package Tmp1 { use Test::Requires { 'Class::Method::Modifiers' => '2.00' } };
package Tmp2 { use Test::Requires { 'Class::Tiny' => '0' } };
package Tmp3 { use Test::Requires { 'Role::Tiny' => '1.003000' } };
package Tmp4 { use Test::Requires { 'parent' => '0' } };

use Test::Fatal;

package Parent {
	use Class::Tiny;
	use Class::Method::Modifiers;
	use Kavorka qw( -default -modifiers );
	
	method process ( ScalarRef $n ) {
		$$n *= 3;
	}
};

package Sibling {
	use Role::Tiny;
	use Kavorka qw( -default -modifiers );
	
	after process ( ScalarRef $n ) {
		$$n += 2;
	}
};

package Child {
	use Class::Tiny;
	use Class::Method::Modifiers;
	use Role::Tiny::With;
	use Kavorka qw( -default -modifiers );
	use parent qw( -norequire Parent );
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
	use Class::Tiny;
	use Class::Method::Modifiers;
	use Kavorka qw( -default -modifiers );
	use parent qw( -norequire Child );
	
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
