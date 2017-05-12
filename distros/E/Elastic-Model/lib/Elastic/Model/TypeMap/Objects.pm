package Elastic::Model::TypeMap::Objects;
$Elastic::Model::TypeMap::Objects::VERSION = '0.52';
use strict;
use warnings;
use Elastic::Model::TypeMap::Base qw(:all);
use Scalar::Util qw(reftype weaken);
use Moose::Util qw(does_role);
use namespace::autoclean;

#===================================
has_type 'Moose::Meta::TypeConstraint::Class',
#===================================
    deflate_via { _deflate_class(@_) },
    inflate_via { _inflate_class(@_) },
    map_via { _map_class(@_) };

# TODO: Moose role

#===================================
has_type 'Moose::Meta::TypeConstraint::Role',
#===================================
    deflate_via {undef}, inflate_via {undef};

#===================================
has_type 'Object',
#===================================
    deflate_via {
    sub {
        my $obj = shift;
        my $ref = ref $obj;

        die "$ref does not provide a deflate() method"
            unless $obj->can('deflate');
        return { $ref => $obj->deflate };
    };
    },

    inflate_via {
    sub {
        my ( $class, $data ) = %{ shift() };
        my $inflated = $class->inflate($data);
        return bless $inflated, $class;
        }
    },

    map_via { type => 'object', enabled => 0 };

#===================================
sub _deflate_class {
#===================================
    my ( $tc, $attr, $map ) = @_;

    my $class = $tc->name;
    my $attrs = _class_attrs( $map, $class, $attr )
        or return;

    return $map->class_deflator( $class, $attrs );
}

#===================================
sub _inflate_class {
#===================================
    my ( $tc, $attr, $map ) = @_;

    my $class = $tc->name;
    if ( $map->model->knows_class($class) ) {
        my $model = $map->model;
        weaken $model;
        return sub {
            my $hash = shift;
            die "Missing UID\n" unless $hash->{uid};
            my $uid = Elastic::Model::UID->new( %{ $hash->{uid} },
                from_store => 1 );
            return $model->get_doc( uid => $uid );
        };
    }

    my $attrs = _class_attrs( $map, $class, $attr )
        or return;

    my $attr_inflator = $map->class_inflator( $class, $attrs );

    return sub {
        my $hash = shift;
        my $obj  = Class::MOP::class_of($class)
            ->get_meta_instance->create_instance;
        $attr_inflator->( $obj, $hash );
    };
}

#===================================
sub _map_class {
#===================================
    my ( $tc, $attr, $map ) = @_;

    return ( type => 'object', enabled => 0 )
        if $attr->can('has_enabled')
        && $attr->has_enabled
        && !$attr->enabled;

    my $class = $tc->name;
    my $attrs = _class_attrs( $map, $class, $attr )
        or return;

    return $map->class_mapping( $class, $attrs );
}

#===================================
sub _class_attrs {
#===================================
    my ( $map, $class, $attr ) = @_;

    $class = $map->model->class_for($class) || $class;

    my $meta = Class::MOP::class_of($class);
    return unless $meta && $meta->isa('Moose::Meta::Class');

    my %attrs;

    my $inc = $attr->can('include_attrs') && $attr->include_attrs;
    my $exc = $attr->can('exclude_attrs') && $attr->exclude_attrs;

    my @inc_attr = $inc
        ? map {
        $meta->find_attribute_by_name($_)
            or die "Unknown attribute ($_) in class $class"
        } @$inc
        : $meta->get_all_attributes;

    %attrs = map { $_->name => $_ }
        grep { !( $_->can('exclude') && $_->exclude ) } @inc_attr;

    # TODO: does it ever make sense to remove the UID field?
    if ( my $uid = $meta->find_attribute_by_name('uid') ) {
        $attrs{uid} = $uid;
    }

    delete @attrs{@$exc} if $exc;

    return \%attrs;
}

1;

# ABSTRACT: Type maps for objects and Moose classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::TypeMap::Objects - Type maps for objects and Moose classes

=head1 VERSION

version 0.52

=head1 DESCRIPTION

L<Elastic::Model::TypeMap::Objects> provides mapping, inflation and deflation
for Moose-based classes and objects.
It is loaded automatically by L<Elastic::Model::TypeMap::Default>.

=head1 TYPES

=head2 Moose classes

    has 'bar' => (
        is  => 'rw,
        isa => 'Bar'
    );

If C<Bar> is a Moose class, then its attributes will be introspected and
the mapping will look like:

    {
        type        => 'object',
        dynamic     => 'strict',
        properties  => {
            ... mapping for Bar's attributes...
        }
    }

By default, all attributes are included. You can control the attribute list
with:

    has 'bar' => (
        is              => 'rw,
        isa             => 'Bar',
        include_attrs   => [],              # no attributes
      | include_attrs   => ['foo','bar']    # just 'foo' and 'bar'
      | exclude_attrs   => ['foo','bar']    # all except 'foo' and 'bar'
    );

You can control the mapping for individual attributes in Moose classes with
the L<Elastic::Model::Trait::Field> trait:

    package Bar;

    use Moose;

    has 'foo' => (
        is              => 'rw,
        isa             => 'Str',
        trait           => ['Elastic::Model::Trait::Field']
    );

=head2 Elastic::Doc classes

Elastic::Doc classes work in exactly the same way as other Moose classes except

=over

=item *

You don't need to specify the L<Elastic::Model::Trait::Field> trait - it is
added automatically.

=item *

The L<UID|Elastic::Model::UID> field is always included, unless you specifically
list it in C<exclude_attrs>.

=back

By default, all the attributes of an Elastic::Doc class will be included.
For instance, if we have two classes: C<User> and C<Post>, and the C<Post> class
has a C<user> attribute.  Because all the attributes of the C<$user> are
also indexed in the C<$post> object, you can search for C<Posts>
which have been written by a C<User> whose name is C<"john">.

This also means that if a C<User> updates their name, then you need
to reindex all of their C<Posts>.

If you don't want to include any attributes, then you can just specify:
C<< include_attrs => [] >>.  The L<UID|Elastic::Model::UID> will still be indexed,
meaning that you can still do:

    $user_name = $post->user->name;

=head2 Moose Roles and non-Moose classes

Moose roles and non-Moose classes must provide
L<custom mappings, deflators and inflators|Elastic::Manual::Attributes/CUSTOM MAPPING, INFLATION AND DEFLATION>

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
