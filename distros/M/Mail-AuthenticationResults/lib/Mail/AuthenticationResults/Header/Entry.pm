package Mail::AuthenticationResults::Header::Entry;
use strict;
use warnings;
our $VERSION = '1.20171226'; # VERSION

use Scalar::Util qw{ refaddr };

sub HAS_KEY{ return 1; }
sub HAS_VALUE{ return 1; }
sub HAS_CHILDREN{ return 1; }

use base 'Mail::AuthenticationResults::Header::Base';

sub add_child {
    my ( $self, $child ) = @_;
    die 'Cannot add an Entry as a child of an Entry' if ref $child eq 'Mail::AuthenticationResults::Header::Entry';
    return $self->SUPER::add_child( $child );
}

sub as_string {
    my ( $self ) = @_;
    return $self->SUPER::as_string();
}

1;
