package Foo;
use Moose;
use ElasticSearchX::Model::Document;

has some => ( is => 'ro' );
has name => ( is => 'ro', required => 1, id => 1 );
has more => ( is => 'ro', property => 0 );

use Test::More;
use strict;
use warnings;

is( Foo->meta->get_id_attribute, Foo->meta->get_attribute('name') );
ok( Foo->meta->get_id_attribute->is_required );
ok(
    Foo->meta->get_id_attribute->does(
        'MooseX::Attribute::LazyInflator::Meta::Role::Attribute')
);
done_testing;
