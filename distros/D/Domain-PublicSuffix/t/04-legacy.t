#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use Domain::PublicSuffix;

my $ps = Domain::PublicSuffix->new({
    'dataFile' => 'effective_tld_names.dat'
});
is( $ps->getRootDomain('google.com'), 'google.com', 'compatibility' );
is( $ps->tld(), 'com',                            , 'compatibility-tld' );

done_testing();

1;
