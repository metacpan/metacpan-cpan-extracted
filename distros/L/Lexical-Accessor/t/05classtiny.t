=pod

=encoding utf-8

=head1 PURPOSE

Test that Lexical::Accessor works with Class::Tiny.

=head1 DEPENDENCIES

Class::Tiny 0.006; skipped otherwise.

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
use Test::Requires { 'Class::Tiny', '0.006' };
use Test::Fatal;

my $trigger;
my ($ggg, $get_ggg, $set_ggg, $has_ggg, $clear_ggg);

# *_rv is the return value
my ($aaa, $aaa_rv);  # rw
my ($get_bbb, $get_bbb_rv);  # ro
my ($get_ccc, $get_ccc_rv, $set_ccc, $set_ccc_rv);  # rwp
my ($get_ddd, $get_ddd_rv);  # lazy

{
	package Grimy;
	
	use Class::Tiny;
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
	
	$aaa_rv = lexical_has aaa => (
		is => 'rw',
		accessor => \$aaa,
	);
	
	$get_bbb_rv = lexical_has bbb => (
		is => 'ro',
		reader => \$get_bbb,
	);
	
	($get_ccc_rv, $set_ccc_rv) = lexical_has ccc => (
		is => 'rwp',
		reader => \$get_ccc,
		writer => \$set_ccc,
	);
	
	$get_ddd_rv = lexical_has ddd => (
		is => 'lazy',
		reader => \$get_ddd,
		default => sub { 42 },
	);
}

my $g1 = Grimy->new;
my $g2 = Grimy->new;

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

is($aaa_rv, $aaa, 'correct accessor returned for is => rw');
is($get_bbb_rv, $get_bbb, 'correct getter returned for is => ro');
is($get_ccc_rv, $get_ccc, 'correct getter returned for is => rwp');
is($set_ccc_rv, $set_ccc, 'correct setter returned for is => rwp');
is($get_ddd_rv, $get_ddd, 'correct reader returned for is => lazy');

done_testing;
