package Elastic::Model::Domain;
$Elastic::Model::Domain::VERSION = '0.52';
use Carp;
use Moose;
use namespace::autoclean;
use MooseX::Types::Moose qw(Maybe Str);

#===================================
has 'name' => (
#===================================
    isa      => Str,
    is       => 'rw',
    required => 1,
);

#===================================
has 'namespace' => (
#===================================
    is       => 'ro',
    isa      => 'Elastic::Model::Namespace',
    required => 1,
    handles  => ['class_for_type'],
);

#===================================
has '_default_routing' => (
#===================================
    isa => Maybe [Str],
    is => 'ro',
    lazy    => 1,
    builder => '_get_default_routing',
    clearer => 'clear_default_routing',
);

no Moose;

#===================================
sub _get_default_routing {
#===================================
    my $self    = shift;
    my $name    = $self->name;
    my $aliases = $self->model->store->get_aliases( index => $name );

    croak "Domain ($name) doesn't exist either as an index or an alias"
        unless %$aliases;

    my @indices = keys %$aliases;
    croak "Domain ($name) is an alias pointing at more than one index: "
        . join( ", ", @indices )
        if @indices > 1;

    my $index = shift @indices;
    return '' if $index eq $name;
    return $aliases->{$index}{aliases}{$name}{index_routing} || '';
}

#===================================
sub new_doc {
#===================================
    my $self  = shift;
    my $type  = shift or croak "No type passed to new_doc";
    my $class = $self->class_for_type($type) or croak "Unknown type ($type)";

    my %params = ref $_[0] ? %{ shift() } : @_;

    my $uid = Elastic::Model::UID->new(
        index   => $self->name,
        type    => $type,
        routing => $self->_default_routing,
        %params
    );

    return $class->new( %params, uid => $uid, );
}

#===================================
sub create { shift->new_doc(@_)->save }
#===================================

#===================================
sub get {
#===================================
    my $self = shift;

    my $type = shift or croak "No type passed to get()";
    my $id   = shift or croak "No id passed to get()";
    my %args = @_;
    my $uid  = Elastic::Model::UID->new(
        index   => $self->name,
        type    => $type,
        id      => $id,
        routing => delete $args{routing} || $self->_default_routing,
    );
    $self->model->get_doc( uid => $uid, %args );
}

#===================================
sub try_get { shift->get( @_, ignore => 404 ) }
#===================================

#===================================
sub exists {
#===================================
    my $self = shift;
    my $type = shift or croak "No type passed to exists()";
    my $id   = shift or croak "No id passed to exists()";
    my %args = @_;
    my $uid  = Elastic::Model::UID->new(
        index   => $self->name,
        type    => $type,
        id      => $id,
        routing => delete $args{routing} || $self->_default_routing,
    );
    $self->model->doc_exists( uid => $uid, %args );
}

#===================================
sub delete {
#===================================
    my $self = shift;

    my $type = shift or croak "No type passed to delete()";
    my $id   = shift or croak "No id passed to delete()";
    my %args = @_;

    my $uid = Elastic::Model::UID->new(
        index   => $self->name,
        type    => $type,
        id      => $id,
        routing => delete $args{routing} || $self->_default_routing,
    );
    $self->model->delete_doc( uid => $uid, %args );
}

#===================================
sub try_delete { shift->delete( @_, ignore => 404 ) }
#===================================

