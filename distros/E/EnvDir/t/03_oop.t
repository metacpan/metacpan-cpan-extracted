use utf8;
use strict;
use warnings;
use Test::More;
use EnvDir;

my $PATH = $ENV{PATH};
my $envdir = EnvDir->new;
{
    my $guard = $envdir->envdir('t/env');

    my $PATH2 = $ENV{PATH};
    is $PATH2, '/env/bin', 'PATH=/env/bin';
    isnt $PATH2, $PATH, 'PATH is overrided';

    {
        my $guard = $envdir->envdir('t/env2');
        is $ENV{PATH}, '/env2/bin', 'PATH=/env2/bin';
        isnt $ENV{PATH}, $PATH2, 'PATH is overrided again';
    }

    is $PATH2, '/env/bin', 'PATH is reverted';
}

is $ENV{PATH}, $PATH, 'PATH is reverted';

done_testing;

