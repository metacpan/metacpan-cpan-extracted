use strict;
use warnings;
use Test::More;

use_ok('Mail::Outlook');

my $outlook = Mail::Outlook->new();

my @accounts = $outlook->all_accounts;
ok( scalar(@accounts), "Got at least one account." );

foreach my $a (@accounts) {
    ok( $a->{address}, "Account: $a->{address}" );
}

my $acc = $accounts[0];
my $msg = $outlook->create(
    To      => $acc->{address},
    Subject => 'Test',
    Body    => 'Sent by Mail::Outlook. Please delete this.'
);

$msg->use_account( $acc->{account} );

# ok( $msg->send, "Sent test message to $acc->{address}" );

done_testing;
