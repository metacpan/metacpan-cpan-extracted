use utf8;

package Interchange6::Schema::Result::Message;

=head1 NAME

Interchange6::Schema::Result::Message

=cut

use Interchange6::Schema::Candy -components =>
  [qw(Tree::AdjacencyList InflateColumn::DateTime TimeStamp)];

use Moo;

=head1 DESCRIPTION

Shared messages table for blog, order comments, reviews, bb, etc.

=head1 ACCESSORS

=head2 type

A short-cut accessor which takes a message type name (L<Interchange6::Schema::Result::MessageType/name>) as argument and sets L</message_types_id> to the appropriate value;

=cut

has type => ( is => 'rw', );

=head2 messages_id

Primary key.

=cut

primary_column messages_id => {
    data_type         => "integer",
    is_auto_increment => 1,
};

=head2 title

The title of the message.

=cut

column title => {
    data_type         => "varchar",
    default_value     => "",
    size              => 255
};

=head2 message_types_id

Foreign key constraint on L<Interchange6::Schema::Result::MessageType/message_types_id>
via L</message_type> relationship.

=cut

column message_types_id => {
    data_type         => "integer",
};

=head2 uri

The uri of the message data.

Unique constraint.

=cut

unique_column uri => {
    data_type         => "varchar",
    is_nullable       => 1,
    size              => 255
};

=head2 format

The format of the text held in L</content>, e.g. plain, html or markdown.
Defaults to 'plain'.

=cut

column format => {
    data_type => "varchar",
    size      => 32,
    default_value => "plain",
};

=head2 content

Content for the message.

=cut

column content => {
    data_type         => "text"
};

=head2 summary

Summary/teaser for L</content>.

Defaults to empty string.

=cut

column summary => {
    data_type     => "varchar",
    size          => 1024,
    default_value => '',
};

=head2 author_users_id

Foreign key constraint on L<Interchange6::Schema::Result::User/users_id>
via L</author> relationship. Is nullable.

=cut

column author_users_id => {
    data_type         => "integer",
    is_nullable       => 1
};

=head2 rating

Numeric rating of the message by a user.

=cut

column rating => {
    data_type         => "numeric",
    default_value     => 0,
    size              => [ 4, 2 ],
};

=head2 recommend

Do you recommend the message? Default is no. Is nullable.

=cut

column recommend => {
    data_type         => "boolean",
    is_nullable       => 1
};

=head2 public

Is this public viewable?  Default is no.

=cut

column public => {
    data_type         => "boolean",
    default_value     => 0,
};

=head2 approved

Has this been approved by someone with proper rights?

=cut

column approved => {
    data_type         => "boolean",
    default_value     => 0,
};

=head2 approved_by_users_id

Foreign key constraint on L<Interchange6::Schema::Result::User/users_id>
via L</approved_by> relationship. Is nullable

=cut

column approved_by_users_id => {
    data_type         => "integer",
    is_nullable       => 1
};

=head2 parent_id

For use by L<DBIx::Class::Tree::AdjacencyList> this defines the L</messages_id>
of the parent of this message (if any).

=cut

column parent_id => { data_type => "integer", is_nullable => 1 };

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => {
    data_type         => "datetime",
    set_on_create     => 1,
};

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified => {
    data_type         => "datetime",
    set_on_create     => 1,
    set_on_update     => 1,
};

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

=cut

belongs_to
    author => 'Interchange6::Schema::Result::User',
    { 'foreign.users_id' => 'self.author_users_id' },
    { join_type          => 'left' };

=head2 approved_by

Type: belongs_to

Related object: L<Interchange6::Schema::Result::User>

=cut

belongs_to
  approved_by => 'Interchange6::Schema::Result::User',
  { 'foreign.users_id' => 'self.approved_by_users_id' },
  { join_type          => 'left' };

=head2 message_type

Type: belongs_to

Related object: L<Interchange6::Schema::Result::MessageType>

=cut

belongs_to
  message_type => 'Interchange6::Schema::Result::MessageType',
  'message_types_id';

=head2 order_comment

Type: might_have

Related object: L<Interchange6::Schema::Result::OrderComment>

=cut

