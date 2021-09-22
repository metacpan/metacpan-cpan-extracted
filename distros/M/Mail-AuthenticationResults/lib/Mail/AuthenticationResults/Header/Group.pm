package Mail::AuthenticationResults::Header::Group;
# ABSTRACT: Class modelling Groups of Authentication Results Header parts

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Scalar::Util qw{ refaddr };
use Carp;

use base 'Mail::AuthenticationResults::Header::Base';


sub _HAS_CHILDREN{ return 1; }

sub _ALLOWED_CHILDREN {
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
    croak 'Cannot add child' if ! $self->_ALLOWED_CHILDREN( $child );
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

sub build_string {
    my ( $self, $header ) = @_;

    my $sep = 0;
    foreach my $child ( @{ $self->children() } ) {
        $header->separator( ';' ) if $sep;
        $header->space( "\n" ) if $sep;
        $sep = 1;
        $child->build_string( $header );
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Header::Group - Class modelling Groups of Authentication Results Header parts

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

A group of classes, typically returned as a search results set, and should include
all required parts.

Please see L<Mail::AuthenticationResults::Header::Base>

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
