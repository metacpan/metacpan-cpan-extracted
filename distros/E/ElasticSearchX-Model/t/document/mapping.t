package MyType;
use Moose;
use ElasticSearchX::Model::Document;

has name => ( is => 'ro', index => 'analyzed' );

package MyClass;
use Moose;
use ElasticSearchX::Model::Document;
use ElasticSearchX::Model::Document::Types qw(:all);
use MooseX::Types -declare => [ 'Resources', 'Profile' ];
use MooseX::Types::Structured qw(Dict Tuple Optional);
use MooseX::Types::Moose qw/Int Str ArrayRef HashRef Undef/;

subtype Resources,
    as Dict [
    license => Optional [ ArrayRef [Str] ],
    homepage => Optional [Str],
    bugtracker => Optional [ Dict [ web => Str, mailto => Str ] ]
    ];

subtype Profile, as ArrayRef [ Dict [ id => Str ] ];
coerce Profile, from HashRef, via { [$_] };

has default => ( is => 'ro' );
has profile =>
    ( is => 'ro', isa => Profile, type => 'nested', include_in_root => 1 );
has date => ( is => 'ro', isa            => 'DateTime' );
has pod  => ( is => 'ro', include_in_all => 0 );
has loc  => ( is => 'ro', isa            => Location );
has res  => ( is => 'ro', isa            => Resources );
has abstract => (
    is          => 'ro',
    analyzer    => 'lowercase',
    term_vector => 'with_positions_offsets'
);
has module => (
    is              => 'ro',
    isa             => Type ['MyType'],
    type            => 'nested',
    include_in_root => 1
);
has modules => (
    is              => 'ro',
    isa             => ArrayRef [ Type ['MyType'] ],
    type            => 'nested',
    include_in_root => 1
);
has extra => ( is => 'ro', source_only => 1 );
has vater => ( is => 'ro', parent      => 1 );

package main;
use Test::More;
use strict;
use warnings;

my $meta = MyClass->meta;

is_deeply(
    [ sort map { $_->name } $meta->get_all_properties ],
    [
        qw(_id _version abstract date default extra loc module modules pod profile res vater)
    ]
);

my $module  = $meta->get_attribute('module')->build_property;
my $modules = $meta->get_attribute('modules')->build_property;
is_deeply(
    $module,
    {
        dynamic         => \0,
        include_in_root => \1,
        properties      => {
            name => {
                fields => {
                    analyzed => {
                        analyzer  => 'standard',
                        index     => 'analyzed',
                        store     => 'yes',
                        type      => 'string',
                        fielddata => { format => 'disabled' },
                    },
                    name => {
                        doc_values   => \1,
                        ignore_above => 2048,
                        index        => 'not_analyzed',
                        type         => 'string',
                    },
                },
                type => 'multi_field',
            },
        },
        type => 'nested',
    }
);

is_deeply( $module, $modules );

is_deeply(
    MyClass->meta->mapping,
    {
        dynamic => \0,
        _parent => {
            type => 'vater',
        },
        properties => {
            abstract => {
                fields => {
                    abstract => {
                        doc_values   => \1,
                        ignore_above => 2048,
                        index        => 'not_analyzed',
                        type         => 'string',
                    },
                    analyzed => {
                        analyzer    => 'lowercase',
                        index       => 'analyzed',
                        store       => 'yes',
                        term_vector => 'with_positions_offsets',
                        type        => 'string',
                        fielddata   => { format => 'disabled' },
                    },
                },
                type => 'multi_field',
            },
            date => {
                doc_values => \1,
                type       => 'date',
            },
            default => {
                doc_values   => \1,
                ignore_above => 2048,
                index        => 'not_analyzed',
                type         => 'string',
            },
            loc => {
                doc_values => \1,
                type       => 'geo_point',
            },
            module => {
                dynamic         => \0,
                include_in_root => \1,
                properties      => {
                    name => {
                        fields => {
                            analyzed => {
                                analyzer  => 'standard',
                                index     => 'analyzed',
                                store     => 'yes',
                                type      => 'string',
                                fielddata => { format => 'disabled' },
                            },
                            name => {
                                doc_values   => \1,
                                ignore_above => 2048,
                                index        => 'not_analyzed',
                                type         => 'string',
                            },
                        },
                        type => 'multi_field',
                    },
                },
                type => 'nested',
            },
            modules => {
                dynamic         => \0,
                include_in_root => \1,
                properties      => {
                    name => {
                        fields => {
                            analyzed => {
                                analyzer  => 'standard',
                                index     => 'analyzed',
                                store     => 'yes',
                                type      => 'string',
                                fielddata => { format => 'disabled' },
                            },
                            name => {
                                doc_values   => \1,
                                ignore_above => 2048,
                                index        => 'not_analyzed',
                                type         => 'string',
                            },
                        },
                        type => 'multi_field',
                    },
                },
                type => 'nested',
            },
            pod => {
                doc_values     => \1,
                ignore_above   => 2048,
                include_in_all => \0,
                index          => 'not_analyzed',
                type           => 'string',
            },
            profile => {
                dynamic         => \0,
                include_in_root => \1,
                properties      => {
                    id => {
                        doc_values   => \1,
                        ignore_above => 2048,
                        index        => 'not_analyzed',
                        type         => 'string',
                    },
                },
                type => 'nested',
            },
            res => {
                dynamic    => \0,
                properties => {
                    bugtracker => {
                        dynamic    => \0,
                        properties => {
                            mailto => {
                                doc_values   => \1,
                                ignore_above => 2048,
                                index        => 'not_analyzed',
                                type         => 'string',
                            },
                            web => {
                                doc_values   => \1,
                                ignore_above => 2048,
                                index        => 'not_analyzed',
                                type         => 'string',
                            },
                        },
                        type => 'object',
                    },
                    homepage => {
                        doc_values   => \1,
                        ignore_above => 2048,
                        index        => 'not_analyzed',
                        type         => 'string',
                    },
                    license => {
                        doc_values   => \1,
                        ignore_above => 2048,
                        index        => 'not_analyzed',
                        type         => 'string',
                    },
                },
                type => 'object',
            },
        },
    }
);

done_testing;
