package JMAP::Validation::Generators::SetError;

use strict;
use warnings;

use JMAP::Validation::Generators::String;
use JSON::Typist;

my %types = (
  invalidArguments => {
    description => JMAP::Validation::Generators::String->generate(),
  },
  invalidProperties => {
    properties  => [],
    description => JMAP::Validation::Generators::String->generate(),
  },
  (
    map { $_ => undef }
      qw{
        accountReadOnly
        fromAccountNoMail
        fromAccountNotFound
        invalidMailboxes
        maxQuotaReached
        notFound
        stateMismatch
        toAccountNoMail
        toAccountNotFound
      }
  ),
);

sub generate {
  my (@types) = @_;

  my @SetErrors;

  foreach my $type (@types ? @types : (keys %types)) {
    push @SetErrors, {
      type => JSON::Typist::String->new($type),
      ($types{$type} ? (%{$types{$type}}) : ()),
    };
  }

  return \@SetErrors;
}

1;
