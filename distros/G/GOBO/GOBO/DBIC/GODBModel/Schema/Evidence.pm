=head1 GOBO::DBIC::GODBModel::Schema::Evidence


=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::Evidence;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('evidence');

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
			 code =>
			 {
			  data_type => 'varchar',
			  size      => 8,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => '',
			 },
			 association_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => '',
			 },
			 dbxref_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => '',
			 },
			 seq_acc =>
			 {
			  data_type => 'varchar',
			  size      => 255,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			);

##
__PACKAGE__->set_primary_key('id');

##
__PACKAGE__->belongs_to('association' =>
			'GOBO::DBIC::GODBModel::Schema::Association',
			'association_id');
__PACKAGE__->belongs_to('dbxref' =>
		      'GOBO::DBIC::GODBModel::Schema::DBXRef',
		      'dbxref_id');
#__PACKAGE__->belongs_to('evidence_dbxref' =>
#			'GOBO::DBIC::GODBModel::Schema::EvidenceDBXRef',
#			'evidence_id');
__PACKAGE__->has_many('evidence_dbxref' =>
		      'GOBO::DBIC::GODBModel::Schema::EvidenceDBXRef',
		      'evidence_id');

## TODO: need an index?
#__PACKAGE__->add_unique_constraint("a0", ["id"]);



1;
