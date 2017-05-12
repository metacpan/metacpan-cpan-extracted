package Elastic::Model::TypeMap::Structured;
$Elastic::Model::TypeMap::Structured::VERSION = '0.52';
use strict;
use warnings;

use Elastic::Model::TypeMap::Base qw(:all);
use namespace::autoclean;

#===================================
has_type 'MooseX::Meta::TypeConstraint::Structured',
#===================================
    deflate_via { _structured( 'deflator', @_ ) },
    inflate_via { _structured( 'inflator', @_ ) },
    map_via { _structured( 'mapper', @_ ) };

#===================================
has_type 'MooseX::Types::Structured::Optional',
#===================================
    deflate_via { _content_handler( 'deflator', @_ ) },
    inflate_via { _content_handler( 'inflator', @_ ) },
    map_via { _content_handler( 'mapper', @_ ) };

#===================================
has_type 'MooseX::Types::Structured::Tuple',
#===================================
    deflate_via { _deflate_tuple(@_) },    #
    inflate_via { _inflate_tuple(@_) },    #
    map_via { _map_dict( _tuple_to_dict(shift), @_ ) };

#===================================
has_type 'MooseX::Types::Structured::Dict',
#===================================
    deflate_via {
    _flate_dict( 'deflator', { @{ shift->type_constraints || [] } }, @_ );
    },

    inflate_via {
    _flate_dict( 'inflator', { @{ shift->type_constraints || [] } }, @_ );
    },

    map_via {
    _map_dict( { @{ shift->type_constraints || [] } }, @_ );
    };

#===================================
has_type 'MooseX::Types::Structured::Map',
#===================================
    deflate_via { _flate_map( 'deflator', @_ ) },
    inflate_via { _flate_map( 'inflator', @_ ) },
    map_via { type => 'object', enabled => 0 };

#===================================
sub _deflate_tuple {
#===================================
    my $dict = _tuple_to_dict(shift);
    return '$val' unless %$dict;

    my $deflator = _flate_dict( 'deflator', $dict, @_ );

    return sub {
        my $array = shift;
        my %hash;
        @hash{ 0 .. $#{$array} } = @$array;
        $deflator->( \%hash );
    };
}

#===================================
sub _inflate_tuple {
#===================================
    my $dict = _tuple_to_dict(shift);
    return '$val' unless %$dict;
    my $inflator = _flate_dict( 'inflator', $dict, @_ );
    sub {
        my $hash = $inflator->(@_);
        [ @{$hash}{ 0 .. keys(%$hash) - 1 } ];
    };
}

#===================================
sub _tuple_to_dict {
#===================================
    my $i = 0;
    return { map { $i++ => $_ } @{ shift->type_constraints || [] } };
}

#===================================
sub _flate_dict {
#===================================
    my ( $type, $dict, $attr, $map ) = @_;

    return '$val' unless %$dict;

    my %flators;

    for my $key ( keys %$dict ) {
        my $flator = $map->find( $type, $dict->{$key}, $attr )
            || die "No $type found for key ($key)";

        $flators{$key}
            = ref $flator
            ? $flator
            : Eval::Closure::eval_closure(
            source => [ 'sub { my $val = $_[0];', $flator, '}' ] );
    }

    sub {
        my $hash = shift;
        +{  map { $_ => $flators{$_}->( $hash->{$_} ) }
            grep { exists $flators{$_} } keys %$hash
        };
    };
}

#===================================
sub _map_dict {
#===================================
    my ( $tcs, $attr, $map ) = @_;

    return ( type => 'object', enabled => 0 )
        unless %$tcs;

    my %properties;
    for ( keys %$tcs ) {
        my %key_mapping = $map->find( 'mapper', $tcs->{$_}, $attr );
        die "Couldn't find mapping for key $_"
            unless %key_mapping;
        $properties{$_} = \%key_mapping;
    }
    return (
        type       => 'object',
        dynamic    => 'strict',
        properties => \%properties
    );
}

#===================================
sub _flate_map {
#===================================
    my ( $type, $tc, $attr, $map ) = @_;

    my $tcs = $tc->type_constraints || [];
    my $content_tc = $tcs->[1]
        or return \&_pass_through;

    my $content = $map->find( $type, $content_tc, $attr ) or return;

    return sub {
        my $hash = shift;
        +{ map { $_ => $content->( $hash->{$_} ) } keys %$hash };
        }
        if ref $content;

    'do { '
        . 'my $hash = $val; '
        . '+{map { '
        . 'my $key = $_; my $val = $hash->{$_}; '
        . '$key => '
        . $content
        . '} keys %$hash}}';

}

#===================================
sub _structured {
#===================================
    my ( $type, $tc, $attr, $map ) = @_;
    my $types  = $type . 's';
    my $parent = $tc->parent;
    if ( my $handler = $map->$types->{ $parent->name } ) {
        return $handler->( $tc, $attr, $map );
    }
    $map->find( $type, $parent, $attr );
}

#===================================
sub _content_handler {
#===================================
    my ( $type, $tc, $attr, $map ) = @_;
    return $tc->can('type_parameter')
        ? $map->find( $type, $tc->type_parameter, $attr )
        : $type eq 'mapper' ? ( type => 'object', enabled => 0 )
        :                     '$val';
}

#===================================
sub _pass_through { $_[0] }
#===================================

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::TypeMap::Structured - Type maps for MooseX::Types::Structured

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::TypeMap::Structured> provides mapping, inflation and deflation
for the L<MooseX::Types::Structured> type constraints.
It is loaded automatically byL<Elastic::Model::TypeMap::Default>.

=head1 TYPES

=head2 Optional

Optional values are mapped, inflated and deflated according to their
content type, eg C<Optional[Int]>. An C<Optional> type with no
content type is mapped as C<<{ type => 'object', enabled => 'no' }>>
and the value would be passed through unaltered when deflating/inflating.

=head2 Tuple

Because array refs are interpreted by Elasticsearch as multiple values
of the same type, tuples are converted to hash refs whose keys are
the index number.  For instance, a field C<foo> with C<Tuple[Int,Str]>
and value C<[5,'foo']> will be deflated to C<< { 0 => 5, 1 => 'foo' } >>.

A tuple is mapped as an object, with:

    {
        type       => 'object',
        dynamic    => 'strict',
        properties => \%properties
    }

The C<%properties> mapping depends on the content types. A C<Tuple> without
content types is mapped as C<<{ type => 'object', enabled => 'no' }>>
and the value would be passed through unaltered when deflating/inflating.

=head2 Dict

A C<Dict> is mapped as an object, with:

    {
        type       => 'object',
        dynamic    => 'strict',
        properties => \%properties
    }

The C<%properties> mapping depends on the content types. A C<Dict> without
content types is mapped as C<<{ type => 'object', enabled => 'no' }>>
and the value would be passed through unaltered when deflating/inflating.

=head2 Map

It is not advisable to allow arbitrary key names in indexed hashes, as you
could end up generating many (and conflicting) field mappings.  For this reason,
Maps are mapped as C<< { type => 'object', enabled => 0 } >>. In/deflation
depends on the content type (eg C<Map[Str,Int>]). A C<Map> without a content type
would pass through the value unaltered when inflating/deflatin.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Type maps for MooseX::Types::Structured

