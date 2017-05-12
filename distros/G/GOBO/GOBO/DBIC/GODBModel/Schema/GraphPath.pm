=head1 GOBO::DBIC::GODBModel::Schema::GraphPath


=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::GraphPath;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('graph_path');

__PACKAGE__->add_columns(
			 id =>
			 {
			  accessor  => 'id',#overrides default of 'id' (irony)
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 1,
			  default_value => undef,
			 },
			 term1_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => '',
			 },
			 term2_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => '',
			 },
			 distance =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => '',
			 },
			);

##
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to('term1' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term1_id');
__PACKAGE__->belongs_to('term2' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term2_id');
__PACKAGE__->belongs_to('object' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term1_id');
__PACKAGE__->belongs_to('subject' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term2_id');
__PACKAGE__->belongs_to('graph_object' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term1_id');
__PACKAGE__->belongs_to('graph_subject' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term2_id');

##
#__PACKAGE__->add_unique_constraint("t0", ["id"]);
#__PACKAGE__->add_unique_constraint("acc", ["acc"]);


1;
