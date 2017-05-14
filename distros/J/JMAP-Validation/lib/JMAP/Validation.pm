package JMAP::Validation;
# ABSTRACT: Validation checking for JMAP

use Test2::Bundle::Extended;

use Test2::Compare qw{
  compare
  strict_convert
};

sub validate {
  my ($got, $expected) = @_;

  return !compare($got, $expected, \&strict_convert);
}

1;
