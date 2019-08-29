use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code::Func';
use_ok 'Data::Object::Code::Func::Call';
use_ok 'Data::Object::Code::Func::Compose';
use_ok 'Data::Object::Code::Func::Conjoin';
use_ok 'Data::Object::Code::Func::Curry';
use_ok 'Data::Object::Code::Func::Defined';
use_ok 'Data::Object::Code::Func::Disjoin';
use_ok 'Data::Object::Code::Func::Next';
use_ok 'Data::Object::Code::Func::Rcurry';

ok 1 and done_testing;
