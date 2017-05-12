use utf8;

package Interchange6::Schema::Result::MediaType;

=head1 NAME

Interchange6::Schema::Result::MediaType

=head1 SYNOPSIS

This table holds the available media types to use in
L<Interchange6::Schema::Result::MediaDisplay>.

This table should hold only the "parent" type of a media, like
C<image> or C<video>.

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 media_types_id

Primary key.

=cut

primary_column media_types_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "media_types_media_types_id_seq",
};

=head2 type

Type of media, e.g.: image, video.

Unique constraint.

=cut

unique_column type => { data_type => "varchar", size => 32 };

=head1 RELATIONS

=head2 media_displays

Type: has_many

Related object: L<Interchange6::Schema::Result::MediaDisplay>

=cut

has_many
  media_displays => "Interchange6::Schema::Result::MediaDisplay",
  "media_types_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 media

Type: has_many

Related object: L<Interchange6::Schema::Result::Media>

=cut

has_many
  media => "Interchange6::Schema::Result::Media",
  "media_types_id",
  { cascade_copy => 0, cascade_delete => 0 };

1;
