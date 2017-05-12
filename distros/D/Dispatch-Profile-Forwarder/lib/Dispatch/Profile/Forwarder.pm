package Dispatch::Profile::Forwarder;
#-------------------------------------------------------------------------------
#   Module  : Dispatch::Profile::Forwarder
#
#   Purpose : Scaffolding to allow a package to receive a Dispatch::Profile
#             store
#-------------------------------------------------------------------------------
use Moose;
our $VERSION = '0.001';

#-------------------------------------------------------------------------------
#   Object constructor parameters
#-------------------------------------------------------------------------------
has 'forwarder', is => 'rw', required => 0;

#-------------------------------------------------------------------------------
#   Subroutine : BUILD
#
#   Purpose : Post creation manipulation of object to link desired targets
#             with corresponding code references
#-------------------------------------------------------------------------------
sub BUILD {
   my $self = shift;

   #-------------------------------------------------------------------------------
   #   If we're being initialised with a forwarder declaration we're being passed
   #   an existing Profile::Dispatch store, update the local store
   #-------------------------------------------------------------------------------
   if ( defined $self->{forwarder}{_store} ) {
      # Move the coderef store to the current object
      $self->{_store} = $self->{forwarder}{_store};

      # Delete the forwarder
      delete $self->{forwarder};
   }
}

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Dispatch::Profile constructor forwarder

__END__

=pod

=encoding UTF-8

=head1 NAME

Dispatch::Profile::Forwarder - Dispatch::Profile constructor forwarder

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This module provides a Moose BUILD constructor that is utilised by the Dispatch::Profile package. It is responsible for configuring a local code store based on passed parameters.

=head2 BUILD

Moose constructor with the following configurable parameters

=head3 forwarder => Dispatch::Profile

An object of type Dispatch::Profile

=head1 AUTHOR

James Spurin <james@spurin.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by James Spurin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
