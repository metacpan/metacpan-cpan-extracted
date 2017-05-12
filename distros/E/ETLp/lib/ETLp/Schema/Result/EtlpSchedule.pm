package ETLp::Schema::Result::EtlpSchedule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpSchedule

=cut

__PACKAGE__->table("etlp_schedule");

=head1 ACCESSORS

=head2 schedule_id

  is_auto_increment: 1

=head2 section_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 user_updated

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 user_created

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 schedule_description

  data_type: 'clob'
  is_nullable: 1

=head2 schedule_comment

  data_type: 'clob'
  is_nullable: 1

=head2 status

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

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
  "schedule_id",
  { is_auto_increment => 1 },
  "section_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "user_updated",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "user_created",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "schedule_description",
  { data_type => "clob", is_nullable => 1 },
  "schedule_comment",
  { data_type => "clob", is_nullable => 1 },
  "status",
  {
    data_type     => "integer",
    default_value => 1,
    is_nullable   => 0,
    original      => { data_type => "number", size => [38, 0] },
  },
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
__PACKAGE__->set_primary_key("schedule_id");

=head1 RELATIONS

=head2 user_created

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpUser>

=cut

__PACKAGE__->belongs_to(
  "user_created",
  "ETLp::Schema::Result::EtlpUser",
  { user_id => "user_created" },
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

=head2 user_updated

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpUser>

=cut

__PACKAGE__->belongs_to(
  "user_updated",
  "ETLp::Schema::Result::EtlpUser",
  { user_id => "user_updated" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 etlp_schedule_days_of_month

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpScheduleDayOfMonth>

=cut

__PACKAGE__->has_many(
  "etlp_schedule_days_of_month",
  "ETLp::Schema::Result::EtlpScheduleDayOfMonth",
  { "foreign.schedule_id" => "self.schedule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 etlp_schedule_days_of_week

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpScheduleDayOfWeek>

=cut

__PACKAGE__->has_many(
  "etlp_schedule_days_of_week",
  "ETLp::Schema::Result::EtlpScheduleDayOfWeek",
  { "foreign.schedule_id" => "self.schedule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 etlp_schedule_hours

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpScheduleHour>

=cut

__PACKAGE__->has_many(
  "etlp_schedule_hours",
  "ETLp::Schema::Result::EtlpScheduleHour",
  { "foreign.schedule_id" => "self.schedule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 etlp_schedule_minutes

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpScheduleMinute>

=cut

__PACKAGE__->has_many(
  "etlp_schedule_minutes",
  "ETLp::Schema::Result::EtlpScheduleMinute",
  { "foreign.schedule_id" => "self.schedule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 etlp_schedule_months

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpScheduleMonth>

=cut

__PACKAGE__->has_many(
  "etlp_schedule_months",
  "ETLp::Schema::Result::EtlpScheduleMonth",
  { "foreign.schedule_id" => "self.schedule_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-25 13:03:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e1lV06l6VpdE2BIajCMxlw

use Data::Page::Navigation;

# You can replace this text with custom content, and it will be preserved on regeneration
1;
