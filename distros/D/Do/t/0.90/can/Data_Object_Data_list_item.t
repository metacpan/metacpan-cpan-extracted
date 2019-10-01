use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

list_item

=usage

  =pod attribute

  Attribute #1 content

  =cut

  =pod attribute

  Attribute #2 content

  =cut

  # given $data

  $data->list_item('pod', 'attribute');

  # [,...]

=description

The list_item method returns metadata for the pod-like sections that matches
the given list name and argument.

=signature

list_item(Str $arg1, Str $arg2) : ArrayRef[ArrayRef]

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok "Data::Object::Data", "list_item";

ok 1 and done_testing;
