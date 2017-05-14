package JMAP::Validation::Generators::Contact;

use strict;
use warnings;

use Data::Fake::Dates;
use JMAP::Validation::Generators::Address;
use JMAP::Validation::Generators::ContactInformation;
use JMAP::Validation::Generators::File;
use JMAP::Validation::Generators::String;
use JSON::PP;
use JSON::Typist;

sub generate {
  my ($type) = @_;

  my @avatars = (
    JMAP::Validation::Generators::File::generate(),
    undef,
  );

  my %ContactInformation
    = map { $_ => [JMAP::Validation::Generators::ContactInformation::generate($_)] }
        qw{emails phones online};

  my @addresses = (
    [JMAP::Validation::Generators::Address::generate()],
    [],
  );

  my @Contacts;

  foreach my $isFlagged (JSON::PP::true, JSON::PP::false) {
    foreach my $avatar (@avatars) {
      foreach my $email (@{$ContactInformation{emails}}) {
        foreach my $phone (@{$ContactInformation{phones}}) {
          foreach my $online (@{$ContactInformation{online}}) {
            foreach my $address (@addresses) {
              push @Contacts, {
                id          => JMAP::Validation::Generators::String->generate(),
                isFlagged   => $isFlagged,
                avatar      => $avatar,
                prefix      => JMAP::Validation::Generators::String->generate(),
                firstName   => JMAP::Validation::Generators::String->generate(),
                lastName    => JMAP::Validation::Generators::String->generate(),
                suffix      => JMAP::Validation::Generators::String->generate(),
                nickname    => JMAP::Validation::Generators::String->generate(),
                birthday    => JSON::Typist::String->new(fake_past_datetime('%Y-%m-%d')->()),
                anniversary => JSON::Typist::String->new(fake_past_datetime('%Y-%m-%d')->()),
                company     => JMAP::Validation::Generators::String->generate(),
                department  => JMAP::Validation::Generators::String->generate(),
                jobTitle    => JMAP::Validation::Generators::String->generate(),
                emails      => $ContactInformation{emails},
                phones      => $ContactInformation{phones},
                online      => $ContactInformation{online},
                addresses   => $address,
                notes       => JMAP::Validation::Generators::String->generate(),
              };
            }
          }
        }
      }
    }
  }

  return @Contacts;
}

1;
