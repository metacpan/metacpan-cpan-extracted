use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::String::Func::Render

=abstract

Data-Object String Function (Render) Class

=synopsis

  use Data::Object::String::Func::Render;

  my $func = Data::Object::String::Func::Render->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=library

Data::Object::Library

=attributes

arg1(StringLike, req, ro)
arg2(HashLike, opt, ro)

=description

Data::Object::String::Func::Render is a function object for
Data::Object::String.

=cut

use_ok "Data::Object::String::Func::Render";

ok 1 and done_testing;
