use strict;
use warnings;
use Test::More;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'set TD_API_ID and TD_API_HASH'
    unless $ENV{TD_API_ID} && $ENV{TD_API_HASH};
plan skip_all => 'set TD_BOT_TOKEN or TD_PHONE'
    unless $ENV{TD_BOT_TOKEN} || $ENV{TD_PHONE};

# require, not use: the module lives in blib and must load after the skips
require EV;
require File::Temp;
File::Temp->import('tempdir');
require EV::Telegram::TDLib;

# TD_DATABASE_DIRECTORY persists the session, so a rerun skips the login code
# entirely; without it every run authenticates afresh and adds a device
my $dir = $ENV{TD_DATABASE_DIRECTORY}
    || tempdir('ev-td-live-XXXXXX', TMPDIR => 1, CLEANUP => 1);

# prompts go to STDERR: STDOUT is the TAP stream
sub ask {
    my ($what) = @_;
    print STDERR "$what: ";
    my $line = <STDIN>;
    defined $line or die "$what needed but STDIN gave EOF\n";
    $line =~ s/\s+//g;
    return $line;
}

my %cred = $ENV{TD_BOT_TOKEN}
    ? (bot_token => $ENV{TD_BOT_TOKEN})
    : (phone_number => $ENV{TD_PHONE},
       on_code => sub {
           my ($info, $submit, $err) = @_;
           diag "login code rejected: $err->{message}" if $err;
           if (!$err and my $code = $ENV{TD_LOGIN_CODE}) { $submit->($code); return }
           $submit->(ask('Telegram login code'));
       },
       on_password => sub {
           my ($info, $submit, $err) = @_;
           diag "password rejected: $err->{message}" if $err;
           if (!$err and my $pw = $ENV{TD_PASSWORD}) { $submit->($pw); return }
           $submit->(ask('Telegram 2FA password'));
       });

my $td = EV::Telegram::TDLib->new(
    api_id             => $ENV{TD_API_ID},
    api_hash           => $ENV{TD_API_HASH},
    use_test_dc        => $ENV{TD_TEST_DC} ? 1 : 0,
    register           => { first_name => 'live', last_name => 'auth' },
    database_directory => $dir,
    on_error           => sub { diag "tdlib: $_[0]" },
    %cred,
);

my $watchdog = EV::timer($ENV{TD_TIMEOUT} || 300, 0, sub {
    fail 'timed out'; EV::break();
});

my $text = "live_auth $$";
my ($me, $sent, $read);

$td->login(sub {
    my (undef, $err) = @_;
    if ($err) { fail "login: $err->{message}"; EV::break(); return }
    $td->me(sub {
        my ($user, $err) = @_;
        if ($err) { fail "me: $err->{message}"; EV::break(); return }
        $me = $user;
        # TDLib refuses to send to a chat it has not loaded, Saved Messages
        # included; createPrivateChat resolves and opens it first
        $td->send({ '@type' => 'createPrivateChat',
                    user_id => 0 + $me->{id} }, sub {
          my ($chat, $err) = @_;
          if ($err) { fail "createPrivateChat: $err->{message}"; EV::break(); return }
          $td->send_message($chat->{id}, $text, sub {
            my ($msg, $err) = @_;
            if ($err) { fail "send: $err->{message}"; EV::break(); return }
            $sent = $msg;
            $td->history($chat->{id}, limit => 1, sub {
                my ($msgs, $err, $state) = @_;
                if ($err) { fail "history: $err->{message}"; EV::break(); return }
                $read = $msgs;
                $td->close(sub { EV::break() });
            });
          });
        });
    });
});

EV::run();

ok $me && $me->{id}, 'logged in and fetched me';
ok $sent, 'message accepted';
ok $read && @$read, 'history returned messages';
is $read && $read->[0]{content}{text}{text}, $text,
    'the message read back from Saved Messages matches';
is $td->auth_state, 'authorizationStateClosed', 'client closed cleanly';

done_testing;
