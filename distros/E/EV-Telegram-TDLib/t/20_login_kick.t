use strict;
use warnings;
use Test::More;

# This file stubs _send, so the END-block shutdown cannot deliver its close
# requests and would idle out the whole budget at exit. Nothing was ever sent
# to TDLib here, so there is nothing to wait for.
BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;

# tdjson creates the client, and emits its first update, only after a request
# reaches it. The auth flow runs off updateAuthorizationState, so login() on a
# fresh client must send something or the client never starts at all.

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}

sub new_client {
    return EV::Telegram::TDLib->new(
        api_id             => 1,
        api_hash           => 'x',
        phone_number       => '+10000000000',
        database_directory => 't/tmp-login-kick',
        on_code            => sub {},
    );
}

my $td = new_client();
is scalar @sent, 0, 'new() alone sends nothing';

$td->login(sub {});
ok scalar @sent, 'login() sends a request on a fresh client';
like $sent[0], qr/getAuthorizationState/,
    'the kick is getAuthorizationState';

my $n = scalar @sent;
$td->login(sub {});
is scalar @sent, $n, 'a second login() does not kick again';

# a client already driven by updates must not be kicked
my $td2 = new_client();
$td2->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitPhoneNumber"}}));
my $before = scalar @sent;
$td2->login(sub {});
my @new = @sent[$before .. $#sent];
is scalar(grep { /getAuthorizationState/ } @new), 0,
    'no kick once the state machine is already running';

done_testing;
