=head1 GOBO::DBIC::GODBModel::Schema::GeneProduct


=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::GeneProduct;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('gene_product');

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
			 symbol =>
			 { data_type => 'varchar',
			   size      => 128,
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
			 species_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 type_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 full_name =>
			 {
			  data_type => 'text',
			  size      => 65535,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			);

##
__PACKAGE__->set_primary_key('id');

##
__PACKAGE__->has_many('association' =>
		      'GOBO::DBIC::GODBModel::Schema::Association',
		      'gene_product_id');
__PACKAGE__->has_many('association_aux' =>
		      'GOBO::DBIC::GODBModel::Schema::Association',
		      'gene_product_id');
__PACKAGE__->has_many('gene_product_seq' =>
		      'GOBO::DBIC::GODBModel::Schema::GeneProductSeq',
		      'gene_product_id');
__PACKAGE__->has_many('gene_product_synonym' =>
		      'GOBO::DBIC::GODBModel::Schema::GeneProductSynonym',
		      'gene_product_id');
__PACKAGE__->might_have('gene_product_homolset' =>
		      'GOBO::DBIC::GODBModel::Schema::GeneProductHomolset',
		      'gene_product_id');
__PACKAGE__->belongs_to('dbxref' =>
			'GOBO::DBIC::GODBModel::Schema::DBXRef',
			'dbxref_id');
__PACKAGE__->belongs_to('species' =>
			'GOBO::DBIC::GODBModel::Schema::Species',
			'species_id');

__PACKAGE__->belongs_to('type' =>
			'GOBO::DBIC::GODBModel::Schema::Term',
			'type_id');



##
__PACKAGE__->add_unique_constraint("dbxref_id", ["dbxref_id"]);
__PACKAGE__->add_unique_constraint("g0", ["id"]);




1;
