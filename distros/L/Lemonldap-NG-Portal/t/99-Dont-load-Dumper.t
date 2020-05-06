use Test::More tests => 5;

use_ok('Lemonldap::NG::Portal::Main');

my ( $p, $app );
my $ini = {
    configStorage => {
        type    => 'File',
        dirName => 't',
    },
    localSessionStorage        => 'Cache::FileCache',
    localSessionStorageOptions => {
        namespace   => 'lemonldap-ng-session',
        cache_root  => 't/',
        cache_depth => 0,
    },
    logLevel                   => 'error',
    cookieName                 => 'lemonldap',
    domain                     => 'example.com',
    templateDir                => 'site/templates',
    staticPrefix               => '/static',
    authentication             => 'Demo',
    userDB                     => 'Demo',
    passwordDB                 => 'Demo',
    registerDB                 => 'Demo',
    loginHistoryEnabled        => 1,
    securedCookie              => 0,
    https                      => 0,
    portalDisplayResetPassword => 1,

    # portalDisplayCertificateResetByMail => 1, Missing dependencies
    portalStatus         => 1,
    cda                  => 1,
    notification         => 1,
    portalCheckLogins    => 1,
    stayConnected        => 1,
    bruteForceProtection => 1,
    grantSessionRules    => 1,
    upgradeSession       => 1,
    autoSigninRules      => { a => 1 },
    checkState           => 1,
    portalForceAuthn     => 1,
    checkUser            => 1,
    impersonationRule    => 1,
    contextSwitchingRule => 1,
    decryptValueRule     => 1,
    globalLogoutRule     => 1,
    grantSessionRules    => { a => 1 },
    checkStateSecret     => 'x',
};

ok( $p = Lemonldap::NG::Portal::Main->new, 'Portal object' );
ok( $p->init($ini),                        'Init' );
ok( $app = $p->run,                        'App' );

eval { Data::Dumper::Dumper( {} ) };
ok( $@, "Portal doesn't depend on Data::Dumper" );
