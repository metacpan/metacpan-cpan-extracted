package ETLp::Schema::Result::EtlpDayOfWeek;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpDayOfWeek

=cut

__PACKAGE__->table("etlp_day_of_week");

=head1 ACCESSORS

=head2 dow_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 day_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 cron_day_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=cut

__PACKAGE__->add_columns(
  "dow_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "day_name",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "cron_day_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
);
__PACKAGE__->set_primary_key("dow_id");
__PACKAGE__->add_unique_constraint("sys_c00192894", ["day_name"]);

=head1 RELATIONS

=head2 etlp_schedule_days_of_week

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpScheduleDayOfWeek>

=cut

__PACKAGE__->has_many(
  "etlp_schedule_days_of_week",
  "ETLp::Schema::Result::EtlpScheduleDayOfWeek",
  { "foreign.dow_id" => "self.dow_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-25 13:03:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3a7i/IB+E8+bjxex4E56zw

use Data::Page::Navigation;

# You can replace this text with custom content, and it will be preserved on regeneration
1;
