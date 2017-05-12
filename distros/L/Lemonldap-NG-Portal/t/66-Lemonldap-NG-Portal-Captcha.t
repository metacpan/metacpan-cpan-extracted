use Test::More tests => 5;

BEGIN {
    use_ok("Lemonldap::NG::Portal::Simple");
}

# build Lemonldap::NG::Portal::Simple object
my $p = Lemonldap::NG::Portal::Simple->new(
    {
        globalStorage   => 'Apache::Session::File',
        domain          => 'example.com',
        portal          => 'http://auth.example.com',
        error           => 0,
        authentication  => 'Demo',
        userDB          => 'Null',
        passwordDB      => 'Null',
        registerDB      => 'Null',
        applicationList => {},
        locationRules   => {
            'test.example.com' => {
                'default' => "deny",
                '^/ok'    => '$uid eq "kharec"',
                '^/nok'   => '$uid eq "toto"',
            },
        },
        cfgNum       => 42,
        sessionInfo  => { uid => "kharec" },
        captcha_size => 6,
    }
);

ok(
    ref($p) eq "Lemonldap::NG::Portal::Simple",
    "Portal object with captcha configuration"
);

# try to init a captcha
$p->initCaptcha;
ok( $p->{captcha_img}, "Generation of captcha image" );

# try a wrong values to check checkCaptcha method
my $captcha_result =
  $p->checkCaptcha( $p->{captcha_secret}, $p->{captcha_code} );
ok( 1 == $captcha_result, "Verification of good captcha" );

# New captcha
$p->initCaptcha;
my $captcha_result_2 = $p->checkCaptcha( "wrongcode", $p->{captcha_code} );
ok( 1 != $captcha_result_2, "Reject of bad captcha" );

