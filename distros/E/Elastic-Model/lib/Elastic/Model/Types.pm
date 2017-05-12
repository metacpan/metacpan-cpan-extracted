package Elastic::Model::Types;
$Elastic::Model::Types::VERSION = '0.52';
use strict;
use warnings;
use Search::Elasticsearch();

use MooseX::Types::Moose qw(HashRef ArrayRef Str Bool Num Int Defined Any);
use MooseX::Types::Structured qw (Dict Optional Map);
use namespace::autoclean;

use MooseX::Types -declare => [ qw(
        ArrayRefOfStr
        Binary
        Consistency
        CoreFieldType
        DynamicMapping
        ES
        ES_1x
        ES_90
        FieldType
        GeoPoint
        HighlightArgs
        IndexMapping
        IndexNames
        Keyword
        Latitude
        Longitude
        MultiField
        MultiFields
        PathMapping
        Replication
        SortArgs
        StoreMapping
        TermVectorMapping
        Timestamp
        UID
        )
];

my @enums = (
    FieldType,
    [   'string', 'integer',   'long',   'float',
        'double', 'short',     'byte',   'boolean',
        'date',   'binary',    'object', 'nested',
        'ip',     'geo_point', 'attachment'
    ],
    CoreFieldType,
    [   'string', 'integer', 'long', 'float',
        'double', 'short',   'byte', 'boolean',
        'date',   'ip',      'geo_point'
    ],
    TermVectorMapping,
    [ 'no', 'yes', 'with_offsets', 'with_positions', 'with_positions_offsets' ],
    IndexMapping,
    [ 'analyzed', 'not_analyzed', 'no' ],
    DynamicMapping,
    [ 'false', 'strict', 'true' ],
    PathMapping,
    [ 'just_name', 'full' ],
    Replication,
    [ 'sync', 'async' ],
    Consistency,
    [ 'quorum', 'one', 'all' ],
);

while ( my $type = shift @enums ) {
    my $vals = shift @enums;
    subtype(
        $type,
        {   as      => enum($vals),
            message => sub { "Allowed values are: " . join '|', @$vals }
        }
    );
}

class_type ES_1x, { class => 'Search::Elasticsearch::Client::1_0::Direct' };
class_type ES_90, { class => 'Search::Elasticsearch::Client::0_90::Direct' };

#===================================
subtype ES(), as ES_1x | ES_90;
#===================================
coerce ES, from HashRef,
    via { Search::Elasticsearch->new( { client => '1_0::Direct', %$_ } ) };
coerce ES, from Str, via {
    s/^:/127.0.0.1:/;
    Search::Elasticsearch->new( client => '1_0::Direct', nodes => $_ );
};
coerce ES, from ArrayRef, via {
    my @nodes = @$_;
    s/^:/127.0.0.1:/ for @nodes;
    Search::Elasticsearch->new( client => '1_0::Direct', nodes => \@nodes );
};

#===================================
subtype StoreMapping, as enum( [ 'yes', 'no' ] );
#===================================
coerce StoreMapping, from Any, via { $_ ? 'yes' : 'no' };

#===================================
subtype MultiField, as Dict [
#===================================
    type                  => Optional [CoreFieldType],
    index                 => Optional [IndexMapping],
    index_name            => Optional [Str],
    boost                 => Optional [Num],
    null_value            => Optional [Str],
    analyzer              => Optional [Str],
    index_analyzer        => Optional [Str],
    search_analyzer       => Optional [Str],
    search_quote_analyzer => Optional [Str],
    term_vector           => Optional [TermVectorMapping],
    geohash               => Optional [Bool],
    lat_lon               => Optional [Bool],
    geohash_precision     => Optional [Int],
    precision_step        => Optional [Int],
    format                => Optional [Str],

];

#===================================
subtype MultiFields, as HashRef [MultiField];
#===================================

#===================================
subtype SortArgs, as ArrayRef;
#===================================
coerce SortArgs, from HashRef, via { [$_] };
coerce SortArgs, from Str,     via { [$_] };

