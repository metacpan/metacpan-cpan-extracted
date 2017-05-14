package JMAP::Validation::Generators;

use strict;
use warnings;

use JSON::PP;
use JSON::Typist;
use JMAP::Validation::Generators::String;

sub true {
  return JSON::PP::true;
}

sub false {
  return JSON::PP::false;
}

sub negative_int {
  return JSON::Typist::Number->new(0-int(rand 2**64));
}

sub negative_real {
  return JSON::Typist::Number->new(0-(rand 2**64));
}

sub zero {
  return JSON::Typist::Number->new(0);
}

sub int {
  return JSON::Typist::Number->new(int(rand 2**64));
}

sub real {
  return JSON::Typist::Number->new(rand 2**64);
}

sub string {
  return JMAP::Validation::Generators::String->generate();
}

1;
