use utf8;
package Dwimmer::DB::Result::PageHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dwimmer::DB::Result::PageHistory

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<page_history>

=cut

__PACKAGE__->table("page_history");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 pageid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 revision

  data_type: 'integer'
  is_nullable: 0

=head2 siteid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 body

  data_type: 'blob'
  is_nullable: 1

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 abstract

  data_type: 'blob'
  is_nullable: 1

=head2 filename

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 timestamp

  data_type: 'integer'
  is_nullable: 0

=head2 author

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "pageid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "revision",
  { data_type => "integer", is_nullable => 0 },
  "siteid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "body",
  { data_type => "blob", is_nullable => 1 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "abstract",
  { data_type => "blob", is_nullable => 1 },
  "filename",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "timestamp",
  { data_type => "integer", is_nullable => 0 },
  "author",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<Dwimmer::DB::Result::User>

=cut

__PACKAGE__->belongs_to(
  "author",
  "Dwimmer::DB::Result::User",
  { id => "author" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 pageid

Type: belongs_to

Related object: L<Dwimmer::DB::Result::Page>

=cut

__PACKAGE__->belongs_to(
  "pageid",
  "Dwimmer::DB::Result::Page",
  { id => "pageid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 siteid

Type: belongs_to

Related object: L<Dwimmer::DB::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "siteid",
  "Dwimmer::DB::Result::Site",
  { id => "siteid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-02-15 11:13:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jMCkzMyVWLGHhj+NBTMHZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
our $VERSION = '0.32';
1;
