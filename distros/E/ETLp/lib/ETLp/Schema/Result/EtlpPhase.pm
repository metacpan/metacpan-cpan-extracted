package ETLp::Schema::Result::EtlpPhase;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpPhase

=cut

__PACKAGE__->table("etlp_phase");

=head1 ACCESSORS

=head2 phase_id

  is_auto_increment: 1

=head2 phase_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "phase_id",
  { is_auto_increment => 1 },
  "phase_name",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
);
__PACKAGE__->set_primary_key("phase_id");
__PACKAGE__->add_unique_constraint("etl_phase_u1", ["phase_name"]);

=head1 RELATIONS

=head2 etlp_items

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpItem>

=cut

__PACKAGE__->has_many(
  "etlp_items",
  "ETLp::Schema::Result::EtlpItem",
  { "foreign.phase_id" => "self.phase_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-12 15:25:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kIL+Q/y7WrUlLuCmGC7B3Q

use Data::Page::Navigation;
# You can replace this text with custom content, and it will be preserved on regeneration
1;
