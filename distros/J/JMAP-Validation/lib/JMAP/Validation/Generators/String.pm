package JMAP::Validation::Generators::String;

use strict;
use warnings;

use Data::Fake::Text;
use JSON::PP;
use JSON::Typist;

sub generate {
  return JSON::Typist::String->new(join '', fake_words(4)->());
}

1;
