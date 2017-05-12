#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Domain::PublicSuffix') };

my $ps = Domain::PublicSuffix->new();

is( ref($ps), 'Domain::PublicSuffix',                       , 'create-object' );
is( $ps->get_root_domain('google.com'), 'google.com'        , 'root-to-root-com' );
is( $ps->tld(), 'com',                                      , 'root-to-root-com-tld' );

is( $ps->get_root_domain('www.google.com'), 'google.com'    , 'www-to-root-com' );
is( $ps->tld(), 'com',                                      , 'root-to-root-com-tld' );

is( $ps->get_root_domain('www.google.co.uk'), 'google.co.uk', 'www-to-root-co-uk' );
is( $ps->tld(), 'uk',                                       , 'root-to-root-co-uk-tld' );
is( $ps->suffix(), 'co.uk',                                 , 'root-to-root-co-uk-etld' );

is( $ps->get_root_domain('www.0.com'), '0.com'              , '0.com' );
is( $ps->tld(), 'com',                                      , '0.com-tld' );

is( $ps->get_root_domain('not_valid_at_all'), undef         , 'invalid-domain' );
is( $ps->error, 'Malformed domain',                         , 'domain-error' );

$ps = Domain::PublicSuffix->new({ 'use_default' => 1 });

is( ref($ps), 'Domain::PublicSuffix',                       , 'create-object' );
is( $ps->get_root_domain('google.com'), 'google.com'        , 'root-to-root-com' );
is( $ps->tld(), 'com',                                      , 'domain-error' );

$ps = Domain::PublicSuffix->new({ 
    'data_file' => 'effective_tld_names.dat'
});

is( ref($ps), 'Domain::PublicSuffix',                       , 'create-external-object' );
is( $ps->get_root_domain('www.domain.me'), 'domain.me'      , 'external-me' );
is( $ps->tld(), 'me',                                       , 'external-me-tld' );

done_testing();

1;
