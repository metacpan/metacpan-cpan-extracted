#!/usr/bin/env perl
####
## This file provides a base class for RouterBase elements (atoms).
####

package RouterBase::Atom;
use IPv4;
use strict;
use vars qw($VERSION);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

RouterBase::Atom

=head1 SYNOPSIS

 package MyPackage;
 use RouterBase::Atom;
 use vars qw($VERSION @ISA);
 @ISA = qw(RouterBase::Atom);

=head1 DESCRIPTION

This module provides a base class for RouterBase elements (atoms).

=head1 CONSTRUCTOR AND METHODS

=head2 set_toplevel($routerbaseatom)

Stores a reference to the toplevel object in the atom.

=cut
sub set_toplevel {
  my($self, $toplevel) = @_;
  $self->{toplevel} = $toplevel;
}


=head2 toplevel()

Returns the toplevel object.

=cut
sub toplevel {
  my $self = shift;
  return $self->{toplevel};
}


=head2 set_parent($routerbaseatom)

Stores a reference to the parent object in the atom.

=cut
sub set_parent {
  my($self, $parent) = @_;
  $self->{parent} = $parent;
}


=head2 parent()

Returns the parent object.

=cut
sub parent {
  my $self = shift;
  return $self->{parent};
}


=head1 COPYRIGHT

Copyright (c) 2004 Samuel Abels.
All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Samuel Abels <spam debain org>

=cut

1;

__END__
