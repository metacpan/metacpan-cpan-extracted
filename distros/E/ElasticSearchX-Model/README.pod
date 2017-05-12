package ElasticSearchX::Model;

# ABSTRACT: Extensible and flexible model for Elasticsearch based on Moose
use Moose 2.02 ();
use Moose::Exporter ();
use ElasticSearchX::Model::Index;
use ElasticSearchX::Model::Bulk;

Moose::Exporter->setup_import_methods(
    with_meta        => [qw(index analyzer tokenizer filter)],
    class_metaroles  => { class => ['ElasticSearchX::Model::Trait::Class'] },
    base_class_roles => [qw(ElasticSearchX::Model::Role)],
);

sub index {
    my ( $self, $name, @rest ) = @_;
    if ( !ref $name ) {

        # DSL call, where $self is the meta object
        return $self->add_index( $name, {@rest} );
    }
    elsif ( ref $name eq 'ARRAY' ) {
        $self->add_index( $_, {@rest} ) for (@$name);
        return;
    }
    else {

        # method call, i.e. $model->index()
        my $options = $name->meta->get_index( $rest[0] );
        my $index   = ElasticSearchX::Model::Index->new(
            name => $rest[0],
            %$options, model => $name
        );
        $options->{types} = $index->types;
        return $index;
    }
}

sub analyzer {
    shift->add_analyzer( shift, {@_} );
}

sub tokenizer {
    shift->add_tokenizer( shift, {@_} );
}

sub filter {
    shift->add_filter( shift, {@_} );
}

1;

__END__

=head1 SYNOPSIS

 package MyModel::Tweet;
 use Moose;
 use ElasticSearchX::Model::Document;

 has message => ( is => 'ro', isa => 'Str' );
 has date => (
    is       => 'ro',
    required => 1,
    isa      => 'DateTime',
    default  => sub { DateTime->now }
 );

 package MyModel;
 use Moose;
 use ElasticSearchX::Model;

 __PACKAGE__->meta->make_immutable;

  my $model = MyModel->new;
  $model->deploy;
  my $tweet = $model->index('default')->type('tweet')->put({
      message => 'Hello there!'
  });
  print $tweet->_id;
  $tweet->delete;

=head1 DESCRIPTION

This is an Elasticsearch to Moose mapper which hides the REST api
behind object-oriented api calls. Elasticsearch types and indices
are defined using Moose classes and a flexible DSL.

Deployment statements for Elasticsearch can be build dynamically
using these classes. Results from Elasticsearch inflate automatically
to the corresponding Moose classes. Furthermore, it provides
sensible defaults.

The search API makes the tedious task of building Elasticsearch queries
a lot easier.

B<< The L<ElasticSearchX::Model::Tutorial> is probably the best place
to get started! >>

B<< WARNING: This module is being used in production already but I don't
consider it being stable in terms of the API and implementation details. >>



=head1 DSL

=head2 index

 index twitter => ( namespace => 'MyNamespace', traits => ['MyTrait'] );

 index facebook => ( types => [qw(FB::User FB::Friends)] );

Adds an index to the model. By default there is a C<default>
index, which will be removed once you add custom indices.

See L<ElasticSearchX::Model::Index/ATTRIBUTES> for available options.

=head2 analyzer

=head2 tokenizer

=head2 filter

 analyzer lowercase => ( tokenizer => 'keyword',  filter   => 'lowercase' );

 tokenizer camelcase => (
     type => 'pattern',
     pattern => "([^\\p{L}\\d]+)|(?<=\\D)(?=\\d)|(?<=\\d)(?=\\D)|(?<=[\\p{L}&&[^\\p{Lu}]])(?=\\p{Lu})|(?<=\\p{Lu})(?=\\p{Lu}[\\p{L}&&[^\\p{Lu}]])"
 );
 analyzer camelcase => (
     type => 'custom',
     tokenizer => 'camelcase',
     filter => ['lowercase', 'unique']
 );

Adds analyzers, tokenizers or filters to all indices. They can
then be used in attributes of L<ElasticSearchX::Model::Document> classes.

=head1 ATTRIBUTES

=head2 es

Builds and holds the L<ElasticSearch> object. Valid values are:

=over

=item B<:9200>

Connect to a server on C<127.0.0.1>, port C<9200> with the C<httptiny>
transport class and a timeout of 30 seconds.

=item B<[qw(:9200 12.12.12.12:9200)]>

Connect to C<127.0.0.1:9200> and C<12.12.12.12:9200> with the same
defaults as above.

=item B<{ %args }>

Passes C<%args> directly to the L<ElasticSearch> constructor.

=back

=head2 bulk

 my $bulk = $model->bulk( size => 100 );
 $bulk->put($tweet);
 $bulk->commit; # optional

Returns an instance of L<ElasticSearchX::Model::Bulk>.

=head1 METHODS

=head2 index

 my $index = $model->index('twitter');

Returns an L<ElasticSearchX::Model::Index> object.

=head2 deploy

C<deploy> pushes the mapping to the Elasticsearch server. It will
automatically try to upgrade your mapping if the types already
exists. However, this might not be possible in case you changes
a field from one data type to another and Elasticsearch cannot
figure out how to translate it. In this case C<deploy> will
throw an error message.

To create the indices from scratch, pass C<< delete => 1 >>.
B<< This will delete all the data in your indices. >>

 $model->deploy( delete => 1 );

=head2 es_version

 if($model->es_version > 0.02) { ... }

Returns the L<version> number of the Elasticsearch server you are currently
connected to. Elasticsearch uses Semantic Versioning. However, release candidates
have a special syntax. For example, the version 0.20.0.RC1 would be parsed
as 0.020_000_001.

=head1 PERFORMANCE CONSIDERATIONS

Creating objects is a quite expensive operation. If you are
crawling through large amounts of data, you will gain a huge
speed improvement by not inflating the results to their
document classes (see L<ElasticSearchX::Model::Document::Set/raw>).
