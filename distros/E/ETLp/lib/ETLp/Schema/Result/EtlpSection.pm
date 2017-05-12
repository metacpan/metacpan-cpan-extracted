package ETLp::Schema::Result::EtlpSection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpSection

=cut

__PACKAGE__->table("etlp_section");

=head1 ACCESSORS

=head2 section_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 config_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 section_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 date_created

  data_type: 'datetime'
  is_nullable: 0
  original: {data_type => "date"}

=head2 date_updated

  data_type: 'datetime'
  is_nullable: 0
  original: {data_type => "date"}

=cut

__PACKAGE__->add_columns(
  "section_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "config_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "section_name",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "date_created",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "date_updated",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
);
__PACKAGE__->set_primary_key("section_id");
__PACKAGE__->add_unique_constraint("etlp_section_u1", ["config_id", "section_name"]);

=head1 RELATIONS

=head2 etlp_jobs

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpJob>

=cut

__PACKAGE__->has_many(
  "etlp_jobs",
  "ETLp::Schema::Result::EtlpJob",
  { "foreign.section_id" => "self.section_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 config

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpConfiguration>

=cut

__PACKAGE__->belongs_to(
  "config",
  "ETLp::Schema::Result::EtlpConfiguration",
  { config_id => "config_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 etlp_schedules

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpSchedule>

=cut

__PACKAGE__->has_many(
  "etlp_schedules",
  "ETLp::Schema::Result::EtlpSchedule",
  { "foreign.section_id" => "self.section_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-12 15:25:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G26RynkviOYeii2d5jGi5w

use Data::Page::Navigation;
# You can replace this text with custom content, and it will be preserved on regeneration
1;

