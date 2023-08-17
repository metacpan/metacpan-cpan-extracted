#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use MVC::Neaf;

throws_ok {
    neaf 'view';
} qr(two arguments), '0 args = no go';;

throws_ok {
    neaf view => 'foo';
} qr(two arguments), '1 args = no go';

throws_ok {
    neaf view => bar => {};
} qr(must be), 'wrong argument type = no go';

lives_ok {
    neaf view => sub => sub { return 'foobar' };
    is ref neaf->get_view( 'sub' ), 'CODE', 'fetched some code';
    is neaf->get_view( 'sub' )->({}), 'foobar', 'actually that sub';
} 'normal setup with sub';

lives_ok {
    neaf view => tt1 => 'TT';
    isa_ok neaf->get_view( 'tt1' ), 'MVC::Neaf::View::TT';
} 'normal setup with new';

lives_ok {
    neaf view => tt2 => 'TT', EVAL_PERL => 1;
    isa_ok neaf->get_view( 'tt1' ), 'MVC::Neaf::View::TT';
} 'normal setup with new, module already loaded';

# TODO 0.40 loading the same view twice must fail

done_testing;
