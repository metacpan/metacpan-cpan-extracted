=head1 NAME

Genealogy::Relationship - calculate the relationship between two people

=head1 SYNOPSIS

    use Genealogy::Relationship;
    use Person; # Imaginary class modelling people

    my $rel = Genealogy::Relationship->new;

    my $grandfather = Person->new( ... );
    my $father      = Person->new( ... );
    my $me          = Person->new( ... );
    my $aunt        = Person->new( ... );
    my $cousin      = Person->new( ... );

    my $common_ancestor = $rel->most_recent_common_ancestor(
      $me, $cousin,
    );
    say $common_ancestor->name; # Grandfather's name

    say $rel->get_relationship($me, $grandfather); # Grandson
    say $rel->get_relationship($grandfather, $me); # Grandfather

    say $rel->get_relationship($father, $cousin);  # Uncle
    say $rel->get_relationship($cousin, $father);  # Niece

=head1 DESCRIPTION

This module makes it easy to calculate the relationship between two people.

If you have a set of objects modelling your family tree, then you will
be able to use this module to get a description of the relationship between
any two people on that tree.

The objects that you use with this module need to implement three methods:

=over 4

=item * parents

This method should return an array reference containing the objects which are
the parents of the current person. The array reference can contain zero, one
or two objects.

If an object does not have a C<parents()> method, then the module will fall
back to using a C<parent()> method that returns a single parent object.

=item * id

This method should return a unique identifier for the current person.
The identifier can be a string or a number.

=item * gender

This method should return the gender of the current person. It should be
the character 'm' or 'f'.

=back

=head2 Note

THe objects that you use with this class can actually have different names
for these methods. C<parent>, C<parents>, C<id> and C<gender> are the default
names used by this module, but you can change them by passing the correct names
to the constructor. For example:

    my $rel = Genealogy::Relationship->new(
      parent_field_name     => 'progenitor',
      parents_field_name    => 'progenitors',
      identifier_field_name => 'person_id',
      gender_field_name     => 'sex',
    );

=head2 Limitations

This module was born out of a need I had while creating
L<https://lineofsuccession.co.uk/>. Relationship calculations are based on
finding the most recent common ancestor between two people, and choosing the
path that uses the fewest generations.

=head2 Constructor

The constructor for this class takes one optional attribute called `abbr`.
The default value for this attribute is 2. When set, strings of repeated
"great"s in a relationship description will collapsed to "$n x great".

For example, if the description you have is "Great, great, great
grandfather", then that will be abbreviated to to "3 x great grandfather".

The value for `abbr` is the maximum number of repetitions that will be left
untouched. You can turn abbreviations off by setting `abbr` to zero.

=head2 Caching

Calculating relationship names isn't at all different. But there can be a lot
of (simple and repetitive) work involved. This is particularly true if your
objects are based on database tables (as I found to my expense).

If you're calculating a lot of relationships, then you should probably
consider putting a caching layer in front of C<get_relationship>.

=cut

use strict;
use warnings;
use Feature::Compat::Class;

class Genealogy::Relationship;

use List::Util qw[first];
use Lingua::EN::Numbers qw[num2en num2en_ordinal];

our $VERSION = '2.0.0';

field $parent_field_name :param = 'parent';
field $parents_field_name :param = 'parents';
field $identifier_field_name :param = 'id';
field $gender_field_name :param = 'gender';

field $relationship_table :param = {
  m => [
    [ undef, 'Father', 'Grandfather', 'Great grandfather', 'Great, great grandfather', 'Great, great, great grandfather' ],
    ['Son', 'Brother', 'Uncle', 'Great uncle', 'Great, great uncle', 'Great, great, great uncle' ],
    ['Grandson', 'Nephew', 'First cousin', 'First cousin once removed', 'First cousin twice removed', 'First cousin three times removed' ],
    ['Great grandson', 'Great nephew', 'First cousin once removed', 'Second cousin', 'Second cousin once removed', 'Second cousin twice removed' ],
    ['Great, great grandson', 'Great, great nephew', 'First cousin twice removed', 'Second cousin once removed', 'Third cousin', 'Third cousin once removed' ],
    ['Great, great, great grandson', 'Great, great, great nephew', 'First cousin three times removed', 'Second cousin twice removed', 'Third cousin once removed', 'Fourth cousin' ],
  ],
  f => [
    [ undef, 'Mother', 'Grandmother', 'Great grandmother', 'Great, great grandmother', 'Great, great great grandmother' ],
    ['Daughter', 'Sister', 'Aunt', 'Great aunt', 'Great, great aunt', 'Great, great, great aunt' ],
    ['Granddaughter', 'Niece', 'First cousin', 'First cousin once removed', 'First cousin twice removed', 'First cousin three times removed' ],
    ['Great granddaughter', 'Great niece', 'First cousin once removed', 'Second cousin', 'Second cousin once removed', 'Second cousin twice removed' ],
    ['Great, great granddaughter', 'Great, great niece', 'First cousin twice removed', 'Second cousin once removed', 'Third cousin', 'Third cousin once removed' ],
    ['Great, great, great granddaughter', 'Great, great, great niece', 'First cousin three times removed', 'Second cousin twice removed', 'Third cousin once removed', 'Fourth cousin' ],
  ],
};

