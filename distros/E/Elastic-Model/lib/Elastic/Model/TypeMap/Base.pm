package Elastic::Model::TypeMap::Base;
$Elastic::Model::TypeMap::Base::VERSION = '0.52';
use strict;
use warnings;

use Sub::Exporter qw(build_exporter);
use Class::MOP();
use Class::Load();
use List::MoreUtils qw(uniq);
use Moose::Util qw(does_role);
use Scalar::Util qw(blessed);
use Moose::Util::TypeConstraints qw(find_type_constraint);
use namespace::autoclean;

sub deflate_via (&) { deflator => $_[0] }
sub inflate_via (&) { inflator => $_[0] }
sub map_via (&)     { mapper   => $_[0] }

#===================================
sub import {
#===================================
    my ( $class, @args ) = @_;
    my $callee = caller;
    return if $callee->isa(__PACKAGE__) || @args == 0;

    {
        no strict 'refs';
        unshift @{ $callee . '::ISA' }, __PACKAGE__;
    }

    build_exporter(
        {   into    => $callee,
            exports => [
                qw(deflate_via inflate_via map_via),
                has_type => sub {
                    sub { $callee->_has_type(@_) }
                },
            ]
        }
    )->( $class, ':all' );

    for (@args) {
        next if /^[:-]/;
        Class::Load::load_class($_);
        $callee->import_types( $_->typemap );
    }
}

#===================================
sub find_deflator {
#===================================
    my ( $map, $attr ) = @_;
    my $deflator = $map->find_raw_deflator($attr);
    return $deflator if ref $deflator;
    Eval::Closure::eval_closure(
        source => [ 'sub { my $val = $_[0];', $deflator, '}' ] );
}

#===================================
sub find_raw_deflator {
#===================================
    my ( $map, $attr ) = @_;
    $attr->can('deflator') && $attr->deflator
        || eval { $map->find( 'deflator', $attr->type_constraint, $attr ) }
        || die _type_error( 'deflator', $attr, $@ );
}

#===================================
sub find_inflator {
#===================================
    my ( $map, $attr ) = @_;
    my $inflator = $map->find_raw_inflator($attr);
    return $inflator if ref $inflator;
    Eval::Closure::eval_closure(
        source => [ 'sub { my $val = $_[0];', $inflator, '}' ] );
}

#===================================
sub find_raw_inflator {
#===================================
    my ( $map, $attr ) = @_;
    $attr->can('inflator') && $attr->inflator
        || eval { $map->find( 'inflator', $attr->type_constraint, $attr ) }
        || die _type_error( 'inflator', $attr, $@ );
}

#===================================
sub find_mapper {
#===================================
    my ( $map, $attr ) = @_;
    my $mapping;
    $mapping = $attr->mapping if $attr->can('mapping');
    return %$mapping if $mapping && %$mapping;

    my %mapping;
    eval {
        my @mapping = $map->find( 'mapper', $attr->type_constraint, $attr );
        die "Expected an even number of elements "
            . "to be returned by the mapper.\n"
            if @mapping % 2;
        %mapping = @mapping;
    };

    die _type_error( 'mapper', $_[1], $@ )
        unless %mapping;

    return %mapping;
}

#===================================
sub _type_error {
#===================================
    my ( $type, $attr, $error ) = @_;
    my $name  = $attr->name;
    my $class = $attr->associated_class->name;
    return $error
        ? "Error finding $type for attribute ($name) in class $class:\n$error"
        : "No $type found for attribute ($name) in class $class";
}

#===================================
sub find {
#===================================
    my ( $map, $type, $tc, $attr ) = @_;

    $tc ||= find_type_constraint('Any');

    my $types    = $type . 's';
    my $handlers = $map->$types;
    my $name     = $tc->name;

    if ( my $handler = $handlers->{$name} || $handlers->{ ref $tc } ) {
        return $handler->( $tc, $attr, $map );
    }

    my $parent = $tc->can('parent') && $tc->parent or return;
    $map->find( $type, $parent, $attr );
}

