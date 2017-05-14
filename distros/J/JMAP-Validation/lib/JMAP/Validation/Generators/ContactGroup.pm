package JMAP::Validation::Generators::ContactGroup;

use strict;
use warnings;

use JMAP::Validation::Generators::String;
use JSON::Typist;

sub generate {
  my (%args) = @_;

  my @contactIds
    = map { JMAP::Validation::Generators::String->generate() }
        1..2;

  my @ContactGroups;

  foreach my $contactIds ([@contactIds], []) {
    push @ContactGroups, {
      ($args{no_id} ? () : (id => JMAP::Validation::Generators::String->generate())),
      name       => JMAP::Validation::Generators::String->generate(),
      contactIds => $contactIds,
    };
  }

  return @ContactGroups;
}

1;
