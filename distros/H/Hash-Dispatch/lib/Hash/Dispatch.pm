package Hash::Dispatch;
BEGIN {
  $Hash::Dispatch::VERSION = '0.0010';
}
# ABSTRACT: Find CODE in a hash (hashlike)

use strict;
use warnings;

use Any::Moose;

use List::MoreUtils qw/ natatime /;

has map => qw/ is ro required 1 isa ArrayRef /;

sub dispatch {
    my $self = shift;
    if ( blessed $self && $self->isa( 'Hash::Dispatch' ) ) {
        return $self->_dispatch_object( @_ );
    }
    else {
        return $self->_dispatch_class( @_ );
    }
}

sub _dispatch_class {
    my $self = shift;
    return $self->new( map => [ %{ $_[0] } ] ) if 1 == @_ && ref $_[0] eq 'HASH';
    return $self->new( map => [ @_ ] );
}

sub _dispatch_object {
    my $self = shift;
    my $query = shift;

    my $original_query = $query;
    my ( $value, $captured, %seen );
    while ( 1 ) {
        ( $value, $captured ) = $self->_lookup( $query );
        return unless defined $value;
        last if ref $value eq 'CODE';
        if ( $seen{ $value } ) {
            die "*** Dispatch loop detected on query ($original_query => $query)";
        }
        $seen{ $query } = 1;
        $query = $value;
    }

    return $self->_result( $value, $captured );
}

sub _lookup {
    my $self = shift;
    my $query = shift;

    my $each = natatime 2, @{ $self->map };
    while ( my ( $key, $value ) = $each->() ) {
        if ( ref $key eq '' ) {
            if ( $key eq $query ) {
                return ( $value );
            }
        }
        elsif ( ref $key eq 'Regexp' ) {
            if ( my @captured = ( $query =~ $key ) ) {
                return ( $value, \@captured );
            }
        }
        else {
            die "*** Invalid dispatch key ($key)";
        }
    }

    return;
}

sub _result {
    my $self = shift;
    
    return Hash::Dispatch::Result->new( value => $_[0], captured => $_[1] );
}

package Hash::Dispatch::Result;
BEGIN {
  $Hash::Dispatch::Result::VERSION = '0.0010';
}

use Any::Moose;

has value => qw/ is ro required 1 isa CodeRef /; 
has captured => qw/ reader _captured /;

sub captured {
    my $self = shift;
    return @{ $self->_captured || [] };
}

1;



=pod

=head1 NAME

Hash::Dispatch - Find CODE in a hash (hashlike)

=head1 VERSION

version 0.0010

=head1 SYNOPSIS

    $dispatch = Hash::Dispatch->dispatch(

        'xyzzy' => sub {
            return 'xyzzy';
        },

        qr/.../ => 'xyzzy',

        ...

    );

    $result = $dispatch->dispatch( 'xyzzy' );

    $result->value->( ... );

=head1 DESCRIPTION

Hash::Dispatch is a tool for creating a hash-like lookup for returning a CODE reference

It is hash-like because a query against the dispatcher will only return once a CODE reference a found. If a key (a string or regular expression) maps to a string, then that will cause the lookup to begin again with the new value, recursing until a CODE reference is found or a deadend is reached:

    a => CODE0
    b => CODE1
    c => CODE2
    d => a
    qr/z/ => c

    query( a ) => CODE0
    query( b ) => CODE1
    query( d ) => CODE0
    query( xyzzy ) => CODE2
    query( j ) => undef

Hash::Dispatch will throw an exception if it is cycling:

    a => b
    b => a

    query( a ) => {{{ Exception! }}}

=head1 USAGE

=head2 $dispatcher = Hash::Dispatch->dispatch( ... )

Returns a new C<$dispatcher> with the given mapping

=head2 $result = $dispatcher->dispatch( <query> )

Search C<$dispatcher> with C<< <query> >> 

Returns an object with a C<< ->value >> method that contains the CODE reference 

Returns undef is nothing is found

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

