=head1 GOBO::DBIC::GODBModel::Schema::Species


=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::Species;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('species');

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
			 ncbi_taxa_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 common_name =>
			 { data_type => 'varchar',
			   size      => 255,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 lineage_string =>
			 {
			  data_type => 'text',
			  size      => 65535,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 genus =>
			 { data_type => 'varchar',
			   size      => 55,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 species =>
			 { data_type => 'varchar',
			   size      => 255,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 parent_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 left_value =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 right_value =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 taxonomic_rank =>
			 { data_type => 'varchar',
			   size      => 255,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			);

##
__PACKAGE__->set_primary_key('id');

##
__PACKAGE__->has_many('gene_product' =>
		      'GOBO::DBIC::GODBModel::Schema::GeneProduct',
		      'species_id');
#__PACKAGE__->belongs_to('dbxref' =>
#			'GOBO::DBIC::GODBModel::Schema::DBXRef',
#			'dbxref_id');

##
__PACKAGE__->add_unique_constraint("ncbi_taxa_id", ["ncbi_taxa_id"]);
#__PACKAGE__->add_unique_constraint("g0", ["id"]);




1;
