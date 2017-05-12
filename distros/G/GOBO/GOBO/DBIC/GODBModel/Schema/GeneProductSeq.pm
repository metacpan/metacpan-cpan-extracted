=head1 GOBO::DBIC::GODBModel::Schema::GeneProductSeq


=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::GeneProductSeq;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('gene_product_seq');

__PACKAGE__->add_columns(
			 gene_product_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 seq_id =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 0,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 is_primary_seq =>
			 {
			  data_type => 'integer',
			  size      => 11,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			);

##
#__PACKAGE__->set_primary_key('gene_product_id');
#__PACKAGE__->set_primary_key('product_synonym');

__PACKAGE__->belongs_to('gene_product' =>
                        'GOBO::DBIC::GODBModel::Schema::GeneProduct', 'gene_product_id');
__PACKAGE__->belongs_to('seq' =>
                        'GOBO::DBIC::GODBModel::Schema::Seq', 'seq_id');

#__PACKAGE__->add_unique_constraint("g0", ["id"]);



1;
