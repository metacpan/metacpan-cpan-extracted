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

    my $common_ancestor = $rel->get_most_recent_common_ancestor(
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

=item * parent

This method should return the object which is the parent of the current
person.

=item * id

This method should return a unique identifier for the current person.
The identifier should be a number.

=item * gender

This method should return the gender of the current person. It should be
the character 'm' or 'f'.

=back

=head2 Limitations

This module was born out of a need I had while creating
L<https://lineofsuccession.co.uk/>. This leads to a couple of limitations
that I hope to remove at a later date.

=over 4

=item 1

Each person in the tree is expected to have only one parent. This is, of
course, about half of the usual number. It's like that because for the line
of succession I'm tracing bloodlines and only one parent is ever going to
be significant.

I realise that this is a significant limitation and I'll be thinking about
how to fix it as soon as possible.

=item 2

The table that I use to generate the relationship names only goes back five
generations - that's to fourth cousins (people who share great, great,
great grandparents with each other).

This has, so far, been enough for my purposes, but I realise that more
coverage would be useful. I should probably move away from a table-based
approach and find a way to calculate the relationship names.

=back

=head2 Caching

Calculating relationship names isn't at all different. But there can be a lot
of (simple and repetitive) work involved. This is particularly true if your
objects are based on database tables (as I found to my expense).

If you're calculating a lot of relationships, then you should probably
consider putting a caching layer in front of C<get_relationship>.

=cut

package Genealogy::Relationship;

use Moo;
use Types::Standard qw[Str HashRef];
use List::Util qw[first];
use List::MoreUtils qw[firstidx];

our $VERSION = '0.0.5';

has parent_field_name => (
  is => 'ro',
  isa => Str,
  default => 'parent',
);

has identifier_field_name => (
  is => 'ro',
  isa => Str,
  default => 'id',
);

has gender_field_name => (
  is => 'ro',
  isa => Str,
  default => 'gender',
);

has relationship_table => (
  is => 'ro',
  isa => HashRef,
  builder => '_build_relationship_table',
);

sub _build_relationship_table {
  return {
    m => [
    [ undef, 'Father', 'Grandfather', 'Great grandfather', 'Great, great grandfather', 'Great, great, great grandfather' ],
    ['Son', 'Brother', 'Uncle', 'Great uncle', 'Great, great uncle', 'Great, great, great uncle' ],
    ['Grandson', 'Nephew', 'First cousin', 'First cousin once removed', 'First cousin twice removed', 'First cousin three times removed' ],
    ['Great grandson', 'Great nephew', 'First cousin once removed', 'Second cousin', 'Second cousin once removed', 'Seconc cousin twice removed' ],
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
}

=head1 Methods

The following methods are defined.

=head2 most_recent_common_ancestor

Given two person objects, returns the person who is the most recent common
ancestor for the given people.

=cut

sub most_recent_common_ancestor {
  my $self = shift;
  my ($person1, $person2) = @_;

  # Are they the same person?
  return $person1 if $person1->id == $person2->id;

  my @ancestors1 = ($person1, $self->get_ancestors($person1));
  my @ancestors2 = ($person2, $self->get_ancestors($person2));

  for my $anc1 (@ancestors1) {
    for my $anc2 (@ancestors2) {
      return $anc1 if $anc1->id == $anc2->id;
    }
  }

  die "Can't find a common ancestor.\n";
}

=head2 get_ancestors

Given a person object, returns a list of person objects, one for each
ancestor of the given person.

The first person in the list will be the person's parent and the last person
will be their most distant ancestor.

=cut

sub get_ancestors {
  my $self = shift;
  my ($person) = @_;

  my @ancestors = ();

  while (defined ($person = $person->parent)) {
    push @ancestors, $person;
  }

  return @ancestors;
}

=head2 get_relationship

Given two person objects, returns a string containing a description of the
relationship between those two people.

=cut

sub get_relationship {
  my $self = shift;
  my ($person1, $person2) = @_;

  my ($x, $y) = $self->get_relationship_coords($person1, $person2);

  return $self->relationship_table->{$person1->gender}[$x][$y];
}

=head2 get_relationship_coords

Given two person objects, returns the "co-ordinates" of the relationship
between them.

The relationship co-ordinates are a pair of integers. The first integer is
the number of generations between the first person and their most recent
common ancestor. The second integer is the number of generations between
the second person and their most recent common ancestor.

=cut

sub get_relationship_coords {
  my $self = shift;
  my ($person1, $person2) = @_;

  # If the two people are the same person, then return (0, 0).
  return (0, 0) if $person1->id == $person2->id;

  my @ancestors1 = ($person1, $self->get_ancestors($person1));
  my @ancestors2 = ($person2, $self->get_ancestors($person2));

  for my $i (0 .. $#ancestors1) {
    for my $j (0 .. $#ancestors2) {
      return ($i, $j) if $ancestors1[$i]->id == $ancestors2[$j]->id;
    }
  }

  die "Can't work out the relationship.\n";
}

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 SEE ALSO

perl(1)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2020, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
