#!/usr/bin/env perl
####
## This file provides a class for holding informations about a prefixlist.
####

package RouterBase::Prefixlist;
use RouterBase::Atom;
use RouterBase::PrefixlistEntry;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(RouterBase::Atom);

$VERSION = 0.01;

use constant TRUE  => 1;
use constant FALSE => 0;


=head1 NAME

RouterBase::Prefixlist

=head1 SYNOPSIS

 use RouterBase::Prefixlist;
 my $pfxlist = new RouterBase::Prefixlist;
 $pfxlist->set_name('Prefixlist Name');
 $pfxlist->add_prefix('permit', '192.168.0.0/22', '20', '24');

=head1 DESCRIPTION

This module provides routines for storing informations regarding an IP prefix
list.

=head1 CONSTRUCTOR AND METHODS

=head2 new([%args])

Object constructor. Valid arguments:

I<name>: The prefixlist name.

=cut
sub new {
  my($class, %args) = @_;
  $class = ref($class) || $class;
  my $self = {};
  bless $self, $class;
  return $self->_init(%args);
}


## Purpose: Initialize a new prefixlist.
##
sub _init {
  my($self, %args) = @_;
  $self->{name} = $args{name} if $args{name};
  $self->{sequencenumber} = 0;
  return $self;
}


=head2 set_name($name)

Set the prefixlist name.

=cut
sub set_name {
  my($self, $name) = @_;
  $self->{name} = $name;
}


=head2 get_name()

Returns the prefixlist name.

=cut
sub get_name {
  my $self = shift;
  return $self->{name};
}


=head2 set_description($description)

Defines the card description.

=cut
sub set_description {
  my($self, $description) = @_;
  $self->{description} = $description;
}


=head2 get_description()

Returns the card description.

=cut
sub get_description {
  my $self = shift;
  return $self->{description};
}


=head2 add_prefix($seq, $permitdeny, $prefix, $lessequal, $greaterequal)

Checks & adds the given IP prefix to the list. If the sequence number is not
specified, the last sequence number + 5 will be used.
Returns TRUE on success, otherwise FALSE.

=cut
sub add_prefix {
  my($self, $seq, $permden, $pfx, $le, $ge) = @_;
  #print "DEBUG: RouterBase::Prefixlist::add_prefix(): $permden, $pfx\n";
  my $pe = new RouterBase::PrefixlistEntry;
  $pe->set_toplevel($self->toplevel);
  $pe->set_parent($self->parent);
  $pe->set_sequence($seq ? $seq : ($self->{sequencenumber} + 5));
  $pe->set_permitdeny($permden) || return FALSE;
  $pe->set_prefix($pfx)         || return FALSE;
  return if $pe->set_le($le) < 0;
  return if $pe->set_ge($ge) < 0;
  $self->{prefixlist}->{$pfx} = $pe;
  return TRUE;
}


=head2 get_prefix($prefix)

Returns the L<RouterBase::PrefixlistEntry|RouterBase::PrefixlistEntry> object.

=cut
sub get_prefix {
  my($self, $prefix) = @_;
  return $self->{prefixlist}->{$prefix};
}


=head2 foreach_prefix($func, %data)

Walks through all prefixlist entries calling the function $func.
Args passed to $func are:

I<$prefix>: The L<RouterBase::PrefixlistEntry|RouterBase::PrefixlistEntry>.
I<%data>: The given data, just piped through.

If $func returns FALSE, list evaluation will be stopped.

=cut
sub foreach_prefix {
  my($self, $func, %data) = @_;
  for my $prefixno (keys %{$self->{prefixlist}}) {
    my $prefix = $self->{prefixlist}->{$prefixno};
    #print "DEBUG: RouterBase::Prefixlist::foreach_prefix(): Pfx $prefixno\n";
    return FALSE if !$func->($prefix, %data);
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