might_have
  order_comment => 'Interchange6::Schema::Result::OrderComment',
  'messages_id';

=head2 orders

Type: many_to_many

Accessor to related Order results.

=cut

many_to_many orders => "order_comment", "order";

=head2 product_messages

Type: has_many

Related object: L<Interchange6::Schema::Result::ProductMessage>

=cut

has_many
  product_messages => 'Interchange6::Schema::Result::ProductMessage',
  'messages_id';

=head2 products

Type: many_to_many

Accessor to related Product results.

=cut

many_to_many products => "product_messages", "product";

=head2 navigation_messages

Type: has_many

Related object: L<Interchange6::Schema::Result::NavigationMessage>

=cut

has_many
  navigation_messages => 'Interchange6::Schema::Result::NavigationMessage',
  'messages_id';

=head2 navigations

Type: many_to_many

Accessor to related Navigation results.

=cut

many_to_many navigations => "navigation_messages", "navigation";

=head2 media_messages

Type: has_many

Related object: L<Interchange6::Schema::Result::MediaMessage>

=cut

has_many
  media_messages => "Interchange6::Schema::Result::MediaMessage",
  "messages_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 media

Type: many_to_many with media

=cut

many_to_many media => "media_messages", "media";

=head1 INHERITED METHODS

=head2 DBIx::Class::Tree::AdjacencyList

=over 4

=item *

L<parent|DBIx::Class::Tree::AdjacencyList/parent>

=item *

L<ancestors|DBIx::Class::Tree::AdjacencyList/ancestors>

=item *

L<has_descendant|DBIx::Class::Tree::AdjacencyList/has_descendant>

=item *

L<parents|DBIx::Class::Tree::AdjacencyList/parents>

=item *

L<children|DBIx::Class::Tree::AdjacencyList/children>

=item *

L<attach_child|DBIx::Class::Tree::AdjacencyList/attach_child>

=item *

L<siblings|DBIx::Class::Tree::AdjacencyList/siblings>

=item *

L<attach_sibling|DBIx::Class::Tree::AdjacencyList/attach_sibling>

=item *

L<is_leaf|DBIx::Class::Tree::AdjacencyList/is_leaf>

=item *

L<is_root|DBIx::Class::Tree::AdjacencyList/is_root>

=item *

L<is_branch|DBIx::Class::Tree::AdjacencyList/is_branch>

=back

=cut

# define parent column

__PACKAGE__->parent_column('parent_id');

=head1 METHODS

=head2 FOREIGNBUILDARGS

Remove L</type> attribute from call to parent class.

=cut

sub FOREIGNBUILDARGS {
    my ( $self, $attrs ) = @_;

    if ( defined $attrs->{type} ) {
        delete $attrs->{type};
    }
    return $attrs;
}

=head2 insert

Overload insert to set message_types_id if required. Throw exception if requested message type
is not active. See L<Interchange6::Schema::Result::MessageType/active>.

=cut

sub insert {
    my $self = shift;

    my $rset_message_type =
      $self->result_source->schema->resultset("MessageType");

    if ( defined $self->type ) {

        my $name = $self->type;

        if ( defined $self->message_types_id ) {
            $self->throw_exception("mismatched type settings")
              if $name ne $self->message_type->name;
        }
        else {

            my $rset = $rset_message_type->search( { name => $self->type } );

            if ( $rset->has_rows ) {
                my $result = $rset->next;
                $self->set_column( message_types_id => $result->id );
            }
            else {
                $self->throw_exception(
                    qq(MessageType with name "$name" does not exist));
            }
        }
    }

    if ( defined $self->message_types_id ) {

        # make sure message type is active

        my $rset = $rset_message_type->search(
            { message_types_id => $self->message_types_id } );

        if ( $rset->has_rows ) {
            my $result = $rset->next;
            if ( $result->active ) {
                return $self->next::method;
            }
            else {
                $self->throw_exception( q(MessageType with name ")
                      . $result->name
                      . q(" is not active) );
            }
        }
        else {
            $self->throw_exception(
                q(message_types_id value does not exist in MessageType));
        }
    }
    else {
        $self->throw_exception("Cannot create message without type");
    }
}

1;
