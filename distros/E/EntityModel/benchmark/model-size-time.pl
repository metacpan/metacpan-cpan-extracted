#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes ();
use EntityModel;

my $name = 'aaaaaaaaaaa';
for my $entity_count (qw(1 2 5 10 20 50 100 200 500 1000 2000)) {
# for my $entity_count (qw(1 2 5 10 20 50 100 200 500 1000 2000 5000 10000 20000 50000 100000 200000 500000 1000000)) {
	my @entities;
	for my $idx (1..$entity_count) {
		push @entities, {
			"name" => $name,
			"primary" => "id$name",
			"field" => [
				{ "name" => "id$name", "type" => "bigserial" },
				{ "name" => "name", "type" => "varchar" },
				{ "name" => "other", "type" => "varchar" }
			]
		};
		++$name;
	}
	my $start = Time::HiRes::time;
	my $model = EntityModel->new;
	my $now = Time::HiRes::time;
	$model->load_from(
		Perl	=> {
			"name"	=> "mymodel",
			"entity"	=> \@entities
		}
	);
	my $now2 = Time::HiRes::time;
	my $load = 1000.0 * ($now2 - $now);
	$now = $now2;
	$model->add_storage(Perl => {});
	$now2 = Time::HiRes::time;
	my $storage = 1000.0 * ($now2 - $now);
	$now = $now2;
	$model->add_support(Perl => {});
	$now2 = Time::HiRes::time;
	my $perl = 1000.0 * ($now2 - $now);
	$now = $now2;
	printf("%9d %12.3f %12.3f %12.3f %12.3f\n", $entity_count, $load, $storage, $perl, 1000.0 * ($now - $start));
}

