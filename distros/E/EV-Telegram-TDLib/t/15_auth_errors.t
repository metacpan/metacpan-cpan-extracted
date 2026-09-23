use strict;
use warnings;
use Test::More;

# This file stubs _send, so the END-block shutdown cannot deliver its close
# requests and would idle out the whole budget at exit. Nothing was ever sent
# to TDLib here, so there is nothing to wait for.
BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1]; };
}

sub extra_of {
    my ($json) = @_;
    my ($extra) = $json =~ /"\@extra":"(\d+)"/;
    return $extra;
}

# --- a rejected credential re-asks the handler with the error; retry works
my @asks;
my $td = EV::Telegram::TDLib->new(
    api_id       => 1,
    api_hash     => 'x',
    phone_number => '+10000000000',
    database_directory => 't/tmp-auth-errors',
    on_code => sub {
        my ($info, $submit, $err) = @_;
        push @asks, $err;
        $submit->(@asks > 1 ? '22222' : '11111');
    },
);
my $login;
$td->login(sub { $login = [@_] });

$td->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitPhoneNumber"}}));
like($sent[-1], qr/setAuthenticationPhoneNumber/, 'phone number sent');

$td->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitCode","code_info":{"@type":"authenticationCodeInfo"}}}));
is(scalar @asks, 1, 'on_code asked once');
is($asks[0], undef, 'the first ask carries no error');
like($sent[-1], qr/checkAuthenticationCode/, 'the code was submitted');

my $extra_bad = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"error","code":400,"message":"PHONE_CODE_INVALID","\@extra":"$extra_bad"}));
is(scalar @asks, 2, 'a rejected code asks the handler again');
is($asks[1]{message}, 'PHONE_CODE_INVALID', 'the rejection reaches the handler');
ok(!$login, 'login is not resolved by a credential error');
like($sent[-1], qr/checkAuthenticationCode/, 'the corrected code was submitted');

my $extra_ok = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"ok","\@extra":"$extra_ok"}));
ok(!$login, 'an ok reply alone does not finish login');
$td->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateReady"}}));
ok($login, 'login completed after the retry');
is($login->[1], undef, 'login reports no error');

# --- a rejected automatic step fails login with the TDLib error
my $td2 = EV::Telegram::TDLib->new(
    api_id       => 1,
    api_hash     => 'x',
    phone_number => '+10000000000',
    database_directory => 't/tmp-auth-errors2',
);
my $login2;
$td2->login(sub { $login2 = [@_] });
$td2->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitPhoneNumber"}}));
like($sent[-1], qr/setAuthenticationPhoneNumber/, 'phone number sent');
my $extra_ph = extra_of($sent[-1]);
$td2->inject_raw(qq({"\@type":"error","code":400,"message":"PHONE_NUMBER_INVALID","\@extra":"$extra_ph"}));
ok($login2, 'a rejected phone number resolves login');
is($login2->[0], undef, 'no result on a failed login');
like($login2->[1]{message}, qr/PHONE_NUMBER_INVALID/, 'the TDLib error reaches login');

# --- a rejected setTdlibParameters fails login
my $td3 = EV::Telegram::TDLib->new(
    api_id       => 1,
    api_hash     => 'x',
    phone_number => '+10000000000',
    database_directory => 't/tmp-auth-errors3',
);
my $login3;
$td3->login(sub { $login3 = [@_] });
$td3->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitTdlibParameters"}}));
like($sent[-1], qr/setTdlibParameters/, 'parameters sent');
my $extra_par = extra_of($sent[-1]);
$td3->inject_raw(qq({"\@type":"error","code":400,"message":"DATABASE_DIRECTORY_ERROR","\@extra":"$extra_par"}));
ok($login3, 'rejected parameters resolve login');
like($login3->[1]{message}, qr/DATABASE_DIRECTORY_ERROR/, 'the parameters error reaches login');

