package Elastic::Model::Role::Doc;
$Elastic::Model::Role::Doc::VERSION = '0.52';
use Moose::Role;

use Elastic::Model::Trait::Exclude;
use MooseX::Types::Moose qw(Maybe Bool HashRef);
use Elastic::Model::Types qw(Timestamp UID);
use Scalar::Util qw(refaddr);
use Try::Tiny;
use Time::HiRes();
use Carp;
use namespace::autoclean;

#===================================
has 'uid' => (
#===================================
    isa      => UID,
    is       => 'ro',
    required => 1,
    writer   => '_set_uid',
    traits   => ['Elastic::Model::Trait::Exclude'],
    exclude  => 1,
    handles  => [ 'id', 'type' ]
);

#===================================
has 'timestamp' => (
#===================================
    traits  => ['Elastic::Model::Trait::Field'],
    isa     => Timestamp,
    is      => 'rw',
    exclude => 0
);

#===================================
has '_can_inflate' => (
#===================================
    isa     => Bool,
    is      => 'rw',
    default => 0,
    traits  => ['Elastic::Model::Trait::Exclude'],
    exclude => 1,
);

#===================================
has '_source' => (
#===================================
    isa => Maybe [HashRef],
    is => 'ro',
    traits  => ['Elastic::Model::Trait::Exclude'],
    lazy    => 1,
    exclude => 1,
    builder => '_get_source',
    writer  => '_set_source',
);

no Moose::Role;

#===================================
sub has_changed {
#===================================
    my $self = shift;
    my $old  = $self->old_values;
    return '' unless keys %$old;
    return @_
        ? exists $old->{ $_[0] }
        : 1;
}

#===================================
sub old_values {
#===================================
    my $self = shift;
    return {} if $self->_can_inflate;
    my $current  = $self->model->deflate_object($self);
    my %original = %{ $self->uid->from_store ? $self->_source : {} };
    my $json     = $self->model->json;
    my %old;

    my ( $o, $c, $o_str, $c_str );
    my $meta  = Class::MOP::class_of($self);
    my $model = $self->model;
    for my $key ( keys %$current ) {
        unless ( exists $original{$key} ) {
            $old{$key} = undef;
            next;
        }
        no warnings 'uninitialized';
        ( $o, $c ) = ( delete $original{$key}, $current->{$key} );
        ( $o_str, $c_str )
            = map { ref $_ ? $json->encode($_) : $_ } ( $o, $c );

        if ( $o_str ne $c_str ) {
            $old{$key} = $meta->inflator_for( $model, $key )->($o);
        }
    }
    $old{$_} = $meta->inflator_for( $model, $_ )->( $original{$_} )
        for keys %original;
    return \%old;
}

#===================================
sub old_value {
#===================================
    die('old_value($attr) has been removed. Use old_values->{$attr} instead');
}

#===================================
sub _get_source {
#===================================
    my $self = shift;
    $self->model->get_doc_source(
        uid    => $self->uid,
        ignore => 404,
        @_
    );
}

#===================================
sub _inflate_doc {
#===================================
    my $self   = $_[0];
    my $source = $self->_source
        or return bless( $self, 'Elastic::Model::Deleted' )->croak;

    $self->_can_inflate(0);
    eval {
        $self->model->inflate_object( $self, $source );
        1;
    } or do {
        my $error = $@;
        $self->_can_inflate(1);
        die $error;
    };
}

#===================================
sub touch {
#===================================
    my $self = shift;
    $self->timestamp( int( Time::HiRes::time * 1000 + 0.5 ) / 1000 );
    $self;
}

#===================================
sub save {
#===================================
    my $self = shift;

    unless ( $self->_can_inflate ) {
        $self->touch;
        $self->model->save_doc( doc => $self, @_ );
    }
    $self;
}

#===================================
sub overwrite { shift->save( @_, version => 0 ) }
#===================================

#===================================
sub delete {
#===================================
    my $self = shift;
    $self->model->delete_doc( uid => $self->uid, @_ )
        or return;
    bless $self, 'Elastic::Model::Deleted';
}

#===================================
sub has_been_deleted {
#===================================
    my $self = shift;
    my $uid  = $self->uid;
    $uid->from_store or return 0;
    !$self->model->doc_exists( uid => $uid, @_ );
}

