=head1 GOBO::DBIC::GODBModel::Schema::InstanceData

DB unique instance data.

=cut

use utf8;
use strict;

package GOBO::DBIC::GODBModel::Schema::InstanceData;

## TODO: Make sure that GOBO::DBIC::GODBModel
#use base ("GOBO::DBIC::GODBModel");
use base qw/DBIx::Class/;

##
__PACKAGE__->load_components(qw/ PK::Auto Core /);

__PACKAGE__->table('instance_data');

__PACKAGE__->add_columns(
			 release_name =>
			 { data_type => 'varchar',
			   size      => 255,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 release_type =>
			 { data_type => 'varchar',
			   size      => 255,
			   is_nullable => 1,
			   is_auto_increment => 0,
			   default_value => undef,
			 },
			 release_notes =>
			 {
			  data_type => 'text',
			  size      => 65535,
			  is_nullable => 1,
			  is_auto_increment => 0,
			  default_value => undef,
			 },
			);

## DB unique, so don't have one.
#__PACKAGE__->set_primary_key('id');

##
__PACKAGE__->add_unique_constraint("release_name", ["release_name"]);



1;
