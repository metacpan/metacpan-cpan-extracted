package Mail::AuthenticationResults::Header;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
use Carp;

use Mail::AuthenticationResults::Header::AuthServID;

use base 'Mail::AuthenticationResults::Header::Base';

sub HAS_VALUE{ return 1; }
sub HAS_CHILDREN{ return 1; }

sub ALLOWED_CHILDREN {
    my ( $self, $child ) = @_;
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Comment';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Entry';
    return 0;
}

sub set_value {
    my ( $self, $value ) = @_;
    croak 'Does not have value' if ! $self->HAS_VALUE();
    croak 'Value cannot be undefined' if ! defined $value;
    croak 'value should be an AuthServID type' if ref $value ne 'Mail::AuthenticationResults::Header::AuthServID';
    $self->{ 'value' } = $value;
    return $self;
}

sub add_parent {
    my ( $self, $parent ) = @_;
    return;
}

sub add_child {
    my ( $self, $child ) = @_;
    croak 'Cannot add a SubEntry as a child of a Header' if ref $child eq 'Mail::AuthenticationResults::Header::SubEntry';
    return $self->SUPER::add_child( $child );
}

sub as_string {
    my ( $self ) = @_;
    my $string = q{};
    my $value = q{};
    if ( $self->value() ) {
        $value = $self->value()->as_string();
    }
    else {
        $value = 'unknown';
    }
    $value .= ";\n";

    $value .= join( ";\n", map { $_->as_string() } @{ $self->children() } );

    if ( scalar @{ $self->search({ 'isa' => 'entry' } )->children() } == 0 ) {
        if ( scalar @{ $self->children() } > 0 ) {
            $value .= ' ';
        }
        $value .= 'none';
    }

    return $value;
}

1;
