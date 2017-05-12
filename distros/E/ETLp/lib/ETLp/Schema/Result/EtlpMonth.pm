package ETLp::Schema::Result::EtlpMonth;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpMonth

=cut

__PACKAGE__->table("etlp_month");

=head1 ACCESSORS

=head2 month_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 month_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "month_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "month_name",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
);
__PACKAGE__->set_primary_key("month_id");
__PACKAGE__->add_unique_constraint("sys_c00192902", ["month_name"]);

=head1 RELATIONS

=head2 etlp_schedule_months

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpScheduleMonth>

=cut

__PACKAGE__->has_many(
  "etlp_schedule_months",
  "ETLp::Schema::Result::EtlpScheduleMonth",
  { "foreign.month_id" => "self.month_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-25 13:03:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sFWOblDSrnIdiX5X0iXBeg

use Data::Page::Navigation;

# You can replace this text with custom content, and it will be preserved on regeneration
1;
