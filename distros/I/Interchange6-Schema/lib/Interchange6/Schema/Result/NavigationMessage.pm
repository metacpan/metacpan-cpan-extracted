use utf8;

package Interchange6::Schema::Result::NavigationMessage;

=head1 NAME

Interchange6::Schema::Result::NavigationMessage

=cut

use Interchange6::Schema::Candy;

=head1 DESCRIPTION

Link table between Navigation and Message for blogs, etc

=cut

=head1 ACCESSORS

=head2 messages_id

Foreign key constraint on L<Interchange6::Schema::Result::Message/messages_id>
via L</message> relationship.

=cut

column messages_id => {
    data_type      => "integer",
};

=head2 navigation_id

Foreign key constraint on
L<Interchange6::Schema::Result::Navigation/navigation_id>
via L</navigation> relationship.

=cut

column navigation_id => {
    data_type      => "integer",
};

=head1 PRIMARY KEY

=over 4

=item * L</messages_id>

=item * L</navigation_id>

=back

=cut

primary_key "messages_id", "navigation_id";

=head1 RELATIONS

=head2 message

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Message>

=cut

belongs_to
  message => "Interchange6::Schema::Result::Message",
  "messages_id",
  { cascade_delete => 1 };

=head2 navigation

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Navigation>

=cut

belongs_to
  navigation => "Interchange6::Schema::Result::Navigation",
  "navigation_id";

1;