#===================================
subtype HighlightArgs, as HashRef;
#===================================
coerce HighlightArgs, from Str, via { return { $_ => {} } };
coerce HighlightArgs, from ArrayRef, via {
    my $args = $_;
    my %fields;

    while ( my $field = shift @$args ) {
        die "Expected a field name but got ($field)"
            if ref $field;
        $fields{$field} = ref $args->[0] eq 'HASH' ? shift @$args : {};
    }
    return \%fields;
};

#===================================
subtype Longitude, as Num,
#===================================
    where { $_ >= -180 and $_ <= 180 },
    message {"Longitude must be in the range -180 to 180"};

#===================================
subtype Latitude, as Num,
#===================================
    where { $_ >= -90 and $_ <= 90 },
    message {"Latitude must be in the range -90 to 90"};

#===================================
subtype GeoPoint, as Dict [ lat => Latitude, lon => Longitude ];
#===================================
coerce GeoPoint, from ArrayRef, via { { lon => $_->[0], lat => $_->[1] } };
coerce GeoPoint, from Str, via {
    my ( $lat, $lon ) = split /,/;
    { lon => $lon, lat => $lat };
};

#===================================
subtype Binary, as Defined;
#===================================

#===================================
subtype IndexNames, as ArrayRef [Str],
#===================================
    where { @{$_} > 0 },    #
    message {"At least one domain name is required"};
coerce IndexNames, from Str, via { [$_] };

#===================================
subtype ArrayRefOfStr, as ArrayRef [Str];
#===================================
coerce ArrayRefOfStr, from Str, via { [$_] };

#===================================
subtype Timestamp, as Num;
#===================================

#===================================
subtype Keyword, as Str;
#===================================

#===================================
class_type UID, { class => 'Elastic::Model::UID' };
#===================================
coerce UID, from Str,     via { Elastic::Model::UID->new_from_string($_) };
coerce UID, from HashRef, via { Elastic::Model::UID->new($_) };

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Types - MooseX::Types for general and internal use

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    use Elastic::Model::Types qw(GeoPoint);

    has 'point' => (
        is      => 'ro',
        isa     => GeoPoint,
        coerce  => 1
    );

=head1 DESCRIPTION

Elastic::Model::Types define a number of L<MooseX::Types>, some for internal
use and some which will be useful generally.

=head1 PUBLIC TYPES

=head2 Keyword

    use Elastic::Model::Types qw(Keyword);

    has 'status' => (
        is  => 'ro',
        isa => Keyword
    );

C<Keyword> is a sub-type of C<Str>.  It is provided to make it easy to map
string values which should not be analyzed (eg a C<status> field rather than
a C<comment_body> field). See L<Elastic::Model::TypeMap::ES/Keyword>.

=head2 Binary

    use Elastic::Model::Types qw(Binary);

    has 'binary_field' => (
        is  => 'ro',
        isa => Binary
    );

Inherits from the C<Defined> type. Is automatically Base64 encoded/decoded.

=head2 GeoPoint

    use Elastic::Model::Types qw(GeoPoint);

    has 'point' => (
        is     => 'ro',
        isa    => GeoPoint,
        coerce => 1,
    );

C<GeoPoint> is a hashref with two keys:

=over

=item *

C<lon>: a C<Number> between -180 and 180

=item *

C<lat>: a C<Number> between -90 and 90

=back

It can be coerced from an C<ArrayRef> with C<[$lon,$lat]> and from a
C<Str> with C<"$lat,$lon">.

=head2 Timestamp

    use Elastic::Model::Types qw(Timestamp);

    has 'timestamp' => (
        is  => 'ro',
        isa => Timestamp
    );

A C<Timestamp> is a C<Num> which holds floating point epoch seconds, with milliseconds resolution.
It is automatically mapped as a C<date> field in Elasticsearch.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: MooseX::Types for general and internal use

