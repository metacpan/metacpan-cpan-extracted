use strict;
use warnings;
use Test::More;
use EnvDir -autoload => 't/env-clean', -clean;

is $ENV{PATH}, '/bin:/usr/bin', 'set default value to PATH';
is $ENV{FOO},  'foo',           'env-clean/Foo ok';

done_testing;
