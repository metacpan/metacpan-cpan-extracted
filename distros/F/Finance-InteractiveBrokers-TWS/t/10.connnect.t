package Local::Callback;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub AUTOLOAD {                        # Catch-all to avoid errors
    my ($self, @args) = @_;
    our $AUTOLOAD;
    return;
}
1;

package main;

use Finance::InteractiveBrokers::TWS;
use Test::More tests => 2;

my $cb = Local::Callback->new();

my $tws = Finance::InteractiveBrokers::TWS->new($cb);

$tws->eclient->eConnect("localhost",7496,15);
ok($tws->eclient->isConnected() eq 1, "Connected");
$tws->eclient->eDisconnect();
ok($tws->eclient->isConnected() ne 1, "Disconnected");


