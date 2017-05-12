package ETLp::Schema::Result::EtlpAppConfig;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpAppConfig

=cut

__PACKAGE__->table("etlp_app_config");

=head1 ACCESSORS

=head2 parameter

  data_type: 'varchar2'
  is_nullable: 0
  size: 50

=head2 value

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "parameter",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
  "value",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("parameter");


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-25 13:03:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VwX8jpxHTqqZ1KM42VxxXw

use Data::Page::Navigation;

# You can replace this text with custom content, and it will be preserved on regeneration
1;
