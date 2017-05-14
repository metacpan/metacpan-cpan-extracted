package JMAP::Validation::Generators::Address;

use strict;
use warnings;

use JMAP::Validation::Generators::String;
use JSON::PP;
use JSON::Typist;

sub generate {
  my @Addresses;

  foreach my $type (qw{home work billing postal other}) {
    foreach my $label (JMAP::Validation::Generators::String->generate(), undef) {
      foreach my $isDefault (JSON::PP::true, JSON::PP::false) {
        push @Addresses, {
          type      => JSON::Typist::String->new($type),
          label     => $label,
          street    => JMAP::Validation::Generators::String->generate(),
          locality  => JMAP::Validation::Generators::String->generate(),
          region    => JMAP::Validation::Generators::String->generate(),
          postcode  => JMAP::Validation::Generators::String->generate(),
          country   => JMAP::Validation::Generators::String->generate(),
          isDefault => $isDefault,
        };
      }
    }
  }

  return @Addresses;
}

1;
