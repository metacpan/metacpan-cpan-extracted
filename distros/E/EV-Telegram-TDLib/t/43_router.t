use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;
use MIME::Base64 ();

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}

sub new_client {
    return EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-router', @_);
}

# a message update carrying $text, with the bot-command entity TDLib supplies
sub msg {
    my ($text, %opt) = @_;
    my $entities = '';
    if ($text =~ /\A(\/\S+)/) {
        my $len = length $1;
        $entities = qq(,"entities":[{"\@type":"textEntity","offset":0,)
                  . qq("length":$len,"type":{"\@type":"textEntityTypeBotCommand"}}]);
    }
    my $out = $opt{outgoing} ? 'true' : 'false';
    return qq({"\@type":"updateNewMessage","message":{"\@type":"message",)
         . qq("id":1,"chat_id":-100,"is_outgoing":$out,)
         . qq("sender_id":{"\@type":"messageSenderUser","user_id":42},)
         . qq("content":{"\@type":"messageText","text":{"\@type":"formattedText",)
         . qq("text":"$text"$entities}}}});
}

# --- basic dispatch
{
    my $td = new_client();
    my @got;
    $td->on_command(start => sub { push @got, [@_[0,1]] });
    $td->inject_raw(msg('/start'));
    is scalar(@got), 1, '/start fires its handler';
    is $got[0][1], '', 'no arguments gives an empty string';

    @got = ();
    $td->inject_raw(msg('/start now please'));
    is $got[0][1], 'now please', 'arguments are the rest of the line';
}

# --- a leading slash in the registration is accepted and stripped
{
    my $td = new_client();
    my $n = 0;
    $td->on_command('/help' => sub { $n++ });
    $td->inject_raw(msg('/help'));
    is $n, 1, 'registering with a leading slash works too';
}

# --- matching is case sensitive, as Telegram itself is
{
    my $td = new_client();
    my $n = 0;
    $td->on_command(start => sub { $n++ });
    $td->inject_raw(msg('/Start'));
    is $n, 0, '/Start does not match /start';
}

# --- a command mid-message must not fire
{
    my $td = new_client();
    my $n = 0;
    $td->on_command(start => sub { $n++ });
    $td->inject_raw(msg('please /start it'));
    is $n, 0, 'a command later in the line does not fire';
}

# --- outgoing messages must not trigger our own handlers
{
    my $td = new_client();
    my $n = 0;
    $td->on_command(start => sub { $n++ });
    $td->inject_raw(msg('/start', outgoing => 1));
    is $n, 0, 'an outgoing message never fires a command handler';
}

# --- @username addressing
{
    my $td = new_client();
    my $n = 0;
    $td->on_command(stats => sub { $n++ });

    $td->inject_raw(msg('/stats@otherbot'));
    is $n, 0, 'a command addressed to another bot does not fire';

    $td->inject_raw(msg('/stats@mybot'));
    is $n, 0, 'nor does the @ form before our username is known';

    $td->{my_username} = 'mybot';
    $td->inject_raw(msg('/stats@mybot'));
    is $n, 1, 'once the username is known the @ form fires';

    $td->inject_raw(msg('/stats@otherbot'));
    is $n, 1, 'and another bot still does not';

    $td->inject_raw(msg('/stats@MyBot'));
    is $n, 2, 'the username half is matched case insensitively';
}

# --- renaming. The memo cannot be repaired by re-fetching: a getMe issued
# after the rename can still be answered from TDLib's own user cache with the
# old name, and memoing that freezes it for the life of the process.
{
    my $td = new_client();
    my $n = 0;
    $td->on_command(stats => sub { $n++ });
    $td->{state} = 'authorizationStateReady';
    $td->{my_username} = 'oldname';
    $td->{my_username_asked} = 1;

    @sent = ();
    $td->set_username('newname');
    my $req = Cpanel::JSON::XS->new->utf8->decode($sent[-1]);
    is $req->{'@type'}, 'setUsername', 'set_username sends setUsername';
    is $req->{username}, 'newname', 'carrying the new name';

    $td->inject_raw(msg('/stats@newname'));
    is $n, 0, 'the new name does not route before the server accepts it';

    my $x = $req->{'@extra'};
    $td->inject_raw(qq({"\@type":"ok","\@extra":"$x"}));
    $td->inject_raw(msg('/stats@newname'));
    is $n, 1, 'and routes as soon as it does, with no getMe of its own';

    $td->inject_raw(msg('/stats@oldname'));
    is $n, 1, 'while the old name no longer routes';

    # an addressed message arriving mid-rename does ask getMe, and TDLib can
    # answer it from its own user cache with the name we just replaced
    my ($me) = grep { /getMe/ } @sent;
    ok $me, 'an addressed message in the rename window does ask getMe';
    my $mx = Cpanel::JSON::XS->new->utf8->decode($me)->{'@extra'};
    $td->inject_raw(qq({"\@type":"user","id":5,"usernames":)
                   . qq({"\@type":"usernames","editable_username":"oldname"},)
                   . qq("\@extra":"$mx"}));
    $td->inject_raw(msg('/stats@newname'));
    is $n, 2, 'a stale getMe answered after the rename does not undo it';
    $td->inject_raw(msg('/stats@oldname'));
    is $n, 2, 'and does not resurrect the old name';

    # removing the username leaves nothing to address, and must not re-ask
    @sent = ();
    $td->set_username('');
    my $rx = Cpanel::JSON::XS->new->utf8->decode($sent[-1])->{'@extra'};
    $td->inject_raw(qq({"\@type":"ok","\@extra":"$rx"}));
    $td->inject_raw(msg('/stats@newname'));
    is $n, 2, 'an account with no username matches no addressed command';
    is scalar(grep { /getMe/ } @sent), 0, 'and still asks nothing';
}

