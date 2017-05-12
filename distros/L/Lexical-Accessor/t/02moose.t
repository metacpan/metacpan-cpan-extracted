=pod

=encoding utf-8

=head1 PURPOSE

Test that Lexical::Accessor works with Moose.

=head1 DEPENDENCIES

Moose 2.0000; skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More 0.96;
use Test::Requires { 'Moose', '2.0000' };
use Test::Fatal;

my $trigger;
my ($ggg, $get_ggg, $set_ggg, $has_ggg, $clear_ggg);

{
	package Goose;
	
	use Moose;
	use Types::Standard qw(Str ArrayRef);
	use Lexical::Accessor;
	
	lexical_has ggg => (
		accessor   => \$ggg,
		reader     => \$get_ggg,
		writer     => \$set_ggg,
		predicate  => \$has_ggg,
		clearer    => \$clear_ggg,
		isa        => Str->plus_coercions(ArrayRef, q[join('', @$_)]),
		coerce     => 1,
		trigger    => sub { ++$trigger },
	);
}

my $g1 = Goose->new;
my $g2 = Goose->new;

ok(!$g1->$has_ggg, 'predicate');
ok(!$g2->$has_ggg, 'predicate');

$g1->$set_ggg([qw/ foo bar /]);
ok( $g1->$has_ggg, 'setter makes value visible to predicate');
ok(!$g2->$has_ggg, '... does not mix up objects');
is($g1->$ggg, 'foobar', '... and visible to accessor called as getter');
is($g2->$ggg, undef, '... does not mix up objects');
is($g1->$get_ggg, 'foobar', '... and visible to reader');
is($g2->$get_ggg, undef, '... does not mix up objects');

$g2->$ggg('xyz', 'abc');
ok( $g1->$has_ggg, 'accessor called as setter makes value visible to predicate');
ok( $g2->$has_ggg, '... does not mix up objects');
is($g1->$ggg, 'foobar', '... and visible to accessor called as getter');
is($g2->$ggg, 'xyz', '... does not mix up objects');
is($g1->$get_ggg, 'foobar', '... and visible to reader');
is($g2->$get_ggg, 'xyz', '... does not mix up objects');

$g1->$clear_ggg;
ok(!$g1->$has_ggg, 'clearer');
ok( $g2->$has_ggg, '... does not mix up objects');

undef($g1);
undef($g2);

is($trigger, 2, 'triggers work');
ok(!keys %Sub::Accessor::Small::FIELDS, 'no leaks');

done_testing;
