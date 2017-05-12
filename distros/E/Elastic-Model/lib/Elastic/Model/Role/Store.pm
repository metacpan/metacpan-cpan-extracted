package Elastic::Model::Role::Store;
$Elastic::Model::Role::Store::VERSION = '0.52';
use Moose::Role;

use Elastic::Model::Types qw(ES);
use namespace::autoclean;

#===================================
has 'es' => (
#===================================
    isa      => ES,
    is       => 'ro',
    required => 1,
);

my @Top_Level = qw(
    index       type        lenient
    preference  routing     scroll
    search_type timeout     version
);

#===================================
sub search {
#===================================
    my $self = shift;
    my $args = _tidy_search(@_);
    $self->es->search($args);
}

#===================================
sub scrolled_search {
#===================================
    my $self = shift;
    my $args = _tidy_search(@_);
    $self->es->scroll_helper($args);
}

#===================================
sub _tidy_search {
#===================================
    my %body = ref $_[0] eq 'HASH' ? %{ shift() } : @_;
    my %args;
    for (@Top_Level) {
        my $val = delete $body{$_};
        if ( defined $val ) {
            $args{$_} = $val;
        }
    }
    $args{body} = \%body;
    return \%args;
}
#===================================
sub delete_by_query {
#===================================
    my $self = shift;
    my $args = _tidy_search(@_);
    $self->es->delete_by_query($args);
}

#===================================
sub get_doc {
#===================================
    my ( $self, $uid, %args ) = @_;
    return $self->es->get(
        fields  => [qw(_routing _parent)],
        _source => 1,
        %{ $uid->read_params },
        %args,
    );
}

#===================================
sub doc_exists {
#===================================
    my ( $self, $uid, %args ) = @_;
    return !!$self->es->exists( %{ $uid->read_params }, %args, );
}

#===================================
sub create_doc { shift->_write_doc( 'create', @_ ) }
sub index_doc  { shift->_write_doc( 'index',  @_ ) }
#===================================

#===================================
sub _write_doc {
#===================================
    my ( $self, $action, $uid, $data, %args ) = @_;
    return $self->es->$action(
        body => $data,
        %{ $uid->write_params },
        %args
    );
}

#===================================
sub delete_doc {
#===================================
    my $self = shift;
    my $uid  = shift;
    my %args = _cleanup(@_);
    return $self->es->delete( %{ $uid->write_params }, %args );
}

#===================================
sub bulk {
#===================================
    my ( $self, %args ) = @_;
    return $self->es->bulk(%args);
}

#===================================
sub index_exists {
#===================================
    my ( $self, %args ) = @_;
    return $self->es->indices->exists(%args);
}

#===================================
sub create_index {
#===================================
    my ( $self, %args ) = @_;
    $args{body} = {
        settings => ( delete( $args{settings} ) || {} ),
        mappings => ( delete( $args{mappings} ) || {} ),
    };
    return $self->es->indices->create(%args);
}

#===================================
sub delete_index {
#===================================
    my $self = shift;
    my %args = _cleanup(@_);
    return $self->es->indices->delete(%args);
}

#===================================
sub refresh_index {
#===================================
    my $self = shift;
    my %args = _cleanup(@_);
    return $self->es->indices->refresh(%args);
}

#===================================
sub open_index {
#===================================
    my $self = shift;
    my %args = _cleanup(@_);
    return $self->es->indices->open(%args);
}

#===================================
sub close_index {
#===================================
    my $self = shift;
    my %args = _cleanup(@_);
    return $self->es->indices->close(%args);
}

#===================================
sub update_index_settings {
#===================================
    my ( $self, %args ) = @_;
    $args{body} = { settings => delete $args{settings} };
    return $self->es->indices->put_settings(%args);
}

#===================================
sub get_aliases {
#===================================
    my $self = shift;
    my %args = _cleanup(@_);
    return $self->es->indices->get_aliases( ignore => 404, %args ) || {};
}

#===================================
sub put_aliases {
#===================================
    my ( $self, %args ) = @_;
    $args{body} = { actions => delete $args{actions} };
    return $self->es->indices->update_aliases(%args);
}

