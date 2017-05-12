package Test::JSON::TypeInference::Matcher;
use strict;
use warnings;

use Exporter 'import';
use Test::Deep ();

use JSON::TypeInference::Type::Array;
use JSON::TypeInference::Type::Boolean;
use JSON::TypeInference::Type::Null;
use JSON::TypeInference::Type::Number;
use JSON::TypeInference::Type::Object;
use JSON::TypeInference::Type::String;
use JSON::TypeInference::Type::Union;

our @EXPORT = qw(
  number string null boolean array object union unknown maybe
);

sub unknown () {
  return JSON::TypeInference::Type::Unknown->new;
}

sub number () {
  return JSON::TypeInference::Type::Number->new;
}

sub string () {
  return JSON::TypeInference::Type::String->new;
}

sub null () {
  return JSON::TypeInference::Type::Null->new;
}

sub boolean () {
  return JSON::TypeInference::Type::Boolean->new;
}

sub array ($) {
  my ($type) = @_;
  return Test::Deep::isa('JSON::TypeInference::Type::Array') & Test::Deep::methods(element_type => $type);
}

sub object (%) {
  my (%args) = @_;
  return Test::Deep::isa('JSON::TypeInference::Type::Object') & Test::Deep::methods(properties => \%args);
}

sub union (@) {
  my (@types) = @_;
  return Test::Deep::isa('JSON::TypeInference::Type::Union') & Test::Deep::methods(types => \@types);
}

sub maybe ($) {
  my ($type) = @_;
  return Test::Deep::isa('JSON::TypeInference::Type::Maybe') & Test::Deep::methods(type => $type);
}

1;
