package TestModel::DocumentTypeA;

use Moose;
use Elasticsearch::Model::Document;
use Elasticsearch::Model::Types qw/:all/;

has full_name => (
    is       => 'ro',
    isa      => 'Str',
    analyzer => 'electro',
);

has id_number => (
    is         => 'ro',
    isa        => 'Int',
    null_value => 0,
);

has place => (
    is  => 'ro',
    isa => Location,
    type => 'geo_point',
);

has meaningless => (
    is    => 'ro',
    isa   => 'Maybe[Str]',
    index => 0,
    fields => {
        search_meaning => {
           type => 'keyword',
           normalizer => 'normie',
       },
    },
);

has second_place => (
    is    => 'ro',
    isa   => 'Maybe[' . Location . ']',
    type => 'geo_point',
    store => 1,
);

has trashbin => (
    is         => 'ro',
    isa        => 'Str',
    type       => 'binary',
    store      => 1,
    doc_values => 1,
);

__PACKAGE__->meta->make_immutable;

1;

