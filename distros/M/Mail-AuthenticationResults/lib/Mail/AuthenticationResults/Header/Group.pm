package Mail::AuthenticationResults::Header::Group;
use strict;
use warnings;
our $VERSION = '1.20171226'; # VERSION

use Carp;
use Scalar::Util qw{ refaddr };

sub HAS_CHILDREN{ return 1; }

use base 'Mail::AuthenticationResults::Header::Base';

sub add_parent {
    my ( $self ) = @_;
    die 'Cannot add group class as a child';
    return; # uncoverable statement
}

sub add_child {
    my ( $self, $child ) = @_;
    die 'Cannot add a class as its own parent' if refaddr $self == refaddr $child;

    if ( ref $child eq 'Mail::AuthenticationResults::Header::Group' ) {
        foreach my $subchild ( @{ $child->children() } ) {
            $self->SUPER::add_child( $subchild );
        }
        ## ToDo what to return in this case?
    }
    else {
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

