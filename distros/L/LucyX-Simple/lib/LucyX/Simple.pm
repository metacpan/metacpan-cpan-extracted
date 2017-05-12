package LucyX::Simple;

our $VERSION = '0.008002';
$VERSION = eval $VERSION;

use Moo;

use Lucy::Analysis::PolyAnalyzer;
use Lucy::Plan::Schema;
use Lucy::Index::Indexer;
use Lucy::Search::IndexSearcher;
use Lucy::Search::QueryParser;
use Lucy::Plan::FullTextType;
use Lucy::Plan::BlobType;
use Lucy::Plan::Float32Type;
use Lucy::Plan::Float64Type;
use Lucy::Plan::Int32Type;
use Lucy::Plan::Int64Type;
use Lucy::Plan::StringType;

use Data::Page;
use Exception::Simple;

has _language => (
    'is' => 'ro',
    'default' => sub{ 'en' },
    'init_arg' => 'language',
);

has _index_path => (
    'is' => 'ro',
    'required' => 1,
    'init_arg' => 'index_path',
);

has _analyser => (
    'is' => 'ro',
    'init_arg' => 'analyser',
    'default' => sub { return Lucy::Analysis::PolyAnalyzer->new( language => shift->_language ) },
    'lazy' => 1,
);

has schema => (
    'is' => 'ro',
    'required' => 1,
);

has '_index_schema' => (
    'is' => 'lazy',
    'init_arg' => undef,
);

sub _build__index_schema{
    my $self = shift;
    
    my $schema = Lucy::Plan::Schema->new;

    my $types = {
        'fulltext' => 'Lucy::Plan::FullTextType',
        'blob' => 'Lucy::Plan::BlobType',
        'float32' => 'Lucy::Plan::Float32Type', 
        'float64' => 'Lucy::Plan::Float64Type',
        'int32' => 'Lucy::Plan::Int32Type',
        'int64' => 'Lucy::Plan::Int64Type',
        'string' => 'Lucy::Plan::StringType',
    };

    foreach my $field ( @{$self->schema} ){
        my $type_options = {};
        foreach my $option ( qw/boost indexed stored sortable/ ){
            my $field_option = delete( $field->{ $option } );
            if ( defined( $field_option ) ){
                $type_options->{ $option } = $field_option;
            }
        }

        my $type = $field->{'type'} || 'fulltext';
        if ( $type eq 'fulltext' ){
            $type_options->{'analyzer'} = $self->_analyser;
            $type_options->{'highlightable'} = delete $field->{'highlightable'} || 0;
        }
        $field->{'type'} = $types->{ $type }->new( %{$type_options} );
        $schema->spec_field( %{$field} );
    }
    return $schema;
}

has _indexer => (
    'is' => 'lazy',
    'init_arg' => undef,
    'clearer' => 1,
);

sub _build__indexer{
    my $self = shift;

    return Lucy::Index::Indexer->new(
        schema => $self->_index_schema,   
        index  => $self->_index_path,
        create => 1,
    );
}

has _searcher => (
    'is' => 'lazy',
    'init_arg' => undef,
    'clearer' => 1,
);

sub _build__searcher{
    return Lucy::Search::IndexSearcher->new( 
        'index' => shift->_index_path,
    );
}

has search_fields => (
    'is' => 'ro',
    'required' => 1,
);

has search_boolop => (
    'is' => 'ro',
    'default' => sub{ return 'OR' },
);

has _query_parser => (
    'is' => 'lazy',
    'init_arg' => undef,
);

sub _build__query_parser{
    my $self = shift;

    my $query_parser = Lucy::Search::QueryParser->new(
        schema => $self->_searcher->get_schema,
        fields => $self->search_fields,
        default_boolop => $self->search_boolop,
    );

    $query_parser->set_heed_colons(1);

    return $query_parser;
}

has resultclass => (
    'is' => 'rw',
    'lazy' => 1,
    'coerce' => sub{my $class = shift; eval "use ${class}"; return $class},
    'default' => sub{ return 'LucyX::Simple::Result::Object' },
);

has entries_per_page => (
    'is' => 'rw',
    'lazy' => 1,
    'default' => sub{ return 100 },
);

sub sorted_search{
    my ( $self, $query, $criteria, $page ) = @_;

    my @rules;
    foreach my $key ( keys( %{$criteria} ) ){
        push( 
            @rules,  
            Lucy::Search::SortRule->new(
                field   => $key,
                reverse => $criteria->{ $key },
            )
        );
    }

    return $self->search( $query, $page, Lucy::Search::SortSpec->new( rules => \@rules ) );
}

sub search{
    my ( $self, $query_string, $page, $sort_spec ) = @_;

    Exception::Simple->throw('no query string') if !$query_string;
    $page ||= 1;

    my $query = $self->_query_parser->parse( $query_string );

    my $search_options = {
        'query' => $query,
        'offset' => ( ( $self->entries_per_page * $page ) - $self->entries_per_page ),
        'num_wanted' => $self->entries_per_page,
    };
    $search_options->{'sort_spec'} = $sort_spec if $sort_spec;

    my $hits = $self->_searcher->hits( %{$search_options} );
    my $pager = Data::Page->new($hits->total_hits, $self->entries_per_page, $page);

    my @results;
    while ( my $hit = $hits->next ) {
        my $result = {};
        foreach my $field ( @{$self->schema} ){
            $result->{ $field->{'name'} } = $hit->{ $field->{'name'} };
        }
        push( @results, $self->resultclass->new( $result ) );
    }

    return ( \@results, $pager ) if scalar(@results);
    Exception::Simple->throw('no results');

}

sub create{
    my ( $self, $document ) = @_;

    Exception::Simple->throw('no document') if ( !$document );

    $self->_indexer->add_doc( $document );
}

sub update_or_create{
    my ( $self, $document, $pk ) = @_;

    Exception::Simple->throw('no document') if !$document;
    $pk ||= 'id';
    my $pv = $document->{ $pk };

    Exception::Simple->throw('no primary key value') if !$pv;
    $self->delete( $pk, $pv );

    $self->create( $document );
}

sub delete{
    my ( $self, $key, $value ) = @_;

    Exception::Simple->throw( 'missing key' ) if !defined( $key );
    Exception::Simple->throw( 'missing value' ) if !defined( $value );

    #delete only works on finished indexes
    $self->commit;
    $self->_indexer->delete_by_term(
        'field' => $key,
        'term' => $value,
    );
}

sub commit{
    my ( $self, $optimise ) = @_;

    $self->_indexer->optimize if $optimise;
    $self->_indexer->commit;

    $self->_clear_indexer;
    $self->_clear_searcher;
}

__PACKAGE__->meta->make_immutable;
