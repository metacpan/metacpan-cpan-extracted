package Elastic::Model::UID;
$Elastic::Model::UID::VERSION = '0.52';
use Moose;
use MooseX::Types::Moose qw(Str Int Maybe Bool);
use namespace::autoclean;

#===================================
has index => (
#===================================
    is       => 'ro',
    isa      => Str,
    required => 1,
    writer   => '_index'
);

#===================================
has type => (
#===================================
    is       => 'ro',
    isa      => Str,
    required => 1
);

#===================================
has id => (
#===================================
    is     => 'ro',
    isa    => Str,
    writer => '_id'
);

#===================================
has version => (
#===================================
    is     => 'ro',
    isa    => Int,
    writer => '_version'
);

#===================================
has routing => (
#===================================
    is     => 'ro',
    isa    => Maybe [Str],
    writer => '_routing'
);

#===================================
has from_store => (
#===================================
    is     => 'ro',
    isa    => Bool,
    writer => '_from_store'
);

#===================================
has 'is_partial' => (
#===================================
    is  => 'ro',
    isa => Bool,
);

#===================================
has cache_key => (
#===================================
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_cache_key',
    clearer => '_clear_cache_key',
);

no Moose;

#===================================
sub new_from_store {
#===================================
    my $class  = shift;
    my %params = %{ shift() };
    $class->new(
        from_store => 1,
        routing    => $params{fields}{_routing},
        map { $_ => $params{"_$_"} } qw(index type id version)
    );
}

#===================================
sub new_partial {
#===================================
    my $class  = shift;
    my %params = %{ shift() };
    $class->new(
        from_store => 1,
        is_partial => 1,
        routing    => $params{fields}{_routing},
        map { $_ => $params{"_$_"} } qw(index type id version)
    );
}

#===================================
sub update_from_store {
#===================================
    my $self   = shift;
    my $params = shift;
    $self->$_( $params->{$_} ) for qw(_index _id _version);
    $self->_from_store(1);
    $self->_clear_cache_key;
    $self;
}

#===================================
sub update_from_uid {
#===================================
    my $self = shift;
    my $uid  = shift;
    $self->_index( $uid->index );
    $self->_routing( $uid->routing );
    $self->_version( $uid->version );
    $self->_from_store(1);
    $self->_clear_cache_key;
    $self;
}

#===================================
sub clone {
#===================================
    my $self = shift;
    bless {%$self}, ref $self;
}

#===================================
sub read_params  { shift->_params(qw(index type id routing)) }
sub write_params { shift->_params(qw(index type id routing version)) }
#===================================

#===================================
sub _params {
#===================================
    my $self = shift;
    my %vals;
    for (@_) {
        my $val = $self->$_ or next;
        $vals{$_} = $val;
    }
    return \%vals;
}

#===================================
sub _build_cache_key {
#===================================
    my $self = shift;
    return join ";", map { s/;/;;/g; $_ } map { $self->$_ } qw(type id);
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::UID - The Unique ID of a document in an Elasticsearch cluster

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    $doc = $domain->new_doc(
        $type => {
            id      => $id,             # optional
            routing => $routing,        # optional
            ....
        }
    );

    $doc = $domain->get( $type => $id                      );
    $doc = $domain->get( $type => $id, routing => $routing );

    $uid = $doc->uid;

    $index   = $uid->index;
    $type    = $uid->type;
    $id      = $uid->id;
    $version = $uid->version;
    $routing = $uid->routing;

=head1 DESCRIPTION

To truly identify a document as unique in Elasticsearch, you need to know
the L<index|Elastic::Model::Terminology/Index> where it is stored, the
L<type|Elastic::Model::Terminology/Type> of the document, its
L<id|Elastic::Model::Terminology/ID>, and
possibly its L<routing|Elastic::Model::Terminology/Routing> value (which
defaults to the ID).  Also, each object
has a L</version> number which is incremented on every change.
L<Elastic::Model::UID> wraps up all of these details into an object.

=head1 ATTRIBUTES

=head2 index

The L<index|Elastic::Model::Terminology/Index> (or
L<domain|Elastic::Model::Terminology/Domain>) name.  When you create a new
document, its UID will set C<index> to C<< $domain->name >>, which may be an index
or an L<index alias|Elastic::Manual::Terminology/Alias>. However, when you
save the document, the L</index> will be updated to reflect the actual index
name.

=head2 type

The L<type|Elastic::Model::Terminology/Type> of the document, eg C<user>.

=head2 id

The string L<id|Elastic::Model::Terminology/ID> of the document - if not set
when creating a new document, then a unique ID is auto-generated when the
document is saved.

=head2 routing

The L<routing|Elastic::Model::Terminology/Routing> string is used to determine
in which shard the document lives. If not specified, then Elasticsearch
generates a routing value using a hash of the ID.  If you use a custom
routing value, then you can't change that value as the new routing B<may>
point to a new shard.  Instead, you should delete the old doc, and create a
new doc with the new routing value.

=head2 version

The version is an integer representing the current version of the document.
Each write operation will increment the C<version>, and attempts to update
an older version of the document will throw an exception.

=head2 from_store

A boolean value indicating whether the C<UID> was loaded from Elasticsearch
(C<true>) or created via L</"new()">.

=head2 is_partial

A boolean value indicating whether the C<UID> represents a partial or full
object. Partial objects cannot be saved.

=head2 cache_key

A generated string combining the L</"type"> and the L</"id">

=head1 METHODS

=head2 new()

    $uid = Elastic::Model::Uid->new(
        index   => $domain->name,               # required
        type    => $type,                       # required
        id      => $id,                         # optional
        routing => $routing,                    # optional
    );

Creates a new UID with L</"from_store"> set to false.

=head2 new_from_store()

    $uid = Elastic::Model::UID->new_from_store(
        _index   => $index,
        _type    => $type,
        _id      => $id,
        _version => $version,
        fields   => { routing => $routing }
    );

This is called when creating a new UID for a doc that has been loaded
from Elasticsearch. You shouldn't need to use this method directly.

=head2 new_partial()

    $uid = Elastic::Model::UID->new_partial(
        _index   => $index,
        _type    => $type,
        _id      => $id,
        _version => $version,
        fields   => { routing => $routing }
    );

This is called when creating a new UID for a partial doc that has been loaded
from Elasticsearch. You shouldn't need to use this method directly.

=head2 clone()

    $new_uid = $uid->clone();

Clones an existing UID.

=head2 update_from_store()

    $uid->update_from_store(
        _index   => $index,
        _id      => $id,
        _version => $version,
    );

When a doc is saved, we update the UID to use the real index name (as opposed
to an alias or domain name), the ID (in case it has been auto-generated)
and the current version number.  It also sets the L</"from_store"> attribute
to C<true>. You shouldn't need to use this method directly.

=head2 update_from_uid()

    $uid->update_from_uid($new_uid);

Updates the L</"index">, L</"routing"> and L</"id"> parameters of one UID
from a newer UID. You shouldn't need to use this method directly.

=head2 read_params()

    $params = $uid->read_params()

Returns a hashref containing L</"index">, L</"type">, L</"id"> and L</"routing">
values.

=head2 write_params()

    $params = $uid->write_params()

Returns a hashref containing L</"index">, L</"type">, L</"id">, L</"routing">
and L</"version"> values.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: The Unique ID of a document in an Elasticsearch cluster

