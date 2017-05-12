#!/usr/bin/perl
use strict;
use warnings;
use EntityModel;
use EntityModel::Web::PSGI;
my $model = EntityModel->new->add_plugin(Web => {
})->load_from(JSON => {
	file		=> $ENV{ENTITYMODEL_JSON_MODEL}
#	})->load_from(XML => {
#		file		=> $ENV{ENTITYMODEL_XML_MODEL}
})->add_storage(Perl => {
	schema		=> $ENV{ENTITYMODEL_PG_SCHEMA},
	user		=> $ENV{ENTITYMODEL_PG_USER},
	password	=> $ENV{ENTITYMODEL_PG_PASSWORD},
	host		=> $ENV{ENTITYMODEL_PG_HOST},
})->add_support(Perl => {
});
my $app = EntityModel::Web::PSGI->new;
my ($web) = grep $_->isa('EntityModel::Web'), $model->plugin->list;
my $tmpl = EntityModel::Template->new(
	include_path	=> $ENV{ENTITYMODEL_TEMPLATE_PATH}
);
$tmpl->process_template(\qq{[% PROCESS Main.tt2 %]});
$app->template($tmpl);
$app->web($web);
sub {
# Ignore favicon requests
	my $env = shift;
	return [ 404, [], ['Not found'] ] if $env->{REQUEST_URI} eq '/favicon.ico';
	$app->run_psgi($env, @_);
};
