use strict;
use warnings;
use Test::More;

# _send is stubbed, so the END-block shutdown has nothing to deliver and
# would otherwise idle out the whole budget at exit
BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;

# _send receives the encoded JSON string, not the request hashref
my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_json { $sent[-1] }
sub last_req  { Cpanel::JSON::XS->new->decode($sent[-1]) }

sub client {
    my %opt = @_;
    return EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-webapps', %opt);
}

my $td = client();

# --- open parameters
my $p = EV::Telegram::TDLib::WebApps::open_params($td, {});
is $p->{'@type'}, 'webAppOpenParameters', 'builds a webAppOpenParameters';
is $p->{application_name}, 'tdesktop', 'defaults to a conventional platform';
is $p->{mode}{'@type'}, 'webAppOpenModeFullSize', 'defaults to full size';
ok !exists $p->{theme}, 'theme is omitted when not asked for';

is(EV::Telegram::TDLib::WebApps::open_params($td, { mode => 'compact' })
    ->{mode}{'@type'}, 'webAppOpenModeCompact', 'compact mode');
is(EV::Telegram::TDLib::WebApps::open_params($td, { mode => 'full_screen' })
    ->{mode}{'@type'}, 'webAppOpenModeFullScreen', 'full screen mode');

my $err = do { local $@;
    eval { EV::Telegram::TDLib::WebApps::open_params($td, { mode => 'huge' }) }; $@ };
like $err, qr/unknown web app mode/, 'an unknown mode is refused';

# --- application_name is the platform identifier, and charset limited.
# A hyphen is the natural way to write a name and the server answers with
# an opaque PLATFORM_INVALID, so it has to fail here instead.
$err = do { local $@; eval { client(application_name => 'perl-probe') }; $@ };
like $err, qr/application_name/, 'a hyphenated application_name is refused';
like $err, qr/letters, digits or underscores/, 'the error names the real rule';

$err = do { local $@; eval { client(application_name => 'a' x 65) }; $@ };
like $err, qr/application_name/, 'over 64 characters is refused';

ok defined client(application_name => 'perl_probe'), 'underscores are accepted';

# \w would accept this; the server does not. Escaped so the file stays ASCII.
$err = do { local $@; eval { client(application_name => "caf\x{e9}") }; $@ };
like $err, qr/application_name/, 'a non-ASCII letter is refused';

$err = do { local $@;
    eval { EV::Telegram::TDLib::WebApps::open_params($td, { application_name => 'bad name' }) };
    $@ };
like $err, qr/application_name/, 'a per-call override is validated too';

is(EV::Telegram::TDLib::WebApps::open_params($td, { application_name => 'weba' })
    ->{application_name}, 'weba', 'a valid override is used');
is(EV::Telegram::TDLib::WebApps::open_params($td, { application_name => undef })
    ->{application_name}, 'tdesktop', 'an explicit undef falls back to the default');

# --- discovery
$td->web_app(42, 'probe', sub {});
my $r = last_req();
is $r->{'@type'}, 'searchWebApp', 'web_app sends searchWebApp';
is $r->{web_app_short_name}, 'probe', 'short name passed through';
like last_json(), qr/"bot_user_id":42[,}]/, 'bot id crosses as a JSON number';

$td->web_app_link(-100, 42, 'probe', start_parameter => 'ref1', sub {});
$r = last_req();
is $r->{'@type'}, 'getWebAppLinkUrl', 'web_app_link sends getWebAppLinkUrl';
is $r->{chat_id}, -100, 'chat id passed through';
is $r->{start_parameter}, 'ref1', 'start parameter passed through';
is $r->{parameters}{application_name}, 'tdesktop', 'open params are built in';
like last_json(), qr/"allow_write_access":false/, 'write access is a JSON boolean';

$td->main_web_app(-100, 42, mode => 'compact', sub {});
$r = last_req();
is $r->{'@type'}, 'getMainWebApp', 'main_web_app sends getMainWebApp';
is $r->{parameters}{mode}{'@type'}, 'webAppOpenModeCompact', 'mode reaches the request';

$td->web_app_url(42, url => 'https://example.com/', sub {});
$r = last_req();
is $r->{'@type'}, 'getWebAppUrl', 'web_app_url sends getWebAppUrl';
is $r->{url}, 'https://example.com/', 'url passed through';

$td->web_app_placeholder(42, sub {});
is last_req()->{'@type'}, 'getWebAppPlaceholder', 'web_app_placeholder sends its method';

$err = do { local $@; eval { $td->web_app(undef, 'probe', sub {}) }; $@ };
like $err, qr/required/, 'a missing bot id is refused';

# --- launch and data
$td->open_web_app(-100, 42, 'https://example.com/', sub {});
$r = last_req();
is $r->{'@type'}, 'openWebApp', 'open_web_app sends openWebApp';
is $r->{url}, 'https://example.com/', 'button url passed through';
is $r->{parameters}{application_name}, 'tdesktop', 'open params are built in';

# int64: above 2^53 a JSON number would lose precision, and only the raw
# JSON can prove it went as a string
$td->close_web_app('7239857203948572039', sub {});
is last_req()->{'@type'}, 'closeWebApp', 'close_web_app sends closeWebApp';
like last_json(), qr/"web_app_launch_id":"7239857203948572039"/,
    'launch id crosses as a JSON string';

$td->send_web_app_data(42, 'Open probe', '{"n":1}', sub {});
$r = last_req();
is $r->{'@type'}, 'sendWebAppData', 'send_web_app_data sends sendWebAppData';
is $r->{button_text}, 'Open probe', 'button text passed through';
is $r->{data}, '{"n":1}', 'payload passed through verbatim';

$td->web_app_request(42, 'getBalance', '{"currency":"XTR"}', sub {});
$r = last_req();
is $r->{'@type'}, 'sendWebAppCustomRequest', 'web_app_request sends the custom request';
is $r->{method}, 'getBalance', 'method name passed through';

$td->answer_web_app_query('9182736450', { '@type' => 'inputInlineQueryResultArticle' }, sub {});
$r = last_req();
is $r->{'@type'}, 'answerWebAppQuery', 'answer_web_app_query sends its method';
is $r->{web_app_query_id}, '9182736450', 'query id passed through';

$err = do { local $@; eval { $td->close_web_app(undef, sub {}) }; $@ };
like $err, qr/required/, 'a missing launch id is refused';

# --- on_web_app_data lifts the payload out of the message content
my (@got, @plain);
$td->on_web_app_data(sub { push @got, [@_] });
$td->on_message(sub { push @plain, $_[0] });

my $J = Cpanel::JSON::XS->new;
$td->inject_raw($J->encode({ '@type' => 'updateNewMessage', message => {
    '@type' => 'message', id => 5, chat_id => 42,
    content => { '@type' => 'messageWebAppDataReceived',
                 button_text => 'Open probe', data => '{"n":7}' } } }));

is scalar @got, 1, 'on_web_app_data fired once';
is $got[0][0]{id}, 5, 'the whole message is the first argument';
is $got[0][1], '{"n":7}', 'payload is the second argument';
is $got[0][2], 'Open probe', 'button text is the third argument';
is scalar @plain, 1, 'on_message still sees the message';

$td->inject_raw($J->encode({ '@type' => 'updateNewMessage', message => {
    '@type' => 'message', id => 6, chat_id => 42,
    content => { '@type' => 'messageText',
                 text => { '@type' => 'formattedText', text => 'hi' } } } }));
is scalar @got, 1, 'a plain message does not fire on_web_app_data';
is scalar @plain, 2, 'but it does reach on_message';

done_testing;