# --- unregistering
{
    my $td = new_client();
    my $n = 0;
    $td->on_command(ping => sub { $n++ });
    $td->inject_raw(msg('/ping'));
    is $n, 1, 'registered';
    $td->on_command(ping => undef);
    $td->inject_raw(msg('/ping'));
    is $n, 1, 'on_command($name => undef) unregisters';
}

# --- commands do not consume the message
{
    my $td = new_client();
    my ($cmd, $any) = (0, 0);
    $td->on_command(start => sub { $cmd++ });
    $td->on_message(sub { $any++ });
    $td->inject_raw(msg('/start'));
    is $cmd, 1, 'the command handler fired';
    is $any, 1, 'and on_message still saw the same message';
}

# --- a command-only bot still receives commands with no on_message set
{
    my $td = new_client();
    my $n = 0;
    $td->on_command(start => sub { $n++ });
    $td->inject_raw(msg('/start'));
    is $n, 1, 'routing does not depend on on_message being set';
}

# --- callback data routing
sub cbq {
    my ($data) = @_;
    my $b64 = MIME::Base64::encode_base64($data, '');
    return qq({"\@type":"updateNewCallbackQuery","id":"1","sender_user_id":42,)
         . qq("chat_id":-100,"message_id":5,)
         . qq("payload":{"\@type":"callbackQueryPayloadData","data":"$b64"}});
}

{
    my $td = new_client();
    my @order;
    $td->on_callback_data(qr/^vote:/ => sub { push @order, 'regex' });
    $td->on_callback_data('vote:42' => sub { push @order, 'literal' });
    $td->inject_raw(cbq('vote:42'));
    is_deeply \@order, ['regex', 'literal'],
        'every matching handler fires, in registration order';

    # the data must be longer than the literal, or prefix matching and
    # equality are indistinguishable and the assertion pins nothing
    @order = ();
    $td->inject_raw(cbq('vote:420'));
    is_deeply \@order, ['regex'], 'a literal pattern is an exact match, not a prefix';
}

