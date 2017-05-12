use strict;
use warnings;
use Test::More tests => 4;
use Finance::Card::Discover;
use Finance::Card::Discover::Account;

new_ok(
    'Finance::Card::Discover' => [
        username => 'Your username',
        password => 'Your Password'
    ]
);

{
    local $@;
    eval {
        my $card = Finance::Card::Discover->new(debug => 1);
    };
    like(
        $@, qr/^'username' and 'password' are required/,
        'username/password are required'
    );
}

can_ok('Finance::Card::Discover', qw(accounts response ua));
can_ok('Finance::Card::Discover::Account', qw(
    balance profile soan soan_transactions transactions
));
