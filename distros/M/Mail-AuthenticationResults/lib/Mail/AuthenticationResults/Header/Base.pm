package Mail::AuthenticationResults::Header::Base;
require 5.010;
use strict;
use warnings;
our $VERSION = '1.20171230'; # VERSION
use Scalar::Util qw{ weaken refaddr };
use Carp;

use Mail::AuthenticationResults::Header::Group;

sub HAS_KEY{ return 0; }
sub HAS_VALUE{ return 0; }
sub HAS_CHILDREN{ return 0; }
sub ALLOWED_CHILDREN{ return 0; } # uncoverable statement

sub new {
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub set_key {
    my ( $self, $key ) = @_;
    croak 'Does not have key' if ! $self->HAS_KEY();
    croak 'Key cannot be undefined' if ! defined $key;
    croak 'Key cannot be empty' if $key eq q{};
    croak 'Invalid characters in key' if $key =~ /"/;
    $self->{ 'key' } = $key;
    return $self;
}

sub key {
    my ( $self ) = @_;
    croak 'Does not have key' if ! $self->HAS_KEY();
    return $self->{ 'key' } // q{};
}

sub set_value {
    my ( $self, $value ) = @_;
    croak 'Does not have value' if ! $self->HAS_VALUE();
    croak 'Value cannot be undefined' if ! defined $value;
    #croak 'Value cannot be empty' if $value eq q{};
    croak 'Invalid characters in value' if $value =~ /"/;
    $self->{ 'value' } = $value;
    return $self;
}

sub value {
    my ( $self ) = @_;
    croak 'Does not have value' if ! $self->HAS_VALUE();
    return $self->{ 'value' } // q{};
}

sub stringify {
    my ( $self, $value ) = @_;
    my $string = $value // q{};

    if ( $string =~ /[\s\t \(\);]/ ) {
        $string = '"' . $string . '"';
    }

    return $string;
}

sub children {
    my ( $self ) = @_;
    croak 'Does not have children' if ! $self->HAS_CHILDREN();
    return $self->{ 'children' } // [];
}

sub add_parent {
    my ( $self, $parent ) = @_;
    return if ( ref $parent eq 'Mail::AuthenticationResults::Header::Group' );
    croak 'Child already has a parent' if exists $self->{ 'parent' };
    croak 'Cannot add parent' if ! $parent->ALLOWED_CHILDREN( $self );
    $self->{ 'parent' } = $parent;
    weaken $self->{ 'parent' };
    return;
}

sub parent {
    my ( $self ) = @_;
    return $self->{ 'parent' };
}

sub add_child {
    my ( $self, $child ) = @_;
    croak 'Does not have children' if ! $self->HAS_CHILDREN();
    croak 'Cannot add child' if ! $self->ALLOWED_CHILDREN( $child );
    croak 'Cannot add a class as its own parent' if refaddr $self == refaddr $child;

    $child->add_parent( $self );
    push @{ $self->{ 'children' } }, $child;

    return $child;
}

sub as_string {
    my ( $self ) = @_;
    my $string = $self->stringify( $self->key() );
    if ( $self->value() ) {
        $string .= '=' . $self->stringify( $self->value() );
    }
    else {
        # We special case none here
        if ( $self->key() ne 'none' ) {
             $string .= '=';
        }
    }
    if ( $self->HAS_CHILDREN() ) {
        foreach my $child ( @{$self->children()} ) {
            $string .= ' ' . $child->as_string();
        }
    }
    return $string;
}

sub search {
    my ( $self, $search ) = @_;

    my $group = Mail::AuthenticationResults::Header::Group->new();

    my $match = 1;

    if ( exists( $search->{ 'key' } ) ) {
        if ( $self->HAS_KEY() ) {
            if ( ref $search->{ 'key' } eq 'Regexp' && $self->key() =~ m/$search->{'key'}/ ) {
                $match = $match && 1;
            }
            elsif ( lc $search->{ 'key' } eq lc $self->key() ) {
                $match = $match && 1;
            }
            else {
                $match = 0;
            }
        }
        else {
            $match = 0;
        }
    }

    if ( exists( $search->{ 'value' } ) ) {
        if ( $self->HAS_VALUE() ) {
            if ( ref $search->{ 'value' } eq 'Regexp' && $self->value() =~ m/$search->{'value'}/ ) {
                $match = $match && 1;
            }
            elsif ( lc $search->{ 'value' } eq lc $self->value() ) {
                $match = $match && 1;
            }
            else {
                $match = 0;
            }
        }
        else {
            $match = 0; # uncoverable statement
        }
    }

    if ( exists( $search->{ 'isa' } ) ) {
        if ( lc ref $self eq 'mail::authenticationresults::header::' . lc $search->{ 'isa' } ) {
            $match = $match && 1;
        }
        else {
            $match = 0;
        }
    }

    if ( $match ) {
        $group->add_child( $self );
    }

    if ( $self->HAS_CHILDREN() ) {
        foreach my $child ( @{$self->children()} ) {
            my $childfound = $child->search( $search );
            if ( $childfound ) {
                $group->add_child( $childfound );
            }
        }
    }

    return $group;
}

1;
package Mail::AuthenticationResults::Header::Base;
