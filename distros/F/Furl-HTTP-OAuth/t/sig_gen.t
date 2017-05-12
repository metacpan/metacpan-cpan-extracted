#!/usr/bin/env perl

use warnings;
use strict;
use Test::More qw/no_plan/;

BEGIN { use_ok 'Furl::HTTP::OAuth' }

my $furl = Furl::HTTP::OAuth->new;
my $uri = URI->new('http://metacpan.org/search?q=Foo');

sub run_tests {
    test_sha1_sig();
    test_plain_sig();
}

sub test_sha1_sig {
    my %args = (
        consumer_key => 'consumer_key',
        consumer_secret => 'consumer_secret',
        token => 'token',
        token_secret => 'token_secret',
        signature_method => 'HMAC-SHA1',
        method => 'GET',
        uri => $uri,
        timestamp => &{$furl->timestamp},
        nonce => &{$furl->nonce}
    );

    my $orig_sig = $furl->_gen_sha1_sig(%args);

    # test same parameters
    ok($orig_sig, 'Generated orig sig');
    is($orig_sig, $furl->_gen_sha1_sig(%args), 'Same timestamp and nonce -> same sig');

    # change uri param
    $uri->query_form({ 'q' => 'Bar' });
    isnt($orig_sig, $furl->_gen_sha1_sig(%args), 'Diff query -> diff sig');

    # change timestamp
    $uri->query_form({ 'q' => 'Foo' });
    $args{timestamp} += 1;
    isnt($orig_sig, $furl->_gen_sha1_sig(%args), 'Diff timestamp -> diff sig');

    # change nonce
    $args{timestamp} -= 1;
    $args{nonce} .= 'a';
    isnt($orig_sig, $furl->_gen_sha1_sig(%args), 'Diff nonce -> diff sig');
}

sub test_plain_sig {
}

run_tests();
