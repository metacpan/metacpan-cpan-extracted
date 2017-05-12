=head1 GOBO::DBIC::GODBModel::Schema::Term2Term


=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::Term2Term;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('term2term');

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
			 relationship_type_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => '',
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
			 complete =>
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

##
#__PACKAGE__->belongs_to('term' =>
#			'GOBO::DBIC::GODBModel::Schema::Term', 'term1_id');
#__PACKAGE__->belongs_to('term' =>
#			'GOBO::DBIC::GODBModel::Schema::Term', 'term2_id');
__PACKAGE__->belongs_to('term1' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term1_id');
__PACKAGE__->belongs_to('term2' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term2_id');
__PACKAGE__->belongs_to('object' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term1_id');
__PACKAGE__->belongs_to('subject' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'term2_id');
__PACKAGE__->belongs_to('relationship' =>
			'GOBO::DBIC::GODBModel::Schema::Term', 'relationship_type_id');
## ...?
__PACKAGE__->belongs_to('graph_path' =>
			'GOBO::DBIC::GODBModel::Schema::GraphPath',
			{'foreign.term1_id' => 'self.term1_id',
			 'foreign.term2_id' => 'self.term2_id'});

##
#__PACKAGE__->add_unique_constraint("t0", ["id"]);
#__PACKAGE__->add_unique_constraint("acc", ["acc"]);


1;
