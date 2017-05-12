package Elastic::Model::Namespace;
$Elastic::Model::Namespace::VERSION = '0.52';
use Moose;
use MooseX::Types::Moose qw(Str HashRef ArrayRef);
use Elastic::Model::Index();
use Elastic::Model::Alias();
use List::MoreUtils qw(uniq);
use namespace::autoclean;

#===================================
has 'name' => (
#===================================
    is       => 'ro',
    isa      => Str,
    required => 1
);

#===================================
has 'types' => (
#===================================
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    builder => '_build_types',
    handles => {
        class_for_type => 'get',
        all_types      => 'keys'
    },
);

#===================================
has 'fixed_domains' => (
#===================================
    is      => 'ro',
    isa     => ArrayRef [Str],
    default => sub { [] }
);

no Moose;

#===================================
sub all_domains {
#===================================
    my $self    = shift;
    my @domains = ( $self->name, @{ $self->fixed_domains } );
    my $aliases = $self->model->store->get_aliases( index => \@domains );
    for ( keys %$aliases ) {
        push @domains, ( $_, keys %{ $aliases->{$_}{aliases} } );
    }
    return uniq @domains;
}

#===================================
sub all_live_indices {
#===================================
    my $self    = shift;
    my @domains = ( $self->name, @{ $self->fixed_domains } );
    my $aliases = $self->model->store->get_aliases( index => \@domains );
    return keys %$aliases;
}

#===================================
sub index {
#===================================
    my $self = shift;
    Elastic::Model::Index->new(
        namespace => $self,
        name      => shift() || $self->name
    );
}

#===================================
sub alias {
#===================================
    my $self = shift;
    Elastic::Model::Alias->new(
        namespace => $self,
        name      => shift() || $self->name
    );
}

#===================================
sub mappings {
#===================================
    my $self  = shift;
    my @types = @_ == 0 ? $self->all_types : @_;
    my $model = $self->model;
    +{ map { $_ => $model->map_class( $self->class_for_type($_) ) } @types };
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Namespace - Class-to-type map

=head1 VERSION

version 0.52

=head1 SYNOPSIS

=head2 Namespace declaration

    package MyApp;

    use Elastic::Model;

    has_namespace 'myapp' => {
        user    => 'MyApp::User',
        post    => 'MyApp::Post',
    };

    no Elastic::Model;

=head2 Using the namespace

    $namespace  = $model->namespace('myapp');

    $index      = $namespace->index($index_name);
    $alias      = $namespace->alias($alias_name);

    $name       = $namespace->name;
    @domains    = $namespace->all_domains
    \%types     = $namespace->types;
    @types      = $namespace->all_types;
    \%mappings  = $namespace->mappings( @types );

=head1 DESCRIPTION

L<Elastic::Model::Namespace> maps your doc classes to
L<types|Elastic::Manual::Terminology/Type> (like a database table) in
Elasticsearch. For instance, you could map your class
C<MyApp::User> to type C<user>.

This class <=> type mapping is applied to all
L<domains|Elastic::Manual::Terminology/Domain> known to the Namespace.
Each L<domain|Elastic::Model::Domain> has a single Namespace, and all documents
stored in that C<domain> (L<index|Elastic::Manual::Terminology/Index> or
L<index alias|Elastic::Manual::Terminology/Alias>) are handled by
the same Namespace. A C<namespace>/C<type>/C<id> combination must be
unique across all domains associated with a Namespace.

A Namespace "knows" about Domains via the L</name> attribute. Either you can
have a single index called C<< $namespace->name >>, OR an alias called
C<< $namespace->name >> which points to multiple indices.  Additional
domains (indices or aliases) can be specified with L</fixed_domains>

Namespaces are also used to create, update or delete L<indices|/index()>
or L<aliases/alias()>.

See L<Elastic::Manual::Intro>, L<Elastic::Model> for how to declare your
namespaces, and L<Elastic::Manual::Scaling> for more about
namespaces, indices and aliases.

=head1 ATTRIBUTES

=head2 name

    $name = $namespace->name

The C<name> of the namespace.  This attribute is important! It is used
in a couple of places:

=head3 As the "main domain" name

A L<domain|Elastic::Model::Domain> is like a database handle - you need
a domain to create, retrieve, update and deleted individual docs from
Elasticsearch.  The L<domain name|Elastic::Model::Domain/name> can be an
L<index|Elastic::Manual::Terminology/Index> or an
L<alias|Elastic::Manual::Terminology/Alias>.
Several domains (indices/aliases) can be associated with a namespace.
The easiest way to do this it to make the "main domain name"
(ie the namespace L</name>) an alias which points to all the indices in that
namespace.

See L<Elastic::Manual::Scaling/Namespaces, domains, aliases and indices>
L</fixed_domains> and L</all_domains()> for more.

=head3 As the scope name

A L<scope|Elastic::Model::Scope> is an optional in-memory cache.  The cache ID
uses the object's L<type|Elastic::Manual::Terminology/Type>,
L<ID|Elastic::Manual::Terminology/ID> and namespace L</name> to group objects,
so the ID must be unique across all indices in a namespace.

=head2 types

=head3 all_types

=head3 class_for_type

    \%types     = $namespace->types
    @type_names = $namespace->all_types
    $class      = $namespace->class_for_type($type_name)

A hashref whose keys are the type names in Elasticsearch, and whose
values are wrapped doc classes, eg the class C<MyApp::User>
wrapped by L<Elastic::Model::Role::Model/wrap_doc_class()>.

=head2 fixed_domains

    \@fixed_domains = $namespace->fixed_domains;

While the preferred method for associating domains with a namespace is via
an alias named after the namespace L</name>, you can include a list of other
domains (indices or aliases) in the namespace declaration:

    has_namespace 'myapp' => {
        user    => 'MyApp::User'
    },
    fixed_domains => ['index_1','alias_2'];

See L<Elastic::Manual::Scaling/Namespaces, domains, aliases and indices>
L</name> and L</all_domains()> for more.

=head1 METHODS

=head2 index()

    $index = $namespace->index;
    $index = $namespace->index('index_name');

Creates an L<Elastic::Model::Index> object for creating and administering indices
in the Elasticsearch cluster. The C<$index> L<name|Elastic::Model::Index/name>
is either the L</name> of the C<$namespace> or the value passed in to L</index()>.

=head2 alias()

    $alias = $namespace->alias;
    $alias = $namespace->alias('alias_name');

Creates an L<Elastic::Model::Alias> object for creating and administering index
aliases in the Elasticsearch cluster. The C<$alias> L<name|Elastic::Model::Alias/name>
is either the L</name> of the C<$namespace> or the value passed in to L</alias()>.

=head2 all_domains()

    @domains = $namespace->all_domains();

Returns all domain names known to the namespace. It does this by retrieving
all indices and aliases associated with the namespace L</name> and the
L</fixed_domains> (if any).

=head2 all_live_indices()

    @indices = $namespace->all_live_indices();

Queries Elasticsearch to find all existing indices related to the namespace

=head2 mappings()

    \%mapping = $namespace->mappings();
    \%mapping = $namespace->mappings(@type_names);

Generates the type mappings for the specified list of types, or, for all
types known to the namespace if not specified.

=head1 SEE ALSO

=over

=item *

L<Elastic::Manual::Intro>

=item *

L<Elastic::Model::Domain>

=item *

L<Elastic::Model::Index>

=item *

L<Elastic::Model::Alias>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Class-to-type map

