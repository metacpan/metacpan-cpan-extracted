use utf8;
use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{EMPTY} = 'this value will be deleted soon';
}

use EnvDir -autoload => 't/env';

is $ENV{FOO},  'foo',      'env/FOO ok';
is $ENV{PATH}, '/env/bin', 'evn/PATH ok';
ok( ( not exists $ENV{EMPTY}) , 'EMPTY key is deleted');
ok( ( not exists $ENV{'.IGNORE'} ), 'dotfile is ignored' );

done_testing;