field $abbr :param = 3;

=head1 Methods

The following methods are defined.

=head2 most_recent_common_ancestor

Given two person objects, returns the person who is the most recent common
ancestor for the given people. When multiple common ancestors exist at the
same distance, returns the one reachable via the fewest total generations
across both people.

=cut

method most_recent_common_ancestor {
  my ($person1, $person2) = @_;

  # Are they the same person?
  return $person1
    if $person1->$identifier_field_name eq $person2->$identifier_field_name;

  my $map1 = $self->_ancestor_map($person1);
  my $map2 = $self->_ancestor_map($person2);

  my ($best_person, $best_total);

  for my $id (keys %$map1) {
    if (exists $map2->{$id}) {
      my $total = $map1->{$id}{distance} + $map2->{$id}{distance};
      if (!defined $best_total || $total < $best_total) {
        $best_total  = $total;
        $best_person = $map1->{$id}{person};
      }
    }
  }

  die "Can't find a common ancestor.\n" unless defined $best_person;

  return $best_person;
}

=head2 _get_parents

Internal method. Given a person object, returns a list of that person's
parents. Uses the C<parents_field_name> method if the person object supports
it; otherwise falls back to the configured C<parent_field_name> method.

=cut

method _get_parents {
  my ($person) = @_;

  if ($person->can($parents_field_name)) {
    return @{ $person->$parents_field_name() };
  }

  my $parent = $person->$parent_field_name;
  return defined $parent ? ($parent) : ();
}

=head2 _ancestor_map

Internal method. Given a person object, returns a hash reference mapping
each ancestor's identifier to a hash containing C<distance> (number of
generations from the given person) and C<person> (the ancestor object).
The person themself is included at distance zero.

=cut

method _ancestor_map {
  my ($person) = @_;

  my %map;
  my @queue = ([$person, 0]);

  while (@queue) {
    my ($current, $dist) = @{ shift @queue };
    my $id = $current->$identifier_field_name;

    next if exists $map{$id};

    $map{$id} = { distance => $dist, person => $current };

    for my $parent ($self->_get_parents($current)) {
      push @queue, [$parent, $dist + 1];
    }
  }

  return \%map;
}

=head2 get_ancestors

Given a person object, returns a list of person objects, one for each
ancestor of the given person. When a person has two parents, all ancestors
from both parent lines are included (breadth-first order).

The first entries in the list will be the person's direct parent(s) and the
last person will be their most distant ancestor.

=cut

method get_ancestors {
  my ($person) = @_;

  my %visited;
  my @ancestors;
  my @queue = ($person);

  while (@queue) {
    my $current = shift @queue;
    for my $parent ($self->_get_parents($current)) {
      my $id = $parent->$identifier_field_name;
      unless ($visited{$id}++) {
        push @ancestors, $parent;
        push @queue, $parent;
      }
    }
  }

  return @ancestors;
}

=head2 get_relationship

Given two person objects, returns a string containing a description of the
relationship between those two people.

=cut

method get_relationship {
  my ($person1, $person2) = @_;

  my ($x, $y) = $self->get_relationship_coords($person1, $person2);

  my $rel;

  if (defined $relationship_table->{$person1->$gender_field_name}[$x][$y]) {
    $rel = $relationship_table->{$person1->$gender_field_name}[$x][$y];
  } else {
    $rel = $relationship_table->{$person1->$gender_field_name}[$x][$y] =
      ucfirst $self->make_rel($person1->$gender_field_name, $x, $y);
  }

  $rel = $self->abbr_rel($rel) if $abbr;

  return $rel;
}

=head2 abbr_rel

Optionally abbreviate a relationship description.

=cut

method abbr_rel {
  my ($rel) = @_;

  return $rel unless $abbr;

  my @greats = $rel =~ /(great)/gi;
  my $count  = @greats;

  return $rel if $count < $abbr;

  $rel =~ s/(great,\s+)+/$count x /i;

  return $rel;
}

=head2 make_rel

