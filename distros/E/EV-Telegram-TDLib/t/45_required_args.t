use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;

# A required id left undef used to reach 0 + undef, which is an NV, which
# Cpanel::JSON::XS writes as 0.0 -- and TDLib rejects 0.0 in an integer slot,
# so the request was unparseable rather than merely wrong. Croaking at the
# call site is the module's stated convention for a missing required argument.
my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-required');

my @cases = (
    ['send_message',          sub { $td->send_message(undef, 'hi', sub {}) }],
    ['history',               sub { $td->history(undef, sub {}) }],
    ['search_messages',       sub { $td->search_messages(undef, 'q', sub {}) }],
    ['edit_message',          sub { $td->edit_message(undef, 5, 'x', sub {}) }],
    ['forward_messages',      sub { $td->forward_messages(undef, 5, [1], sub {}) }],
    ['mark_read',             sub { $td->mark_read(undef, sub {}) }],
    ['chat_action',           sub { $td->chat_action(undef, 'typing', sub {}) }],
    ['set_chat_photo',        sub { $td->set_chat_photo(undef, 'p.jpg', sub {}) }],
    ['set_member_status',     sub { $td->set_member_status(undef, 7, 'member', sub {}) }],
    ['download',              sub { $td->download(undef, sub {}) }],
    ['answer_callback_query', sub { $td->answer_callback_query(undef, sub {}) }],
    ['answer_inline_query',   sub { $td->answer_inline_query(undef, [], sub {}) }],
    ['cancel_download',       sub { $td->cancel_download(undef) }],
    ['upload',                sub { $td->upload(undef) }],
    ['on_upload',             sub { $td->on_upload(undef, sub {}) }],
    ['join_chat',             sub { $td->join_chat(undef) }],
    ['leave_chat',            sub { $td->leave_chat(undef) }],
    ['unpin_message',         sub { $td->unpin_message(undef, undef) }],
    ['set_chat_title',        sub { $td->set_chat_title(undef, 'x') }],
    ['load_chats',            sub { $td->load_chats(undef) }],
    ['edit_message_markup',   sub { $td->edit_message_markup(undef, undef, {}) }],
    ['unmute',                sub { $td->unmute(undef) }],
    ['user_by_username',      sub { $td->user_by_username(undef, sub {}) }],
    ['chat_by_username',      sub { $td->chat_by_username(undef, sub {}) }],
);

# No required argument is ever a callback, so a coderef in a positional slot
# is the caller having omitted one: it is defined, so the check above passes,
# and the address would go out as the id while the callback is dropped.
for my $case (['load_chats',    sub { $td->load_chats(sub {}) }],
              ['join_chat',     sub { $td->join_chat(sub {}) }],
              ['cancel_download', sub { $td->cancel_download(sub {}) }]) {
    my ($name, $code) = @$case;
    @sent = ();
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    ok !eval { $code->(); 1 }, "$name refuses a callback in a positional slot";
    like $@, qr/required/, "$name says which argument was missing";
    is scalar(@sent), 0, "$name sends nothing";
    is scalar(@warns), 0, "$name warns from nowhere inside the module";
}

# clearing a bio or a username is a real operation, so undef is a value there
# rather than a missing argument: these must keep sending
for my $case (['set_bio', sub { $td->set_bio(undef) }],
              ['set_username', sub { $td->set_username(undef) }]) {
    my ($name, $code) = @$case;
    @sent = ();
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    ok eval { $code->(); 1 }, "$name accepts undef as a clear";
    is scalar(@sent), 1, "$name still sends";
    is scalar(@warns), 0, "$name warns from nowhere inside the module";
}

for my $case (@cases) {
    my ($name, $code) = @$case;
    @sent = ();
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $ok = eval { $code->(); 1 };
    ok !$ok, "$name croaks on a missing required argument";
    like $@, qr/is required/, "$name says which argument";
    is scalar(@sent), 0, "$name sends nothing";
    is scalar(@warns), 0, "$name warns from nowhere inside the module";
}

# and the positive control: the same calls with real ids build a request
# TDLib's own parser accepts
sub parses_ok {
    my ($json, $label) = @_;
    my $req = Cpanel::JSON::XS->new->utf8->decode($json);
    delete $req->{'@extra'};
    my $r = EV::Telegram::TDLib->execute($req);
    unlike $r->{message} // '', qr/Failed to parse/, $label;
}

@sent = ();
$td->send_message(-100, 'hi', sub {});
parses_ok $sent[-1], 'a send_message with a real chat id parses';

@sent = ();
$td->history(-100, sub {});
parses_ok $sent[-1], 'a history with a real chat id parses';

@sent = ();
$td->download(5, sub {});
parses_ok $sent[-1], 'a download with a real file id parses';

