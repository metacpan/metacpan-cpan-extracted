use utf8;
package Dwimmer::DB::Result::Feed;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Dwimmer::DB::Result::Feed

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<feeds>

=cut

__PACKAGE__->table("feeds");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 collector

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 feed

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "collector",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "feed",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 collector

Type: belongs_to

Related object: L<Dwimmer::DB::Result::FeedCollector>

=cut

__PACKAGE__->belongs_to(
  "collector",
  "Dwimmer::DB::Result::FeedCollector",
  { id => "collector" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07017 @ 2012-02-15 11:14:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qEU7f55BdkSg2NsBlx3kuQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
our $VERSION = '0.32';
1;