Given relationship co-ords and a gender, this will synthesise a relationship
description. This only works because we've hard-coded an initial relationship
table that covers all of the trickier situations.

=cut

method make_rel {
  my ($gender, $x, $y) = @_;

  my %terms = (
    m => {
      child => 'son',
      parent => 'father',
      parent_sibling => 'uncle',
      parent_sibling_child => 'nephew',
    },
    f => {
      child => 'daughter',
      parent => 'mother',
      parent_sibling => 'aunt',
      parent_sibling_child => 'niece',
    },
  );

  if ($x == $y) {
    return num2en_ordinal($x - 1) . ' cousin';
  }

  if ($x == 0) {
    return join(', ', ('great') x ($y - 2)) . ' grand' . $terms{$gender}{parent};
  }

  if ($x == 1) {
    return join(', ', ('great') x ($y - 2)) . ' ' . $terms{$gender}{parent_sibling};
  }

  if ($y == 0) {
    return join(', ', ('great') x ($x - 2)) . ' grand' . $terms{$gender}{child};
  }

  if ($y == 1) {
    return join(', ', ('great') x ($x - 2)) . ' ' . $terms{$gender}{parent_sibling_child};
  }

  if ($x > $y) {
    return num2en_ordinal($y - 1) . ' cousin ' . times_str($x - $y) . ' removed';
  } else {
    return num2en_ordinal($x - 1) . ' cousin ' . times_str($y - $x) . ' removed';
  }

  return 'working on it';
}

=head2 times_str

Given an integer, this method returns a string version for use in a
"removed" cousin relationship, i.e. "once", "twice", "three times", etc.

=cut

sub times_str {
  my ($num) = @_;

  return 'once'  if $num == 1;
  return 'twice' if $num == 2;

  return num2en($num) . ' times';
}

=head2 get_relationship_coords

Given two person objects, returns the "co-ordinates" of the relationship
between them.

The relationship co-ordinates are a pair of integers. The first integer is
the number of generations between the first person and their most recent
common ancestor. The second integer is the number of generations between
the second person and their most recent common ancestor.

When a person has two parents, the shortest path to the common ancestor
is used.

=cut

method get_relationship_coords {
  my ($person1, $person2) = @_;

  # If the two people are the same person, then return (0, 0).
  return (0, 0)
    if $person1->$identifier_field_name eq $person2->$identifier_field_name;

  my $map1 = $self->_ancestor_map($person1);
  my $map2 = $self->_ancestor_map($person2);

  my ($best_i, $best_j, $best_total);

  for my $id (keys %$map1) {
    if (exists $map2->{$id}) {
      my $i     = $map1->{$id}{distance};
      my $j     = $map2->{$id}{distance};
      my $total = $i + $j;
      if (!defined $best_total || $total < $best_total) {
        $best_total = $total;
        $best_i     = $i;
        $best_j     = $j;
      }
    }
  }

  die "Can't work out the relationship.\n" unless defined $best_total;

  return ($best_i, $best_j);
}

=head2 get_relationship_ancestors

Given two people, returns lists of people linking those two people
to their most recent common ancestor.

The return value is a reference to an array containing two array
references. The first referenced array contains the person1 and
all their ancestors up to and including the most recent common
ancestor. The second list does the same for person2.

When a person has two parents, the shortest path to the common ancestor
is used.

=cut

method get_relationship_ancestors {
  my ($person1, $person2) = @_;

  my $mrca = $self->most_recent_common_ancestor($person1, $person2)
    or die "There is no most recent common ancestor\n";

  return [
    $self->_path_to_ancestor($person1, $mrca),
    $self->_path_to_ancestor($person2, $mrca),
  ];
}

=head2 _path_to_ancestor

Internal method. Given a person object and a target ancestor object, returns
an array reference containing the shortest path from the person to the
ancestor (inclusive of both endpoints). Uses breadth-first search so that
the shortest path is always found, even when a person has two parents.

=cut

method _path_to_ancestor {
  my ($person, $target) = @_;

  my $target_id = $target->$identifier_field_name;
  my $person_id = $person->$identifier_field_name;

  return [$person] if $person_id eq $target_id;

  # BFS to find the shortest path
  my @queue   = ([$person]);
  my %visited = ($person_id => 1);

  while (@queue) {
    my $path    = shift @queue;
    my $current = $path->[-1];

    for my $parent ($self->_get_parents($current)) {
      my $parent_id = $parent->$identifier_field_name;
      next if $visited{$parent_id}++;

      my $new_path = [@$path, $parent];
      return $new_path if $parent_id eq $target_id;
      push @queue, $new_path;
    }
  }

  die "No path found to ancestor\n";
}

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 SEE ALSO

perl(1)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2026, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
