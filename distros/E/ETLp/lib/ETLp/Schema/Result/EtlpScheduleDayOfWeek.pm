package ETLp::Schema::Result::EtlpScheduleDayOfWeek;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpScheduleDayOfWeek

=cut

__PACKAGE__->table("etlp_schedule_day_of_week");

=head1 ACCESSORS

=head2 schedule_dow_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 dow_id

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
  "schedule_dow_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "dow_id",
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
__PACKAGE__->set_primary_key("schedule_dow_id");

=head1 RELATIONS

=head2 dow

Type: belongs_to

Related object: L<ETLp::Schema::Result::EtlpDayOfWeek>

=cut

__PACKAGE__->belongs_to(
  "dow",
  "ETLp::Schema::Result::EtlpDayOfWeek",
  { dow_id => "dow_id" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mtaeeYoSfDZBDOhV8XrR2Q

use Data::Page::Navigation;

# You can replace this text with custom content, and it will be preserved on regeneration
1;
