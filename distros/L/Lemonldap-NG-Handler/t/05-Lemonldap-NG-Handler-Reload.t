# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler-Vhost.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package My::Package;

use Test::More tests => 6;

BEGIN {
    use_ok('Lemonldap::NG::Handler::Main');
    use_ok('Lemonldap::NG::Handler::Reload');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $globalinit;

open STDERR, '>/dev/null';

my $tsv = {};

ok(
    Lemonldap::NG::Handler::Reload->jailInit(
        {
            https        => 0,
            port         => 0,
            maintenance  => 0,
            vhostOptions => {
                www1 => {
                    vhostHttps       => 1,
                    vhostPort        => 443,
                    vhostMaintenance => 1,
                    vhostAliases     => 'www2 www3',

                }
            },
        },
        $tsv
    ),
    'defaultValuesInit'
);

ok(
    Lemonldap::NG::Handler::Reload->defaultValuesInit(
        {
            https        => 0,
            port         => 0,
            maintenance  => 0,
            vhostOptions => {
                www1 => {
                    vhostHttps       => 1,
                    vhostPort        => 443,
                    vhostMaintenance => 1,
                    vhostAliases     => 'www2 www3',

                }
            },
        },
        $tsv
    ),
    'defaultValuesInit'
);

ok(
    Lemonldap::NG::Handler::Reload->locationRulesInit(
        {
            'locationRules' => {
                'www1' => {
                    'default' => 'accept',
                    '^/no'    => 'deny',
                    'test'    => '$groups =~ /\badmin\b/',
                }
            }
        },
        $tsv
    ),
    'locationRulesInit'
);

ok(
    Lemonldap::NG::Handler::Reload->headersInit(
        { exportedHeaders => { www1 => { Auth => '$uid', } } }, $tsv
    ),
    'forgeHeadersInit'
);

