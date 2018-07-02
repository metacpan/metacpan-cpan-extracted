package Elasticsearch::Model::Document::Role;

use Moose::Role;

has index => (
    isa => 'Elasticsearch::Model::Index',
    is  => 'rw'
);

1;
