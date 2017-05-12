package ETLp::Schema::Result::EtlpFile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

ETLp::Schema::Result::EtlpFile

=cut

__PACKAGE__->table("etlp_file");

=head1 ACCESSORS

=head2 file_id

  is_auto_increment: 1

=head2 canonical_filename

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

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
  "file_id",
  { is_auto_increment => 1 },
  "canonical_filename",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
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
__PACKAGE__->set_primary_key("file_id");

=head1 RELATIONS

=head2 etlp_file_processes

Type: has_many

Related object: L<ETLp::Schema::Result::EtlpFileProcess>

=cut

__PACKAGE__->has_many(
  "etlp_file_processes",
  "ETLp::Schema::Result::EtlpFileProcess",
  { "foreign.file_id" => "self.file_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-05-12 15:25:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZKh77wWHKNOgoVxvtPTKjg

use Data::Page::Navigation;
# You can replace this text with custom content, and it will be preserved on regeneration
1;
