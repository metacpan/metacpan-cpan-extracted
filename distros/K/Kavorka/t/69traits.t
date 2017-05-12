=pod

=encoding utf-8

=head1 PURPOSE

Test custom traits.

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

use Kavorka;

BEGIN {
	package Kavorka::TraitFor::Parameter::superbad;
	use Moo::Role;
	$INC{'Kavorka/TraitFor/Parameter/superbad.pm'} = __FILE__;
};

BEGIN {
	package Kavorka::TraitFor::Sub::superbad;
	use Moo::Role;
	$INC{'Kavorka/TraitFor/Sub/superbad.pm'} = __FILE__;
};

fun foo ($x but superbad) {
	42;
}

fun bar ($x is superbad(boom)) {
	42;
}

subtest "Parameter traits" => sub
{
	my ($foo,   $bar)   = map Kavorka->info( 'main'->can($_) ), qw/ foo bar /;
	my ($foo_x, $bar_x) = map $_->signature->params->[0], $foo, $bar;
	
	ok $foo_x->DOES('Kavorka::TraitFor::Parameter::superbad');
	ok $bar_x->DOES('Kavorka::TraitFor::Parameter::superbad');
	is_deeply(
		$bar_x->traits->{superbad},
		['boom'],
	);
};

fun foo2 ($x) but superbad {
	42;
}

fun bar2 ($x) is superbad(boom) {
	42;
}

subtest "Sub traits" => sub
{
	my ($foo, $bar) = map Kavorka->info( 'main'->can($_) ), qw/ foo2 bar2 /;
	
	ok $foo->DOES('Kavorka::TraitFor::Sub::superbad');
	ok $bar->DOES('Kavorka::TraitFor::Sub::superbad');
	is_deeply(
		$bar->traits->{superbad},
		['boom'],
	);
};

use Kavorka funny => {
	implementation => 'Kavorka::Sub::Fun',
	traits         => [ 'Kavorka::TraitFor::Sub::superbad' ],
};

funny foo3 () {
	43
}

subtest "Passing traits to import" => sub
{
	my $foo = Kavorka->info( 'main'->can('foo3') );
	ok $foo->DOES('Kavorka::TraitFor::Sub::superbad');
	is foo3(), 43;
};

done_testing;