# --- a rejected registerUser fails login
my $td4 = EV::Telegram::TDLib->new(
    api_id       => 1,
    api_hash     => 'x',
    phone_number => '+10000000000',
    register     => { first_name => 'Ada' },
    database_directory => 't/tmp-auth-errors4',
);
my $login4;
$td4->login(sub { $login4 = [@_] });
$td4->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitRegistration"}}));
like($sent[-1], qr/registerUser/, 'registerUser sent');
my $extra_reg = extra_of($sent[-1]);
$td4->inject_raw(qq({"\@type":"error","code":400,"message":"FIRSTNAME_INVALID","\@extra":"$extra_reg"}));
ok($login4, 'a rejected registration resolves login');
like($login4->[1]{message}, qr/FIRSTNAME_INVALID/, 'the registration error reaches login');

# --- without a pending login the failure goes to on_error
my @errors;
my $td5 = EV::Telegram::TDLib->new(
    api_id       => 1,
    api_hash     => 'x',
    bot_token    => 'bad-token',
    database_directory => 't/tmp-auth-errors5',
    on_error     => sub { push @errors, $_[0] },
);
$td5->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitPhoneNumber"}}));
like($sent[-1], qr/checkAuthenticationBotToken/, 'bot token sent');
my $extra_bt = extra_of($sent[-1]);
$td5->inject_raw(qq({"\@type":"error","code":400,"message":"ACCESS_TOKEN_INVALID","\@extra":"$extra_bt"}));
is(scalar @errors, 1, 'a login failure with no login pending reaches on_error');
like($errors[0], qr/ACCESS_TOKEN_INVALID/, 'on_error carries the TDLib message');

# --- a login() after a recorded failure fails fast instead of hanging
my $late5;
$td5->login(sub { $late5 = [@_] });
ok(!$late5, 'a post-failure login does not fire synchronously');
EV::run(EV::RUN_NOWAIT);
ok($late5, 'a post-failure login fails deferred');
is($late5->[0], undef, 'a post-failure login has no result');
like($late5->[1]{message}, qr/ACCESS_TOKEN_INVALID/, 'the recorded failure is delivered');

# --- a stale credential error after close is not re-asked
my @asks6;
my $td6 = EV::Telegram::TDLib->new(
    api_id       => 1,
    api_hash     => 'x',
    phone_number => '+10000000000',
    database_directory => 't/tmp-auth-errors6',
    on_code => sub { my ($info, $submit, $err) = @_; push @asks6, $err; },
);
$td6->login(sub {});
$td6->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitCode","code_info":{"@type":"authenticationCodeInfo"}}}));
is(scalar @asks6, 1, 'on_code asked');
$td6->close;
$td6->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));
is(scalar @asks6, 1, 'close does not re-ask the credential handler');

# a credential submitter has to refer to itself so a rejection can ask again,
# and that cycle captures the client: closing must break it or the client
# outlives its own close, caches and all
{
    require Scalar::Util;
    my $ref;
    {
        my $leak = EV::Telegram::TDLib->new(
            api_id => 1, api_hash => 'x',
            database_directory => 't/tmp-auth-leak',
            phone_number => '+10000000000',
            on_code => sub { },
        );
        $ref = $leak;
        Scalar::Util::weaken($ref);
        $leak->login(sub { });
        $leak->inject_raw('{"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateWaitCode","code_info":{}}}');
        $leak->inject_raw('{"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}');
    }
    is $ref, undef, 'a client that reached a credential state is freed on close';
}

# --- with no credential at all the login must fail with a clear message
# rather than sending an empty phone number and warning from inside here
{
    my @sent;
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $err;
    {
        no warnings 'redefine';
        local *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
        my $c = EV::Telegram::TDLib->new(
            api_id => 1, api_hash => 'x', database_directory => 't/tmp-nocred');
        $c->login(sub { $err = $_[1] });
        $c->inject_raw(
            q({"@type":"updateAuthorizationState","authorization_state":)
          . q({"@type":"authorizationStateWaitPhoneNumber"}}));
    }
    is scalar(grep { /setAuthenticationPhoneNumber/ } @sent), 0,
        'no phone number request is sent when there is nothing to send';
    ok $err, 'the login callback is told';
    like $err->{message}, qr/phone_number/, 'and the message names what is missing';
    is scalar(@warns), 0, 'with no warning from inside the module';
}

done_testing;
