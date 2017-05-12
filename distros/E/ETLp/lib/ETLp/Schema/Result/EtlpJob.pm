package ETLp::Schema::Result::EtlpJob;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpJob

=cut

__PACKAGE__->table("etlp_job");

=head1 ACCESSORS

=head2 job_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 section_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 session_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 process_id

  data_type: 'integer'
  is_nullable: 0
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
  "job_id",
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
  "section_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "session_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "process_id",
  {
    data_type   => "integer",
    is_nullable => 0,
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
__PACKAGE__->set_primary_key("job_id");

=head1 RELATIONS

=head2 etlp_items

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpItem>

=cut

__PACKAGE__->has_many(
  "etlp_items",
  "ETLp::Schema::Result::EtlpItem",
  { "foreign.job_id" => "self.job_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 section

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpSection>

=cut

__PACKAGE__->belongs_to(
  "section",
  "ETLp::Schema::Result::EtlpSection",
  { section_id => "section_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-12 15:25:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KJt4Ggq1rlvt2pfPTsvlXw

use Data::Page::Navigation;
# You can replace this text with custom content, and it will be preserved on regeneration
1;
