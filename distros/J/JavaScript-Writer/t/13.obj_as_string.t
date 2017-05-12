#!/usr/bin/env perl

use strict;
use warnings;
use JavaScript::Writer;

use Test::More;

plan tests => 5;


is
    js->obj_as_string({ "foo" => sub { js->alert(42); } }),
    '{"foo":function(){alert(42);}}';

is
    js->obj_as_string(["foo", sub { js->alert(42); }]),
    '["foo",function(){alert(42);}]';

is js->obj_as_string(["foo"]), '["foo"]';

is js->obj_as_string(\ "foo"), "foo";

is js->obj_as_string("foo"), '"foo"';


