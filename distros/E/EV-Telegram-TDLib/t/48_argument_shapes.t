use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;

{
    package Str;
    use overload '""' => sub { ${ $_[0] } }, fallback => 1;
    sub new { my ($class, $s) = @_; bless \$s, $class }
}

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_req { Cpanel::JSON::XS->new->utf8->decode($sent[-1]) }

my $n = 0;
sub new_client {
    return EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x',
        database_directory => 't/tmp-shapes' . $n++, @_);
}
my $td = new_client();
my $cb = sub {};

# a refusal must happen at the call site, before anything is sent, and without
# perl warning from inside the module on the way
sub refused {
    my ($code, $re, $name) = @_;
    @sent = ();
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $e = do { local $@; eval { $code->(); 1 } ? '' : $@ };
    like $e, qr/$re.* at \Q${\__FILE__}\E line/, $name;
    is scalar @sent, 0, "  and nothing is sent: $name";
    is_deeply \@w, [], "  and nothing warns: $name";
}

sub sent {
    my ($code, $name) = @_;
    @sent = ();
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $ok = eval { $code->(); 1 };
    ok $ok && @sent, $name or diag $@;
    is_deeply \@w, [], "  without a warning: $name";
    return @sent ? last_req() : {};
}

# --- a callback written before the options landed in an optional flag or
# number and was dropped; for mute_scope its address became the mute time
refused sub { $td->pin_chat(-100, $cb, list => 'archive') },
    qr/callback goes last/, 'pin_chat with the callback before its options';
refused sub { $td->mute_scope('private', $cb, show_preview => 0) },
    qr/callback goes last/, 'mute_scope with the callback before its options';
refused sub { $td->set_updates_status($cb, error => 'down') },
    qr/callback goes last/, 'set_updates_status with the callback first';
refused sub { $td->set_menu_button($cb, text => 'Go', url => 'https://example.org') },
    qr/callback goes last/, 'set_menu_button with the callback first';
refused sub { $td->mute(-100, $cb, undef) },
    qr/takes at most 2 arguments/, 'mute with the callback before a forwarded undef';

# --- a flag is JSON's idea of true and false
refused sub { $td->pin_chat(-100, \0, $cb) }, qr/pass 0 or 1/,
    '\0 as a flag, which perl reads as true';
refused sub { $td->pin_chat(-100, {}, $cb) }, qr/a flag must be true or false/,
    'a hashref as a flag';
refused sub { $td->install_sticker_set('123', $cb, archived => 1) },
    qr/callback goes last/,
    'install_sticker_set with the callback before archived, which skipped the flag';

# --- login, close and me take the callback last
refused sub { $td->login(timeout => 30, $cb) }, qr/login takes no arguments/,
    'login with an option before its callback';
refused sub { $td->close(timeout => 5, $cb) }, qr/close takes no arguments/,
    'close with an option before its callback';
refused sub { $td->me(retry => 1, $cb) }, qr/me takes no arguments/,
    'me with an option before its callback';
{
    my $got;
    my $extra = sent(sub { $td->me(sub { $got = $_[0] }) }, 'me with only a callback')
        ->{'@extra'} // 0;
    $td->inject_raw(qq({"\@type":"user","id":7,"\@extra":"$extra"})) if $extra;
    is $got && $got->{id}, 7, 'and the callback gets the reply';

    my $c = new_client();
    my $fired = 0;
    @sent = ();
    $c->login(undef, sub { $fired++ });
    ok scalar @sent, 'login(undef, $cb) starts the login';
    $c->inject_raw('{"@type":"updateAuthorizationState","authorization_state":'
                 . '{"@type":"authorizationStateReady"}}');
    my $t = EV::timer 1, 0, sub { EV::break };
    EV::run(EV::RUN_ONCE) until $fired || !$t->is_active;
    is $fired, 1, 'and calls back once the account is ready';
}

