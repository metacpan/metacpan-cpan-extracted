use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Undef::Func';
use_ok 'Data::Object::Undef::Func::Defined';
use_ok 'Data::Object::Undef::Func::Eq';
use_ok 'Data::Object::Undef::Func::Gt';
use_ok 'Data::Object::Undef::Func::Ge';
use_ok 'Data::Object::Undef::Func::Lt';
use_ok 'Data::Object::Undef::Func::Le';
use_ok 'Data::Object::Undef::Func::Ne';

ok 1 and done_testing;
