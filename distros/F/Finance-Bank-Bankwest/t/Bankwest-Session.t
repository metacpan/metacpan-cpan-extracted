use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;

with 't::lib::Util::ResponseFixtures';

use WWW::Mechanize ();
use Finance::Bank::Bankwest::Session ();

test 'single-argument construction' => sub {
    lives_ok
        { Finance::Bank::Bankwest::Session->new( WWW::Mechanize->new ) }
        'constructor should accept a single argument';
};

test 'accounts method returns an account normally' => sub {
    my $self = shift;
    my $s = Finance::Bank::Bankwest::Session->new(
        mech            => WWW::Mechanize->new,
        accounts_uri    => $self->uri_for('acct-balances'),
    );
    my ($a) = $s->accounts;
    isa_ok $a, 'Finance::Bank::Bankwest::Account';
};

test 'transactions method works as expected in normal operation' => sub {
    my $self = shift;
    my $s = Finance::Bank::Bankwest::Session->new(
        mech                => WWW::Mechanize->new,
        transactions_uri    => $self->uri_for('txn-search-then-txn-export'),
    );
    my @txns = $s->transactions( account => 'irrelevant' );
    ok(@txns > 0, 'one or more transactions must be returned');
    isa_ok $_, 'Finance::Bank::Bankwest::Transaction' for @txns;
};

test 'transactions method propagates TransactionSearch exceptions' => sub {
    my $self = shift;
    my $s = Finance::Bank::Bankwest::Session->new(
        mech                => WWW::Mechanize->new,
        transactions_uri    => $self->uri_for('txn-search-then-bad-acct'),
    );
    throws_ok
        { $s->transactions( account => 'irrelevant' ) }
        qr{rejected transaction parameter/s \[account\]},
        'TransacionExport failure must trigger TransactionSearch test';
};

test 'logout method works as expected in normal operation' => sub {
    my $self = shift;
    my $s = Finance::Bank::Bankwest::Session->new(
        mech        => WWW::Mechanize->new,
        logout_uri  => $self->uri_for('logged-out'),
    );
    lives_ok { $s->logout };
};

for (qw{ accounts transactions logout }) {
    my $method = $_;
    test "$method method tests for login pages" => sub {
        my $self = shift;
        my $s = Finance::Bank::Bankwest::Session->new(
            mech            => WWW::Mechanize->new,
            "${method}_uri" => $self->uri_for('login-timeout'),
        );
        throws_ok
            { $s->$method }
            'Finance::Bank::Bankwest::Error::NotLoggedIn::Timeout';
    };
}

run_me;
run_tests(
    undef,
    't::lib::Test::UnexpectedParamFails' => {
        class       => 'Session',
        good_args   => { mech => WWW::Mechanize->new },
    },
);
done_testing;
