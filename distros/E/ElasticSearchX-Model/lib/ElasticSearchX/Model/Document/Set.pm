#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2018 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Document::Set;
$ElasticSearchX::Model::Document::Set::VERSION = '2.0.0';
# ABSTRACT: Represents a query used for fetching a set of results
use Moose;
use MooseX::Attribute::Chained;
use MooseX::Attribute::ChainedClone;
use ElasticSearchX::Model::Scroll;
use ElasticSearchX::Model::Document::Types qw(:all);

has type => ( is => 'ro', required => 1 );
has index => ( is => 'ro', required => 1, handles => [qw(es model)] );

has query => (
    isa    => 'HashRef',
    is     => 'rw',
    traits => [qw(ChainedClone)]
);

has filter => (
    isa    => 'HashRef',
    is     => 'rw',
    traits => [qw(ChainedClone)]
);

has [qw(from size)] =>
    ( isa => 'Int', is => 'rw', traits => [qw(ChainedClone)] );

has [qw(fields sort)] => (
    isa    => 'ArrayRef',
    is     => 'rw',
    traits => [qw(ChainedClone)]
);

has source => (
    is      => 'rw',
    traits  => [qw(ChainedClone)],
    default => sub { \1 },
);

sub add_sort { push( @{ $_[0]->sort }, $_[1] ); return $_[0]; }

sub add_field { push( @{ $_[0]->fields }, $_[1] ); return $_[0]; }

has search_type =>
    ( isa => QueryType, is => 'rw', traits => [qw(ChainedClone)] );

sub query_type { shift->search_type(@_) }

has mixin => ( is => 'ro', isa => 'HashRef', traits => [qw(ChainedClone)] );

has inflate =>
    ( isa => 'Bool', default => 1, is => 'rw', traits => [qw(ChainedClone)] );

sub raw {
    shift->inflate(0);
}

has _refresh =>
    ( isa => 'Bool', default => 0, is => 'rw', traits => [qw(ChainedClone)] );

sub refresh {
    shift->_refresh(1);
}

sub _build_qs {
    my ( $self, $qs ) = @_;
    $qs ||= {};

    # we only want to set qs if they are not the default
    $qs->{refresh} = 1 if ( $self->_refresh );
    $qs->{search_type} = $self->search_type if $self->search_type;
    return $qs;
}

sub _build_query {
    my $self = shift;
    my $q = $self->query || { match_all => {} };
    if ( my $f = $self->filter ) {
        $q = { filtered => { query => $q, filter => $f } };
    }
    return {
        query   => $q,
        _source => $self->source,
        $self->size   ? ( size   => $self->size )   : (),
        $self->from   ? ( from   => $self->from )   : (),
        $self->fields ? ( fields => $self->fields ) : (),
        $self->sort   ? ( sort   => $self->sort )   : (),
        $self->mixin ? ( %{ $self->mixin } ) : (),
    };
}

sub put {
    my ( $self, $args, $qs ) = @_;
    my $doc = $self->new_document($args);
    $doc->put( $self->_build_qs($qs) );
    return $doc;
}

sub new_document {
    my ( $self, $args ) = @_;
    return $self->type->name->new( %$args, index => $self->index );
}

sub inflate_result {
    my ( $self, $res ) = @_;
    my ( $type, $index ) = ( $res->{_type}, $res->{_index} );
    $index = $index ? $self->model->index($index) : $self->index;
    $type  = $type  ? $index->get_type($type)     : $self->type;
    my $doc = $type->inflate_result( $index, $res );
    unless ( $res->{_source} ) {
        $doc->_loaded_attributes( { map { $_ => 1 } @{ $self->fields } } );
    }
    return $doc;
}

