package Elastic::Model::TypeMap::ES;
$Elastic::Model::TypeMap::ES::VERSION = '0.52';
use strict;
use warnings;

use Elastic::Model::TypeMap::Base qw(:all);
use namespace::autoclean;

#===================================
has_type 'Elastic::Model::Types::UID',
#===================================
    deflate_via {
    'do {'
        . 'die "Cannot deflate UID as it not saved\n"'
        . 'unless $val->from_store;'
        . '$val->read_params;' . '}';
    },

    inflate_via {
    'Elastic::Model::UID->new( from_store => 1, %$val  )';
    },

    map_via {
    my %props = map { $_ => { type => 'string', index => 'not_analyzed', } }
        qw(index type id routing);

    $props{routing}{index} = 'no';
    delete $props{routing}{index_name};

    return (
        type       => 'object',
        dynamic    => 'strict',
        properties => \%props,
        path       => 'full'
    );

    };

#===================================
has_type 'Elastic::Model::Types::Keyword',
#===================================
    map_via {
    type  => 'string',
    index => 'not_analyzed'
    };

#===================================
has_type 'Elastic::Model::Types::GeoPoint',
#===================================
    deflate_via {'$val'},
    inflate_via {'$val'},
    map_via { type => 'geo_point' };

#===================================
has_type 'Elastic::Model::Types::Binary',
#===================================
    deflate_via {
    require MIME::Base64;
    'MIME::Base64::encode_base64( $val )';
    },

    inflate_via {
    'MIME::Base64::decode_base64( $val )';
    },

    map_via { type => 'binary' };

#===================================
has_type 'Elastic::Model::Types::Timestamp',
#===================================
    deflate_via {'int( $val * 1000 + 0.5 )'},
    inflate_via {'sprintf "%.3f", $val / 1000'},
    map_via { type => 'date' };

1;

# ABSTRACT: Type maps for ElasticSearch-specific types

__END__

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::TypeMap::ES - Type maps for ElasticSearch-specific types

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::TypeMap::ES> provides mapping, inflation and deflation
for Elasticsearch specific types.

=head1 TYPES

=head2 Elastic::Model::Types::Keyword

Attributes of type L<Elastic::Model::Types/Keyword> are in/deflated
via L<Elastic::Model::TypeMap::Moose/Any> and are mapped as:

    {
        type   => 'string',
        index  => 'not_analyzed'
    }

It is a suitable type to use for string attributes which should not
be analyzed, and will not be used for scoring. Rather they are suitable
to use as filters.

=head2 Elastic::Model::Types::UID

An L<Elastic::Model::UID> is deflated into a hash ref and reinflated
via L<Elastic::Model::UID/"new_from_store()">. It is mapped as:

    {
        type        => 'object',
        dynamic     => 'strict',
        path        => 'path',
        properties  => {
            index   => {
                type  => 'string',
                index => 'not_analyzed'
            },
            type => {
                type  => 'string',
                index => 'not_analyzed'
            },
            id   => {
                type  => 'string',
                index => 'not_analyzed'
            },
            routing   => {
                type  => 'string',
                index => 'no'
            },
        }
    }

=head2 Elastic::Model::Types::GeoPoint

Attributes of type L<Elastic::Model::Types/"GeoPoint"> are mapped as
C<< { type => 'geo_point' } >>.

=head2 Elastic::Model::Types::Binary

Attributes of type L<Elastic::Model::Types/"Binary"> are deflated via
L<MIME::Base64/"encode_base64"> and inflated via L<MIME::Base64/"decode_base_64">.
They are mapped as C<< { type => 'binary' } >>.

=head2 Elastic::Model::Types::Timestamp

Attributes of type L<Elastic::Model::Types/"Timestamp"> are deflated
to epoch milliseconds, and inflated to epoch seconds (with floating-point
milliseconds). It is mapped as C<< { type => 'date' } >>.

B<Note:> When querying timestamp fields in a View you will need to express the
comparison values as epoch milliseconds or as an RFC3339 datetime:

    { my_timestamp => { '>' => 1351748867 * 1000      }}
    { my_timestamp => { '>' => '2012-11-01T00:00:00Z' }}

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