#===================================
sub get_mapping {
#===================================
    my $self = shift;
    my %args = _cleanup(@_);
    return $self->es->indices->get_mapping(%args);
}

#===================================
sub put_mapping {
#===================================
    my ( $self, %args ) = @_;
    $args{body} = delete $args{mapping};
    return $self->es->indices->put_mapping(%args);
}

#===================================
sub delete_mapping {
#===================================
    my $self = shift;
    my %args = _cleanup(@_);
    return $self->es->indices->delete_mapping(%args);
}

#===================================
sub reindex {
#===================================
    my ( $self, %args ) = @_;
    my %params = (
        max_count   => delete $args{bulk_size},
        on_conflict => delete $args{on_conflict},
        on_error    => delete $args{on_error},
        verbose     => delete $args{verbose},
    );
    for ( keys %params ) {
        delete $params{$_} unless defined $params{$_};
    }
    my $bulk = $self->es->bulk_helper(%params);
    $bulk->reindex( %args, version_type => 'external', );
}

#===================================
sub bootstrap_uniques {
#===================================
    my ( $self, %args ) = @_;

    my $es = $self->es;
    return if $es->indices->exists( index => $args{index} );

    $es->indices->create(
        index => $args{index},
        body  => {
            settings => { number_of_shards => 1 },
            mappings => {
                _default_ => {
                    _all    => { enabled => 0 },
                    _source => { enabled => 0 },
                    _type   => { index   => 'no' },
                    enabled => 0,
                }
            }
        }
    );
}

#===================================
sub create_unique_keys {
#===================================
    my ( $self, %args ) = @_;
    my %keys = %{ $args{keys} };

    my %failed;
    my $bulk = $self->es->bulk_helper(
        index       => $args{index},
        on_conflict => sub {
            my ( $action, $doc ) = @_;
            $failed{ $doc->{_type} } = $doc->{_id};
        },
        on_error => sub {
            die "Error creating multi unique keys: $_[2]";
        }
    );
    $bulk->create(
        map { +{ _type => $_, _id => $keys{$_}, _source => {} } }
            keys %keys
    );
    $bulk->flush;
    if (%failed) {
        delete @keys{ keys %failed };
        $self->delete_unique_keys( index => $args{index}, keys => \%keys );
    }
    return %failed;
}

#===================================
sub delete_unique_keys {
#===================================
    my ( $self, %args ) = @_;
    my %keys = %{ $args{keys} };

    my $bulk = $self->es->bulk_helper(
        index    => $args{index},
        on_error => sub {
            die "Error deleting multi unique keys: $_[2]";
        }
    );
    $bulk->delete( map { { type => $_, id => $keys{$_} } } keys %keys );
    $bulk->flush;
    return 1;
}

our %Warned;

