#!/usr/bin/env perl

use strict;
use Test::More tests => 7;

{
    use Method::Cached::Manager;
    is_deeply(
        Method::Cached::Manager->default_domain,
        {
            class => 'Cache::FastMmap',
        }
    );
}

{
    my $apps_1 = {
        class => 'Cache::FastMmap',
        args  => [
            share_file     => '/tmp/apps1_cache.bin',
            unlink_on_exit => 1,
        ],
        key_rule      => 'HASH',
    };
    my $apps_2 = {
        class => 'Cache::FastMmap',
        args  => [
            share_file     => '/tmp/apps2_cache.bin',
            unlink_on_exit => 1,
        ],
        key_rule      => [qw/PER_OBJECT HASH/],
    };
    Method::Cached::Manager->import(-domains => {
        apps_1 => $apps_1,
        apps_2 => $apps_2,
    });
    is_deeply(Method::Cached::Manager->get_domain('apps_1'), $apps_1);
    is_deeply(Method::Cached::Manager->get_domain('apps_2'), $apps_2);
}

{
    eval { Method::Cached::Manager->import(-domains => []) };
    like $@, qr/^-domains option should be a hash reference/;
}

{
    eval { Method::Cached::Manager->import(-default => 0) };
    like $@, qr/^-default option should be a hash reference/;
}

{
    eval { Method::Cached::Manager->import(-default => { class => 'B' }) };
    like $@, qr/^storage-class needs the following methods:/;
}

{
    eval { Method::Cached::Manager->import(-default => { class => 'Dummy' . time }) };
    like $@, qr/^Can't load module:/;
}
