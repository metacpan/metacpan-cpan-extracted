#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2016 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyModel::Tweet;
use Moose;
use ElasticSearchX::Model::Document;
use DateTime;

has id   => ( is => 'ro', id  => [qw(user post_date)] );
has user => ( is => 'ro', isa => 'Str' );
has name => ( is => 'ro', isa => 'Str' );
has post_date =>
    ( is => 'ro', isa => 'DateTime', default => sub { DateTime->now } );
has message => ( is => 'rw', isa => 'Str', index => 'analyzed' );

__PACKAGE__->meta->make_immutable;
