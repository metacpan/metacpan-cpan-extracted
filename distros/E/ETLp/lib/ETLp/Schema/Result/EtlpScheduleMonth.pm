package ETLp::Schema::Result::EtlpScheduleMonth;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpScheduleMonth

=cut

__PACKAGE__->table("etlp_schedule_month");

=head1 ACCESSORS

=head2 schedule_month_id

  is_auto_increment: 1

=head2 month_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 schedule_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=cut

__PACKAGE__->add_columns(
  "schedule_month_id",
  { is_auto_increment => 1 },
  "month_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "schedule_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
);
__PACKAGE__->set_primary_key("schedule_month_id");

=head1 RELATIONS

=head2 month

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpMonth>

=cut

__PACKAGE__->belongs_to(
  "month",
  "ETLp::Schema::Result::EtlpMonth",
  { month_id => "month_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 schedule

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpSchedule>

=cut

__PACKAGE__->belongs_to(
  "schedule",
  "ETLp::Schema::Result::EtlpSchedule",
  { schedule_id => "schedule_id" },
  { on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-25 13:03:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DOdaEMRohVfIfkPWqUmuDQ

use Data::Page::Navigation;

# You can replace this text with custom content, and it will be preserved on regeneration
1;
