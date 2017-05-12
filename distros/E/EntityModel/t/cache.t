use strict;
use warnings;
use Test::Class;

package EntityModel::Cache::Test;
use base qw(Test::Class);
use Test::More;
use Test::Deep;
use EntityModel::Cache;
use EntityModel;

sub test_cache : Test(17) {
	my $self = shift;
	my $cache = $self->{cache} or die 'no cache';
	can_ok($cache, $_) for qw(new get set remove incr decr atomic);

	my @cases = (
		[ 'int' => 123 ],
		[ 'string' => 'test' ],
		[ 'float' => 0.763 ],
		[ 'arrayref' => [1,2,3] ],
		[ 'hashref' => {a => 1, b => 2} ]
	);

	foreach (@cases) {
		ok($cache->set($_->[0], $_->[1]), 'set ' . $_->[0] . ' value');
		is_deeply($cache->get($_->[0]), $_->[1], 'get ' . $_->[0] . ' value');
	}
}

package EntityModel::Cache::PerlTest;
use base qw(EntityModel::Cache::Test);
use Test::More;
use EntityModel::Cache::Perl;

sub setup_cache : Test(startup => 2) {
	my $self = shift;

	my $cache = new_ok('EntityModel::Cache::Perl');
	isa_ok($cache, 'EntityModel::Cache');
	$self->{cache} = $cache;
}

package main;
Test::Class->runtests(qw(EntityModel::Cache::PerlTest));
