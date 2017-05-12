package ETLp::Schema::Result::EtlpFileProcess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpFileProcess

=cut

__PACKAGE__->table("etlp_file_process");

=head1 ACCESSORS

=head2 file_proc_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 item_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 file_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 filename

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 record_count

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

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
  "file_proc_id",
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
  "item_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "file_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "filename",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "record_count",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
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
__PACKAGE__->set_primary_key("file_proc_id");

=head1 RELATIONS

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

=head2 file

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpFile>

=cut

__PACKAGE__->belongs_to(
  "file",
  "ETLp::Schema::Result::EtlpFile",
  { file_id => "file_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 item

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpItem>

=cut

__PACKAGE__->belongs_to(
  "item",
  "ETLp::Schema::Result::EtlpItem",
  { item_id => "item_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-12 15:25:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hwsRKuuXljAzGf/GrUN0Ww

use Data::Page::Navigation;

# You can replace this text with custom content, and it will be preserved on regeneration
1;
