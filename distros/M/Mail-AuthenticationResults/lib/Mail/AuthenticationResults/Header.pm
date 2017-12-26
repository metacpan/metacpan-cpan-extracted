package Mail::AuthenticationResults::Header;
use strict;
use warnings;
our $VERSION = '1.20171226'; # VERSION

use Carp;

sub HAS_VALUE{ return 1; }
sub HAS_CHILDREN{ return 1; }

use base 'Mail::AuthenticationResults::Header::Base';

sub add_parent {
    my ( $self ) = @_;
    die 'Cannot add top level class as a child';
    return; # uncoverable statement
}

sub add_child {
    my ( $self, $child ) = @_;
    die 'Cannot add a Comment as a child of a Header' if ref $child eq 'Mail::AuthenticationResults::Header::Comment';
    die 'Cannot add a SubEntry as a child of a Header' if ref $child eq 'Mail::AuthenticationResults::Header::SubEntry';
    return $self->SUPER::add_child( $child );
}

sub as_string {
    my ( $self ) = @_;
    my $string = q{};
    return $self->value() . ";\n" . join( ";\n", map { $_->as_string() } @{ $self->children() } );
}

1;
