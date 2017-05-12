use strict;
use Test::More;

BEGIN {
    if ($^O eq 'MSWin32' or $^O eq 'os2') {
        plan skip_all => "irrelevant on dosish OS";
    }
    $ENV{PWD} = '/tmp'; chdir '/tmp';
};
plan tests => 1;

use Find::Lib;

eval {
    Find::Lib->import('../mylib', 'MyLib', a => 1, b => 42);
};
ok $@, "we die because chdir and PWD are changed";
