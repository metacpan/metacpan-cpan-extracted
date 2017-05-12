=head1 GOBO::DBIC::GODBModel::Schema::EvidenceDBXRef

BUG: hrm...something wrong here...can't link out from here. JOIN
issues? use seq_acc instead

=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::EvidenceDBXRef;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('evidence_dbxref');

__PACKAGE__->add_columns(
			 evidence_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 dbxref_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			);

##
#__PACKAGE__->set_primary_key('id');

##
__PACKAGE__->belongs_to('evidence' =>
			'GOBO::DBIC::GODBModel::Schema::Evidence',
			'evidence_id');
__PACKAGE__->belongs_to('dbxref' =>
			'GOBO::DBIC::GODBModel::Schema::DBXRef',
			'dbxref_id');

##
#__PACKAGE__->add_unique_constraint("evidence_id", ["evidence_id"]);
#__PACKAGE__->add_unique_constraint("dbxref_id", ["dbxref_id"]);
#__PACKAGE__->add_unique_constraint("g0", ["id"]);



1;
