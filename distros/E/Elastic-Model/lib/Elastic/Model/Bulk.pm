package Elastic::Model::Bulk;
$Elastic::Model::Bulk::VERSION = '0.52';
use Moose;
use namespace::autoclean;
use Data::Dumper;
our $Conflict = qr/
    DocumentAlreadyExistsException
  | :.version.conflict,.current.\[(\d+)\]
  /x;

use Carp;

#===================================
has 'on_success' => (
#===================================
    is  => 'rw',
    isa => 'CodeRef',
);

#===================================
has 'on_conflict' => (
#===================================
    is  => 'rw',
    isa => 'CodeRef',
);

#===================================
has 'on_error' => (
#===================================
    is  => 'rw',
    isa => 'CodeRef',
);

#===================================
has 'size' => (
#===================================
    is      => 'ro',
    isa     => 'Int',
    default => sub {1000}
);

#===================================
has '_actions' => (
#===================================
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    writer  => '_set_actions',
    default => sub { [] },
    handles => { _push_action => 'push' }
);

#===================================
has '_docs' => (
#===================================
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    writer  => '_set_docs',
    default => sub { [] },
    handles => {
        _push_doc => 'push',
        count     => 'count',
    },
);

no Moose;

#===================================
sub save {
#===================================
    my $self = shift;
    my $doc  = shift;

    return if $doc->_can_inflate;

    my $meta = Class::MOP::class_of($doc);
    die "Cannot bulk index class ("
        . $doc->original_class
        . ") because it contains unique keys"
        if $meta->unique_keys;

    $doc->touch;

    my %args = @_;
    my $uid  = $doc->uid;

    croak "Cannot save partial doc type ("
        . $uid->type
        . ") id ("
        . $uid->id . ")"
        if $uid->is_partial;

    my $data    = $self->model->deflate_object($doc);
    my $version = delete $args{version};

    my $action
        = ( $uid->from_store or $uid->id and defined $version )
        ? 'index'
        : 'create';

    %args = ( %args, %{ $uid->write_params } );
    $args{version} = $version
        if defined $version;

    for ( keys %args ) {
        $args{"_$_"} = delete $args{$_};
    }

    $self->_push_action( { $action => {%args} }, $data );
    $self->_push_doc($doc);
    $self->commit if $self->count >= $self->size;
    return;
}

#===================================
sub overwrite {
#===================================
    my $self = shift;
    $self->save( @_, version => 0 );
}

#===================================
sub commit {
#===================================
    my $self = shift;
    return unless $self->count;

    my $actions     = $self->_actions;
    my $docs        = $self->_docs;
    my $on_success  = $self->on_success;
    my $on_conflict = $self->on_conflict;
    my $on_error    = $self->on_error;

    $self->clear;

    my $response = $self->model->store->bulk( body => $actions );
    my $results  = $response->{items};
    my $model    = $self->model;
    my $scope    = $model->current_scope;

    my @unhandled;

    my $i = 0;

    for my $item (@$results) {
        my ( $action, $result ) = %$item;

        my $doc = $docs->[ $i++ ];

        if ( my $error = $result->{error} ) {
            if ( $on_conflict and $error =~ /$Conflict/ ) {
                my $uid
                    = $1
                    ? Elastic::Model::UID->new( %{ $doc->uid->read_params },
                    version => $1 )
                    : $doc->uid->clone;
                my $new = $self->model->get_doc( uid => $uid );
                $on_conflict->( $doc, $new );
            }
            elsif ($on_error) {
                $on_error->( $doc, $error );
            }
            else {
                push @unhandled, $result;
            }
            next;
        }

        my $uid = $doc->uid;
        $uid->update_from_store($result);
        $doc->_set_source( $result->{data} );
        if ($scope) {
            my $ns = $model->namespace_for_domain( $result->{_index} );
            $scope->store_object( $ns->name, $doc );
        }
        $on_success->($doc) if $on_success;
    }

    if (@unhandled) {
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 1;

        my @errors = splice @unhandled, 0, 2;
        die "Uncaught errors while commiting Bulk:"
            . Dumper( \@errors )
            . ( @unhandled ? "\nand " . ( 0 + @unhandled ) . " more" : '' );
    }
    return 1;

}

#===================================
sub clear {
#===================================
    my $self = shift;
    $self->_set_actions( [] );
    $self->_set_docs(    [] );
}

#===================================
sub DEMOLISH { shift->commit }
#===================================

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Bulk - Bulk-saving of multiple docs for increased throughput

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    $bulk = $model->bulk(
        size        => 1000,
        on_conflict => sub {...},
        on_error    => sub {...}
    );

    $bulk->save($doc);
    $bulk->overwrite($doc);
    ...

    $bulk->commit;

=head1 DESCRIPTION

If you need to create or update multiple docs at once, then bulk indexing is
the way to go.  It batches up the documents and saves C<size> (default 1000)
documents in a single request, which is much faster than writing each
doc individually.

Once you are finished adding docs to the C<$bulk> indexer, call L</commit()>
to save any docs that haven't been saved yet.  If C<$bulk> goes out of scope,
then L</commit()> will be called for you, but it is safer to call it yourself.

B<Note:> Bulk indexing is not supported for classes which have
L<unique key constraints|Elastic::Manual::Attributes/unique_key>.

=head1 ATTRIBUTES

=head2 size

The number of docs that will be saved in a single request. Defaults to 1000.

=head2 on_success

An optional callback which will be called when a document has been
indexed successfully.  It is called with a single argument: the current
document.

=head2 on_conflict

A callback which will be called if there is any conflict when saving a doc, for
instance, trying to create a doc that already exists, or trying to save a doc
when a newer version already exists in Elasticsearch.

The callback is called with two arguments:

=over

=item *

The doc you are trying to save

=item *

The current version of the doc which exists in Elasticsearch

=back

See L<Elastic::Model::Role::Doc/save()> for more.

=head2 on_error

The C<on_error> callback will be called for any non-conflict error (or
for conflict errors if no L</on_conflict> handler has been specified).
It is called with two arguments:

=over

=item *

The doc you are trying to save

=item *

The error string returned by Elasticsearch

=back

If no C<on_error> handler is specified, then bulk indexing will die with
an error message.

=head1 METHODS

=head2 save()

    $bulk->save($doc);

Adds a doc to the internal queue to be saved later.

=head2 overwrite()

    $bulk->overwrite($doc);

Adds a doc to the interal queue to be overwritten later.  In other words,
no version checking is done - if a newer version of the doc exists in
Elasticsearch, it will be overwritten.

=head2 commit()

    $bulk->commit()

Writes all docs in the queue to Elasticsearch.  This is called automatically
when there are L</size> docs in the queue, or when the C<$bulk> instance
goes out of scope, although you should call L</commit()> yourself once
you are finished adding docs, just to be on the safe side.

=head2 clear()

    $bulk->clear()

Clears any docs that are still in the queue.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Bulk-saving of multiple docs for increased throughput

