package TestModel::DocumentTypeB;

use Moose;
use Elasticsearch::Model::Document;
use Elasticsearch::Model::Types qw/:all/;

has frobnob => (
    is => 'ro',
    isa => 'Str',
    format => "epoch_millis",
);

has place => (
    is  => 'ro',
    isa => Location,
    type => 'geo_point',
);

__PACKAGE__->meta->make_immutable;

1;



