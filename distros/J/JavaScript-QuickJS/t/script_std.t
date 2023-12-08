#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new()->std();

my $environ;

$js->set_globals(
    env2perl => sub { $environ = shift },
);

my @env_kv = (
    "on\xe9" => "tw\xf6",
);

my @env_kv_utf8 = @env_kv;
utf8::encode($_) for @env_kv_utf8;

{
    local %ENV = @env_kv_utf8;

    $js->eval( q/
        env2perl(std.getenviron());
    / );

    $js->await();
}

TODO: {
    local $TODO = 'Seems not to work on Windows' if $^O eq 'MSWin32';

    is_deeply(
        $environ,
        { @env_kv },
        'imported `std` and called getenviron() as expected',
    ) or diag explain $environ;
}

done_testing;

1;

