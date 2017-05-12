package Foorum::ResultSet::SecurityCode;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

use Foorum::Utils qw/generate_random_word/;
use vars qw/%types/;

%types = (
    forget_password => 1,
    change_email    => 2,
);

sub get {
    my ( $self, $type, $user_id ) = @_;

    $type = $types{$type} if ( exists $types{$type} );

    my $rs = $self->search(
        {   type    => $type,
            user_id => $user_id
        }
    )->first;
    return unless ($rs);

    if (wantarray) {
        return ( $rs->code, $rs->note );
    } else {
        return $rs->code;
    }
}

sub get_or_create {
    my ( $self, $type, $user_id, $note ) = @_;

    $type = $types{$type} if ( exists $types{$type} );
    return unless ($type);

    my $code = $self->get( $type, $user_id );
    return $code if ( $code and length($code) );

    $code = &generate_random_word(12);

    $self->create(
        {   type    => $type,
            user_id => $user_id,
            code    => $code,
            time    => time(),
            note    => $note,
        }
    );

    return $code;
}

sub remove {
    my ( $self, $type, $user_id ) = @_;

    $type = $types{$type} if ( exists $types{$type} );

    $self->search(
        {   type    => $type,
            user_id => $user_id
        }
    )->delete;
}

1;
__END__

