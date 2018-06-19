#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2018 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Bulk;
$ElasticSearchX::Model::Bulk::VERSION = '2.0.0';
use Moose;

use ElasticSearchX::Model::Document::Types qw(ESBulk);

has stash => (
    is         => 'ro',
    isa        => ESBulk,
    handles    => { stash_size => '_buffer_count', commit => "flush" },
    lazy_build => 1,
);
has size => ( is => 'ro', isa => 'Int', default => 100 );
has es => ( is => 'ro' );

sub _build_stash {
    my $self = shift;
    $self->es->bulk_helper( max_count => $self->size );
}

sub add {
    my ( $self, $action, $payload ) = ( shift, %{ $_[0] } );
    $payload->{source} = delete $payload->{body};
    $self->stash->add_action( $action => $payload );
}

sub update {
    my ( $self, $doc, $qs ) = @_;
    $self->add(
        {
            index => ref $doc eq 'HASH'
            ? $doc
            : { $doc->_put( $doc->_update($qs) ) }
        }
    );
    return $self;
}

sub create {
    my ( $self, $doc, $qs ) = @_;
    $self->add(
        { create => ref $doc eq 'HASH' ? $doc : { $doc->_put($qs) } } );
    return $self;
}

sub put {
    my ( $self, $doc, $qs ) = @_;
    $self->add(
        {
            index => ref $doc eq 'HASH'
            ? $doc
            : { $doc->_put, %{ $qs || {} } }
        }
    );
    return $self;
}

sub delete {
    my ( $self, $doc, $qs ) = @_;
    $self->add(
        {
            delete => ref $doc eq 'HASH'
            ? $doc
            : {
                index => $doc->index->name,
                type  => $doc->meta->short_name,
                id    => $doc->_id,
            }
        }
    );
    return $self;
}

sub clear {
    my $self = shift;
    $self->stash->clear_buffer;
    return $self;
}

sub DEMOLISH {
    my ($self, $in_gd) = @_;
    return if $in_gd;
    $self->commit if $self->has_stash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Bulk

=head1 VERSION

version 2.0.0

=head1 SYNOPSIS

 my $bulk = $model->bulk( size => 10 );
 my $document = $model->index('default')->type('tweet')->new_document({
     message => 'Hello there!',
     date    => DateTime->now,
 });
 $bulk->put( $document );
 $bulk->commit;

=head1 DESCRIPTION

This class is a wrapper around L<Search::Elasticsearch>'s bulk helper which adds
some convenience. By specifiying a L</size> you set the maximum
number of documents that are processed in one request. You can either
L</put> or L</delete> documents. Once the C<$bulk> object is out
of scope, it will automatically commit its L</stash>. Call L</clear>
if before if you don't want that to happen.

=head1 ATTRIBUTES

=head2 size

The maximum number of documents that are processed in one request.
Once the stash hits that number, a bulk request will be issued
automatically and the stash will be cleared.

=head2 stash

The stash includes the documents that will be processed at the
next commit. A commit is either automatically issued if the size
of the stash is greater then L</size>, if the C<$bulk> object
gets out of scope or if you call L</commit> explicitly.

=head2 es

The L<Search::Elasticsearch> object.

=head1 METHODS

=head2 create

=head2 update

=head2 put( $doc )

=head2 put( $doc, { %qs } )

Put a document. Accepts a document object (see
L<ElasticSearchX::Model::Document::Set/new_document>) or a
HashRef for better performance.

=head2 delete

Delete a document. You can either pass a document object or a
HashRef that consists of C<index>, C<type> and C<id>.

=head2 commit

Commits the documents in the stash to ElasticSearch.

=head2 clear

Clears the stash.

=head2 stash_size

Returns the number of documents in the stash.

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
