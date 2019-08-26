use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

parser

=usage

  # given $data

  $data->parser($string);

  # [,...]

=description

The parser method extracts pod-like sections from a given string and returns an
arrayref of metadata.

=signature

parser(Str $arg1) : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok 'Data::Object::Data', 'parser';

ok 1 and done_testing;
