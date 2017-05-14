#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use JMAP::Validation::Checks::Contact;
use JMAP::Validation::Generators::SetError;
use JMAP::Validation::Generators::String;
use Test2::Bundle::Extended;

my $created_objects = {};

for (1..3) {
  $created_objects->{JMAP::Validation::Generators::String->generate()} = {
    id => JMAP::Validation::Generators::String->generate(),
  };
}

my $updated_objects = [
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
];

my $destroyed_objects = [
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
  JMAP::Validation::Generators::String->generate(),
];

my %notType_types = (
  created   => [qw{invalidProperties}],
  updated   => [qw{invalidProperties notFound}],
  destroyed => [qw{notFound}],
);

my %notTypes;

foreach my $notType_type (keys %notType_types) {
  foreach my $subtype (@{$notType_types{$notType_type}}) {
    $notTypes{$notType_type}{JMAP::Validation::Generators::String->generate()}
      = JMAP::Validation::Generators::SetError::generate($subtype)->[0];
  }
}

foreach my $oldState (JMAP::Validation::Generators::String->generate(), undef) {
  foreach my $created ($created_objects, {}) {
    foreach my $updated ($updated_objects, []) {
      foreach my $destroyed ($destroyed_objects, []) {
        foreach my $notCreated ($notTypes{created}, {}) {
          foreach my $notUpdated ($notTypes{updated}, {}) {
            foreach my $notDestroyed ($notTypes{destroyed}, {}) {
              is(
                {
                  accountId    => JMAP::Validation::Generators::String->generate(),
                  oldState     => $oldState,
                  newState     => JMAP::Validation::Generators::String->generate(),
                  created      => $created,
                  updated      => $updated,
                  destroyed    => $destroyed,
                  notCreated   => $notCreated,
                  notUpdated   => $notUpdated,
                  notDestroyed => $notDestroyed,
                },
                $JMAP::Validation::Checks::Contact::is_contactsSet,
              );
            }
          }
        }
      }
    }
  }
}

done_testing();
