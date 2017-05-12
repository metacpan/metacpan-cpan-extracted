use utf8;
use strict;
use warnings;
use Test::More;
use EnvDir 'envdir';

ok( ( not exists $ENV{FOO} ), 'FOO does not exist' );
my $PATH = $ENV{PATH};

{
    my $envdir = envdir('t/env');
    is $ENV{FOO}, 'foo', 'Foo exists';
    isnt $ENV{PATH}, $PATH, 'PATH is overrided';
}

ok( ( not exists $ENV{FOO} ), 'FOO does not exist' );
is $ENV{PATH}, $PATH, 'PATH is reverted';

done_testing;