#===================================
sub _cleanup {
#===================================
    my (%args) = @_;
    if ( delete $args{ignore_missing} ) {
        warn "(ignore_missing) is deprecated. use { ignore => 404 } instead"
            unless $Warned{ignore_missing}++;
        $args{ignore} = 404;
    }
    return (%args);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Role::Store - Elasticsearch backend for document read/write requests

=head1 VERSION

version 0.52

=head1 DESCRIPTION

All document-related requests to the Elasticsearch backend are handled
via L<Elastic::Model::Role::Store>.

=head1 ATTRIBUTES

=head2 es

    $es = $store->es

Returns the connection to Elasticsearch.

=head1 METHODS

=head2 get_doc()

    $result = $store->get_doc($uid, %args);

Retrieves the doc specified by the L<$uid|Elastic::Model::UID> from
Elasticsearch, by calling L<Search::Elasticsearch/"get()">. Throws an exception
if the document does not exist.

=head2 doc_exists()

    $bool = $store->doc_exists($uid, %args);

Checks whether the doc exists in ElastciSearch. Any C<%args> are passed through
to L<Search::Elasticsearch/exists()>.

=head2 create_doc()

    $result = $store->create_doc($uid => \%data, %args);

Creates a doc in the Elasticsearch backend and returns the raw result.
Throws an exception if a doc with the same L<$uid|Elastic::Model::UID>
already exists.  Any C<%args> are passed to L<Search::Elasticsearch::Client::Direct/"create()">

=head2 index_doc()

    $result = $store->index_doc($uid => \%data, %args);

Updates (or creates) a doc in the Elasticsearch backend and returns the raw
result. Any failure throws an exception.  If the L<version|Elastic::Model::UID/"version">
number does not match what is stored in Elasticsearch, then a conflict exception
will be thrown.  Any C<%args> will be passed to L<Search::Elasticsearch::Client::Direct/"index()">.
For instance, to overwrite a document regardless of version number, you could
do:

    $result = $store->index_doc($uid => \%data, version => 0 );

=head2 delete_doc()

    $result = $store->delete_doc($uid, %args);

Deletes a doc in the Elasticsearch backend and returns the raw
result. Any failure throws an exception.  If the L<version|Elastic::Model::UID/"version">
number does not match what is stored in Elasticsearch, then a conflict exception
will be thrown.  Any C<%args> will be passed to L<Search::Elasticsearch::Client::Direct/"delete()">.

=head2 bulk()

    $result = $store->bulk(
        actions     => $actions,
        on_conflict => sub {...},
        on_error    => sub {...},
        on_success  => sub {...},
        %args
    );

Performs several actions in a single request. Any %args will be passed to
L<Search::Elasticsearch::Client::Direct/bulk_helper()>.

=head2 search()

    $results = $store->search(@args);

Performs a search, passing C<@args> to L<Search::Elasticsearch::Client::Direct/"search()">.

=head2 scrolled_search()

    $results = $store->scrolled_search(@args);

Performs a scrolled search, passing C<@args> to L<Search::Elasticsearch::Client::Direct/"scroll_helper()">.

=head2 delete_by_query()

    $response = $store->delete_by_query(@args);

Performs a delete-by-query, passing C<@args> to L<Search::Elasticsearch::Client::Direct/delete_by_query()>.

=head2 index_exists()

    $bool = $store->index_exists(@args);

Checks whether the specified index exists, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/exists()>.

=head2 create_index()

    $response = $store->create_index(@args);

Creates the specified index, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/create()>.

=head2 delete_index()

    $response = $store->delete_index(@args);

Deletes the specified index, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/delete()>.

=head2 refresh_index()

    $response = $store->refresh_index(@args);

Refreshes the specified index, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/refresh()>.

=head2 open_index()

    $response = $store->open_index(@args);

Opens the specified index, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/open()>.

=head2 close_index()

    $response = $store->close_index(@args);

Closes the specified index, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/close()>.

=head2 update_index_settings()

    $response = $store->update_index_settings(@args);

Updates the settings of the specified index, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/update_settings()>.

=head2 get_aliases()

    $response = $store->get_aliases(@args);

Retrieves the aliases for the specified indices, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/get_aliases()>.

=head2 put_aliases()

    $response = $store->put_aliases(@args);

Updates the aliases for the specified indices, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/update_aliases()>.

=head2 get_mapping()

    $response = $store->get_mapping(@args);

Retrieves the mappings for the specified index, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/get_mapping()>.

=head2 put_mapping()

    $response = $store->put_mapping(@args);

Updates the mappings for the specified index, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/put_mapping()>.

=head2 delete_mapping()

    $response = $store->delete_mapping(@args);

Deletes the mappings and associated documents for the specified index, passing C<@args> to L<Search::Elasticsearch::Client::Direct::Indices/delete_mapping()>.

=head2 reindex()

    $response = $store->reindex(@args);

Passes the C<@args> to L<Search::Elasticsearch::Bulk/reindex()>.

=head2 bootstrap_uniques()

    $response = $store->bootstrap_uniques(@args);

Creates the index which will store unique constraints, unless it already exists.

=head2 create_unique_keys()

    $response = $store->create_unique_keys(@args);

Inserts the documents representing unique constraints, and throws an error if they already exist.

=head2 delete_unique_keys()

    $response = $store->delete_unique_keys(@args);

Deletes the documents representing the specified unique constraints.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Elasticsearch backend for document read/write requests

