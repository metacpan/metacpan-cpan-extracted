package JMAP::Validation::Generators::File;

use strict;
use warnings;

use JMAP::Validation::Generators::String;
use JSON::Typist;

sub generate {
  my $blobId = 1;

  my @files;

  foreach my $type (JMAP::Validation::Generators::String->generate(), undef) {
    foreach my $name (JMAP::Validation::Generators::String->generate(), undef) {
      foreach my $size (JSON::Typist::Number->new(int(rand(2**32))), undef) {
        push @files, {
          blobId => JMAP::Validation::Generators::String->generate(),
          type   => $type,
          name   => $name,
          size   => $size,
        };

        $blobId++;
      }
    }
  }

  return @files;
}

1;
