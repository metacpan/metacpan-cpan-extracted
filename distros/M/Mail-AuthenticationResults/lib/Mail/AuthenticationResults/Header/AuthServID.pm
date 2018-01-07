package Mail::AuthenticationResults::Header::AuthServID;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Header::Base';

sub HAS_VALUE{ return 1; }

sub HAS_CHILDREN{ return 1; }

sub ALLOWED_CHILDREN {
    my ( $self, $child ) = @_;
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Comment';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::SubEntry';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Version';
    return 0;
}

sub as_string {
    my ( $self ) = @_;
    my $string = q{};
    return join( ' ', $self->stringify( $self->value() ), map { $_->as_string() } @{ $self->children() } );
}

1;
