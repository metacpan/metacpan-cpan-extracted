use 5.006;
use strict;
use warnings;

package Metabase::Archive;
# ABSTRACT: Interface for Metabase storage
our $VERSION = '1.003'; # VERSION

use Moose::Role;

requires 'store';     # store( $fact_struct ) -- die or return $guid
requires 'extract';   # extract( $guid ) -- die or return $fact_struct
requires 'delete';
requires 'iterator';
requires 'initialize'; # initialize() -- die or prepare storage backend

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Archive - Interface for Metabase storage

=head1 VERSION

version 1.003

=head1 SYNOPSIS

  package Metabase::Archive::Foo;
  use Metabase::Fact;
  use Moose;
  with 'Metabase::Archive';
  
  # define Moose attributes
  
  sub store {
    my ( $self, $fact_struct ) = @_;
    # store a fact
  }

  sub extract {
    my ( $self, $guid ) = @_;
    # retrieve a fact
    return $fact;
  }

  sub delete {
    my ( $self, $guid ) = @_;
    # delete a fact;
    return;
  }

  sub iterator {
    my ( $self ) = @_;
    # get iterator as Data::Stream::Bulk object
    return $iterator;
  }

  sub initialize {
    my ($self, @fact_classes) = @_;
    # prepare backend to store data (e.g. create database, etc.)
    return;
  }

=head1 DESCRIPTION

This describes the interface for storing and retrieving facts.  Implementations
must provide the C<store>, C<extract>, C<delete>, C<iterator> and C<initialize>
methods. C<initialize> must be idempotent. C<iterator> must return a
L<Data::Stream::Bulk> object.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Leon Brocard <acme@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
