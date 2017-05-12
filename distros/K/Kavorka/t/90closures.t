=pod

=encoding utf-8

=head1 PURPOSE

Various tests of named and anonymous functions closing over variables.

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

my $x;
BEGIN { $x = 1 };

package Foo {
	use Kavorka;
	method new ($class: ...) {
		bless {}, $class;
	}
	method inc { ++$x }
	method dec { --$x }
}

subtest "Two functions closing over the same variable" => sub
{
	my $foo = Foo->new;
	
	is($x, 1);
	is($foo->inc, 2);
	is($foo->inc, 3);
	is($x, 3);
	is($foo->dec, 2);
	is($foo->dec, 1);
	is($x, 1);
};

package Goo {
	use Kavorka;
	
	method xyz {
		my @links;
		fun my $xxx { push @links, 42 };
		$xxx->();
		return \@links;
	}
}

subtest "Closing over a variable in a lexical function" => sub
{
	is_deeply(Goo->xyz, [42]);
	is_deeply(Goo->xyz, [42]);
	is_deeply(Goo->xyz, [42]);
};

package Hoo {
	use Kavorka;
	method xyz ($closeme) {
		my $f = fun ($vvv = $closeme) { $vvv };
		return (\$closeme, $f);
	}
}

subtest "Closing over a variable in a default" => sub
{
	my ($X1, $fourtytwo) = Hoo->xyz(42);
	is($fourtytwo->(666), 666);
	is($fourtytwo->(), 42);
	
	my ($X2, $sixsixsix) = Hoo->xyz(666);
	is($sixsixsix->(999), 999);
	is($sixsixsix->(), 666);
	$$X2 = 777;
	is($sixsixsix->(), 777);
};

package Ioo {
	use Kavorka;
	method get_limit ($limit) {
		fun (Int $x where { $_ < $limit }) { 1 };
	}
}

subtest "Closing over a variable in a where {} block" => sub
{
	my $lim7 = Ioo->get_limit(7);
	ok $lim7->(6);
	ok exception { $lim7->(8) };
	
	my $lim12 = Ioo->get_limit(12);
	ok $lim12->(8);
	ok exception { $lim12->(14) };
	
	ok $lim7->(6);
	ok exception { $lim7->(8) };
};

package Joo {
	use Kavorka;
	method get_set ($x) {
		return (
			fun ()   { $x },
			fun ($y) { $x = $y },
		);
	}
}

subtest "Two anonymous functions closing over the same variable" => sub
{
	my ($g, $s) = Joo->get_set(20);
	my ($g2, $s2) = Joo->get_set(666);
	is($g->(), 20);
	is($s->(21), 21);
	is($g->(), 21);
	is($s->($g->() * 2), 42);
	is($g->(), 42);
	is($g2->(), 666);
};

done_testing;
