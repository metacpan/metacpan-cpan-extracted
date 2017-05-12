package ETLp::Schema::Result::EtlpItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpItem

=cut

__PACKAGE__->table("etlp_item");

=head1 ACCESSORS

=head2 item_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 job_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 phase_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 item_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 item_type

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=head2 message

  data_type: 'clob'
  is_nullable: 1

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
  "item_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "status_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "job_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "phase_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "item_name",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "item_type",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "message",
  { data_type => "clob", is_nullable => 1 },
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
__PACKAGE__->set_primary_key("item_id");

=head1 RELATIONS

=head2 etlp_file_processes

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpFileProcess>

=cut

__PACKAGE__->has_many(
  "etlp_file_processes",
  "ETLp::Schema::Result::EtlpFileProcess",
  { "foreign.item_id" => "self.item_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phase

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpPhase>

=cut

__PACKAGE__->belongs_to(
  "phase",
  "ETLp::Schema::Result::EtlpPhase",
  { phase_id => "phase_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 job

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpJob>

=cut

__PACKAGE__->belongs_to(
  "job",
  "ETLp::Schema::Result::EtlpJob",
  { job_id => "job_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 status

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "ETLp::Schema::Result::EtlpStatus",
  { status_id => "status_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-12 15:25:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J16Zy9m1o8bWMU6HHSBTvw

use Data::Page::Navigation;
# You can replace this text with custom content, and it will be preserved on regeneration
1;