sub get {
    my ( $self, $args, $qs ) = @_;
    $qs = $self->_build_qs($qs);
    my ($id);
    my ( $index, $type ) = ( $self->index->name, $self->type->short_name );

    if ( !ref $args ) {
        $id = $args;
    }
    elsif ( my $pk = $self->type->get_id_attribute ) {
        my $found = 0;
        my @fields
            = map { $self->type->find_attribute_by_name($_) } @{ $pk->id };
        map { $found++ } grep { exists $args->{ $_->name } } @fields;
        die "All id fields need to be supplied to get: @fields"
            unless ( @fields == $found );
        $id = ElasticSearchX::Model::Util::digest(
            map {
                      $_->has_deflator
                    ? $_->deflate( $self, $args->{ $_->name } )
                    : $args->{ $_->name }
            } @fields
        );
    }

    my $res = $self->es->get(
        index => $index,
        type  => $type,
        id    => $id,
        $self->fields ? ( fields => $self->fields ) : (),
        ignore => [404],
        %{ $qs || {} },
    );
    return undef unless ($res);
    return $self->inflate ? $self->inflate_result($res) : $res;
}

sub all {
    my ( $self, $qs ) = @_;
    $qs = $self->_build_qs($qs);
    my ( $index, $type ) = ( $self->index->name, $self->type->short_name );
    my $res = $self->es->search(
        {
            index   => $index,
            type    => $type,
            body    => $self->_build_query,
            version => 1,
            %{ $qs || {} },
        }
    );
    return $res unless ( $self->inflate );
    return ()   unless ( $res->{hits}->{total} );
    return map { $self->inflate_result($_) } @{ $res->{hits}->{hits} };
}

sub first {
    my ( $self, $qs ) = @_;
    $qs = $self->_build_qs($qs);
    my @data = $self->size(1)->all($qs);
    return undef unless (@data);
    return $data[0] if ( $self->inflate );
    return $data[0]->{hits}->{hits}->[0];
}

sub count {
    my ( $self, $qs ) = @_;
    $qs = $self->_build_qs($qs);
    my ( $index, $type ) = ( $self->index->name, $self->type->short_name );
    my $query = $self->_build_query;
    delete $query->{_source};
    my $res = $self->es->count(
        {
            index => $index,
            type  => $type,
            body  => $query,
            %$qs,
        }
    );
    return $res->{count};
}

sub delete {
    my ( $self, $qs ) = @_;
    $qs = $self->_build_qs($qs);
    my $query = $self->_build_query;
    delete $query->{_source};

    my %idx_type = (
        index => $self->index->name,
        type  => $self->type->short_name
    );

    my $sc = $self->es->scroll_helper(
        search_type => 'scan',
        body        => $self->_build_query,
        size        => 500,
        %idx_type,
        %$qs,
    );

    my @ids;
    while ( my @d = $sc->next(500) ) {
        push @ids => map { $_->{_id} } @d;
    }

    my $bulk = $self->es->bulk_helper(%idx_type);
    $bulk->delete_ids(@ids);
    return $bulk->flush;
}

