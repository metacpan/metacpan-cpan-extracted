use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;

with 't::lib::Util::ResponseFixtures';

use Finance::Bank::Bankwest::SessionFromLogin ();

run_tests(
    undef,
    't::lib::Test::UnexpectedParamFails' => {
        class       => 'SessionFromLogin',
        good_args   => { pan => '', access_code => '' },
    },
);

test 'pass on correct input' => sub {
    my $self = shift;
    my $sfl = Finance::Bank::Bankwest::SessionFromLogin->new(
        pan         => 'irrelevant',
        access_code => 'irrelevant',
        login_uri   => $self->uri_for('login-then-acct-balances'),
    );
    isa_ok $sfl->session, 'Finance::Bank::Bankwest::Session';
};

test 'pass on correct input and service message intercept' => sub {
    my $self = shift;
    my $sfl = Finance::Bank::Bankwest::SessionFromLogin->new(
        pan         => 'irrelevant',
        access_code => 'irrelevant',
        login_uri   => $self->uri_for('login-then-service-message'),
    );
    isa_ok $sfl->session, 'Finance::Bank::Bankwest::Session';
};

test 'fail if session passed in constructor' => sub {
    dies_ok { Finance::Bank::Bankwest::SessionFromLogin->new(
        pan         => 'irrelevant',
        access_code => 'irrelevant',
        session     => 'something',
    ); } 'constructor must not accept a session';
};

test 'fail correctly if bad credentials supplied' => sub {
    my $self = shift;
    my $sfl = Finance::Bank::Bankwest::SessionFromLogin->new(
        pan         => 'irrelevant',
        access_code => 'irrelevant',
        login_uri   => $self->uri_for('login-then-bad-credentials'),
    );
    throws_ok
        { $sfl->session }
        'Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials';
};

test 'fail correctly if no credentials supplied' => sub {
    my $self = shift;
    my $sfl = Finance::Bank::Bankwest::SessionFromLogin->new(
        pan         => 'irrelevant',
        access_code => 'irrelevant',
        login_uri   => $self->uri_for('login-then-no-credentials'),
    );
    throws_ok
        { $sfl->session }
        'Finance::Bank::Bankwest::Error::NotLoggedIn::BadCredentials';
};

test 'fail on Google' => sub {
    my $self = shift;
    my $sfl = Finance::Bank::Bankwest::SessionFromLogin->new(
        pan         => 'irrelevant',
        access_code => 'irrelevant',
        login_uri   => $self->uri_for('google'),
    );
    throws_ok
        { $sfl->session }
        'Finance::Bank::Bankwest::Error::BadResponse';
};

run_me;
done_testing;