# --- decoded plaintext is what patterns see, and captures are passed
{
    my $td = new_client();
    my @caps;
    $td->on_callback_data(qr/^vote:(\d+)$/ => sub { @caps = @_[1 .. $#_] });
    $td->inject_raw(cbq('vote:99'));
    is_deeply \@caps, ['99'], 'captures reach the handler, base64 already decoded';
}

# --- a game payload has no data field and must be skipped, not matched on undef
{
    my $td = new_client();
    my $n = 0;
    $td->on_callback_data(qr/./ => sub { $n++ });
    $td->inject_raw(
        q({"@type":"updateNewCallbackQuery","id":"1","sender_user_id":42,)
      . q("chat_id":-100,"message_id":5,)
      . q("payload":{"@type":"callbackQueryPayloadGame","game_short_name":"g"}}));
    is $n, 0, 'a game callback query is skipped rather than matched against undef';
}

# --- a callback-data-only bot works without on_callback_query
{
    my $td = new_client();
    my $n = 0;
    $td->on_callback_data(qr/^x$/ => sub { $n++ });
    $td->inject_raw(cbq('x'));
    is $n, 1, 'routing does not depend on on_callback_query being set';
}

# --- and the older hook still fires alongside
{
    my $td = new_client();
    my ($routed, $raw) = (0, 0);
    $td->on_callback_data(qr/^x$/ => sub { $routed++ });
    $td->on_callback_query(sub { $raw++ });
    $td->inject_raw(cbq('x'));
    is $routed, 1, 'the router fired';
    is $raw, 1, 'and on_callback_query still saw it';
}

# --- on_command is a registration method, not a constructor option
{
    my $err = '';
    eval { new_client(on_command => sub {}) ; 1 } or $err = $@;
    like $err, qr/on_command/,
        'passing on_command to new() croaks rather than silently doing nothing';
}

# --- a capture whose value happens to be "1" must survive. Perl yields (1)
# for a match with no capture groups, so testing the captured value cannot
# tell the two apart; the number of groups can.
{
    my $td = new_client();
    my @caps;
    $td->on_callback_data(qr/^page:(\d)$/ => sub { @caps = @_[1 .. $#_] });
    $td->inject_raw(cbq('page:2'));
    is_deeply \@caps, ['2'], 'an ordinary capture reaches the handler';

    @caps = ();
    $td->inject_raw(cbq('page:1'));
    is_deeply \@caps, ['1'], 'and so does a capture of the literal 1';
}

# --- a group that does not participate yields undef, not a warning
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $td = new_client();
    my @caps;
    $td->on_callback_data(qr/^go(?::(\d+))?$/ => sub { @caps = @_[1 .. $#_] });
    $td->inject_raw(cbq('go'));
    is_deeply \@warns, [], 'an unmatched optional group warns about nothing';
    is scalar(@caps), 1, 'the group is still reported';
    ok !defined $caps[0], 'as undef';
}

# --- a pattern with no groups at all still reports no captures
{
    my $td = new_client();
    my ($fired, @args) = (0);
    $td->on_callback_data(qr/^plain$/ => sub { $fired++; @args = @_[1 .. $#_] });
    $td->inject_raw(cbq('plain'));
    is $fired, 1, 'a groupless pattern fires';
    is_deeply \@args, [], 'and passes no captures';
}

# --- a handler that registers a route must not re-enter the dispatch it is in
{
    my $td = new_client();
    my @fired;
    $td->on_callback_data(qr/^go$/ => sub {
        push @fired, 'first';
        $td->on_callback_data(qr/^go$/ => sub { push @fired, 'second' });
    });
    $td->inject_raw(cbq('go'));
    is_deeply \@fired, ['first'],
        'a route registered during dispatch does not fire for that same query';

    @fired = ();
    $td->inject_raw(cbq('go'));
    is_deeply \@fired, ['first', 'second'], 'but it is live for the next one';
}

# --- and a self-re-registering handler must terminate
{
    my $td = new_client();
    my $n = 0;
    my $add;
    $add = sub {
        $td->on_callback_data(qr/^go$/ => sub {
            die "runaway\n" if ++$n > 20;
            $add->();
        });
    };
    $add->();
    $td->inject_raw(cbq('go'));
    is $n, 1, 'one query fires the handler once, however it re-registers';
}

# --- unregistering a callback route, symmetric with on_command
{
    my $td = new_client();
    my $n = 0;
    my $pat = qr/^x$/;
    $td->on_callback_data($pat => sub { $n++ });
    $td->inject_raw(cbq('x'));
    is $n, 1, 'route registered';
    $td->on_callback_data($pat => undef);
    $td->inject_raw(cbq('x'));
    is $n, 1, 'on_callback_data($pattern => undef) unregisters';
}

# --- the username must resolve however the handler was registered
{
    my $ready = q({"@type":"updateAuthorizationState",)
              . q("authorization_state":{"@type":"authorizationStateReady"}});
    my $seen = sub {
        my ($td) = @_;
        my $n = 0;
        for (@sent) {
            $n++ if Cpanel::JSON::XS->new->utf8->decode($_)->{'@type'} eq 'getMe';
        }
        return $n;
    };

    @sent = ();
    my $before = new_client();
    $before->on_command(x => sub {});
    $before->inject_raw($ready);
    is $seen->($before), 1, 'registering before ready resolves the username';

    @sent = ();
    my $after = new_client();
    $after->inject_raw($ready);
    $after->on_command(x => sub {});
    is $seen->($after), 1,
        'registering after ready resolves it too, which login(sub{...}) needs';

    @sent = ();
    my $twice = new_client();
    $twice->inject_raw($ready);
    $twice->on_command(x => sub {});
    $twice->on_command(y => sub {});
    is $seen->($twice), 1, 'and only once, however many handlers are added';
}

# --- the entity offset guard is what stops a mid-line command firing
{
    my $td = new_client();
    my (@fired);
    $td->on_command(abcdef => sub { push @fired, 'abcdef' });
    $td->on_command(ab     => sub { push @fired, 'ab' });
    # The text starts with a command and carries a bot-command entity later
    # whose length differs. Only then does the offset guard matter: without
    # it the grep picks the far entity and substr($text, 0, 3) yields "/ab",
    # firing the wrong handler. A text that does not start with a slash
    # cannot tell the guard from the fallback regex.
    $td->inject_raw(
        q({"@type":"updateNewMessage","message":{"@type":"message","id":1,)
      . q("chat_id":-100,"is_outgoing":false,)
      . q("sender_id":{"@type":"messageSenderUser","user_id":42},)
      . q("content":{"@type":"messageText","text":{"@type":"formattedText",)
      . q("text":"/abcdef x /gh","entities":[{"@type":"textEntity",)
      . q("offset":10,"length":3,"type":{"@type":"textEntityTypeBotCommand"}}]}}}}));
    is_deeply \@fired, ['abcdef'],
        'a bot-command entity away from offset 0 does not choose the token';
}

done_testing;
