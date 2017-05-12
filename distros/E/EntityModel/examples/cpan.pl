#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(say);
use EntityModel;
use EntityModel::Log qw(:all);
use IO::Async::Loop;
use CPAN::SQLite::Info;

my $model = EntityModel->new->load_from(
	Perl => {
		name => 'cpan',
		entity => [ {
			name => 'author',
			primary => 'cpan_id',
			field => [
				{ name => 'cpan_id', type => 'text' },
				{ name => 'fullname', type => 'text' },
				{ name => 'email', type => 'text' },
			],
		}, {
			name => 'distribution',
			primary => 'name',
			field => [
				{ name => 'name', type => 'text' },
				{ name => 'version', type => 'text' },
				{ name => 'file', type => 'text' },
				{ name => 'abstract', type => 'text' },
				{ name => 'idauthor', type => 'text', refer => [
					{ table => 'author', field => 'cpan_id' },
				] },
			],
		}, {
			name => 'module',
			primary => 'name',
			field => [
				{ name => 'name', type => 'text' },
				{ name => 'version', type => 'text' },
				{ name => 'dist_name', type => 'text', refer => [
					{ table => 'distribution', field => 'name' },
				] },
				{ name => 'abstract', type => 'text' },
				{ name => 'dslip', type => 'text' },
				{ name => 'idauthor', type => 'text', refer => [
					{ table => 'author', field => 'cpan_id' },
				] },
			],
		} ],
	}
)->add_storage(
	PerlAsync => { loop => IO::Async::Loop->new },
)->add_support(
	Perl => { }
);

my $info = CPAN::SQLite::Info->new(CPAN => $ENV{HOME} . '/.cpan/sources');
$info->fetch_info;

say 'Authors';
# First populate all the author entries
foreach my $author_key (keys %{$info->{auths}}) {
	my $a = Entity::Author->create({
		cpan_id => $author_key,
		fullname => $info->{auths}{$author_key}{fullname},
		email => $info->{auths}{$author_key}{email},
	})->commit;
}

say 'Distributions';
foreach my $dist_key (keys %{$info->{dists}}) {
	my $d = Entity::Distribution->create({
		name => $dist_key,
		version => $info->{dists}{$dist_key}{dist_vers},
		file => $info->{dists}{$dist_key}{dist_file},
		abstract => $info->{dists}{$dist_key}{dist_abs},
		cpan_id => $info->{dists}{$dist_key}{cpanid},
	})->commit;
}

say 'Modules';
foreach my $mod (keys %{$info->{mods}}) {
	my $m = Entity::Module->create({
		name => $mod,
		dist_name => $info->{mods}{$mod}{dist_name},
		version => $info->{mods}{$mod}{mod_vers},
		abstract => $info->{mods}{$mod}{mod_abs},
		dslip => $info->{mods}{$mod}{dslip},
		author => Entity::Distribution->new($info->{mods}{$mod}{dist_name})->author,
	})->commit;
}

say "My modules:";
say $_->name for Entity::Module->find({ author => Entity::Author->new('TEAM') });