# --- a string slot must carry a JSON String. A scalar that has only ever
# been a number encodes as a JSON Number, and TDLib rejects the request
# outright rather than coercing.
{
    my @string_cases = (
        ['edit_topic name',      sub { $td->edit_topic(-100, 5, name => 2026, sub {}) }],
        ['answer_callback text', sub { $td->answer_callback_query(7, text => 42, sub {}) }],
        ['create_topic name',    sub { $td->create_topic(-100, 2026, sub {}) }],
        ['create_folder name',   sub { $td->create_folder({ name => 2026 }, sub {}) }],
        ['import_contacts phone',
            sub { $td->import_contacts([{ phone => 79991234567,
                                          first_name => 'A' }], sub {}) }],
    );
    for my $case (@string_cases) {
        my ($label, $code) = @$case;
        @sent = ();
        # asserted, not skipped: a case that croaks or sends nothing used to
        # vanish silently, so one of them tested nothing for several rounds
        ok eval { $code->(); 1 }, "$label runs" or diag $@;
        ok scalar(@sent), "$label sent a request";
        next unless @sent;
        my $req = Cpanel::JSON::XS->new->utf8->decode($sent[-1]);
        delete $req->{'@extra'};
        my $r = EV::Telegram::TDLib->execute($req);
        unlike $r->{message} // '', qr/Failed to parse/,
            "$label built from a number still parses";
    }
}

# --- a text field must carry a JSON String even when the caller's scalar has
# been used as a number. Cpanel::JSON::XS emits a Number as soon as the SV
# has IOK, and a bare numeric comparison sets it -- so the same variable
# could send once and be rejected the second time.
{
    my @text_cases = (
        ['send_message', sub { $td->send_message(-100, 42, sub {}) }],
        ['edit_message', sub { $td->edit_message(-100, 5, 42, sub {}) }],
        ['send_poll',    sub { $td->send_poll(-100, 42, [1, 2], sub {}) }],
        ['ask prompt',   sub { $td->ask(-100, 7, 42, sub {}) }],
    );
    for my $case (@text_cases) {
        my ($label, $code) = @$case;
        @sent = ();
        ok eval { $code->(); 1 }, "$label runs" or diag $@;
        ok scalar(@sent), "$label sent a request";
        next unless @sent;
        my $req = Cpanel::JSON::XS->new->utf8->decode($sent[-1]);
        delete $req->{'@extra'};
        my $r = EV::Telegram::TDLib->execute($req);
        unlike $r->{message} // '', qr/Failed to parse|Expected String/,
            "$label accepts a numeric value in its text";
    }

    # the action-at-a-distance case: a string that only later gets compared.
    # Key order is randomised per hash, so compare the encoded value, not the
    # whole document.
    my $text = "42";
    @sent = ();
    $td->send_message(-100, $text, sub {});
    like $sent[-1], qr/"text":"42"/, 'a numeric-looking string sends as a String';

    if ($text > 10) { }             # nothing but a comparison
    @sent = ();
    $td->send_message(-100, $text, sub {});
    like $sent[-1], qr/"text":"42"/,
        'and still does after the caller compares it numerically';
    unlike $sent[-1], qr/"text":42\b/, 'never as a bare JSON Number';
}

# --- the login credentials are string slots too. A phone number written
# without quotes is the obvious way to hit this.
{
    my $wait_phone = q({"@type":"updateAuthorizationState",)
                   . q("authorization_state":{"@type":"authorizationStateWaitPhoneNumber"}});
    @sent = ();
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', phone_number => 79991234567,
        database_directory => 't/tmp-authstr', on_error => sub {});
    $c->inject_raw($wait_phone);
    my ($req) = grep { /setAuthenticationPhoneNumber/ } @sent;
    ok $req, 'the phone number was sent';
    like $req, qr/"phone_number":"79991234567"/,
        'an unquoted phone number still crosses as a JSON String';
}

# --- a dying bool or "" overload must not escape guarded either. The C
# drain was fixed for this; the Perl guard is its sibling, and an escape
# there also clears $@ so nothing reports it.
{
    for my $kind (qw(stringify boolify)) {
        my $pkg = "GuardNasty\u$kind";
        my $body = $kind eq 'stringify'
            ? q{use overload '""' => sub { die "boom\n" }, fallback => 0;}
            : q{use overload 'bool' => sub { die "boom\n" },
                             '""'   => sub { 'nasty' }, fallback => 0;};
        eval "package $pkg; $body sub new { bless {}, shift } 1" or die $@;

        my @errs;
        my $c = EV::Telegram::TDLib->new(
            api_id => 1, api_hash => 'x', database_directory => 't/tmp-guard',
            on_error => sub { push @errs, $_[0] });
        my $escaped = 0;
        eval { $c->guarded(sub { die $pkg->new }); 1 } or $escaped = 1;
        ok !$escaped, "a dying $kind overload does not escape guarded";
        is scalar(@errs), 1, "and is still reported once";
    }
}

# --- the reporting path itself must not be able to escape. An on_error that
# dies is the last place left to throw from, and guarded runs during update
# dispatch, where an escape unwinds out of the handler.
{
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-onerrdie',
        on_error => sub { die "on_error itself died\n" });
    my $escaped = '';
    eval { $c->guarded(sub { die "inner\n" }); 1 } or $escaped = $@;
    is $escaped, '', 'a dying on_error does not escape guarded either';
}

# --- with no on_error at all the report has to go somewhere: it warns, which
# is the only channel left, and losing it would make a dying callback silent
{
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-nowarn');
    my @warns;
    my $escaped = '';
    {
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        eval { $c->guarded(sub { die "unheard\n" }); 1 } or $escaped = $@;
    }
    is $escaped, '', 'a dying callback with no on_error does not escape';
    is scalar(@warns), 1, 'and is warned about instead';
    like $warns[0], qr/unheard/, 'with the original message';
}

done_testing;