#===================================
sub class_deflator {
#===================================
    my ( $map, $class, $attrs ) = @_;

    $attrs ||= $map->indexable_attrs($class);

    my %deflators = map { $_ => $map->find_raw_deflator( $attrs->{$_} ) }
        keys %$attrs;

    my @src = ( 'sub {', 'my $self = shift;', 'my (%hash,$attr,$val);',
        'eval {', );

    my %readers;
    for my $name ( sort keys %deflators ) {
        my $attr     = $attrs->{$name};
        my $deflator = $deflators{$name};
        if ( ref $deflator ) {
            $deflator = '$deflators{"' . $name . '"}->($val)';
        }
        my $is_lazy = $attr->is_lazy;
        my $get_raw = $attr->_inline_instance_get('$self');
        my $exists  = $attr->_inline_instance_has('$self');

        push @src, '$attr="' . $name . '";';
        if ($is_lazy) {
            $readers{$name} = $attr->get_read_method_ref;
            push @src, '$readers{"' . $name . '"}->($self);';
        }
        else {
            push @src, "if ($exists) {";
        }
        push @src, '$val = ' . $get_raw . ';',
            '$hash{"' . $name . '"} = ' . $deflator . ';';
        push @src, '}' unless $is_lazy;
    }

    push @src,
        (
        '1;} ',
        'or die "Error deflating attribute ($attr) in class ".',
        'Scalar::Util::blessed($self).',
        '":\n ".($@ || "Unknown error");',
        'return \%hash',
        '}'
        );

    Eval::Closure::eval_closure(
        source      => \@src,
        environment => {
            '%deflators' => \%deflators,
            '%readers'   => \%readers
        }
    );
}

#===================================
sub class_inflator {
#===================================
    my ( $map, $class, $attrs ) = @_;

    $attrs ||= $map->indexable_attrs($class);
    my %inflators = map { $_ => $map->find_raw_inflator( $attrs->{$_} ) }
        keys %$attrs;

    my @src = (
        'sub {',
        'my ($self,$hash) = @_;',
        'my ($attr,$val,$res);',
        'eval {'
    );
    for my $name ( sort keys %inflators ) {
        my $attr     = $attrs->{$name};
        my $inflator = $inflators{$name};
        my $set_raw  = $attr->_inline_instance_set( '$self', '$res' );
        if ( ref $inflator ) {
            $inflator = '$inflators{"' . $name . '"}->($val)';
        }
        push @src,
            (
            '$attr = "' . $name . '";',
            'if (exists $hash->{"' . $name . '"}) {',
            '$val = $hash->{"' . $name . '"};',
            '$res = ' . $inflator . ';',
            $set_raw . ';',
            $attr->_inline_weaken_value( '$self', '$res' ),
            '}'
            );
    }
    push @src,
        (
        '1}',
        'or die "Error inflating attribute ($attr) in class ".',
        'Scalar::Util::blessed($self).',
        '":\n ".($@ || "Unknown error");',
        'return $self',
        '}'
        );

    Eval::Closure::eval_closure(
        source      => \@src,
        environment => { '%inflators' => \%inflators, }
    );
}

our %Allowed_Attrs = (
    string => {
        'index_name'            => 1,
        'store'                 => 1,
        'index'                 => 1,
        'term_vector'           => 1,
        'boost'                 => 1,
        'null_value'            => 1,
        'analyzer'              => 1,
        'index_analyzer'        => 1,
        'search_analyzer'       => 1,
        'search_quote_analyzer' => 1,
        'include_in_all'        => 1,
        'multi'                 => 1,
    },
    integer => {
        'index_name'     => 1,
        'store'          => 1,
        'index'          => 1,
        'precision_step' => 1,
        'boost'          => 1,
        'null_value'     => 1,
        'include_in_all' => 1,
        'multi'          => 1,
    },
    date => {
        'index_name'     => 1,
        'format'         => 1,
        'store'          => 1,
        'index'          => 1,
        'precision_step' => 1,
        'boost'          => 1,
        'null_value'     => 1,
        'include_in_all' => 1,
        'multi'          => 1,
    },
    boolean => {
        'index_name'     => 1,
        'store'          => 1,
        'index'          => 1,
        'boost'          => 1,
        'null_value'     => 1,
        'include_in_all' => 1,
        'multi'          => 1,
    },
    binary => {
        'index_name' => 1,
        'store'      => 1
    },
    object => {
        'dynamic'        => 1,
        'enabled'        => 1,
        'path'           => 1,
        'include_in_all' => 1,
    },
    nested => {
        'include_in_parent' => 1,
        'include_in_root'   => 1,
        'include_in_all'    => 1,
        'dynamic'           => 1,
        'path'              => 1,
    },
    ip => {
        'index_name'     => 1,
        'store'          => 1,
        'index'          => 1,
        'precision_step' => 1,
        'boost'          => 1,
        'null_value'     => 1,
        'include_in_all' => 1,
        'multi'          => 1,
    },
    geo_point => {
        'lat_lon'           => 1,
        'geohash'           => 1,
        'geohash_precision' => 1,
        'index_name'        => 1,
        'store'             => 1,
        'multi'             => 1,
    },

    # TODO:   attachment => {}
);

