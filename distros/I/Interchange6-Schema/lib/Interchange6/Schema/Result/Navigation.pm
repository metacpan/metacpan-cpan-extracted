use utf8;

package Interchange6::Schema::Result::Navigation;

=head1 NAME

Interchange6::Schema::Result::Navigation

=cut

use base 'Interchange6::Schema::Base::Attribute';

use Interchange6::Schema::Candy -components =>
  [qw(Tree::AdjacencyList InflateColumn::DateTime TimeStamp)];

use Encode;
use Try::Tiny;

=head1 DESCRIPTION

Navigation is where all navigation, category and static page details are stored.  In addition
information such as page title can be linked to these records as attributes.

=over 4

=item B<Attribute>

Common attribute names for a Navigation records include these examples.

meta_title
meta_description
meta_keywords
head_js
head_css

=back

=cut

=head1 SYNOPSIS

NOTE: with items such as head_css which may contain more than one record you must set the priority of the record.
This ensures each record has a unique value and also allows for proper ordering.

    $nav->add_attribute({name => 'head_css', priority => '1'}, '/css/main.css');
    $nav->add_attribute({name => 'head_css', priority => '2'}, '/css/fancymenu.css');

=head1 ACCESSORS

=head2 navigation_id

Primary key.

=cut

primary_column navigation_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "navigation_navigation_id_seq",
};

=head2 uri

URI.

Unique constraint. Is nullable.

See L</generate_uri> method for details of how L</uri> can be created
automatically based on the value of L</name>.

=cut

unique_column uri => {
    data_type   => "varchar",
    size        => 255,
    is_nullable => 1,
};

=head2 type

Type, e.g.: nav, category.

=cut

column type =>
  { data_type => "varchar", default_value => "", size => 32 };

=head2 scope

Scope, e.g.: menu-main, top-login.

=cut

column scope =>
  { data_type => "varchar", default_value => "", size => 32 };

=head2 name

Name, e.g.: Hand Tools, Fly Fishing Rods.

Defaults to empty string.

=cut

column name => {
    data_type     => "varchar",
    default_value => "",
    size          => 255
};

=head2 description

Description, e.g.: All of our hand tools, Our collection of top fly fishing rods.

Defaults to empty string.

=cut

column description => {
    data_type     => "varchar",
    default_value => "",
    size          => 1024
};

=head2 alias

FK on L<Interchange6::Schema::Result::Navigation/navigation_id>.

Can be used for things such as menus in different languages which link back
to the primary navigation menu.

Is nullable.

=cut

column alias =>
  { data_type => "integer", is_nullable => 1 };

=head2 parent_id

Used by L<DBIx::Class::Tree::AdjacencyList> to setup parent/child relationships.

Is nullable.

=cut

column parent_id => { data_type => "integer", is_nullable => 1 };

=head2 priority

Signed integer priority. We normally order descending.

Defaults to 0.

=cut

column priority =>
  { data_type => "integer", default_value => 0 };

=head2 product_count

Can be used to cache product counts.

Default to 0.

=cut

column product_count =>
  { data_type => "integer", default_value => 0 };

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created =>
  { data_type => "datetime", set_on_create => 1 };

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified => {
    data_type     => "datetime",
    set_on_create => 1,
    set_on_update => 1,
};

=head2 active

Whether navigation is active and therefore should be displayed.

Boolean defaults to true (1).

=cut

column active =>
  { data_type => "boolean", default_value => 1 };

=head1 METHODS

Attribute methods are provided by the L<Interchange6::Schema::Base::Attribute> class.

=head2 new

Override inherited method to call L</generate_uri> method in case L</name>
has been supplied as an argument but L</uri> has not.

B<NOTE:> is uri is supplied and is undefined then L</generate_uri> is not
called.

=cut

sub new {
    my ( $class, $attrs ) = @_;

    my $new = $class->next::method($attrs);
    if ( defined $attrs->{name}  && ! exists $attrs->{uri} ) {
        $new->generate_uri;
    }
    return $new;
}

=head2 active_child_count

See L<Interchange6::Schema::ResultSet::Navigation/with_active_child_count>
for a resultset method which will prefill this data.

=cut

sub active_child_count {
    my $self = shift;
    if ( $self->has_column_loaded('active_child_count') ) {
        return $self->get_column('active_child_count');
    }
    return $self->active_children->count;
}

=head2 active_product_count

See L<Interchange6::Schema::ResultSet::Navigation/with_active_product_count>
for a resultset method which will prefill this data.

=cut

