use utf8;
use strict;
use warnings;
use Test::More;
use EnvDir 'envdir', -clean;

ok( ( not exists $ENV{FOO} ), 'FOO does not exist' );
my $PATH = $ENV{PATH};
$ENV{CLEAN} = 0;
{
    my $envdir = envdir('t/env');
    is $ENV{FOO}, 'foo', 'Foo exists';
    isnt $ENV{PATH}, $PATH, 'PATH is overrided';
    ok( (not exists $ENV{CLEAN}), 'CLEAN is removed');
}

ok( ( not exists $ENV{FOO} ), 'FOO does not exist' );
is $ENV{PATH}, $PATH, 'PATH is reverted';
is $ENV{CLEAN}, 0, 'CLEAN is reverted';

done_testing;


