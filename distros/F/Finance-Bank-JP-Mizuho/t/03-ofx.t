use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Test::More;
use Config::Pit;

my $config;

BEGIN {
    my $config_name = $ENV{MIZUHO_TEST_CONFIG} || 'web.ib.mizuhobank.co.jp';
    $config = pit_get($config_name);
    plan skip_all => 'No config' unless $config && $config->{consumer_id};
    use_ok 'Finance::Bank::JP::Mizuho';
}

SKIP: {
    my $m = Finance::Bank::JP::Mizuho->new(%$config);
    
    skip 'Login failure', 4 unless $m->login;

    eval {
    
        like $m->host, qr{^web\d*\.ib\.mizuhobank\.co\.jp$}, 'host';
        ok @{ $m->accounts }, 'accounts are more than 0';
        
        ok $m->get_raw_ofx( $m->accounts->[0], $m->SAME_AS_LAST ), 'Raw OFX';
        is ref $m->get_ofx( $m->accounts->[0], $m->SAME_AS_LAST ), 'ARRAY', 'OFX is an ARRAY';

    };

    $m->logout;

    fail $@ if $@;
    
}

done_testing;
