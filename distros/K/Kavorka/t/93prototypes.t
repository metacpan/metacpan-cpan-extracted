=pod

=encoding utf-8

=head1 PURPOSE

Check prototypes and attributes work.

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

use Kavorka;

fun foo :($) { 1 }
fun bar :prototype($) { 1 }
my $baz  = fun :($) { 1 };
my $quux = fun :prototype($) { 1 };

is(prototype(\&foo), '$');
is(prototype(\&bar), '$');
is(prototype($baz),  '$');
is(prototype($quux), '$');

fun xyzzy :prototype($$$) ($X, $Y, $Z) { 1 }
is(prototype(\&xyzzy), '$$$');

{
	use Attribute::Handlers;
	sub UNIVERSAL::Fooble :ATTR { };
}

subtest "Can distinguish between early attributes and signatures" => sub
{
	my $one = fun :Fooble ($x) { 1 };
	my $two = fun :Fooble($x)  { 2 };
	
	is(
		Kavorka->info($one)->attributes->[0][0],
		'Fooble',
	);
	
	is(
		Kavorka->info($one)->attributes->[0][1],
		undef,
	);
	
	is(
		Kavorka->info($one)->signature->params->[0]->name,
		'$x',
	);
	
	is(
		Kavorka->info($two)->attributes->[0][0],
		'Fooble',
	);
	
	is(
		Kavorka->info($two)->attributes->[0][1],
		'$x',
	);
	
	is(
		Kavorka->info($two)->signature,
		undef,
	);
};

done_testing;
