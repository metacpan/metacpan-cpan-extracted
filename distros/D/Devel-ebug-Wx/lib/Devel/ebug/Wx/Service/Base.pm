package Devel::ebug::Wx::Service::Base;

use strict;
use base qw(Class::Accessor::Fast);

=head1 NAME

Devel::ebug::Wx::Service::Base - base class for services

=head1 SYNOPSIS

  use base qw(Devel::ebug::Wx::Service::Base);

  # it's a subclass of Class::Accessor::Fast
  __PACKAGE__->mk_accessors( qw(foo moo) );

  # override one or more of the stub methods
  sub initialize         { my( $self, $manager ) = @_; # ... }
  sub load_configuration { my( $self ) = @_; # ... }
  sub save_configuration { my( $self ) = @_; # ... }
  sub finalize           { my( $self ) = @_; # ... }

=head1 DESCRIPTION

Useful superclass for all services.

=cut

__PACKAGE__->mk_accessors( qw(initialized finalized) );

# empty base implementations
sub initialize         { my( $self, $manager ) = @_; }
sub load_configuration { my( $self ) = @_; }
sub save_configuration { my( $self ) = @_; }
sub finalize           { my( $self ) = @_; }

=head1 SEE ALSO

L<Devel::ebug::Wx::ServiceManager>

=cut

1;