#===================================
sub view {
#===================================
    my $self = shift;
    $self->model->view( domain => $self->name, @_ );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Domain - The domain (index or alias) where your docs are stored.

=head1 VERSION

version 0.52

=head1 SYNOPSIS

=head2 Get a domain instance

    $domain = $model->domain('myapp');

=head2 Create a new doc/object

    $user = $domain->new_doc( user => \%args );
    $user->save;

    # or:

    $user = $domain->create( user => \%args);

=head2 Retrieve a doc by ID

    $user = $domain->get( $type => $id );

    $user = $domain->try_get( $type => $id );      # return undef if missing

=head2 Check if a doc exists

    $bool = $domain->exists( $type => $id );

=head2 Delete a doc by ID

    $uid = $domain->delete( $type => $id );

    $user = $domain->try_delete( $type => $id );   # return undef if missing

=head2 Create a view on the current domain

    $view = $domain->view(%args);

=head1 DESCRIPTION

A "domain" is like a database handle used for CRUD (creating, updating or deleting)
individual objects or L<documents|Elastic::Manual::Terminology/Document>.
The C<< $domain->name >> can be the name of an
L<index|Elastic::Manual::Terminology/Index> or an
L<index alias|Elastic::Manual::Terminology/Alias>. A domain can only belong to
a single L<namespace|Elastic::Manual::Terminology/Namespace>.

B<NOTE:> If C<< $domain->name >> is an alias, it can only point to a single
index.

=head1 ATTRIBUTES

=head2 name

A C<< $domain->name >> must be either the name of an
L<index|Elastic::Manual::Terminology/Index> or of an
L<index alias|Elastic::Manual::Terminology/Alias> which points to a single
index. The index or alias must exist, and must be known to the
L<namespace|Elastic::Model::Namespace>.

=head2 namespace

The L<Elastic::Model::Namespace> object to which this domain belongs.

=head1 INSTANTIATOR

=head2 new()

    $domain = $model->domain_class->new({
        name            => $domain_name,
        namespace       => $namespace,
    });

Although documented here, you shouldn't need  to call C<new()> yourself.
Instead you should use L<Elastic::Model::Role::Model/"domain()">:

    $domain = $model->domain($domain_name);

=head1 METHODS

=head2 new_doc()

    $doc = $domain->new_doc( $type => \%args );

C<new_doc()> will create a new object in the class that maps to type C<$type>,
passing C<%args> to C<new()> in the associated class. For instance:

    $user = $domain->new_doc(
        user => {
            id   => 1,
            name => 'Clint',
        }
    );

=head2 create()

    $doc = $domain->create( $type => \%args );

This is the equivalent of:

    $doc = $domain->new_doc( $type => \%args )->save();

=head2 get()

    $doc = $domain->get( $type => $id );
    $doc = $domain->get( $type => $id, routing => $routing, ... );

Retrieves a doc of type C<$type> with ID C<$id> from index C<< $domain->name >>
or throws an exception if the doc doesn't exist. See
L<Elastic::Model::Role::Store/get_doc()> for more parameters which can be passed.

=head2 try_get()

    $doc = $domain->try_get( $type => $id );
    $doc = $domain->try_get( $type => $id, routing => $routing, ... );

Retrieves a doc of type C<$type> with ID C<$id> from index C<< $domain->name >>
or returns undef if the doc doesn't exist.

=head2 exists()

    $bool = $domain->exists( $type => $id );
    $bool = $domain->exists( $type => $id, routing => $routing, ... );

Checks if a doc of type C<$type> with ID C<$id> exists in
index C<< $domain->name >>. See L<Elastic::Model::Role::Store/doc_exists()>
for more parameters which can be passed.

=head2 delete()

    $uid = $domain->delete( $type => $id );
    $uid = $domain->delete( $type => $id, routing => $routing, ... );

Deletes a doc of type C<$type> with ID C<$id> from index C<< $domain->name >>
or throws an exception if the doc doesn't exist. See
L<Elastic::Model::Role::Store/delete_doc()> for more parameters which can be passed.

=head2 try_delete()

    $uid = $domain->try_delete( $type => $id );
    $uid = $domain->try_delete( $type => $id, routing => $routing, ... );

Deletes a doc of type C<$type> with ID C<$id> from index C<< $domain->name >>
or returns undef if the doc doesn't exist.

=head2 view()

    $view = $domain->view(%args)

Creates a L<view|Elastic::Model::View> with the L<Elastic::Model::View/"domain">
set to C<< $domain->name >>.  A C<view> is used for searching docs in a
C<$domain>.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: The domain (index or alias) where your docs are stored.

