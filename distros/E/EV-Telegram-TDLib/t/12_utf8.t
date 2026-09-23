use strict;
use warnings;
use Test::More;
use EV;
use Cpanel::JSON::XS;
use EV::Telegram::TDLib;

# Regression test for the UTF-8 contract: JSON crosses the XS boundary as
# unflagged UTF-8 octets in both directions. SvPVutf8 on the send side
# would double-encode the ->utf8 encoder's octets; SvUTF8_on on the
# receive side would hand flagged strings where unflagged octets belong.
# Source stays ASCII; all non-ASCII data is written as \x{} escapes.

my $TYPE = "\@type";

# one sample hitting four ranges: latin-1 supplement, cyrillic, CJK,
# and above the BMP (4-byte UTF-8)
my $text = "h\x{e9}llo \x{410}\x{411}\x{412} \x{4e2d}\x{6587} \x{1f600}";

# the same text as unflagged UTF-8 octets, exactly what TDLib exchanges
my $oct = "h\xc3\xa9llo \xd0\x90\xd0\x91\xd0\x92 \xe4\xb8\xad\xe6\x96\x87 \xf0\x9f\x98\x80";

is length($text), 14, 'sample is 14 characters';
is length($oct), 25, 'the same text is 25 UTF-8 octets';

my $JSON = Cpanel::JSON::XS->new->utf8;

sub check_text {
    my ($got, $where) = @_;
    is $got, $text, "$where: text survives exactly";
    is length($got), 14, "$where: length is in characters, not bytes";
    is ord(substr($got, 1, 1)), 0xe9, "$where: accented latin intact";
    is ord(substr($got, 6, 1)), 0x410, "$where: cyrillic intact";
    is ord(substr($got, 10, 1)), 0x4e2d, "$where: CJK intact";
    is ord(substr($got, 13, 1)), 0x1f600, "$where: emoji above the BMP intact";
}

my %req = (
    $TYPE => 'parseTextEntities',
    text  => $text,
    parse_mode => { $TYPE => 'textParseModeMarkdown', version => 2 },
);

# --- synchronous round trip: SvPVbyte out, newSVpv back, both in _execute
{
    my $res = EV::Telegram::TDLib->execute({ %req });
    is $res->{$TYPE}, 'formattedText', 'parseTextEntities answered';
    check_text($res->{text}, 'execute round trip');
}

# --- the raw _execute return must be unflagged octets for the ->utf8 decoder
{
    my $raw = EV::Telegram::TDLib::_execute($JSON->encode({ %req }));
    ok !utf8::is_utf8($raw), '_execute returns unflagged octets';
    check_text($JSON->decode($raw)->{text}, 'raw _execute decode');
}

# --- asynchronous path through the real pump: _send octets out,
#     tdpump raw octets back
{
    my @raw;
    EV::Telegram::TDLib::_set_dispatch(sub {
        push @raw, $_[1];
        EV::break if grep { /probe-utf8/ } @raw;
    });
    my $cid = EV::Telegram::TDLib::_create_client_id();
    ok $cid > 0, "pump client id $cid";
    EV::Telegram::TDLib::_send($cid, $JSON->encode({ %req, '@extra' => 'probe-utf8' }));
    my $watchdog = EV::timer 15, 0, sub { EV::break };
    EV::run;
    my ($reply) = grep { /probe-utf8/ } @raw;
    ok $reply, 'pump delivered the probe reply';
    SKIP: {
        skip 'no reply from TDLib', 7 unless $reply;
        ok !utf8::is_utf8($reply), 'pump dispatch hands over unflagged octets';
        check_text($JSON->decode($reply)->{text}, 'pump round trip');
    }
    # a raw client id is not in %CLIENTS, so the END-block shutdown never
    # closes it; leaving TDLib a live client at exit aborts during teardown
    my $shut_done = 0;
    EV::Telegram::TDLib::_set_dispatch(sub {
        my (undef, $json) = @_;
        $shut_done = 1 if $json =~ /authorizationStateClosed/;
        EV::break if $shut_done;
    });
    EV::Telegram::TDLib::_send($cid, '{"@type":"close"}');
    # bound on the flag, not the clock: RUN_ONCE with no events left blocks
    my $shut_late = 0;
    my $shut_w = EV::timer 15, 0, sub { $shut_late = 1; EV::break };
    EV::run(EV::RUN_ONCE) while !$shut_done && !$shut_late;
    $shut_w->stop;
    ok $shut_done, 'the raw client closed before exit';

    EV::Telegram::TDLib::_set_dispatch(\&EV::Telegram::TDLib::dispatch_raw);
}

# --- receive decode contract: octets in, characters out
{
    my @msgs;
    my $td = EV::Telegram::TDLib->new(
        api_id   => 1,
        api_hash => 'x',
        auto_auth => 0,
        database_directory => 't/tmp-utf8',
        on_message => sub { push @msgs, $_[0] },
    );
    $td->inject_raw(
        '{"@type":"updateNewMessage","message":{"@type":"message","id":1,"chat_id":1,'
        . '"content":{"@type":"messageText","text":{"@type":"formattedText","text":"'
        . $oct . '"}}}}'
    );
    is scalar(@msgs), 1, 'update delivered';
    check_text($msgs[0]{content}{text}{text}, 'inject_raw decode');

    # injecting the closed update makes the module forget this client, but
    # TDLib still holds the real one, and the END-block shutdown only closes
    # clients the module still knows about: close it for real first, or
    # TDLib aborts during teardown with a client still live
    my $cid = $td->{client_id};
    my $shut = 0;
    EV::Telegram::TDLib::_set_dispatch(sub {
        my (undef, $json) = @_;
        $shut = 1 if $json =~ /authorizationStateClosed/;
        EV::break if $shut;
    });
    EV::Telegram::TDLib::_send($cid, '{"@type":"close"}');
    my $late = 0;
    my $w = EV::timer 15, 0, sub { $late = 1; EV::break };
    EV::run(EV::RUN_ONCE) while !$shut && !$late;
    $w->stop;
    EV::Telegram::TDLib::_set_dispatch(\&EV::Telegram::TDLib::dispatch_raw);
    ok $shut, 'the object client closed for real before exit';

    $td->inject_raw('{"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}');
}

done_testing;
