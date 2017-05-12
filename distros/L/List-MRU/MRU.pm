package List::MRU;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.04';

# -------------------------------------------------------------------------
# Constructor
sub new
{
  my $class = shift;
  my %arg = @_;
  croak "required argument 'max' missing'" unless defined $arg{max};
  croak "'max' argument not an integer'" unless $arg{max} =~ m/^\d+$/;
  croak "'eq' argument not an subroutine'" 
    if $arg{eq} && ref $arg{eq} ne 'CODE';
  bless {
    max  => $arg{max},
    'eq' => $arg{eq},
    uuid => $arg{uuid},
    list => [],
    ulist => [],
    current => 0,
  }, $class;
}

# -------------------------------------------------------------------------
# Private methods

sub _truncate
{
  my $self = shift;
  pop @{$self->{list}} while scalar @{$self->{list}} > $self->max;
  if ($self->uuid) {
    pop @{$self->{ulist}} while scalar @{$self->{ulist}} > $self->max;
  }
}

sub _reset { shift->{current} = 0; }

# -------------------------------------------------------------------------
# Public methods

# Add $item, moving to head of list if already exists 
#   (returns $self for method chaining)
sub add
{
  my $self = shift;
  my ($item, $uuid) = @_;
  croak "no item given to add" unless defined $item;
  croak "no uuid given to add" if $self->uuid && ! defined $uuid;
  if ($self->delete(item => $item, uuid => $uuid)) {
    unshift @{$self->{list}}, $item;
    unshift @{$self->{ulist}}, $uuid if $self->uuid;
  }
  else {
    unshift @{$self->{list}}, $item;
    unshift @{$self->{ulist}}, $uuid if $self->uuid;
    $self->_truncate;
  }
  $self
}

# Delete (first) matching $item (by self or by uuid), returning it if found.
sub delete
{
  my $self = shift;
  my ($item, $uuid) = @_;
  # Check for named arguments style call
  if ($item && ($item eq 'item' || $item eq 'uuid')) {
    my %arg = @_;
    $arg{$item} = $uuid;
    $item = $arg{item};
    $uuid = $arg{uuid};
  }
  croak "no item given to delete" unless defined $item or defined $uuid;
  my $eq = $self->{eq} || sub { $_[0] eq $_[1] };
  for my $i (0 .. $#{$self->{list}}) {
    if (($self->uuid && $uuid && $self->{ulist}->[$i] eq $uuid) ||
        ($item && $eq->($item, $self->{list}->[$i]))) {
      my $deleted = splice @{$self->{list}}, $i, 1;
      my $udeleted = splice @{$self->{ulist}}, $i, 1 if $self->uuid;
      return wantarray && $self->uuid ? ($deleted, $udeleted) : $deleted;
    }
  }
}

# Iterator
sub each  { 
  my $self = shift;
  if ($self->{current} <= $#{$self->{list}}) {
    my $current = $self->{current}++;
    return wantarray ? 
      ($self->{list}->[$current], $self->uuid ? $self->{ulist}->[$current] : undef) :
      $self->{list}->[$current];
  }
  else {
    # Reset current
    $self->_reset;
    return wantarray ? () : undef;
  }
}

# Accessors
sub list  { wantarray ? @{shift->{list}} : shift->{list} }
sub max   { shift->{max} }
sub count { scalar @{shift->{list}} }
sub uuid  { shift->{uuid} }

1;

__END__

=head1 NAME

List::MRU - Perl module implementing a simple fixed-size MRU-ordered list.

=head1 SYNOPSIS

  use List::MRU;

  # Constructor
  $lm = List::MRU->new(max => 20);

  # Constructor with explicit 'eq' subroutine for obj equality tests
  $lm = List::MRU->new(max => 20, 'eq' => sub {
    $_[0]->stringify eq $_[1]->stringify
  });

  # Constructor using explicit UUIDs
  $lm - List::MRU->new(max => 5, uuid => 1);

  # Add item, moving to head of list if already exists
  $lm->add($item);
  # Add item, moving to head of list if $uuid matches or object already exists
  $lm->add($item, $uuid);

  # Iterate in most-recently-added order
  for $item ($lm->list) {
    print "$item\n";
  }
  # each-style iteration
  while (($item, $uuid) = $lm->each) {
    print "$item, $uuid\n";
  }

  # Item deletion
  $lm->delete($item);
  $lm->delete(uuid => $uuid);

  # Accessors
  $max = $lm->max;        # max items in list
  $count = $lm->count;    # current items in list


=head1 DESCRIPTION

Perl module implementing a simple fixed-size most-recently-used-
(MRU)-ordered list of values/objects. Well, really it's a most-
recently-added list - items added to the list are just promoted 
to the front of the list if they already exist, otherwise they 
are added there.

Works fine with with non-scalar items, but you will need to
supply an explicit 'eq' subroutine to the constructor to handle
testing for the 'same' object (or alternatively have overloaded
the 'eq' operator for your object).

List::MRU also supports having explicit UUIDs attached to items,
allowing List::MRU items to be modified, instead of a change just
creating a new entry.


=head1 SEE ALSO

Tie::Cache::LRU, which was kind of what I wanted, but didn't retain 
ordering.


=head1 AUTHOR

Gavin Carr <gavin@openfusion.com.au>


=head1 COPYRIGHT AND LICENSE

Copyright 2005-2006 by Open Fusion Pty. Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

