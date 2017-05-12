package Elastic::Model::Trait::Field;
$Elastic::Model::Trait::Field::VERSION = '0.52';
use Moose::Role;
Moose::Util::meta_attribute_alias('ElasticField');

use MooseX::Types::Moose qw(
    Str HashRef ArrayRef Bool Num Int CodeRef
);
use Elastic::Model::Types qw(
    FieldType IndexMapping TermVectorMapping MultiFields
    StoreMapping DynamicMapping PathMapping
);
use Carp;

use namespace::autoclean;

#===================================
has 'type' => (
#===================================
    isa       => FieldType,
    is        => 'rw',
    predicate => 'has_type'
);

#===================================
has 'mapping' => (
#===================================
    isa => HashRef,
    is  => 'rw'
);

#===================================
has 'exclude' => (
#===================================
    isa => Bool,
    is  => 'rw'
);

#===================================
has 'include_in_all' => (
#===================================
    isa => Bool,
    is  => 'rw'
);

#===================================
has 'index' => (
#===================================
    isa => IndexMapping,
    is  => 'rw'
);

#===================================
has 'store' => (
#===================================
    isa    => StoreMapping,
    is     => 'rw',
    coerce => 1
);

#===================================
has 'multi' => (
#===================================
    isa => MultiFields,
    is  => 'rw'
);

#===================================
has 'index_name' => (
#===================================
    isa => Str,
    is  => 'rw'
);

#===================================
has 'boost' => (
#===================================
    isa => Num,
    is  => 'rw'
);

#===================================
has 'null_value' => (
#===================================
    isa => Str,
    is  => 'rw'
);

#===================================
has 'unique_key' => (
#===================================
    isa => Str,
    is  => 'rw'
);

# strings

#===================================
has 'analyzer' => (
#===================================
    isa => Str,
    is  => 'rw'
);

#===================================
has 'index_analyzer' => (
#===================================
    isa => Str,
    is  => 'rw'
);

#===================================
has 'search_analyzer' => (
#===================================
    isa => Str,
    is  => 'rw'
);

#===================================
has 'search_quote_analyzer' => (
#===================================
    isa => Str,
    is  => 'rw'
);

#===================================
has 'term_vector' => (
#===================================
    isa => TermVectorMapping,
    is  => 'rw'
);

# dates

#===================================
has 'format' => (
#===================================
    isa => Str,
    is  => 'rw'
);

#===================================
has 'precision_step' => (
#===================================
    isa => Int,
    is  => 'rw'
);

# geo-point

#===================================
has 'geohash' => (
#===================================
    isa => Bool,
    is  => 'rw'
);

#===================================
has 'lat_lon' => (
#===================================
    isa => Bool,
    is  => 'rw'
);

#===================================
has 'geohash_precision' => (
#===================================
    isa => Int,
    is  => 'rw'
);

# object

#===================================
has 'enabled' => (
#===================================
    isa       => Bool,
    is        => 'rw',
    predicate => 'has_enabled'
);

#===================================
has 'dynamic' => (
#===================================
    isa => DynamicMapping,
    is  => 'rw'
);

#===================================
has 'path' => (
#===================================
    isa => PathMapping,
    is  => 'rw'
);

# nested

#===================================
has 'include_in_parent' => (
#===================================
    isa => Bool,
    is  => 'rw'
);

#===================================
has 'include_in_root' => (
#===================================
    isa => Bool,
    is  => 'rw'
);

# deflation

#===================================
has 'deflator' => (
#===================================
    isa => CodeRef,
    is  => 'rw'
);

#===================================
has 'inflator' => (
#===================================
    isa => CodeRef,
    is  => 'rw'
);

# esdocs

#===================================
has 'include_attrs' => (
#===================================
    isa => ArrayRef [Str],
    is => 'rw'
);

#===================================
has 'exclude_attrs' => (
#===================================
    isa => ArrayRef [Str],
    is => 'rw'
);

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Trait::Field - Add Elasticsearch specific keywords to your attribute definitions.

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::Trait::Field> is automatically applied to all of your
attributes when you include C<use Elastic::Doc;> at the top of your doc
classes. This trait adds keywords to allow you to configure how each attribute
is indexed in Elasticsearch.

It also wraps all attribute accessors to ensure that Elastic::Doc objects
are properly inflated before any attribute is accessed.

See L<Elastic::Manual::Attributes> for an explanation of how to use these
keywords.

=head1 ATTRIBUTES

=head2 L<type|Elastic::Manual::Attributes/type>

=head2 L<mapping|Elastic::Manual::Attributes/mapping>

=head2 L<exclude|Elastic::Manual::Attributes/exclude>

=head2 L<include_in_all|Elastic::Manual::Attributes/include_in_all>

=head2 L<index|Elastic::Manual::Attributes/index>

=head2 L<store|Elastic::Manual::Attributes/store>

=head2 L<multi|Elastic::Manual::Attributes/multi>

=head2 L<index_name|Elastic::Manual::Attributes/index_name> [DEPRECATED]

=head2 L<boost|Elastic::Manual::Attributes/boost> [DEPRECATED]

=head2 L<null_value|Elastic::Manual::Attributes/null_value>

=head2 L<analyzer|Elastic::Manual::Attributes/analyzer>

=head2 L<index_analyzer|Elastic::Manual::Attributes/index_analyzer>

=head2 L<search_analyzer|Elastic::Manual::Attributes/search_analyzer>

=head2 L<search_quote_analyzer|Elastic::Manual::Attributes/search_quote_analyzer>

=head2 L<term_vector|Elastic::Manual::Attributes/term_vector>

=head2 L<format|Elastic::Manual::Attributes/format>

=head2 L<geohash|Elastic::Manual::Attributes/geohash>

=head2 L<lat_lon|Elastic::Manual::Attributes/lat_lon>

=head2 L<geohash_precision|Elastic::Manual::Attributes/geohash_precision>

=head2 L<enabled|Elastic::Manual::Attributes/enabled>

=head2 L<dynamic|Elastic::Manual::Attributes/dynamic>

=head2 L<path|Elastic::Manual::Attributes/path> [DEPRECATED]

=head2 L<include_in_parent|Elastic::Manual::Attributes/include_in_parent>

=head2 L<include_in_root|Elastic::Manual::Attributes/include_in_root>

=head2 L<deflator|Elastic::Manual::Attributes/deflator>

=head2 L<inflator|Elastic::Manual::Attributes/inflator>

=head2 L<include_attrs|Elastic::Manual::Attributes/include_attrs>

=head2 L<exclude_attrs|Elastic::Manual::Attributes/exclude_attrs>

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Add Elasticsearch specific keywords to your attribute definitions.

