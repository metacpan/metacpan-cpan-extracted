package Mail::AuthenticationResults::Header::Group;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
use Scalar::Util qw{ refaddr };
use Carp;

use base 'Mail::AuthenticationResults::Header::Base';

sub HAS_CHILDREN{ return 1; }

sub ALLOWED_CHILDREN {
    my ( $self, $child ) = @_;
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::AuthServID';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Comment';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Entry';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Group';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::SubEntry';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Version';
    return 0;
}

sub add_child {
    my ( $self, $child ) = @_;
    croak 'Cannot add child' if ! $self->ALLOWED_CHILDREN( $child );
    croak 'Cannot add a class as its own parent' if refaddr $self == refaddr $child;

    if ( ref $child eq 'Mail::AuthenticationResults::Header::Group' ) {
        foreach my $subchild ( @{ $child->children() } ) {
            $self->add_child( $subchild );
        }
        ## ToDo what to return in this case?
    }
    else {
        foreach my $current_child ( @{ $self->children() } ) {
            if ( $current_child == $child ) {
                return $child;
            }
        }
        $self->SUPER::add_child( $child );
    }

    return $child;
}

sub as_string {
    my ( $self ) = @_;
    my $string = q{};
    return join( ";\n", map { $_->as_string() } @{ $self->children() } );
}

1;

