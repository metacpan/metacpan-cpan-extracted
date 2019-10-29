=pod

=encoding utf-8

=head1 PURPOSE

Test that JSON::Eval compiles and works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use_ok('JSON::Eval');

{
	package Local::Foo;
	sub new { bless {}, shift }
	sub TO_JSON {
		{ '$eval' => 'do { eval { require Local::Foo }; Local::Foo->new }' };
	}
}

my $encoder  = JSON::Eval->new;
my $jsontext = $encoder->encode({
	coderefs => [
		sub { "x" },
		sub { "y" },
		sub { "z" },
	],
	object => "Local::Foo"->new,
	scalarrefs => [
		\1,
		\2,
		\3,
		\ [ \42 ],
	],
});

like($jsontext, qr/\$eval/, 'there is some JSON text that looks kinda okayish');

my $decoded = $encoder->decode($jsontext);

is($decoded->{coderefs}[0]->(), 'x', '$decoded->{coderefs}[0]');
is($decoded->{coderefs}[1]->(), 'y', '$decoded->{coderefs}[1]');
is($decoded->{coderefs}[2]->(), 'z', '$decoded->{coderefs}[2]');

isa_ok($decoded->{object}, 'Local::Foo', '$decoded->{object}');

is(${ $decoded->{scalarrefs}[0] }, 1, '$decoded->{scalarrefs}[0]');
is(${ $decoded->{scalarrefs}[1] }, 2, '$decoded->{scalarrefs}[1]');
is(${ $decoded->{scalarrefs}[2] }, 3, '$decoded->{scalarrefs}[2]');

my $thing = ${ $decoded->{scalarrefs}[3] };
is(ref($thing), 'ARRAY', '$decoded->{scalarrefs}[3]');
is(${ $thing->[0] }, 42, '$decoded->{scalarrefs}[3][0]');

done_testing;

