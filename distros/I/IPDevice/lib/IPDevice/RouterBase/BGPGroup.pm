#!/usr/bin/env perl
####
## This file provides a base class for holding informations regarding a Cisco
## BGP neighbor group.
####

package RouterBase::BGPGroup;
use RouterBase::Atom;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(RouterBase::Atom RouterBase::BGPNeighbor);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

RouterBase::BGPGroup

=head1 SYNOPSIS

 use RouterBase::BGPGroup;
 my $neigh = new RouterBase::BGPGroup;
 $neigh->set_name('Neighbor Name');
 $neigh->set_ip('192.168.0.2');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a Cisco Router
BGP neighbor group.

=head1 CONSTRUCTOR AND METHODS

This class provides all methods from
L<RouterBase::BGPNeighbor|RouterBase::BGPNeighbor>.

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
