#!/usr/bin/env perl
####
## Copyright (C) 2003 Samuel Abels, <spam debain org>
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
####

####
## This file provides a class for holding informations about a cisco accesslist
## entry.
####

package CiscoRouter::AccesslistEntry;
use strict;
use vars qw($VERSION);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

CiscoRouter::AccesslistEntry

=head1 SYNOPSIS

 use CiscoRouter::AccesslistEntry;
 my $entry = new CiscoRouter::AccesslistEntry;
 $entry->set_permitdeny('deny');
 $entry->set_field(1, '192.168.0.0/22');
 $entry->set_field(2, '20');
 $entry->set_field(3, 'whatever');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a single
Cisco ACL entry.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<id>: The ACL id.
I<permitdeny>: Valid values: permit|deny. Default is permit.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new accesslist entry.
##
sub _init {
  my($self, %args) = @_;
  $self->{permitdeny} = $args{permitdeny} || 'permit';
  $self->{fields}     = [];
  return $self;
}


=head2 set_permitdeny('permit'|'deny')

Set whether the item permits or denies something.
Returns TRUE on success, otherwise FALSE.

=cut
sub set_permitdeny {
  my($self, $permitdeny) = @_;
  return FALSE if $permitdeny ne 'permit' and $permitdeny ne 'deny';
  $self->{permitdeny} = $permitdeny;
  return TRUE;
}


=head2 get_permitdeny()

Returns whether the item permits or denies something. ('permit'|'deny')

=cut
sub get_permitdeny {
  my $self = shift;
  return $self->{permitdeny};
}


=head2 set_field($fieldnumber, $value)

Set a field value.
Returns TRUE on success, otherwise FALSE.

=cut
sub set_field {
  my($self, $fieldnumber, $value) = @_;
  @{$self->{fields}}[$fieldnumber] = $value;
  return TRUE;
}


=head2 get_field($fieldnumber)

Returns the value of the field with the given fieldnumber.

=cut
sub get_field {
  my($self, $fieldnumber) = @_;
  return @{$self->{fields}}[$fieldnumber];
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
