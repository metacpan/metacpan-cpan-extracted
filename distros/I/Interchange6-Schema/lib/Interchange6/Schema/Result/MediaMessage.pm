use utf8;

package Interchange6::Schema::Result::MediaMessage;

=head1 NAME

Interchange6::Schema::Result::MediaMessage

=cut

use Interchange6::Schema::Candy;

=head1 ACCESSORS

=head2 media_id

FK on L<Interchange6::Schema::Result::Media/media_id>.

=cut

column media_id => { data_type => "integer" };

=head2 messages_id

FK on L<Interchange6::Schema::Result::Message/messages_id>.

=cut

column messages_id => { data_type => "integer" };

=head1 PRIMARY KEY

=over 4

=item * L</media_id>

=item * L</messages_id>

=back

=cut

primary_key "media_id", "messages_id";

=head1 RELATIONS

=head2 media

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Media>

=cut

belongs_to
  media => "Interchange6::Schema::Result::Media",
  "media_id";

=head2 message

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Message>

=cut

belongs_to
  message => "Interchange6::Schema::Result::Message",
  "messages_id";

1;
