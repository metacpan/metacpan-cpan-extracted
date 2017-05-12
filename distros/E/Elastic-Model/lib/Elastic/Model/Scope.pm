package Elastic::Model::Scope;
$Elastic::Model::Scope::VERSION = '0.52';
use Moose;
use namespace::autoclean;
use MooseX::Types::Moose qw(HashRef);
use Scalar::Util qw(refaddr);
use Devel::GlobalDestruction;

#===================================
has '_objects' => (
#===================================
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

#===================================
has 'parent' => (
#===================================
    is  => 'ro',
    isa => 'Elastic::Model::Scope',
);

# if the object exists in the current scope
#   return undef if the object is Deleted
#   return the object if its version is the same or higher
#   otherwise return undef
# otherwise, look for the same object in a parent scope
# and, if found, create a clone in the current scope

#===================================
sub get_object {
#===================================
    my ( $self, $ns, $uid ) = @_;
    my $existing = $self->_objects->{$ns}{ $uid->cache_key };

    if ($existing) {
        return if $existing->isa('Elastic::Model::Deleted');
        return $existing if $existing->uid->version >= ( $uid->version || 0 );
    }

    my $parent = $self->parent or return undef;
    $existing = $parent->get_object( $ns, $uid ) or return undef;

    my $new = Class::MOP::class_of($existing)
        ->new_stub( $existing->uid->clone, $existing->_source );

    return $self->store_object( $ns, $new );
}

# if the object exists in the current scope
#   return the same object if the version is the same or higher
#   if the existing object is not Deleted and has not already been looked at
#     then update it with current details, and return it
#     else move the old version to 'old'
# store the new version in current scope

#===================================
sub store_object {
#===================================
    my ( $self, $ns, $object ) = @_;
    my $uid     = $object->uid;
    my $objects = $self->_objects;

    if ( my $existing = $objects->{$ns}{ $uid->cache_key } ) {
        return $existing if $existing->uid->version >= $uid->version;
        unless ( $existing->isa('Elastic::Model::Deleted') ) {

            if ( $existing->_can_inflate ) {
                $existing->_set_source( $object->_source );
                $existing->uid->update_from_uid($uid);
                return $existing;
            }
        }
        $objects->{old}{ $uid->cache_key . refaddr $existing} = $existing;

    }

    $self->_objects->{$ns}{ $uid->cache_key } = $object;
}

# If the object exists in the current scope
#    then rebless it into Elastic::Model::Deleted
# Otherwise create a new Elastic::Model::Deleted object
#    and store it in the current scope

#===================================
sub delete_object {
#===================================
    my ( $self, $ns, $uid ) = @_;

    my $objects = $self->_objects;
    if ( my $existing = $objects->{$ns}{ $uid->cache_key } ) {
        bless $existing, 'Elastic::Model::Deleted';
    }
    else {
        $objects->{$ns}{ $uid->cache_key }
            = Elastic::Model::Deleted->new( uid => $uid );
    }
    return;
}

#===================================
sub DEMOLISH {
#===================================
    my $self = shift;
    return if in_global_destruction;
    $self->model->detach_scope($self);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Scope - Keeps objects alive and connected

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::Scope> is an optional in-memory cache, which serves three
purposes:

=over

=item *

Keep weak-ref L<Elastic::Doc> attributes alive

=item *

Reuse L<Elastic::Doc> objects as singletons.

=item *

Multiple scopes allow you to have multiple versions of L<Elastic::Doc> objects
live at the same time.

=back

See L<Elastic::Manual::Scoping> for a fuller discussion of when and how to use
scoping.

=head1 ATTRIBUTES

=head2 parent

The parent scope of this scope, or UNDEF.

=head1 METHODS

The logic used in scopes is best explained by the examples below:

=head2 get_object()

    $obj = $scope->get_object($domain_name, $uid);

When calling L<Elastic::Model::Domain/"get()"> or L<Elastic::Model::Role::Model/"get_doc()">
to retrieve an object from Elasticsearch, we first check to see if we can
return the object from our in-memory cache by calling L</get_object()>:

=head3 Getting an object that exists in the current scope

If an object with the same C<namespace_name/type/id> exists in the CURRENT scope
(and its version is as least as high as the requested version, if any) then
we return the SAME object.

    $scope = $model->new_scope;
    $one   = $domain->get( user => 123 );
    $two   = $domain->get( user => 123 );

    print $one->name;
    # Clint

    $two->name('John');

    print $one->name;
    # John

    print refaddr($one) == refaddr($two) ? 'TRUE' : 'FALSE';
    # TRUE

=head3 Getting an object that exists in a parent scope

If an object with the same C<domain_name/type/id> exists in the PARENT scope
(and its version is as least as high as the requested version, if any) then
we return a CLONE of the object. (Note: we clone the original object as it was
when loaded from Elasticsearch. Any unsaved changes are ignored.)

    $scope_1 = $model->new_scope;
    $one     = $domain->get( user => 123 );

    print $one->name;
    # Clint

    $one->name('John');

    $scope_2 = $model->new_scope;
    $two     = $domain->get( user => 123 );

    print $two->name;
    # Clint

    print refaddr($one) == refaddr($two) ? 'TRUE' : 'FALSE';
    # FALSE

Otherwise the calling method will fetch the object from Elasticsearch itself,
and store it in the current scope.

=head3 Getting an object that has been deleted

If the object exists in the same scope or a parent scope, but it is
an L<Elastic::Model::Deleted> object, then we return C<undef>.

=head2 store_object()

    $object = $scope->store_object($ns_name, $object);

When we load a object that doesn't exist in the current scope or in any of
its parents, or we create-a-new or update-an-existing object via
L<Elastic::Model::Role::Doc/"save()">,
we also store it in the current scope via L</store_object()>.

    $scope_1 = $model->new_scope;
    $one     = $domain->get( user => 123 );

    print $one->name;
    # Clint

    $scope_2 = $model->new_scope;
    $two     = $domain->get( user => 123 );

    print $two->name;
    # Clint

    print refaddr($one) == refaddr($two) ? 'TRUE' : 'FALSE';
    # FALSE

=head3 Storing an object in a new scope

Now we update the C<$one> object, while B<< C<$scope_2> >> is current, and save it:

    $one->name('John');
    $one->save;

Object C<$one> is now in C<$scope_1> AND C<$scope_2>.

    $three   = $domain->get( user => 123 );

    print $three->name;
    # John

    print refaddr($one) == refaddr($three) ? 'TRUE' : 'FALSE';
    # TRUE

Object C<$two> still exists, and is still kept alive, but will no longer be
returned from C<$scope_2>.

    print $two->name;
    # Clint

=head2 delete_object()

    $scope->delete_object( $ns_name, $uid );

When calling L<Elastic::Model::Role::Model/delete_doc()>,
L<Elastic::Model::Domain/delete_doc()> or L<Elastic::Model::Role::Doc/delete()>
we check to see if an object with the same UID (C<namespace_name/type/id>)
exists in the current scope.

If it does, we rebless it into L<Elastic::Model::Deleted>. Otherwise, we
create a new L<Elastic::Model::Deleted> object with the C<$uid> and store
that in the current scope.

=head3 Deleting an object which exists in the current scope

    $scope_1 = $model->new_scope;
    $one     = $domain->get( user => 1 );

    $domain->delete (user => 1 );

    print $domain->isa('Elastic::Model::Deleted') ? 'TRUE' : 'FALSE';
    # TRUE

    print $one->name;                        # Throws an error,

=head3 Deleting an object which doesn't exist in the current scope

    $scope_1 = $model->new_scope;
    $one     = $domain->get( user => 1 );

    $scope_2 = $model->new_scope;

    $domain->delete( user => 1);

    $two     = $domain->get( user => 1 );    # Throws an error

    print $one->name;
    # Clint

    undef $scope_2;
    $two     = $domain->get( user => 1 );

    print refaddr($one) == refaddr($two) ? 'TRUE' : 'FALSE';
    # TRUE

But, calling L<delete()|Elastic::Model::Role::Doc/delete()> on an object
which isn't in the current scope still affects that object:

    $scope_1 = $model->new_scope;
    $one     = $domain->get( user => 1 );

    $scope_2 = $model->new_scope;

    $one->delete;

    print $one->name;                        # Throws an error

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Keeps objects alive and connected

