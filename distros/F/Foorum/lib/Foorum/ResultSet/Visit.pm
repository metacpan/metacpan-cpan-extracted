package Foorum::ResultSet::Visit;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

sub make_visited {
    my ( $self, $object_type, $object_id, $user_id ) = @_;

    return unless ($user_id);
    return
        if (
        $self->count(
            {   user_id     => $user_id,
                object_type => $object_type,
                object_id   => $object_id
            }
        )
        );
    $self->create(
        {   user_id     => $user_id,
            object_type => $object_type,
            object_id   => $object_id,
            time        => time(),
        }
    );
}

sub make_un_visited {
    my ( $self, $object_type, $object_id, $user_id ) = @_;

    my @extra_cols;
    if ($user_id) {
        @extra_cols = ( user_id => { '!=', $user_id } );
    }

    $self->search(
        {   object_type => $object_type,
            object_id   => $object_id,
            @extra_cols,
        }
    )->delete;
}

sub is_visited {
    my ( $self, $object_type, $object_id, $user_id ) = @_;

    return {} unless ($user_id);
    my $visit;
    my @visits = $self->search(
        {   user_id     => $user_id,
            object_type => $object_type,
            object_id   => $object_id,
        },
        { columns => ['object_id'], }
    )->all;
    foreach (@visits) {
        $visit->{$object_type}->{ $_->object_id } = 1;
    }

    return $visit;
}

1;
