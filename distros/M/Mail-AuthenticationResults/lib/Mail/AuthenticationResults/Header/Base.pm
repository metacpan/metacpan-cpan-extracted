package Mail::AuthenticationResults::Header::Base;
use strict;
use warnings;
our $VERSION = '1.20171226'; # VERSION
use Scalar::Util qw{ weaken refaddr };
use Carp;

use Mail::AuthenticationResults::Header::Group;

sub HAS_KEY{ return 0; }
sub HAS_VALUE{ return 0; }
sub HAS_CHILDREN{ return 0; }

sub new {
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub set_key {
    my ( $self, $key ) = @_;
    croak 'Does not have key' if ! $self->HAS_KEY();
    die 'Key cannot be undefined' if ! defined $key;
    die 'Key cannot be empty' if $key eq q{};
    die 'Invalid characters in key' if $key =~ /[^a-zA-Z0-9\.\-_]/;
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
    die 'Value cannot be undefined' if ! defined $value;
    #die 'Value cannot be empty' if $value eq q{};
    die 'Invalid characters in value' if $value =~ /[\s\t \(\);]/;
    $self->{ 'value' } = $value;
    return $self;
}
sub value {
    my ( $self ) = @_;
    croak 'Does not have value' if ! $self->HAS_VALUE();
    return $self->{ 'value' } // q{};
}

sub children {
    my ( $self ) = @_;
    croak 'Does not have children' if ! $self->HAS_CHILDREN();
    return $self->{ 'children' } // [];
}

sub add_parent {
    my ( $self, $parent ) = @_;
    return if ( ref $parent eq 'Mail::AuthenticationResults::Header::Group' );
    die 'Child already has a parent' if exists $self->{ 'parent' };
    $self->{ 'parent' } = $parent;
    weaken $self->{ 'parent' };
    return;
}

sub add_child {
    my ( $self, $child ) = @_;
    croak 'Does not have children' if ! $self->HAS_CHILDREN();

    my $parent_ref = ref $self;
    my $child_ref  = ref $child;

    die 'Not a Header object' if ! $child_ref =~ /^Mail::AuthenticationResults::Header/;

    die 'Cannot add a class as its own parent' if refaddr $self == refaddr $child;

    die 'Cannot use base class directly' if $parent_ref eq 'Mail::AuthenticationResults::Header::Base';
    die 'Cannot use base class directly' if $child_ref  eq 'Mail::AuthenticationResults::Header::Base';

    $child->add_parent( $self );

    push @{ $self->{ 'children' } }, $child;
    return $child;
}

sub as_string {
    my ( $self ) = @_;
    my $string = $self->key() . '=' . $self->value();
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
            if ( lc $search->{ 'key' } eq lc $self->key() ) {
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
            if ( lc $search->{ 'value' } eq lc $self->value() ) {
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

    if ( exists( $search->{ 'isa' } ) ) {
        if ( lc $search->{ 'isa' } eq 'entry' ) {
            if ( ref $self eq 'Mail::AuthenticationResults::Header::Entry' ) {
                $match = $match && 1;
            }
            else {
                $match = 0;
            }
        }
        if ( lc $search->{ 'isa' } eq 'subentry' ) {
            if ( ref $self eq 'Mail::AuthenticationResults::Header::SubEntry' ) {
                $match = $match && 1;
            }
            else {
                $match = 0;
            }
        }
        if ( lc $search->{ 'isa' } eq 'comment' ) {
            if ( ref $self eq 'Mail::AuthenticationResults::Header::Comment' ) {
                $match = $match && 1;
            }
            else {
                $match = 0;
            }
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
