#!env perl

use strict;use warnings;

use lib '../lib';
use Test::More;

use_ok('IPC::Transit::Router', 'troute', 'troute_config');
use_ok('IPC::Transit');

my $test_queue_name = 'tr_test_queue_name';
ok (troute_config({
    routes => [
        {   match => {
                a => 'b',
            },
            forwards => [
                {   qname => $test_queue_name, }
            ],
            transform => {
                x => 'y',
            },
        }
    ],
}), 'successful config');

ok troute({a => 'b', c => 'd'}), 'successful send';

ok ((my $ret = IPC::Transit::receive(qname => $test_queue_name, nonblock => 1)), 'successful receive');
ok $ret->{a} eq 'b', 'received over route: a';
ok $ret->{c} eq 'd', 'received over route: c';
ok $ret->{x} eq 'y', 'received over route: transform';
done_testing();
