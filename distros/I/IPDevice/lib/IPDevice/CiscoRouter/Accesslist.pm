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
## This file provides a class for holding informations about a Cisco accesslist.
####

package CiscoRouter::Accesslist;
use CiscoRouter::AccesslistEntry;
use strict;
use vars qw($VERSION);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

CiscoRouter::Accesslist

=head1 SYNOPSIS

 use CiscoRouter::Accesslist;
 my $acl = new CiscoRouter::Accesslist;
 $acl->set_id(10);
 $acl->add_entry('permit', '192.168.0.0/22', '20', '24');

=head1 DESCRIPTION

This module provides routines for storing informations regarding a Cisco
accesslist entry.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<id>: The accesslist number.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new accesslist.
##
sub _init {
  my($self, %args) = @_;
  $self->{name} = $args{name};
  return $self;
}


=head2 set_name($id)

Set the accesslist name.

=cut
sub set_name {
  my($self, $name) = @_;
  $self->{name} = $name;
}


=head2 get_name()

Returns the accesslist number.

=cut
sub get_name {
  my $self = shift;
  return $self->{name};
}


=head2 set_description($id)

Set the accesslist description.

=cut
sub set_description {
  my($self, $descr) = @_;
  $self->{descr} = $descr;
}


=head2 get_description()

Returns the accesslist description.

=cut
sub get_description {
  my $self = shift;
  return $self->{descr};
}


=head2 add_entry($permitdeny, @fields)

Adds a new entry to the accesslist.
Returns TRUE on success, otherwise FALSE.

=cut
sub add_entry {
  my($self, $permitdeny, @fields) = @_;
  my $aclentry = new CiscoRouter::AccesslistEntry;
  return FALSE if !$aclentry->set_permitdeny($permitdeny);
  my $i = 1;
  for my $field (@fields) {
    return FALSE if !$aclentry->set_field($i, $field);
    $i++;
  }
  push(@{$self->{accesslist}}, $aclentry);
  return TRUE;
}


=head2 foreach_entry($func, %data)

Walks through the ACL calling the function $func for every ACL statement.
Args passed to $func are:

I<$aclentry>: The L<CiscoRouter::AccesslistEntry|CiscoRouter::AccesslistEntry>.
I<%data>: The given data, just piped through.

If $func returns FALSE, list evaluation will be stopped.

=cut
sub foreach_entry {
  my($self, $func, %data) = @_;
  for my $aclentry (@{$self->{accesslist}}) {
    return FALSE if !$func->($aclentry, %data);
  }
  return TRUE;
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
