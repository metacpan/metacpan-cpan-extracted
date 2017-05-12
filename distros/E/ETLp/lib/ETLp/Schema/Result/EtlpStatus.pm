package ETLp::Schema::Result::EtlpStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpStatus

=cut

__PACKAGE__->table("etlp_status");

=head1 ACCESSORS

=head2 status_id

  is_auto_increment: 1

=head2 status_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "status_id",
  { is_auto_increment => 1 },
  "status_name",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
);
__PACKAGE__->set_primary_key("status_id");
__PACKAGE__->add_unique_constraint("etlp_status_u1", ["status_name"]);

=head1 RELATIONS

=head2 etlp_file_processes

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpFileProcess>

=cut

__PACKAGE__->has_many(
  "etlp_file_processes",
  "ETLp::Schema::Result::EtlpFileProcess",
  { "foreign.status_id" => "self.status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 etlp_items

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpItem>

=cut

__PACKAGE__->has_many(
  "etlp_items",
  "ETLp::Schema::Result::EtlpItem",
  { "foreign.status_id" => "self.status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 etlp_jobs

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpJob>

=cut

__PACKAGE__->has_many(
  "etlp_jobs",
  "ETLp::Schema::Result::EtlpJob",
  { "foreign.status_id" => "self.status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-12 15:25:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+16aRUB2npzcJScXoZV28g

use Data::Page::Navigation;
# You can replace this text with custom content, and it will be preserved on regeneration
1;
