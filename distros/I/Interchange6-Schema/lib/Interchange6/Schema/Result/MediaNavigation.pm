use utf8;

package Interchange6::Schema::Result::MediaNavigation;

=head1 NAME

Interchange6::Schema::Result::MediaNavigation

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 media_id

FK on L<Interchange6::Schema::Result::Media/media_id>.

=cut

column media_id => { data_type => "integer" };

=head2 navigation_id

FK on L<Interchange6::Schema::Result::Navigation/navigation_id>.

=cut

column navigation_id => { data_type => "integer" };

=head1 PRIMARY KEY

=over 4

=item * L</media_id>

=item * L</navigation_id>

=back

=cut

primary_key "media_id", "navigation_id";

=head1 RELATIONS

=head2 media

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Media>

=cut

belongs_to
  media => "Interchange6::Schema::Result::Media",
  "media_id";

=head2 navigation

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Navigation>

=cut

belongs_to
  navigation => "Interchange6::Schema::Result::Navigation",
  "navigation_id";

1;