# --- call with \%args left out takes its options, and a stray string is not one
{
    my $got;
    my $extra = sent(sub { $td->call(getMe => timeout => 5, sub { $got = $_[0] }) },
                     'call(getMe => timeout => 5, $cb)')->{'@extra'} // 0;
    ok $td->{pending}{$extra}{timer}, 'and the timeout reaches send';
    $td->inject_raw(qq({"\@type":"user","id":8,"\@extra":"$extra"})) if $extra;
    is $got && $got->{id}, 8, 'and the callback gets the reply';
}
refused sub { $td->call(getMe => 'nope') }, qr/hashref/,
    'call with a string where the argument hashref goes';

# --- a reference in a number slot went out as its memory address
refused sub { $td->send_message(-100, 'hi', reply_to => { id => 5 }, $cb) },
    qr/reply_to must be a number/, 'reply_to given the message rather than its id';
refused sub { $td->delete_messages(-100, [ {} ], $cb) },
    qr/each of message_ids must be a number/, 'a hashref among message ids';
refused sub { $td->delete_messages(-100, ['abc'], $cb) },
    qr/each of message_ids must be a number/, 'a word among message ids';
refused sub { $td->history(-100, limit => 'ten', $cb) },
    qr/limit must be a number/, 'a word as a limit';
refused sub { $td->send_location(-100, 'north', 37.6, $cb) },
    qr/latitude must be a number/, 'a word as a latitude';
is sent(sub { $td->send_location(-100, '55.75', '3.7e1', $cb) },
        'a decimal and an exponent as coordinates')
    ->{input_message_content}{location}{latitude}, 55.75,
    'and a double slot keeps its fraction';
refused sub { $td->send(+{ '@type' => 'getMe' }, $cb, timeout => {}) },
    qr/timeout must be a number/, 'a hashref as a timeout';
refused sub { $td->send(+{ '@type' => 'getMe' }, $cb, retry => { attempts => 'x' }) },
    qr/attempts must be a number/, 'a word as a retry attempt count';

# --- a point in time given as a duration landed in 1970, and TDLib quietly
# sent at once, banned for good or cleared the status
refused sub { $td->send_message(-100, 'hi', schedule => 3600, $cb) },
    qr/schedule is a Unix time, not a duration/, 'schedule given a duration';
refused sub { $td->send_message(-100, 'hi', schedule => time + 60.5, $cb) },
    qr/schedule must be a whole number/, 'schedule given a fractional time';
is sent(sub { $td->send_message(-100, 'hi', schedule => time + 3600, $cb) },
        'schedule given a Unix time')
    ->{options}{scheduling_state}{'@type'}, 'messageSchedulingStateSendAtDate',
    'and the message is scheduled';
refused sub { $td->reschedule(-100, 5, 3600, $cb) },
    qr/when is a Unix time/, 'reschedule given a duration';
sent sub { $td->reschedule(-100, 5, $cb) }, 'reschedule with no time sends now';
refused sub { $td->ban_member(-100, 42, until => 86400, $cb) },
    qr/until is a Unix time/, 'a ban until a duration';
refused sub { $td->ban_member(-100, 42, until => -1, $cb) },
    qr/until is a Unix time/, 'a ban until a negative time';
refused sub { $td->set_emoji_status('123', expires => 3600, $cb) },
    qr/expires is a Unix time/, 'an emoji status expiring after a duration';
refused sub { $td->invite_link(-100, expires => 86400, $cb) },
    qr/expires is a Unix time/, 'an invite link expiring after a duration';

# --- the value of these setters is required, 0 being the way to clear
for my $m (qw(set_slow_mode set_auto_delete set_discussion_group)) {
    refused sub { $td->$m(-100, $cb) }, qr/\A$m needs .*pass 0/,
        "$m with its value left out";
    refused sub { $td->$m(-100, undef, $cb) }, qr/\A$m needs/,
        "$m with an undef value";
    sent sub { $td->$m(-100, 0, $cb) }, "$m with 0 still clears";
}

# --- a method with no options took name => value as values
refused sub { $td->set_chat_title(-100, title => 'New', $cb) },
    qr/set_chat_title takes at most 2 arguments before its callback, and no options/,
    'set_chat_title given its title as an option';
refused sub { $td->set_name(first => 'Ann', last => 'Lee') },
    qr/set_name takes at most 2 arguments/, 'set_name given its names as options';
