package JMAP::Validation::Generators::ContactInformation;

use strict;
use warnings;

use JMAP::Validation::Generators::String;
use JSON::PP;
use JSON::Typist;

my %types = (
  emails => [qw{
    personal
    work
    other
  }],
  phones => [qw{
    home
    work
    mobile
    fax
    pager
    other
  }],
  online => [qw{
    uri
    username
    other
  }],
);

sub generate {
  my ($type) = @_;

  my @ContactInformation;

  foreach my $type_value (@{$types{$type} || []}) {
    foreach my $label (JMAP::Validation::Generators::String->generate(), undef) {
      foreach my $isDefault (JSON::PP::true, JSON::PP::false) {
        push @ContactInformation, {
          type      => JSON::Typist::String->new($type_value),
          label     => $label,
          value     => JMAP::Validation::Generators::String->generate(),
          isDefault => $isDefault,
        }
      }
    }
  }

  return @ContactInformation;
}

1;
