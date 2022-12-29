#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use JSON::PP;

use Linux::NFTables;

my $nft = Linux::NFTables->new();
isa_ok( $nft, 'Linux::NFTables', 'new() return' );

SKIP: {
    skip 'Must be root to test commands', 1 if $>;

    my $out = $nft->run_cmd('list tables');
    unlike($out, qr<\[>, '`list tables` - default setup');
}

my $nft2 = $nft->set_output_options('json');
is($nft2, $nft, 'set_output_options() returns the same reference');

SKIP: {
    skip 'Must be root to test commands', 1 if $>;

    my $out = $nft->run_cmd('list tables');
    my $parsed = JSON::PP::decode_json($out);

    cmp_deeply(
        $parsed,
        {
            nftables => superbagof(),
        },
        'JSON return parses',
    );
}

done_testing;
