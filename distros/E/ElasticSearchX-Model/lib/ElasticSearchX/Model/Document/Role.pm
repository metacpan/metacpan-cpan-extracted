#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2016 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Document::Role;
$ElasticSearchX::Model::Document::Role::VERSION = '1.0.2';
use Moose::Role;

use Carp;
use Digest::SHA1;
use ElasticSearchX::Model::Util ();
use List::MoreUtils ();

sub _does_elasticsearchx_model_document_role {1}

has _inflated_attributes =>
    ( is => 'rw', isa => 'HashRef', lazy => 1, default => sub { {} } );

has _loaded_attributes => (
    is      => 'rw',
    isa     => 'HashRef',
    clearer => '_clear_loaded_attributes',
);

has index => (
    isa => 'ElasticSearchX::Model::Index',
    is  => 'rw'
);

has _id => (
    is          => 'ro',
    property    => 0,
    source_only => 1,
    traits      => [
        'ElasticSearchX::Model::Document::Trait::Attribute',
        'ElasticSearchX::Model::Document::Trait::Field::ID',
    ],
);
has _version => (
    is          => 'ro',
    property    => 0,
    source_only => 1,
    traits      => [
        'ElasticSearchX::Model::Document::Trait::Attribute',
        'ElasticSearchX::Model::Document::Trait::Field::Version',
    ],
);

sub update {
    my $self = shift;
    die "cannot update partially loaded document"
        unless ( $self->meta->all_properties_loaded($self) );
    return $self->put( { $self->_update(@_) } );
}

sub _update {
    my ( $self, $qs ) = @_;
    $qs ||= {};
    return %$qs if ( exists $qs->{version} );
    my $version = $self->_version;
    die "cannot update document without a version"
        unless ($version);
    return (
        version => $version,
        %$qs
    );
}

sub create {
    my $self = shift;
    return $self->put( { $self->_create(@_) } );
}

sub _create {
    my ( $self, $qs ) = @_;
    my $version = $self->_version;
    return (
        create => 1,
        %{ $qs || {} }

    );
}

sub put {
    my ( $self, $qs ) = @_;
    my $method
        = $qs
        && ref $qs eq "HASH"
        && ( delete $qs->{create} ) ? "create" : "index";
    my $return = $self->index->model->es->$method( $self->_put($qs) );
    $self->_clear_loaded_attributes;
    my $id = $self->meta->get_id_attribute;
    $id->set_value( $self, $return->{_id} ) if ($id);
    $self->meta->get_attribute('_id')->set_value( $self, $return->{_id} );
    $self->meta->get_attribute('_version')
        ->set_value( $self, $return->{_version} );
    return $self;
}

sub _put {
    my ( $self, $qs ) = @_;
    my $id     = $self->meta->get_id_attribute->get_value($self);
    my $parent = $self->meta->get_parent_attribute;
    my $data   = $self->meta->get_data($self);
    $qs = { %{ $self->meta->get_query_data($self) }, %{ $qs || {} } };
    return (
        index => $self->index->name,
        type  => $self->meta->short_name,
        $id ? ( id => $id ) : (),
        body => $data,
        $parent ? ( parent => $parent->get_value($self) ) : (),
        %$qs,
    );
}

sub delete {
    my ( $self, $qs ) = @_;
    my $id     = $self->meta->get_id_attribute;
    my $return = $self->index->model->es->delete(
        index => $self->index->name,
        type  => $self->meta->short_name,
        id    => $self->_id,
        %{ $qs || {} },
    );
    return $self;
}

sub build_id {
    my $self = shift;
    my $id   = $self->meta->get_id_attribute;
    carp "Need an arrayref of fields for the id, not " . $id->id
        unless ( ref $id->id eq 'ARRAY' );
    my @fields = map { $self->meta->get_attribute($_) } @{ $id->id };
    return ElasticSearchX::Model::Util::digest( map { $_->deflate($self) }
            @fields );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Document::Role

=head1 VERSION

version 1.0.2

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
