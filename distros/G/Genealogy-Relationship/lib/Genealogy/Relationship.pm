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
The identifier can be a string or a number.

=item * gender

This method should return the gender of the current person. It should be
the character 'm' or 'f'.

=back

=head2 Note

THe objects that you use with this class can actually have different names
for these methods. C<parent>, C<id> and C<gender> are the default names
used by this module, but you can change them by passing the correct names
to the constructor. For example:

    my $rel = Genealogy::Relationship->new(
      parent_field_name     => 'progenitor',
      identifier_field_name => 'person_id',
      gender_field_name     => 'sex',
    );

=head2 Limitations

This module was born out of a need I had while creating
L<https://lineofsuccession.co.uk/>. This leads to a limitation
that I hope to remove at a later date.

=over 4

=item *

Each person in the tree is expected to have only one parent. This is, of
course, about half of the usual number. It's like that because for the line
of succession I'm tracing bloodlines and only one parent is ever going to
be significant.

I realise that this is a significant limitation and I'll be thinking about
how to fix it as soon as possible.

=back

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

use v5.38;
use feature 'class';
no warnings 'experimental::class';

class Genealogy::Relationship;

use List::Util qw[first];
use Lingua::EN::Numbers qw[num2en num2en_ordinal];

our $VERSION = '1.0.2';

field $parent_field_name :param = 'parent';
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
ancestor for the given people.

=cut

method most_recent_common_ancestor {
  my ($person1, $person2) = @_;

  # Are they the same person?
  return $person1
    if $person1->$identifier_field_name eq $person2->$identifier_field_name;

  my @ancestors1 = ($person1, $self->get_ancestors($person1));
  my @ancestors2 = ($person2, $self->get_ancestors($person2));

  for my $anc1 (@ancestors1) {
    for my $anc2 (@ancestors2) {
      return $anc1
        if $anc1->$identifier_field_name eq $anc2->$identifier_field_name;
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

method get_ancestors {
  my ($person) = @_;

  my @ancestors = ();

  while (defined ($person = $person->$parent_field_name)) {
    push @ancestors, $person;
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

=cut

method get_relationship_coords {
  my ($person1, $person2) = @_;

  # If the two people are the same person, then return (0, 0).
  return (0, 0)
    if $person1->$identifier_field_name eq $person2->$identifier_field_name;

  my @ancestors1 = ($person1, $self->get_ancestors($person1));
  my @ancestors2 = ($person2, $self->get_ancestors($person2));

  for my $i (0 .. $#ancestors1) {
    for my $j (0 .. $#ancestors2) {
      return ($i, $j)
        if $ancestors1[$i]->$identifier_field_name
          eq $ancestors2[$j]->$identifier_field_name;
    }
  }

  die "Can't work out the relationship.\n";
}

=head2 get_relationship_ancestors

Given two people, returns lists of people linking those two people
to their most recent common ancestor.

The return value is a reference to an array containing two array
references. The first references array contains the person1 and
all their ancestors up to an including the most recent common
ancestor. The second list does the same for person2.

=cut

method get_relationship_ancestors {
  my ($person1, $person2) = @_;

  my $mrca = $self->most_recent_common_ancestor($person1, $person2)
    or die "There is no most recent common ancestor\n";

  my (@ancestors1, @ancestors2);

  for ($person1, $self->get_ancestors($person1)) {
    push @ancestors1, $_;
    last if $_->$identifier_field_name eq $mrca->$identifier_field_name;
  }

  for ($person2, $self->get_ancestors($person2)) {
    push @ancestors2, $_;
    last if $_->$identifier_field_name eq $mrca->$identifier_field_name;
  }

  return [ \@ancestors1, \@ancestors2 ];
}

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 SEE ALSO

perl(1)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2023, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
