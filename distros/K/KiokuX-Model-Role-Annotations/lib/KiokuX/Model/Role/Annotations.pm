package KiokuX::Model::Role::Annotations;
use MooseX::Role::Parameterized;

use Carp;
use KiokuDB::Util qw(set);

use namespace::clean;

our $VERSION = "0.01";

parameter namespace => (
    isa => "Str",
    is  => "ro",
    default => "annotations",
);

parameter method_namespace => (
    isa => "Str",
    is  => "ro",
    lazy => 1,
    default => sub { shift->namespace },
);

parameter key_callback => (
    isa => "Str|CodeRef",
    is  => "ro",
    lazy => 1,
    default => sub {
        my $self = shift;

        my $name = $self->method_namespace;
        
        return sprintf "_${name}_set_id";
    },
);

parameter id_callback => (
    isa => "Str|CodeRef",
    is  => "ro",
    default => "object_to_id",
);

role {
    with qw(KiokuDB::Role::API);

    my $p = shift;

    my $name         = $p->method_namespace;
    my $ns           = $p->namespace;
    my $set_id       = $p->key_callback;
    my $object_to_id = $p->id_callback;

    requires $set_id unless ref $set_id or $set_id eq "_${name}_set_id";

    requires $object_to_id unless ref $object_to_id;

    my $annotation_set = sub {
        my ( $self, $key ) = @_;

        $self->lookup( $self->$set_id($key) );
    };

    method "has_${name}" => sub {
        my ( $self, @args ) = @_;

        $self->exists( $self->$set_id(@args) );
    };

    method "${name}_for" => sub {
        my ( $self, $key ) = @_;

        if ( my $set = $self->$annotation_set($key) ) {
            return $set->members;
        } else {
            return ();
        }
    };

    my $insert_into_set = sub {
        my ( $self, $key, @annotations ) = @_;

        if ( my $set = $self->$annotation_set($key) ) {
            $set->insert(@annotations);
            $self->insert_nonroot(@annotations);
            $self->update($set);
        } else {
            $self->insert( $self->$set_id($key) => set(@annotations) );
        }
    };

    method "add_${name}_for" => sub {
        my ( $self, $key, @annotations ) = @_;

        $self->txn_do(sub {
            $self->$insert_into_set( $key, @annotations );
        });
    };

    method "add_${name}" => sub {
        my ( $self, @annotations ) = @_;

        $self->txn_do(sub {
            foreach my $annotation ( @annotations ) {
                $self->$insert_into_set( $annotation->subject, $annotation );
            }
        });
    };

    my $remove_from_set = sub {
        my ( $self, $key, @annotations ) = @_;

        if ( my $set = $self->$annotation_set($key) ) {
            $set->remove(@annotations);

            if ( $set->size ) {
                $self->update($set);
            } else {
                $self->delete($set);
            }
        }

        $self->delete(@annotations);
    };

    method "remove_${name}_for" => sub {
        my ( $self, $key, @annotations ) = @_;

        $self->txn_do(sub {
            $self->$remove_from_set( $key, @annotations );
        });
    };

    method "remove_${name}" => sub {
        my ( $self, @annotations ) = @_;

        $self->txn_do(sub {
            foreach my $annotation ( @annotations ) {
                $self->$remove_from_set( $annotation->subject, $annotation );
            }
        });
    };

    method "_${name}_set_id" => sub {
        my ( $self, $item ) = @_;

        my $id = ref($item) ? $self->$object_to_id($item) : $item;

        croak "Can't determine ID for $item" unless defined $id;

        return "${ns}:${id}";
    };
};

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuX::Model::Role::Annotations - A role for adding annotations to objects in a KiokuDB database.

=head1 SYNOPSIS

    package MyApp::Model;
    use Moose;

    extends qw(KiokuX::Model);

    with qw(KiokuX::Model::Role::Annotations);

    

    # any object can be an annotation for another object
    $model->add_annotations_for( $obj => $annotation );

    # no need to specify the annotated object if the annotation does
    # KiokuX::Model::Role::Annotations::Annotation
    $model->add_annotations($annotation_object);


    # get annotations
    my @annotations = $model->annoations_for($obj);

=head1 DESCRIPTION

This role provides a mechanism to annotate objects with other objects.

=head1 METHODS

=over 4

=item add_annotations @annotations

=item add_annotations_for $obj, @annotations

Add annotations for an object.

The first form requires the annotation objects to do the role
L<KiokuX::Model::Role::Annotations::Annotation>.

The second form has no restrictions on the annotation objects, but requires the
key object to be specified explicitly.

=item remove_annoations @annotations

=item remove_annotations_for $obj, @annotations

Remove the specified annotations.

=item has_annotations $obj

Returns true if the object has been annotated.

=item annotations_for $obj

Returns a list of all annotations for the object.

=head1 PARAMETERIZED USAGE

The role is actually parameterizable.

=over 4

=item namespace

Defaults to C<annotations>. This string is prepended to the annotated object's
ID and used as the key for the annotation set for that object.

=item method_namespace

Dfeaults to the value of C<namespace>.

Used to provide the names of all the methods (the string C<annotations> in the
above methods would be replaced by the value of this).

=item id_callback

Defaults to C<object_to_id> (see L<KiokuDB>).

The function to map from an object to an ID string, can be a code reference or
a string for a method name to be invoked on the model object.

=item key_callback

The default implementation concatenates C<namespace>, a colon and
C<id_callback> to provide the key of the set.

If the key object is actually a string, the string is used as is.

Can be overridden with a method name to be invoked on the model, or a code
reference.

=back
