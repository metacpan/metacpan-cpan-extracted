#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'KiokuX::Model::Role::Annotations';
use ok 'KiokuX::Model::Role::Annotations::Annotation';

{
    package Model;
    use Moose;

    extends qw(KiokuX::Model);

    with qw(KiokuX::Model::Role::Annotations);

    package Annotation;
    use Moose;

    with qw(KiokuX::Model::Role::Annotations::Annotation);

    package Foo;
    use Moose;
}

my $m = Model->new( dsn => "hash" );

$m->txn_do( scope => 1, body => sub { $m->insert( foo => Foo->new ) } );

$m->txn_do( scope => 1, body => sub {
    is_deeply( [ $m->annotations_for('foo') ], [], "no annotations" );

    ok( !$m->exists('annotations:foo'), "no annotation set in DB" );

    ok( !$m->has_annotations('foo'), "predicate by ID" );
    ok( !$m->has_annotations( $m->lookup('foo') ), "predicate by object" );

    $m->add_annotations( Annotation->new( subject => $m->lookup("foo") ) );

    ok( $m->exists('annotations:foo'), "annotation set inserted" );

    ok( $m->has_annotations('foo'), "predicate by ID" );
    ok( $m->has_annotations( $m->lookup('foo') ), "predicate by object" );

    {
        my ( $ann ) = $m->annotations_for('foo');

        isa_ok( $ann, 'Annotation', 'annotation by key' );
        is( $ann->subject, $m->lookup('foo'), "right annotation objects" );
    }

    {
        my ( $ann ) = $m->annotations_for( $m->lookup('foo') );

        isa_ok( $ann, 'Annotation', 'annotation by object' );
        is( $ann->subject, $m->lookup('foo'), "right annotation object" );
    }

    $m->add_annotations( Annotation->new( subject => $m->lookup("foo") ) );

    {
        my @ann = $m->annotations_for('foo');

        is( scalar(@ann), 2, "two annotations" );
    }
    
    $m->add_annotations_for( $m->lookup("foo"), Foo->new );

    {
        my @ann = $m->annotations_for('foo');

        is( scalar(@ann), 3, "three annotations" );

        is_deeply( [ sort map { ref } @ann ], [qw(Annotation Annotation Foo)], "arbitrary annotation objects" );
    }

    ok( $m->has_annotations('foo'), "predicate by ID" );
    ok( $m->has_annotations( $m->lookup('foo') ), "predicate by object" );

    $m->remove_annotations( grep { $_->does("KiokuX::Model::Role::Annotations::Annotation") } $m->annotations_for("foo") );

    ok( $m->has_annotations('foo'), "predicate by ID" );
    ok( $m->has_annotations( $m->lookup('foo') ), "predicate by object" );

    {
        my @ann = $m->annotations_for('foo');

        is( scalar(@ann), 1, "one annotation" );

        is_deeply( [ sort map { ref } @ann ], [qw(Foo)], "arbitrary annotation objects" );
    }

    $m->remove_annotations_for( $m->lookup("foo"), $m->annotations_for("foo") );
    
    ok( !$m->exists('annotations:foo'), "no annotation set in DB after removal" );

    ok( !$m->has_annotations('foo'), "predicate by ID" );
    ok( !$m->has_annotations( $m->lookup('foo') ), "predicate by object" );

    is_deeply( [ $m->annotations_for('foo') ], [], "no annotations" );
});

done_testing;

# ex: set sw=4 et:

