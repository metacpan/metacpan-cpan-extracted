#!/usr/bin/perl

use String::CRC32 qw{crc32};
use Memcached::Client::Selector::Traditional;
use Test::More tests => 27;

sub check ($$) {
    my ($key, $count) = @_;
    my $hash = crc32 ($key) >> 16 & 0x7fff;
    my $bucket = $hash % $count;
    #diag sprintf "String %s has hash %s and bucket %s of %s", $key, $hash, $bucket, $count;
}

my $selector;

isa_ok ($selector = Memcached::Client::Selector::Traditional->new,
        'Memcached::Client::Selector::Traditional',
        'A new instance of the class');
is ($selector->get_server,
    undef,
    '->get_server should return undef since we have no server list');
is ($selector->set_servers (['localhost:11211']),
    1,
    'Give it a list of a single server');
is ($selector->get_server,
    undef,
    '->get_server should return undef since we gave it no key');
is ($selector->get_server (1),
    'localhost:11211',
    '->get_server should return localhost:11211 since that is the only server we have');

isa_ok ($selector = Memcached::Client::Selector::Traditional->new,
        'Memcached::Client::Selector::Traditional',
        'A new instance of the class');
is ($selector->set_servers (['localhost:11211', 'localhost:11211']),
    1,
    'Give it a list of two duplicate entries');
is ($selector->get_server ("Some wacky string"),
    'localhost:11211',
    '->get_server should return localhost:11211 since that is the only server we (effectively) have');

isa_ok ($selector = Memcached::Client::Selector::Traditional->new,
        'Memcached::Client::Selector::Traditional',
        'A new instance of the class');
is ($selector->set_servers (['localhost:11211', 'localhost:11212']),
    1,
    'Give it a list with 2 servers and no dups');
check "Some wacky string", 2;
is ($selector->get_server ("Some wacky string"),
    'localhost:11212',
    '->get_server should return localhost:11212');
check "Some wackier string", 2;
is ($selector->get_server ("Some wackier string"),
    'localhost:11211',
    '->get_server should return localhost:11212');

isa_ok ($selector = Memcached::Client::Selector::Traditional->new,
        'Memcached::Client::Selector::Traditional',
        'A new instance of the class');
is ($selector->set_servers (['localhost:11211', 'localhost:11212', 'localhost:11213']),
    1,
    'Give it a list with 3 servers and no dups');
check "Some wacky string", 3;
is ($selector->get_server ("Some wacky string"),
    'localhost:11211',
    '->get_server should return localhost:11211');
check "Some llama string", 3;
is ($selector->get_server ("Some llama string"),
    'localhost:11212',
    '->get_server should return localhost:11212');
check "Some ghastly string", 3;
is ($selector->get_server ("Some ghastly string"),
    'localhost:11213',
    '->get_server should return localhost:11213');

isa_ok ($selector = Memcached::Client::Selector::Traditional->new ([['localhost:11211' => 2], 'localhost:11212']),
        'Memcached::Client::Selector::Traditional',
        'A new instance of the class');
is ($selector->set_servers ([['localhost:11211' => 2], 'localhost:11212']),
    1,
    'Give it a list with 2 servers with unequal weights');
check "Some wacky string", 3;
is ($selector->get_server ("Some wacky string"),
    'localhost:11211',
    '->get_server should return localhost:11211');
check "Some llama string", 3;
is ($selector->get_server ("Some llama string"),
    'localhost:11211',
    '->get_server should return localhost:11211');
check "Some ghastly string", 3;
is ($selector->get_server ("Some ghastly string"),
    'localhost:11212',
    '->get_server should return localhost:11212');

isa_ok ($selector = Memcached::Client::Selector::Traditional->new ([['localhost:11211' => 1], ['localhost:11212' => 2]]),
        'Memcached::Client::Selector::Traditional',
        'A new instance of the class');
is ($selector->set_servers ([['localhost:11211' => 1], ['localhost:11212' => 2]]),
    1,
    'Give it a list with 2 servers with unequal weights');
check "Some wacky string", 3;
is ($selector->get_server ("Some wacky string"),
    'localhost:11211',
    '->get_server should return localhost:11211');
check "Some llama string", 3;
is ($selector->get_server ("Some llama string"),
    'localhost:11212',
    '->get_server should return localhost:11212');
check "Some ghastly string", 3;
is ($selector->get_server ("Some ghastly string"),
    'localhost:11212',
    '->get_server should return localhost:11212');
