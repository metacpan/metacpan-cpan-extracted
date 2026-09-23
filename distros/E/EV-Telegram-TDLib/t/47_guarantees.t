use strict;
use warnings;
use Test::More;
use Cpanel::JSON::XS;

# _send is stubbed, so no close can complete at exit
BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;

# Each block pins a promise the POD makes about order or caching. A mutation
# run reversed every one of them with the whole suite still green: the
# behaviour was right, and nothing would have noticed it going wrong.

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
my $J = Cpanel::JSON::XS->new->utf8;
sub last_req { $J->decode($sent[-1]) }

my $n = 0;
sub new_client {
    return EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x',
        database_directory => 't/tmp-guarantees' . $n++, @_);
}
sub auth {
    my ($state, %extra) = @_;
    my $body = $J->encode({ '@type' => $state, %extra });
    return qq({"\@type":"updateAuthorizationState","authorization_state":$body});
}

# --- send() overwrites a caller's @extra: it is the reply correlation channel,
# and letting the caller's win would route the reply to no callback at all
{
    my $c = new_client();
    my $got;
    @sent = ();
    $c->send({ '@type' => 'getMe', '@extra' => 'mine' }, sub { $got = $_[0] });
    my $x = last_req()->{'@extra'};
    isnt $x, 'mine', "the request carries the module's own \@extra";
    $c->inject_raw(qq({"\@type":"user","id":5,"\@extra":"$x"}));
    is $got && $got->{id}, 5, 'and the reply reaches the callback';
}

# --- dispatch runs the auth state machine first, so on_update already sees
# the state it is being told about
{
    my $c = new_client();
    my $seen;
    $c->on_update(sub {
        $seen = $c->auth_state if ($_[0]{'@type'} // '') eq 'updateAuthorizationState';
    });
    $c->inject_raw(auth('authorizationStateWaitTdlibParameters'));
    is $seen, 'authorizationStateWaitTdlibParameters',
        'on_update runs after the auth state has moved';
}

# --- a new message reaches the command router before on_message
{
    my $c = new_client();
    my @order;
    $c->on_command(ping => sub { push @order, 'command' });
    $c->on_message(sub { push @order, 'on_message' });
    $c->inject_raw(
        q({"@type":"updateNewMessage","message":{"@type":"message","id":1,)
      . q("chat_id":-100,"is_outgoing":false,)
      . q("sender_id":{"@type":"messageSenderUser","user_id":42},)
      . q("content":{"@type":"messageText","text":{"@type":"formattedText",)
      . q("text":"/ping","entities":[{"@type":"textEntity","offset":0,"length":5,)
      . q("type":{"@type":"textEntityTypeBotCommand"}}]}}}}));
    is_deeply \@order, [qw(command on_message)],
        'the command handler runs before on_message';
}

# --- on close: pending requests fail first, then close() callbacks, then
# on_close, so a close callback never races a reply that is still owed
{
    my @order;
    my $c = new_client(on_close => sub { push @order, 'on_close' });
    $c->send({ '@type' => 'getMe' }, sub { push @order, 'pending' });
    $c->close(sub { push @order, 'close' });
    $c->inject_raw(auth('authorizationStateClosed'));
    is_deeply \@order, [qw(pending close on_close)],
        'pending fails, then close callbacks, then on_close';
}

# --- the user and chat handlers run after the cache is updated, so reading
# the cache from inside one gives the new value
{
    my $c = new_client();
    my ($user_seen, $chat_seen);
    $c->on_user(sub { $user_seen = $c->user($_[0]{id}) });
    $c->on_chat(sub { $chat_seen = $c->chat($_[0]{id}) });
    $c->inject_raw(q({"@type":"updateUser","user":{"@type":"user","id":42,"first_name":"Ann"}}));
    is $user_seen && $user_seen->{first_name}, 'Ann',
        'on_user sees the user already cached';
    $c->inject_raw(q({"@type":"updateNewChat","chat":{"@type":"chat","id":-100,"title":"Room"}}));
    is $chat_seen && $chat_seen->{title}, 'Room',
        'on_chat sees the chat already cached';
}

# --- a boolean option is cached as a plain 1 or 0. The raw JSON boolean also
# stringifies to "1", which is why an equality test could not tell them apart:
# the difference is that one is a blessed object
{
    my $c = new_client();
    $c->inject_raw(q({"@type":"updateOption","name":"is_location_visible",)
                 . q("value":{"@type":"optionValueBoolean","value":true}}));
    $c->inject_raw(q({"@type":"updateOption","name":"disable_contact_registered_notifications",)
                 . q("value":{"@type":"optionValueBoolean","value":false}}));
    my ($t, $f) = map { $c->option($_) }
        qw(is_location_visible disable_contact_registered_notifications);
    ok !ref $t && !ref $f, 'boolean options are plain scalars, not JSON objects';
    is "$t$f", '10', 'cached as 1 and 0';
}

# --- the downloadFile reply marks the download as started, so an inactive,
# uncompleted update after it is a failure rather than the file's prior state
{
    my $c = new_client();
    my ($res, $err);
    @sent = ();
    $c->download(77, sub { ($res, $err) = @_ });
    my $x = last_req()->{'@extra'};
    $c->inject_raw(qq({"\@type":"file","id":77,"\@extra":"$x",)
                 . q("local":{"@type":"localFile","is_downloading_active":false,)
                 . q("is_downloading_completed":false}}));
    $c->inject_raw(q({"@type":"updateFile","file":{"@type":"file","id":77,)
                 . q("local":{"@type":"localFile","is_downloading_active":false,)
                 . q("is_downloading_completed":false}}}));
    is $err && $err->{message}, 'download failed',
        'a download that stops after its request resolved is reported failed';
}

# --- an automatic auth step's error only counts while the state machine is
# still in that step: a late reply must not fail a login that has moved on
{
    my $c = new_client(phone_number => '+10000000000', on_code => sub {});
    my $login;
    $c->login(sub { $login = [@_] });
    $c->inject_raw(auth('authorizationStateWaitTdlibParameters'));
    @sent = ();
    $c->inject_raw(auth('authorizationStateWaitPhoneNumber'));
    my $x = last_req()->{'@extra'};
    $c->inject_raw(auth('authorizationStateWaitCode',
        code_info => { '@type' => 'authenticationCodeInfo' }));
    $c->inject_raw(qq({"\@type":"error","code":400,)
                 . qq("message":"PHONE_NUMBER_FLOOD","\@extra":"$x"}));
    ok !$login, 'a late error for a step already passed does not fail the login';
    ok !$c->{login_failed}, 'nor mark it failed for the next login()';
    $c->inject_raw(auth('authorizationStateReady'));
    is_deeply $login, [undef, undef], 'and the login still succeeds once ready';
}

done_testing;
