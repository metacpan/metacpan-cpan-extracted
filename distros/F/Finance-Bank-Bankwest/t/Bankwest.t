use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Exception;

with 't::lib::Util::ResponseFixtures';

use Finance::Bank::Bankwest ();

test 'pass on correct input' => sub {
    my $self = shift;
    my $s = Finance::Bank::Bankwest->login(
        pan         => 'irrelevant',
        access_code => 'irrelevant',
        login_uri   => $self->uri_for('login-then-acct-balances'),
    );
    isa_ok $s, 'Finance::Bank::Bankwest::Session';
};

test 'construction must fail' => sub {
    my $self = shift;
    dies_ok
        { Finance::Bank::Bankwest->new }
        'construction must not be possible';
};

run_me;
done_testing;