sub scroll {
    my ( $self, $scroll, $qs ) = @_;
    return ElasticSearchX::Model::Scroll->new(
        set => $self,
        scroll => $scroll || '1m',
        qs => $self->_build_qs( { version => 1, %{ $qs || {} } } ),
    );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Document::Set - Represents a query used for fetching a set of results

=head1 VERSION

version 2.0.0

=head1 SYNOPSIS

 my $type = $model->index('default')->type('tweet');
 my $all  = $type->all;

 my $result = $type->filter( { term => { message => 'hello' } } )->first;
 
 my $tweet
    = $type->get( { user => 'mo', post_date => DateTime->now->iso8601 } );


 package MyModel::Tweet::Set;
 
 use Moose;
 extends 'ElasticSearchX::Model::Document::Set';
 
 sub hello {
     my $self = shift;
     return $self->filter({
         term => { message => 'hello' }
     });
 }
 
 __PACKAGE__->meta->make_immutable;
 
 my $result = $type->hello->first;

=head1 DESCRIPTION

Whenever a type is accessed by calling L<ElasticSearchX::Model::Index/type>
you will receive an instance of this class.  The instance can then be used
to build new objects (L</new_document>), put new documents in the index
(L</put>), do search and so on.

=head1 SUBCLASSING

If you define a C<::Set> class on top of your document class, this class
will be used as set class. This allows you to put most of your business
logic in this class.

=head1 ATTRIBUTES

All attributes have the L<MooseX::Attribute::ChainedClone> trait applied.
That means that you can chain calls to these attributes and that a cloned
instance is returned whenever you set an attribute. This pattern is inspired
by L<DBIx::Class::ResultSet/search>.

 my $type = $model->index('default')->type('tweet');
 my @documents = $type->fields(['user'])->all;
 # $type->fields has not been touched, instead a cloned instance of $type
 # has been created with "fields" set to ['user']

 $type = $type->fields(['user']);
 # this will set $type to a cloned instance of $type with fields
 # set to ['user']
 @documents = $type->all;
 # same result as above

=head2 filter

Adds a filter to the query. If no L</query> is given, it will automatically
build a C<filtered> query, which performs far better.

=head2 query

=head2 size

=head2 from

=head2 fields

=head2 sort

=head2 search_type

These attributes are passed directly to the ElasticSearch search request.

=head2 mixin

The previously mentioned attributes don't cover all of
ElasticSearch's options for searching. You can set the
L</mixin> attribute to a HashRef which is then merged with
the attributes.

=head2 inflate

Inflate the returned results to the appropriate document
object. Defaults to C<1>. You can either use C<< $type->inflate(0) >>
to disable this behaviour for extra speed, or you can
use the L</raw> convenience method.

=head2 index

=head2 type

=head1 METHODS

=head2 all

=head2 all( { %qs } )

Returns all results as a list, limited by L</size> and L</from>.

=head2 scroll

=head2 scroll( $scroll, { %qs } )

 my $iterator = $twitter->type('tweet')->scroll;
 while ( my $tweet = $iterator->next ) {
     # do something
 }

Large results should be scrolled thorugh using this iterator.
It will return an instance of L<ElasticSearchX::Model::Scroll>.
The C<$scroll> parameter is a time value parameter (for example: C<5m>),
indicating for how long the nodes that participate in the search will
maintain relevant resources in order to continue and support it.
C<$scroll> defaults to C<1m>.

Scrolling is executed by pulling in L</size> number of documents.

=head2 first

=head2 first( { %qs } )

Returns the first result only. It automatically sets
L</size> to C<1> to speed up the retrieval. However,
it doesn't touch L</from>. In order to get the second
result, you would do:

 my $second = $type->from(2)->first;

=head2 count

Returns the number of results.

=head2 delete

=head2 delete( { %qs } )

Delete all documents that match the query. Issues a call to
L<ElasticSearch/delete_by_query()>.

=head2 get

=head2 get( { %qs } )

 $type->get('fd_ZGWupT2KOxw3w9Q7VSA');
 
 $type->get({
     user => 'mo',
     post_date => $dt->iso8601,
 });

Get a document by its id from ElasticSearch. You can either
pass the id as a string or you can pass a HashRef of
the values that make up the id.

=head2 put

=head2 put( { %qs } )

 my $doc = $type->put({
     message => 'hello',
 });

This methods builds a new document using L</new_document> and
pushes it to the index. It returns the created document. If
no id was supplied, the id will be fetched from ElasticSearch
and set on the object in the C<_id> attribute.

=head2 new_document

 my $doc = $type->new_document({
      message => 'hello',
  });

Builds a new document but doesn't commit it just yet. You
can manually commit the new document by calling
L<ElasticSearchX::Model::Document/put> on the document
object.

=head2 raw

Don't inflate returned results. This is a convenience
method around L</inflate>.

=head2 refresh

This will add the C<refresh> query parameter to all requests.

  $users->refresh->put( { nickname => 'mo' } );

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
