use strict;
use warnings;

use Test::More tests => 2;

# proper quoting of params and parsing them

use MIME::Field::ParamVal;

my $field = MIME::Field::ParamVal->parse(
    'inline; filename="f\oo\"bar\"b\az\\\\"'
);

is($field->param('filename'), 'foo"bar"baz\\');
is($field->stringify, 'inline; filename="foo\\"bar\\"baz\\\\"');