sub active_product_count {
    my $self = shift;
    if ( $self->has_column_loaded('active_product_count') ) {
        return $self->get_column('active_product_count');
    }
    return $self->products->active->count;
}

=head2 generate_uri($attrs)

Called by L</new> if no uri is given as an argument.

The following steps are taken:

=over

1. Stash C<< $self->name >> in C<$uri> to allow manipulation via filters

2. Remove leading and trailing spaces and replace remaining spaces and
C</> with C<->

3. Search for all rows in L<Interchange6::Schema::Result::Setting> where
C<scope> is C<Navigation> and C<name> is <generate_uri_filter>

4. For each row found eval C<< $row->value >>

5. Finally set the value of column L</uri> to C<$uri>

=back

Filters stored in L<Interchange6::Schema::Result::Setting> are executed via
eval and have access to C<$uri> and also the navigation result held in 
C<$self>

Examples of filters stored in Setting might be:

    {
        scope => 'Navigation',
        name  => 'generate_uri_filter',
        value => '$uri =~ s/badstuff/goodstuff/gi',
    },
    {
        scope => 'Navigation',
        name  => 'generate_uri_filter',
        value => '$uri = lc($uri)',
    },

=cut

sub generate_uri {
    my $self = shift;

    my $uri = $self->name;

    # make sure we have clean utf8
    try {
        $uri = Encode::decode( 'UTF-8', $uri, Encode::FB_CROAK )
          unless utf8::is_utf8($uri);
    }
    catch {
        # I don't know of a way to reach this catch so for now mark uncoverable
        # uncoverable subroutine
        # uncoverable statement
        $self->throw_exception(
            "Navigation->generate_uri failed to decode UTF-8 text: $_" );
    };

    $uri =~ s/^\s+//;       # remove leading space
    $uri =~ s/\s+$//;       # remove trailing space
    $uri =~ s{[\s/]+}{-}g;  # change space and / to -

    my $filters = $self->result_source->schema->resultset('Setting')->search(
        {
            scope => 'Navigation',
            name  => 'generate_uri_filter',
        },
    );

    while ( my $filter = $filters->next ) {
        eval $filter->value;
        $self->throw_exception("Navigation->generate_uri filter croaked: $@")
          if $@;
    }

    $self->uri($uri);
}


=head2 siblings_with_self

Similar to the inherited L<siblings|DBIx::Class::Tree::AdjacencyList/siblings> method but also returns the object itself in the result set/list.

=cut

sub siblings_with_self {
    my $self = shift;
    my $rs = $self->result_source->resultset->search(
        {
            parent_id => $self->parent_id,
        }
    );
    return $rs->all() if (wantarray());
    return $rs;
}

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

=head1 RELATIONS

=head2 active_children

Related object: L<Interchange6::Schema::Result::Navigation>

Conditions: self.parent_id = foreign.navigation_id && foreign.active = 1

=cut

has_many
  active_children => "Interchange6::Schema::Result::Navigation",
  sub {
    my $args = shift;

    return {
        "$args->{foreign_alias}.parent_id" =>
          { -ident => "$args->{self_alias}.navigation_id" },
        "$args->{foreign_alias}.active" => 1,
    };
  };

=head2 media_navigations

Type: has_many

Related object: L<Interchange6::Schema::Result::MediaNavigation>

=cut

has_many
  media_navigations => "Interchange6::Schema::Result::MediaNavigation",
  "navigation_id",
  { cascade_copy => 0, cascade_delete => 0 };


=head2 navigation_products

Type: has_many

Related object: L<Interchange6::Schema::Result::NavigationProduct>

=cut

has_many
  navigation_products => "Interchange6::Schema::Result::NavigationProduct",
  "navigation_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 products

Type: many_to_many

Accessor to related product results ordered by priority and name.

=cut

many_to_many
  products => "navigation_products",
  "product", { order_by => [ 'product.priority', 'product.name' ] };

=head2 navigation_attributes

Type: has_many

Related object: L<Interchange6::Schema::Result::NavigationAttribute>

=cut

has_many
  navigation_attributes => "Interchange6::Schema::Result::NavigationAttribute",
  "navigation_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 attributes

Type: many_to_many

Accessor to related attribute results.

=cut

many_to_many
  attributes => "navigation_attributes", "attribute";

=head2 navigation_messages

Type: has_many

Related object: L<Interchange6::Schema::Result::NavigationMessage>

=cut

has_many
  navigation_messages => "Interchange6::Schema::Result::NavigationMessage",
  "navigation_id", { cascade_copy => 0 };

=head2 messages

Type: many_to_many

Accessor to related Message results.

=cut

many_to_many messages => "navigation_messages", "message";

1;
