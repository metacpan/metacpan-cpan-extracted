#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2016 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyModel;

use Moose;

use version;

use ElasticSearchX::Model;
use IO::Socket::INET;
use Search::Elasticsearch;
use Test::More;

index twitter => ( namespace => 'MyModel' );

sub testing {
    my $class = shift;

    my $bind_to = $ENV{ES} || '127.0.0.1:9900';
    unless ( IO::Socket::INET->new($bind_to) ) {
        plan skip_all =>
            "Requires an Elasticsearch server running on port $bind_to";
    }

    my $model = $class->new(
        es => Search::Elasticsearch->new(
            nodes => $bind_to,

            # trace_to => "Stderr",
        )
    );
    if ( $model->es_version < 1 ) {
        plan skip_all => 'Requires Elasticsearch 1.0.0';
    }
    ok( $model->deploy( delete => 1 ), 'Deploy ok' );
    return $model;
}

__PACKAGE__->meta->make_immutable;
