=pod

=encoding utf-8

=head1 PURPOSE

Test introspection via Moose meta objects.

=head1 DEPENDENCIES

Requires Moose 2.0000.

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
use Test::Requires { 'Moose' => '2.0000' };
use Test::Fatal;

package Parent {
	use Moose;
	use MooseX::KavorkaInfo;
	use Kavorka qw( -default -modifiers );
	method process ( ScalarRef $n ) {
		$$n *= 3;
	}
};

subtest "method introspection" => sub {
	my $method = Parent->meta->get_method('process');
	my $sig    = $method->signature;

	is($method->declaration_keyword, 'method');
	ok($sig->params->[0]->invocant);
	is($sig->params->[1]->type->name, 'ScalarRef');
};

package Sibling {
	use Moose::Role;
	use MooseX::KavorkaInfo;
	use Kavorka qw( -default -modifiers );
	after process ( ScalarRef $n ) {
		$$n += 2;
	}
};

package Child {
	use Moose;
	use MooseX::KavorkaInfo;
	use Kavorka qw( -default -modifiers );
	extends qw( Parent );
	with qw( Sibling );
	before process ( ScalarRef[Num] $n ) {
		$$n += 5;
	}
};

subtest "method introspection works through wrappers" => sub {
	my $method = Child->meta->get_method('process');
	my $sig    = $method->signature;
	
	is($method->declaration_keyword, 'method');
	ok($sig->params->[0]->invocant);
	is($sig->params->[1]->type->name, 'ScalarRef');
};

done_testing;
