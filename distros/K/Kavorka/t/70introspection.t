=pod

=encoding utf-8

=head1 PURPOSE

Test the introspection API.

This only tests a very limited subset of it; much of the API is used
during signature injection, so already gets tested that way.

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
	
	fun Example::foo :(@)                      { return $_[1] }
	fun bar ($Debbie: $x, :$y, %z) { return $_[1] }
}

is(Example::foo(1, 2, y => 3, z => 4), 2,   'foo works');
is(Example::bar(1, 2, y => 3, z => 4), 'y', 'bar works');

my ($foo, $bar) = map Kavorka->info( Example->can($_) ), qw/ foo bar /;

ok($foo->DOES('Kavorka::Sub'), q/$foo->DOES('Kavorka::Sub')/);
is($foo->keyword, 'fun', '$foo->keyword');
is($foo->declared_name, 'Example::foo', '$foo->declared_name');
is($foo->qualified_name, 'Example::foo', '$foo->qualified_name');

is($foo->signature, undef, '$foo->signature')
	or diag explain($foo);

is($foo->prototype, '@', '$foo->prototype');

ok($bar->DOES('Kavorka::Sub'), q/$bar->DOES('Kavorka::Sub')/);
is($bar->keyword, 'fun', '$bar->keyword');
is($bar->declared_name, 'bar', '$bar->declared_name');
is($bar->qualified_name, 'Example::bar', '$bar->qualified_name');;
is($bar->prototype, undef, '$bar->prototype');

my $sig = $bar->signature;
ok($sig->DOES('Kavorka::Signature'), q/$bar->signature->DOES('Kavorka::Signature')/);
is($sig->args_min, 1, '$bar->signature->args_min');
is($sig->args_max, undef, '$bar->signature->args_max');
is_deeply(
	[ map $_->name, $sig->invocants ],
	[ '$Debbie' ],
	q/$bar->signature->invocants/,
);
is_deeply(
	[ map $_->name, $sig->positional_params ],
	[ '$x' ],
	q/$bar->signature->positional_params/,
);
is_deeply(
	[ map @{ $_->named_names or die }, $sig->named_params ],
	[ 'y' ],
	q/$bar->signature->named_params/,
);
is(
	$sig->slurpy_param->name,
	'%z',
	q/$bar->signature->slurpy_param/,
);

{
	package ZZZZ;
	use Kavorka;
	my $info = Kavorka->info(fun ($x) { 42 });
	
	::is($info->package, 'ZZZZ', 'introspection of anon function - A');
	::is($info->signature->params->[0]->name, '$x', 'introspection of anon function - B');
	
	::is($info->(undef), 42, 'overload &{}');
}

done_testing;

