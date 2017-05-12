# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('Lemonldap::NG::Portal::Menu') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$ENV{REQUEST_METHOD} = 'GET';

# Build portal
my $p = Lemonldap::NG::Portal::Simple->new(
    {
        globalStorage   => 'Apache::Session::File',
        domain          => 'example.com',
        error           => 0,
        authentication  => 'Null',
        userDB          => 'Null',
        passwordDB      => 'Null',
        registerDB      => 'Null',
        applicationList => {},
        locationRules   => {
            'test.example.com' => {
                'default' => 'deny',
                '^/ok'    => '$uid eq "coudot"',
                '^/nok'   => '$uid eq "toto"',
            },
        },
        cfgNum      => 42,
        sessionInfo => { uid => "coudot", },
        vhostOptions =>
          { 'test.example.com' => { vhostAliases => 'alias.example.com' }, },
    }
);

# Init menu
$p->menuInit();

# Test that display modules is an array
ok( ref $p->{menuDisplayModules} eq 'ARRAY', 'Modules displayed' );

# Test that application loop is an array
my $appLoop = $p->appslist();

ok( ref $appLoop eq 'ARRAY', 'Application loop' );

# Create an application list
$p->{applicationList} = {
    test => {
        type       => 'category',
        catname    => 'Test',
        testautook => {
            type    => 'application',
            options => {
                uri     => 'http://test.example.com/ok/login.php',
                name    => 'Test application',
                display => 'auto',
            },
        },
        testautonok => {
            type    => 'application',
            options => {
                uri     => 'http://test.example.com/nok/login.php',
                name    => 'Test application',
                display => 'auto',
            },
        },
        teston => {
            type    => 'application',
            options => {
                uri     => 'http://test.example.com/app/login.php',
                name    => 'Test application',
                display => 'on',
            },
        },
        testoff => {
            type    => 'application',
            options => {
                uri     => 'http://test.example.com/app/login.php',
                name    => 'Test application',
                display => 'off',
            },
        },
        testalias => {
            type    => 'application',
            options => {
                uri     => 'http://alias.example.com/ok/login.php',
                name    => 'Test application',
                display => 'auto',
            },
        },
    },
    empty => {
        type     => 'category',
        catname  => 'Test',
        test2off => {
            type    => 'application',
            options => {
                uri     => 'http://test.example.com/app/login.php',
                name    => 'Test application',
                display => 'off',
            },
        },
    }
};

# Reload application list
$appLoop = $p->appslist();

# Check empty category
# Check display off and on
# Check display auto ok and nok
my $emptyCat     = 0;
my $displayOn    = 0;
my $displayOff   = 0;
my $displayOk    = 0;
my $displayNok   = 0;
my $displayAlias = 0;

foreach (@$appLoop) {
    $emptyCat++ if $_->{catid} eq "empty";
    if ( $_->{catid} eq "test" ) {
        foreach ( @{ $_->{'applications'} } ) {
            $displayOn++    if $_->{appid} eq "teston";
            $displayOff++   if $_->{appid} eq "testoff";
            $displayOk++    if $_->{appid} eq "testautook";
            $displayNok++   if $_->{appid} eq "testautonok";
            $displayAlias++ if $_->{appid} eq "testalias";
        }
    }
}

ok( $emptyCat == 0,     'Hide empty category' );
ok( $displayOn != 0,    'Display on' );
ok( $displayOff == 0,   'Display off' );
ok( $displayOk != 0,    'Display auto ok' );
ok( $displayNok == 0,   'Display auto nok' );
ok( $displayAlias != 0, 'Display alias ok' );

# Connect as another user with different rights
$p->{sessionInfo}->{uid} = "toto";
my $appLoop2   = $p->appslist();
my $displayOk2 = 0;

foreach (@$appLoop2) {
    if ( $_->{catid} eq "test" ) {
        foreach ( @{ $_->{'applications'} } ) {
            $displayOk2++ if $_->{appid} eq "testautonok";
        }
    }
}

ok( $displayOk2 != 0, 'Display auto ok for different user' );

