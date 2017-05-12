#!/usr/bin/env perl

use strict;
use warnings;
use FindBin::libs;

use Method::Cached::Manager
    -default => {
        class => 'Cache::Memcached::Fast',
        args  => [
            { servers    => [qw/ 127.0.0.1:11211 /] },
        ],
    },
    -domains => {
        'memcached-fast' => {
            class => 'Cache::Memcached::Fast',
            args  => [
                { servers    => [qw/ 127.0.0.1:11211 /] },
            ],
            key_rule      => 'LIST', # SERIALIZE / LIST
        },
        'fastmmap'       => {
            class => 'Cache::FastMmap',
            args  => [
                share_file     => '/tmp/fastmmap.bin',
                unlink_on_exit => 1,
            ],
            key_rule      => 'LIST', # SERIALIZE / LIST
        },
    }, ;

{
    package Dummy;

    use Method::Cached;

    sub fib {
        my $n = shift;
        return $n if $n < 2;
        fib($n - 1) + fib($n - 2);
    }

    sub fib_default :Cached {
        my $n = shift;
        return $n if $n < 2;
        fib_default($n - 1) + fib_default($n - 2);
    }

    sub fib_memcached :Cached('memcached-fast') {
        my $n = shift;
        return $n if $n < 2;
        fib_memcached($n - 1) + fib_memcached($n - 2);
    }

    sub fib_fastmmap :Cached('cache-fastmmap') {
        my $n = shift;
        return $n if $n < 2;
        fib_fastmmap($n - 1) + fib_fastmmap($n - 2);
    }
}

package main;

use Benchmark qw/cmpthese timethese/;

my $num = 13;

my ($fib, $def_fib, $mc_fib, $fm_fib);

sub fib     { $fib     = $num; $fib     = Dummy::fib($fib)              }
sub def_fib { $def_fib = $num; $def_fib = Dummy::fib_default($def_fib)  }
sub mc_fib  { $mc_fib  = $num; $mc_fib  = Dummy::fib_memcached($mc_fib) }
sub fm_fib  { $fm_fib  = $num; $fm_fib  = Dummy::fib_fastmmap($fm_fib)  }

cmpthese(50000, {
    'fib'               => \&fib,
    'C(default)'        => \&def_fib,
    'C(Memcached-Fast)' => \&mc_fib,
    'C(FastMmap)'       => \&fm_fib,
});
