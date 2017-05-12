#!/usr/bin/perl 
use strict;
use warnings;

use EntityModel::Log ':all';
BEGIN { EntityModel::Log->instance->path('/var/log/apache2/entitymodel.log')->min_level(1) }
use EntityModel;
use EntityModel::Web;
use EntityModel::Web::Apache2;

our $MODEL;
our $WEB;
BEGIN {
	$MODEL = EntityModel->new->add_plugin($WEB = EntityModel::Web->new)->load_from(
		JSON	=> { file => $ENV{ENTITYMODEL_WEB_MODEL} }
	);
}

1;
