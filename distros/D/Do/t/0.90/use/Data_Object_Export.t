use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Export

=abstract

Data-Object Exportable Functions

=synopsis

  use Data::Object::Export 'cast';

  my $array = cast []; # Data::Object::Array

=description

This package is an exporter that provides various useful utility functions and
function-bundles.

+=head1 EXPORTS

This package can export the following functions.

+=head2 all

  use Data::Object::Export ':all';

The all export tag will export all exportable functions.

+=head2 core

  use Data::Object::Export ':core';

The core export tag will export the exportable functions C<cast>, C<const>,
C<deduce>, C<deduce_deep>, C<deduce_type>, C<detract>, C<detract_deep>,
C<dispatch>, C<dump>, C<immutable>, C<load>, C<prototype>, and C<throw>
exclusively.

+=head2 data

  use Data::Object::Export ':data';

The data export tag will export the exportable functions C<data_any>,
C<data_array>, C<data_code>, C<data_float>, C<data_hash>, C<data_integer>,
C<data_number>, C<data_regexp>, C<data_scalar>, C<data_string>, and
C<data_undef>.

+=head2 plus

  use Data::Object::Export ':plus';

The plus export tag will export the exportable functions C<carp>, C<confess>
C<cluck> C<croak>, C<class_file>, C<class_name>, C<class_path>, C<library>,
C<namespace>, C<path_class>, C<path_name>, C<registry>, and C<reify>.

+=head2 type

  use Data::Object::Export ':type';

The type export tag will export the exportable functions C<type_any>,
C<type_array>, C<type_code>, C<type_float>, C<type_hash>, C<type_integer>,
C<type_number>, C<type_regexp>, C<type_scalar>, C<type_string>, and
C<type_undef>.

+=head2 vars

  use Data::Object::Export ':vars';

The vars export tag will export the exportable variable C<$dispatch>.

=cut

use_ok 'Data::Object::Export';

can_ok 'Data::Object::Export', 'cast';
can_ok 'Data::Object::Export', 'class_file';
can_ok 'Data::Object::Export', 'class_name';
can_ok 'Data::Object::Export', 'class_path';
can_ok 'Data::Object::Export', 'const';
can_ok 'Data::Object::Export', 'data_any';
can_ok 'Data::Object::Export', 'data_array';
can_ok 'Data::Object::Export', 'data_code';
can_ok 'Data::Object::Export', 'data_float';
can_ok 'Data::Object::Export', 'data_hash';
can_ok 'Data::Object::Export', 'data_integer';
can_ok 'Data::Object::Export', 'data_number';
can_ok 'Data::Object::Export', 'data_regexp';
can_ok 'Data::Object::Export', 'data_scalar';
can_ok 'Data::Object::Export', 'data_string';
can_ok 'Data::Object::Export', 'data_undef';
can_ok 'Data::Object::Export', 'deduce';
can_ok 'Data::Object::Export', 'deduce_deep';
can_ok 'Data::Object::Export', 'deduce_type';
can_ok 'Data::Object::Export', 'detract';
can_ok 'Data::Object::Export', 'detract_deep';
can_ok 'Data::Object::Export', 'dispatch';
can_ok 'Data::Object::Export', 'immutable';
can_ok 'Data::Object::Export', 'library';
can_ok 'Data::Object::Export', 'load';
can_ok 'Data::Object::Export', 'namespace';
can_ok 'Data::Object::Export', 'path_class';
can_ok 'Data::Object::Export', 'path_name';
can_ok 'Data::Object::Export', 'prototype';
can_ok 'Data::Object::Export', 'registry';
can_ok 'Data::Object::Export', 'reify';
can_ok 'Data::Object::Export', 'throw';

ok 1 and done_testing;