our @All_Keys = uniq map { keys %$_ } values %Allowed_Attrs;

$Allowed_Attrs{$_} = $Allowed_Attrs{integer}
    for qw(long float double short byte);

#===================================
sub class_mapping {
#===================================
    my ( $map, $class, $attrs ) = @_;

    $attrs ||= $map->indexable_attrs($class);

    my %props = map { $_ => $map->attribute_mapping( $attrs->{$_} ) }
        keys %$attrs;

    return ( type => 'object', enabled => 0 )
        unless %props;

    return (
        type       => 'object',
        dynamic    => 'strict',
        properties => \%props
    );
}

#===================================
sub attribute_mapping {
#===================================
    my ( $map, $attr ) = @_;

    my $mapping = $attr->can('mapping') && $attr->mapping
        || { $map->find_mapper($attr) };

    my $type = $mapping->{type} || '';
    if ( $attr->can('type') ) {
        my $new_type = $attr->type;
        if ( $new_type and $new_type ne $type ) {
            delete $mapping->{enabled}
                if $type eq 'object';
            $mapping->{type} = $type = $new_type;
        }
    }

    die "Missing field type" unless $type;

    my $allowed = $Allowed_Attrs{$type} or die "Unknown field type ($type)";

    return $mapping unless does_role( $attr, 'Elastic::Model::Trait::Field' );

    for my $key (@All_Keys) {
        my $val = $attr->$key;
        next unless defined $val;
        die "Attribute has type '$type', which doesn't "
            . "understand '$key'\n"
            unless $allowed->{$key};
        $mapping->{$key} = $val;
    }

    $mapping = $map->_fixup_mapping($mapping);

    my $multi = delete $mapping->{multi}
        or return $mapping;

    my $main = $attr->name;
    my %new = ( type => 'multi_field', fields => { $main => $mapping } );
    for my $name ( keys %$multi ) {
        die "Multi-field name '$name' clashes with the attribute name\n"
            if $name eq $main;
        my $defn = $multi->{$name};
        my $multi_type = $defn->{type} ||= $type;

        $allowed = $Allowed_Attrs{$multi_type}
            or die "Uknown field type ($type)";

        for my $key ( keys %$defn ) {
            die "Attribute has type '$multi_type', which doesn't "
                . "understand '$key'\n"
                unless $allowed->{$key} || $key eq 'type';
        }

        $new{fields}{$name} = $map->_fixup_mapping($defn);
    }
    return \%new;
}

#===================================
sub _fixup_mapping {
#===================================
    my ( $map, $defn ) = @_;

    delete $defn->{analyzer}
        if $defn->{index_analyzer} && $defn->{search_analyzer};

    return $defn;
}

#===================================
sub deflators { shift->typemap->{deflator} }
sub inflators { shift->typemap->{inflator} }
sub mappers   { shift->typemap->{mapper} }
#===================================

#===================================
sub _has_type {
#===================================
    my ( $class, $type, %params ) = @_;
    my $map = $class->typemap();
    for ( keys %params ) {
        $map->{$_}{$type} = $params{$_};
    }
}

#===================================
sub indexable_attrs {
#===================================
    my $map   = shift;
    my $class = shift;
    $class = $map->model->class_for($class) || $class;

    my $meta = Class::MOP::class_of($class);

    return {
        map { $_->name => $_ }
            grep { !( $_->can('exclude') && $_->exclude ) }
            $meta->get_all_attributes
    };
}

