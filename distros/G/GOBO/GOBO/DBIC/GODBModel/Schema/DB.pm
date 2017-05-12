=head1 GOBO::DBIC::GODBModel::Schema::DB


=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::DB;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('db');

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
			 name =>
			 { data_type => 'varchar',
			   size      => 55,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 fullname =>
			 { data_type => 'varchar',
			   size      => 255,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 datatype =>
			 { data_type => 'varchar',
			   size      => 255,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 generic_url =>
			 { data_type => 'varchar',
			   size      => 255,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 url_syntax =>
			 { data_type => 'varchar',
			   size      => 255,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 url_example =>
			 {
			  data_type => 'varchar',
			  size      => 255,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			 uri_prefix =>
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
__PACKAGE__->add_unique_constraint("name", ["name"]);




1;