refused sub { $td->edit_message_markup(-100, 5, reply_markup => {}, $cb) },
    qr/edit_message_markup takes at most 3 arguments/,
    'edit_message_markup given reply_markup as an option';
refused sub { $td->set_slow_mode(-100, seconds => 30, $cb) },
    qr/set_slow_mode takes at most 2 arguments/,
    'set_slow_mode given its delay as an option';
refused sub { $td->message(-100, 5, undef) },
    qr/omit it when it is undef/, 'a forwarded undef callback gets the hint';
refused sub { $td->cancel_download(11, $cb) },
    qr/cancel_download takes only a file id/, 'cancel_download given a callback';

# --- dates TDLib would quietly have taken as "clear the birthdate"
refused sub { $td->set_birthdate(day => 5, $cb) }, qr/needs both day and month/,
    'set_birthdate with a day alone';
refused sub { $td->set_birthdate(year => 1990, $cb) }, qr/needs both day and month/,
    'set_birthdate with a year alone';
refused sub { $td->set_birthdate(day => 1, month => 0, $cb) }, qr/month must be 1 to 12/,
    'set_birthdate with a localtime month';
refused sub { $td->set_birthdate(day => 29, month => 2, year => 2023, $cb) },
    qr/day must be 1 to 28/, 'set_birthdate on a day that does not exist';
refused sub { $td->set_birthdate(day => 1, month => 1, year => 126, $cb) },
    qr/year must be 1800 to 3000/, 'set_birthdate with a localtime year';
is sent(sub { $td->set_birthdate(day => 29, month => 2, $cb) }, 'set_birthdate on Feb 29 with no year')
    ->{birthdate}{day}, 29, 'and the day is kept';
ok !exists sent(sub { $td->set_birthdate($cb) }, 'set_birthdate with nothing')->{birthdate},
    'and that clears it';

refused sub { $td->set_greeting_message(4, inactivity_days => 30, $cb) },
    qr/inactivity_days must be 7, 14, 21 or 28/, 'a greeting after 30 days';
sent sub { $td->set_greeting_message(4, inactivity_days => 14, $cb) },
    'a greeting after 14 days';
refused sub { $td->set_business_location('Main St', latitude => 1, $cb) },
    qr/both latitude and longitude/, 'a business location with a latitude alone';

# --- download followed only through its progress
{
    my $c = new_client();
    my $seen = 0;
    sent sub { $c->download(11, priority => 2, on_progress => sub { $seen++ }) },
        'download with on_progress and no main callback';
    $c->inject_raw('{"@type":"updateFile","file":{"@type":"file","id":11,'
                 . '"local":{"is_downloading_active":true,"is_downloading_completed":false}}}');
    is $seen, 1, 'and the progress callback is the one registered';
    refused sub { $c->download(12, priority => 'high') },
        qr/priority must be a number/, 'download with a word as its priority';
}

# --- an object that stringifies is text wherever text goes
is sent(sub { $td->post_story(-100, Str->new('p.jpg'), $cb) }, 'post_story with a path object')
    ->{content}{photo}{path}, 'p.jpg', 'and the path is the string';
is sent(sub { $td->react(-100, 5, Str->new("\x{1F44D}"), $cb) }, 'react with an emoji object')
    ->{reaction_type}{emoji}, "\x{1F44D}", 'and the emoji is the string';
is sent(sub { $td->remote_file('AgAD', file_type => Str->new('fileTypeVideo'), $cb) },
        'remote_file with a file type object')->{file_type}{'@type'}, 'fileTypeVideo',
    'and the class is the string';
is sent(sub { $td->business_features(source => Str->new('Location'), $cb) },
        'business_features with a source object')->{source}{'@type'},
    'businessFeatureLocation', 'and the feature is the string';

# --- a credential given as a reference croaked inside the login and hung it
for my $opt ([ bot_token => [] ], [ phone_number => {} ],
             [ register => { first_name => {} } ], [ register => 'Ann' ]) {
    my $e = do { local $@; eval { new_client(@$opt); 1 } ? '' : $@ };
    like $e, qr/must be a string|register takes a hashref/,
        "new() refuses $opt->[0] => " . (ref $opt->[1] || 'a string');
}

done_testing;