#===================================
sub terms_indexed_for_field {
#===================================
    my $self  = shift;
    my $field = shift or croak "Missing required param (fieldname)";
    my $size  = shift || 20;

    my $uid = $self->uid;
    return $self->model->view->domain( $uid->index )->type( $uid->type )
        ->filterb( _id => $uid->id )
        ->facets( field => { terms => { field => $field, size => 20 } } )
        ->size(0)->search->facet('field');
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Role::Doc - The role applied to your Doc classes

=head1 VERSION

version 0.52

=head1 SYNOPSIS

=head2 Creating a doc

    $doc = $domain->new_doc(
        user => {
            id      => 123,                 # auto-generated if not specified
            email   => 'clint@domain.com',
            name    => 'Clint'
        }
    );

    $doc->save;
    $uid = $doc->uid;

=head2 Retrieving a doc

    $doc = $domain->get( user => 123 );
    $doc = $model->get_doc( uid => $uid );

=head2 Updating a doc

    $doc->name('John');

    print $doc->has_changed();              # 1
    print $doc->has_changed('name');        # 1
    print $doc->has_changed('email');       # 0
    dump $doc->old_values;                  # { name => 'Clint' }

    $doc->save;
    print $doc->has_changed();              # 0

=head2 Deleting a doc

    $doc->delete;
    print $doc->has_been_deleted            # 1

=head1 DESCRIPTION

L<Elastic::Model::Role::Doc> is applied to your "doc" classes (ie those classes
that you want to be stored in Elasticsearch), when you include this line:

    use Elastic::Doc;

This document explains the changes that are made to your class by applying the
L<Elastic::Model::Role::Doc> role.  Also see L<Elastic::Doc>.

=head1 ATTRIBUTES

The following attributes are added to your class:

=head2 uid

The L<uid|Elastic::Model::UID> is the unique identifier for your doc in
Elasticsearch. It contains an L<index|Elastic::Model::UID/"index">,
a L<type|Elastic::Model::UID/"type">, an L<id|Elastic::Model::UID/"id"> and
possibly a L<routing|Elastic::Model::UID/"routing">. This is what is required
to identify your document uniquely in Elasticsearch.

The UID is created when you create your document, eg:

    $doc = $domain->new_doc(
        user    => {
            id      => 123,
            other   => 'foobar'
        }
    );

=over

=item *

C<index> : initially comes from the C<< $domain->name >> - this is changed
to the actual domain name when you save your doc.

=item *

C<type> : comes  from the first parameter passed to
L<new_doc()|Elastic::Model::Domain/"new_doc()"> (C<user> in this case).

=item *

C<id> : is optional - if you don't provide it, then it will be
auto-generated when you save it to Elasticsearch.

=back

B<Note:> the C<namespace_name/type/ID> of a document must be unique.
Elasticsearch can enforce uniqueness for a single index, but when your
L<namespace|Elastic::Model::Namespace> contains multiple indices, it is up
to you to ensure uniqueness.  Either leave the ID blank, in which case
Elasticsearch will generate a unique ID, or ensure that the way you
generate IDs will not cause a collision.

=head2 type / id

    $type = $doc->type;
    $id   = $doc->id;

C<type> and C<id> are provided as convenience, read-only accessors which
call the equivalent accessor on L</uid>.

You can defined your own C<id()> and C<type()> methods, in which case they
won't be imported, or you can import them under a different name, eg:

    package MyApp::User;
    use Elastic::Doc;

    with 'Elastic::Model::Role::Doc' => {
        -alias => {
            id   => 'doc_id',
            type => 'doc_type',
        }
    };

=head2 timestamp

    $timestamp = $doc->timestamp($timestamp);

This stores the last-modified time (in epoch seconds with milli-seconds), which
is set automatically when your doc is saved. The C<timestamp> is indexed
and can be used in queries.

=head2 Private attributes

These private attributes are also added to your class, and are documented
here so that you don't override them without knowing what you are doing:

=head3 _can_inflate

A boolean indicating whether the object has had its attributes values
inflated already or not.

=head3 _source

The raw uninflated source value as loaded from Elasticsearch.

=head1 METHODS

=head2 save()

    $doc->save( %args );

Saves the C<$doc> to Elasticsearch. If this is a new doc, and a doc with the
same type and ID already exists in the same index, then Elasticsearch
will throw an exception.

Also see L<Elastic::Model::Bulk> for bulk indexing of multiple docs.

If the doc was previously loaded from Elasticsearch, then that doc will be
updated. However, because Elasticsearch uses
L<optimistic locking|http://en.wikipedia.org/wiki/Optimistic_locking>
(ie the doc version number is incremented on every change), it is possible that
another process has already updated the C<$doc> while the current process has
been working, in which case it will throw a conflict error.

For instance:

    ONE                         TWO
    --------------------------------------------------
                                get doc 1-v1
    get doc 1-v1
                                save doc 1-v2
    save doc1-v2
     -> # conflict error

=head3 on_conflict

If you don't care, and you just want to overwrite what is stored in Elasticsearch
with the current values, then use L</overwrite()> instead of L</save()>. If you
DO care, then you can handle this situation gracefully, using the
C<on_conflict> parameter:

    $doc->save(
        on_conflict => sub {
            my ($original_doc,$new_doc) = @_;
            # resolve conflict

        }
    );

See L</has_been_deleted()> for a fuller example of an L</on_conflict> callback.

The doc will only be saved if it has changed. If you want to force saving
on a doc that hasn't changed, then you can do:

    $doc->touch->save;

=head3 on_unique

If you have any L<unique attributes|Elastic::Manual::Attributes/unique_key> then
you can catch unique-key conflicts with the C<on_unique> handler.

    $doc->save(
        on_unique => sub {
            my ($doc,$conflicts) = @_;
            # do something
        }
    )

The C<$conflicts> hashref will contain a hashref whose keys are the name
of the L<unique_keys|Elastic::Manual::Attributes/unique_key> that have
conflicts, and whose values are the values of those keys which already exist,
and so cannot be overwritten.

See L<Elastic::Manual::Attributes::Unique> for more.

=head2 overwrite()

    $doc->overwrite( %args );

L</overwrite()> is exactly the same as L</save()> except it will overwrite
any previous doc, regardless of whether another process has created or updated
a doc with the same UID in the meantime.

=head2 delete()

    $doc->delete;

This will delete the current doc.  If the doc has already been updated
to a new version by another process, it will throw a conflict error.  You
can override this and delete the document anyway with:

    $doc->delete( version => 0 );

The C<$doc> will be reblessed into the L<Elastic::Model::Deleted> class,
and any attempt to access its attributes will throw an error.

=head2 has_been_deleted()

    $bool = $doc->has_been_deleted();

As a rule, you shouldn't delete docs that are currently in use elsewhere in
your application, otherwise you have to wrap all of your code in C<eval>s
to ensure that you're not accessing a stale doc.

However, if you do need to delete current docs, then L</has_been_deleted()>
checks if the doc exists in Elasticsearch.  For instance, you
might have an L</on_conflict> handler which looks like this:

    $doc->save(
        on_conflict => sub {
            my ($original, $new) = @_;

            return $original->overwrite
                if $new->has_been_deleted;

            for my $attr ( keys %{ $old->old_values }) {
                $new->$attr( $old->$attr ):
            }

            $new->save
        }
    );

It is a much better approach to remove docs from the main flow of your
application (eg, set a C<status> attribute to C<"deleted">) then physically
delete the docs only after some time has passed.

=head2 touch()

    $doc = $doc->touch()

Updates the L</"timestamp"> to the current time.

=head2 has_changed()

Has the value for any attribute changed?

    $bool = $doc->has_changed;

Has the value of attribute C<$attr_name> changed?

    $bool = $doc->has_changed($attr_name);

B<Note:> If you're going to check more than one attribute, rather get
all the L</old_values()> and check if the attribute name exists in the
returned hash, rather than calling L<has_changed()> multiple times.

=head2 old_values()

    \%old_vals  = $doc->old_values();

Returns a hashref containing the original values of any attributes that have
been changed. If an attribute wasn't set originally, but is now, it will
be included in the hash with the value C<undef>.

=head2 terms_indexed_for_field()

    $terms = $doc->terms_indexed_for_field( $fieldname, $size );

This method is useful for debugging queries and analysis - it returns
the actual terms (ie after analysis) that have been indexed for
field C<$fieldname> in the current doc. C<$size> defaults to 20.

=head2 Private methods

These private methods are also added to your class, and are documented
here so that you don't override them without knowing what you are doing:

=head3 _inflate_doc

Inflates the attribute values from the hashref stored in L</"_source">.

=head3 _get_source / _set_source

The raw doc source from Elasticsearch.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: The role applied to your Doc classes

