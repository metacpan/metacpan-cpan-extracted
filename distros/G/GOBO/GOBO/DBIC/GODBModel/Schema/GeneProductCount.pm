=head1 GOBO::DBIC::GODBModel::Schema::GeneProductCount

=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::GeneProductCount;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('gene_product_count');

__PACKAGE__->add_columns(
			 term_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 code =>
			 {
			  data_type => 'varchar',
			  size      => 8,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 speciesdbname =>
			 {
			  data_type => 'varchar',
			  size      => 55,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 species_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 product_count =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			);

##
#__PACKAGE__->set_primary_key('term_id');
#__PACKAGE__->set_primary_key('dbxref_id');
#__PACKAGE__->set_primary_key('is_for_definition');

##
__PACKAGE__->belongs_to('term' =>
			'GOBO::DBIC::GODBModel::Schema::Term',
			'term_id');
__PACKAGE__->might_have('species' =>
			'GOBO::DBIC::GODBModel::Schema::Species',
			{'foreign.id' => 'self.species_id'});

##
#__PACKAGE__->add_unique_constraint("evidence_id", ["evidence_id"]);
#__PACKAGE__->add_unique_constraint("dbxref_id", ["dbxref_id"]);
#__PACKAGE__->add_unique_constraint("g0", ["id"]);



1;
