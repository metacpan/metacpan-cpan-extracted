#!/usr/bin/perl 
use strict;
use warnings;
use IO::Async::Loop;
use EntityModel;
use EntityModel::Web;
use EntityModel::Web::NaFastCGI;

my $loop = IO::Async::Loop->new;
my $model = EntityModel->new->add_plugin(Web => {
})->load_from(JSON => {
	file		=> $ENV{ENTITYMODEL_JSON_MODEL}
})->add_storage(PostgreSQL => {
	schema		=> $ENV{ENTITYMODEL_PG_SCHEMA},
	user		=> $ENV{ENTITYMODEL_PG_USER},
	password	=> $ENV{ENTITYMODEL_PG_PASSWORD},
	host		=> $ENV{ENTITYMODEL_PG_HOST},
})->add_support(Perl => {
});

my $tmpl = EntityModel::Template->new(
	include_path	=> $ENV{ENTITYMODEL_TEMPLATE_PATH}
);
$tmpl->process_template(\qq{[% PROCESS $ENV{ENTITYMODEL_TEMPLATE_MAIN} %]}) if $ENV{ENTITYMODEL_TEMPLATE_MAIN};

my $fcgi = EntityModel::Web::NaFastCGI->new(
	model		=> $model,
	context_args	=> [
		template	=> $tmpl,
	],
	show_timing	=> 1,
);

$loop->add($fcgi);
$fcgi->listen(
	service	=> 9738,
	on_listen_error => sub { die "Listen failed: @_"; },
	on_resolve_error => sub { die "Resolve failed: @_"; }
);
warn "Starting up\n";
$loop->loop_forever;

