#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::X::Form::Wildcard;

# once during application setup phase
my $form = MVC::Neaf::X::Form::Wildcard->new(
    [ [ qr/name\d+/ => qr/...*/ ], ] );

# much later, multiple times
my $checked = $form->validate( {
    name1 => 'foo',
    surname2 => 'bar',
    name5 => 'o',
} );

is_deeply [ sort $checked->fields ], [ qw[ name1 name5 ]],
    "Field names read correctly";
ok !$checked->is_valid, "Data was bad";

is_deeply [ keys %{ $checked->error } ], [ "name5" ], "one bad field";
note "error=", explain $checked->error;

is_deeply $checked->data, { name1 => 'foo' }, "one good field";

is_deeply $checked->raw, { name1 => 'foo', name5 => 'o' },
    "All matching fields in raw";

done_testing;