#===================================
sub typemap {
#===================================
    my $class = shift;
    $class = $class->original_class
        if $class->can('original_class');

    # return a reference to the storage in ourself
    {
        no strict 'refs';
        return \%{ $class . '::__ES_TYPE_MAP' };
    }
}

#===================================
sub import_types {
#===================================
    my $class  = shift;
    my $import = shift;
    my $map    = $class->typemap;
    for (qw(deflator inflator mapper)) {
        my $types = $import->{$_} or next;
        @{ $map->{$_} }{ keys %$types } = values %$types;
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::TypeMap::Base - A base class for all TypeMaps

=head1 VERSION

version 0.52

=head1 SYNOPSIS

=head2 Define your own type map

    package MyApp::TypeMap;

    use Elastic::Model::TypeMap::Base qw(
        Elastic::Model::TypeMap::Default
    );

    has_type 'MyCustomType',
        deflate_via { sub { ... }},
        inflate_via { sub { ... }},
        map_via     { type => 'string' };

    # Inlined in/deflation
    has_type 'MyCustomType',
        deflate_via { '$val * 1000'},
        inflate_via { '$val / 1000'},
        map_via     { type => 'string' };

=head2 Use your type map by declaring it in your Model

    package MyApp;

    use Elastic::Model;

    has_namespace 'myapp', {
        user => 'MyApp::User',
        post => 'MyApp::Post'
    };

    has_typemap 'MyApp::TypeMap';

=head1 DESCRIPTION

Moose's L<type constraints|Moose::Util::TypeConstraints> and introspection
allows Elastic::Model to figure out how to map your data model to the
Elasticsearch backend with the minimum of effort on your part.

What YOU need to do is: B<Be specific about the type constraint for each attribute.>

For instance,  if you have an attribute called C<count>, then specify the
type constraint C<< isa => 'Int' >>.
That way, we know how to define the field in Elasticsearch, and how to deflate
and inflate the value.

Type constraints can inherit their mapping, inflator and deflator from
their parent type-constraints.  For instance, if you were to assign
C<count> the type constraint C<PositiveInt>, although we don't know about that
constraint, we do know about its parent, C<Int>, so we could
still handle the field correctly.

Type maps are used to define:

=over

=item *

what mapping Elastic::Model will generate for each attribute when you
L<create an index|Elastic::Model::Domain::Admin/"create_index()">
or L<update the mapping|Elastic::Model::Domain::Admin/"update_mapping()"> of an
existing index.

=item *

how Elastic::Model will deflate and inflate each attribute when saving or
retrieving docs stored in Elasticsearch.

=back

=head1 BUILT-IN TYPE MAPS

See L<Elastic::Model::TypeMap::Default> for the type-maps provided by
default in Elastic::Model.

=head1 DEFINING YOUR OWN TYPE MAP

If you define your own types which need custom mapping or custom deflators/inflators
then you can add these definitions in your own type-map, while still falling
back to the built-in type-maps for other types.

First, you need to name your type map class:

    package MyApp::TypeMap;

Then import the helper functions from L<Elastic::Model::TypeMap::Base>
and load any other typemaps that you want to inherit from:

    use Elastic::Model::TypeMap::Base qw(
        Elastic::Model::TypeMap::Default
        Useful::TypeMap::From::CPAN
    );

Now you can define your type maps:

    has_type 'MyCustomType',
        deflate_via { sub { ... }},
        inflate_via { sub { ... }},
        map_via     { type => 'string' };

The type name passed to C<has_type> should be a string, eg C<'Str'> for the
core Moose string type, or the fully qualified name for the types you have
defined with L<MooseX::Types>, eg C<'MyApp::Types::SomeType'>.

C<deflate_via> and C<inflate_via> each expect a coderef which, when called
returns a coderef:

    sub {
        my ($type_constraint, $attr, $typemap_class) = @_;
        return sub {
            my ($val) = @_;
            return do_something($val)
        }
    }

Alternatively, the C<deflate_via> and C<inflate_via> coderefs can, when
executed, return a string of Perl code which can be inlined for more
efficient flation.  Both the inflator and deflator are passed the value
that needs to be converted in C<$val>. For instance:

    has_type 'MyDateType',
        deflate_via { '$val->to_string'            },
        inflate_via { 'My::Date::Class->new($val)' },
        map_via     { 'type' => 'date'             };

C<map_via> expects a coderef which returns the mapping for that type as a list,
not as a hashref:

    sub {
        my ($type_constraint, $attr, $typemap_class) = @_;
        return (type => 'string', ..... );
    }

=head2 A simple example

Here is an example of how to define a type map for DateTime objects:

    use DateTime;

    has_type 'DateTime',

    deflate_via {
        sub { $_[0]->set_time_zone('UTC')->iso8601 };
    },

    inflate_via {
        sub {
            my %args;
            @args{ (qw(year month day hour minute second)) } = split /\D/, shift;
            DateTime->new(%args);
        };
    },

    map_via { type => 'date' };

=head2 An inlined example:

    use DateTime;

    has_type 'DateTime',

    deflate_via { '$val->set_time_zone("UTC")->iso8601' },
    inflate_via {
         'do {'
       . '  my %args;'
       . '  @args{ (qw(year month day hour minute second)) } = split /\D/, $val;'
       . '  DateTime->new(%args);'
       . '}'
    },

    map_via { type => 'date' };

=head1 ATTRIBUTES

It is unlikely that you will need to know about any of these attributes, but
they are documented here for completeness.

=head2 deflators

    $deflators = $class->deflators

Returns a hashref of all deflators known to C<$class>.

=head2 inflators

    $inflators = $class->inflators

Returns a hashref of all inflators known to C<$class>.

=head2 mappers

    $mappers = $class->mappers

Returns a hashref of all mappers known to C<$class>.

=head2 typemap

    $map = $class->typemap

Returns a hashref containing the L</"deflators">, L</"inflators"> and
L</"mappers"> known to C<$class>.

=head1 METHODS

It is unlikely that you will need to know about any of these methods, but
they are documented here for completeness.

L<Elastic::Model::TypeMap::Base> only has class methods, no instance methods,
and no C<new()>.

=head2 find_deflator()

    $deflator = $class->find_deflator($attr)

Returns a coderef which knows how to deflate C<$attr>, or throws an exception.
Any inlined deflators are eval'ed into an anonymous sub.

=head2 find_raw_deflator()

    $deflator = $class->find_deflator($attr)

Returns a coderef which knows how to deflate C<$attr>, or throws an exception.
Any inlined deflators are returned as strings.

=head2 find_inflator()

    $inflator = $class->find_inflator($attr)

Returns a coderef which knows how to inflate C<$attr>, or throws an exception.
Any inlined inflators are eval'ed into an anonymous sub.

=head2 find_raw_inflator()

    $inflator = $class->find_inflator($attr)

Returns a coderef which knows how to inflate C<$attr>, or throws an exception.
Any inlined inflators are returned as strings.

=head2 find_mapper()

    $mapping = $class->find_mapper($attr)

Returns a mapping for C<$attr>, or throws an exception.

=head2 find()

    $result = $class->find($thing, $type_constraint, $attr);

Finds a C<$thing> (C<deflator>, C<inflator>, C<mapper>) or returns C<undef>.

=head2 class_deflator()

    $deflator = $class->class_deflator( $class_to_deflate, $attrs );

Returns a coderef which knows how to deflate an object of class
C<$class_to_deflate>, including the attributes listed in C<$attr> (or all
attributes if not specified).

=head2 class_inflator()

    $inflator = $class->class_inflator( $class_to_inflate, $attrs );

Returns a coderef which knows how to inflate deflated data for class
C<$class_to_inflate>, including the attributes listed in C<$attr> (or all
attributes if not specified).

=head2 class_mapping()

    $mapping = $class->class_mapping( $class_to_map, $attrs );

Returns a hashref of the mapping for class C<$class_to_map>,
including the attributes listed in C<$attr> (or all attributes if not specified).

=head2 attribute_mapping()

    $mapping = $class->attribute_mapping($attr);

Returns a hashref of the mapping for attribute C<$attr>.

=head2 indexable_attrs()

    $attrs = $class->indexable_attrs($some_class);

Returns an array ref all all attributes in C<$some_class> which don't
have C<exclude> set to true.

=head2 import_types()

    $class->import_types($other_class);

Imports the deflators, inflators and mappers from another typemap class into
the current class.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A base class for all TypeMaps

