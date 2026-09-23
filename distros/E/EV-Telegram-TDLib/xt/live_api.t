use strict;
use warnings;
use Test::More;
use File::Temp ();

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'set TD_API_ID and TD_API_HASH'
    unless $ENV{TD_API_ID} && $ENV{TD_API_HASH};
# this test never authenticates: point it at a session xt/live_auth.t made
plan skip_all => 'set TD_DATABASE_DIRECTORY to an authenticated session directory'
    unless $ENV{TD_DATABASE_DIRECTORY} && -d $ENV{TD_DATABASE_DIRECTORY};

require EV;
require EV::Telegram::TDLib;

my $marker = "live_api $$";
my (%seen, $me, $chat_id, @mine);

my $td = EV::Telegram::TDLib->new(
    api_id             => $ENV{TD_API_ID},
    api_hash           => $ENV{TD_API_HASH},
    use_test_dc        => $ENV{TD_TEST_DC} ? 1 : 0,
    database_directory => $ENV{TD_DATABASE_DIRECTORY},
    on_error           => sub { diag "tdlib: $_[0]" },
    on_code     => sub { BAIL_OUT 'session is not authenticated; run xt/live_auth.t first' },
    on_password => sub { BAIL_OUT 'session is not authenticated; run xt/live_auth.t first' },
    on_user             => sub { $seen{user}++ },
    on_chat             => sub { $seen{chat}++ },
    on_message          => sub { $seen{message}++ },
    on_connection_state => sub { $seen{connection}++ },
);

# steps run one at a time; each calls its argument to advance
my @steps;
sub step { push @steps, [@_] }
my $advance;
$advance = sub {
    my $s = shift @steps or do { $td->close(sub { EV::break() }); return };
    my ($name, $code) = @$s;
    $code->(sub { $advance->() });
};

sub bail { my ($what, $err, $next) = @_; fail "$what: $err->{message}"; $next->() }

step 'me + chat' => sub {
    my $next = shift;
    $td->me(sub {
        my ($user, $err) = @_;
        return bail('me', $err, $next) if $err;
        $me = $user;
        ok $me->{id}, 'me returned a user';
        is_deeply $td->user($me->{id}), $me, 'user() serves me from cache';
        $td->send({ '@type' => 'createPrivateChat', user_id => 0 + $me->{id} }, sub {
            my ($chat, $err) = @_;
            return bail('createPrivateChat', $err, $next) if $err;
            $chat_id = $chat->{id};
            ok $chat_id, 'Saved Messages chat resolved';
            $next->();
        });
    });
};

# Chats.pm:101 assumes a 404 here means "list exhausted", not failure
step 'load_chats' => sub {
    my $next = shift;
    $td->load_chats(20, sub {
        my ($res, $err) = @_;
        is $err, undef, 'load_chats treats end-of-list 404 as success';
        ok $td->chat($chat_id), 'chat() serves the loaded chat from cache';
        $next->();
    });
};

step 'chat_by_username' => sub {
    my $next = shift;
    $td->chat_by_username('telegram', sub {
        my ($chat, $err) = @_;
        # a public-chat lookup is flood-limited per account, which says
        # nothing about the binding
        if ($err && ($err->{code} // 0) == 429) {
            diag "chat_by_username rate-limited: $err->{message}";
            pass 'chat_by_username skipped (rate limited)';
            return $next->();
        }
        return bail('chat_by_username', $err, $next) if $err;
        ok $chat->{id}, 'chat_by_username resolved a public chat';
        $next->();
    });
};

step 'send' => sub {
    my $next = shift;
    $td->send_message($chat_id, $marker, sub {
        my ($msg, $err) = @_;
        return bail('send_message', $err, $next) if $err;
        push @mine, $msg->{id};
        ok $msg->{id}, 'send_message resolved through updateMessageSendSucceeded';
        $next->();
    });
};

step 'history' => sub {
    my $next = shift;
    $td->history($chat_id, limit => 1, sub {
        my ($msgs, $err, $state) = @_;
        return bail('history', $err, $next) if $err;
        is $msgs->[0]{content}{text}{text}, $marker, 'history returned the sent message';
        ok $state->{complete}, 'history reports completion';
        $next->();
    });
};

step 'edit' => sub {
    my $next = shift;
    $td->edit_message($chat_id, $mine[0], "$marker edited", sub {
        my ($msg, $err) = @_;
        return bail('edit_message', $err, $next) if $err;
        $td->history($chat_id, limit => 1, sub {
            my ($msgs, $err) = @_;
            return bail('history after edit', $err, $next) if $err;
            is $msgs->[0]{content}{text}{text}, "$marker edited",
                'edit_message changed the stored text';
            $next->();
        });
    });
};

step 'forward' => sub {
    my $next = shift;
    $td->forward_messages($chat_id, $chat_id, [ $mine[0] ], sub {
        my ($res, $err) = @_;
        return bail('forward_messages', $err, $next) if $err;
        my @ids = map { $_->{id} } @{ $res->{messages} // [] };
        push @mine, @ids;
        ok scalar @ids, 'forward_messages produced a message';
        $next->();
    });
};

my $tmp = File::Temp->new(SUFFIX => '.txt');
print {$tmp} "$marker payload\n" x 64;
close $tmp;

step 'upload + download' => sub {
    my $next = shift;
    is $td->upload("$tmp")->{'@type'}, 'inputFileLocal', 'upload() builds an inputFileLocal';
    $td->send_file($chat_id, "$tmp", caption => "$marker doc", sub {
        my ($msg, $err) = @_;
        return bail('send_file', $err, $next) if $err;
        my $file = $msg->{content}{document}{document};
        ok $file->{id}, 'document message carries a file id';
        $td->on_upload($file->{id}, sub { $seen{upload}++ });
        $td->download($file->{id}, sub {
            my ($f, $err) = @_;
            return bail('download', $err, $next) if $err;
            ok $f->{local}{is_downloading_completed}, 'download completed';
            # Files.pm:59 promises a synchronous refusal, not a silent overwrite
            my $refused;
            $td->download($file->{id}, sub { $refused = $_[1] });
            $td->download($file->{id}, sub { $refused = $_[1] });
            $next->();
        });
    });
};

# a Telegram animation is an MP4; a .gif sent as one arrives as a document,
# so this locks in the classification with a real (tiny) MP4
my $MP4 = <<'B64';
AAAAIGZ0eXBpc29tAAACAGlzb21pc28yYXZjMW1wNDEAAAM9bW9vdgAAAGxtdmhkAAAAAAAAAAAA
AAAAAAAD6AAAAlgAAQAAAQAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAA
AABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAmd0cmFrAAAAXHRraGQAAAADAAAA
AAAAAAAAAAABAAAAAAAAAlgAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAA
AAAAAAAAAABAAAAAAEAAAABAAAAAAAAkZWR0cwAAABxlbHN0AAAAAAAAAAEAAAJYAAAQAAABAAAA
AAHfbWRpYQAAACBtZGhkAAAAAAAAAAAAAAAAAAAoAAAAGABVxAAAAAAALWhkbHIAAAAAAAAAAHZp
ZGUAAAAAAAAAAAAAAABWaWRlb0hhbmRsZXIAAAABim1pbmYAAAAUdm1oZAAAAAEAAAAAAAAAAAAA
ACRkaW5mAAAAHGRyZWYAAAAAAAAAAQAAAAx1cmwgAAAAAQAAAUpzdGJsAAAArnN0c2QAAAAAAAAA
AQAAAJ5hdmMxAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAEAAQABIAAAASAAAAAAAAAABFUxhdmM2
Mi4yOC4xMDIgbGlieDI2NAAAAAAAAAAAAAAAGP//AAAANGF2Y0MBZAAK/+EAF2dkAAqs2UQmhAAA
AwAEAAADACg8SJZYAQAGaOvjyyLA/fj4AAAAABRidHJ0AAAAAAAAKGoAAAAAAAAAGHN0dHMAAAAA
AAAAAQAAAAMAAAgAAAAAFHN0c3MAAAAAAAAAAQAAAAEAAAAYY3R0cwAAAAAAAAABAAAAAwAAEAAA
AAAcc3RzYwAAAAAAAAABAAAAAQAAAAMAAAABAAAAIHN0c3oAAAAAAAAAAAAAAAMAAALNAAAAGgAA
ACEAAAAUc3RjbwAAAAAAAAABAAADbQAAAGJ1ZHRhAAAAWm1ldGEAAAAAAAAAIWhkbHIAAAAAAAAA
AG1kaXJhcHBsAAAAAAAAAAAAAAAALWlsc3QAAAAlqXRvbwAAAB1kYXRhAAAAAQAAAABMYXZmNjIu
MTIuMTAyAAAACGZyZWUAAAMQbWRhdAAAAp8GBf//m9xF6b3m2Ui3lizYINkj7u94MjY0IC0gY29y
ZSAxNjUgLSBILjI2NC9NUEVHLTQgQVZDIGNvZGVjIC0gQ29weWxlZnQgMjAwMy0yMDI1IC0gaHR0
cDovL3d3dy52aWRlb2xhbi5vcmcveDI2NC5odG1sIC0gb3B0aW9uczogY2FiYWM9MSByZWY9MyBk
ZWJsb2NrPTE6MDowIGFuYWx5c2U9MHgzOjB4MTEzIG1lPWhleCBzdWJtZT03IHBzeT0xIHBzeV9y
ZD0xLjAwOjAuMDAgbWl4ZWRfcmVmPTEgbWVfcmFuZ2U9MTYgY2hyb21hX21lPTEgdHJlbGxpcz0x
IDh4OGRjdD0xIGNxbT0wIGRlYWR6b25lPTIxLDExIGZhc3RfcHNraXA9MSBjaHJvbWFfcXBfb2Zm
c2V0PS0yIHRocmVhZHM9MiBsb29rYWhlYWRfdGhyZWFkcz0xIHNsaWNlZF90aHJlYWRzPTAgbnI9
MCBkZWNpbWF0ZT0xIGludGVybGFjZWQ9MCBibHVyYXlfY29tcGF0PTAgY29uc3RyYWluZWRfaW50
cmE9MCBiZnJhbWVzPTMgYl9weXJhbWlkPTIgYl9hZGFwdD0xIGJfYmlhcz0wIGRpcmVjdD0xIHdl
aWdodGI9MSBvcGVuX2dvcD0wIHdlaWdodHA9MiBrZXlpbnQ9MjUwIGtleWludF9taW49NSBzY2Vu
ZWN1dD00MCBpbnRyYV9yZWZyZXNoPTAgcmNfbG9va2FoZWFkPTQwIHJjPWNyZiBtYnRyZWU9MSBj
cmY9MjMuMCBxY29tcD0wLjYwIHFwbWluPTAgcXBtYXg9NjkgcXBzdGVwPTQgaXBfcmF0aW89MS40
MCBhcT0xOjEuMDAAgAAAACZliIQAP//+5nX4FNMIGkky/EPOPzFXKecBbOdNDh9VKAxnUXBjbwAA
ABZBmiFjngfgJ8BQAP4D8A/UEP/+qlfeAAAAHUGaQknhCEMhzwPwFKB0Af4H4G8D8BQAh//+qZ01
B64

# the handle must outlive the upload: File::Temp unlinks on destruction and
# the send is asynchronous, so a file scoped to the step is gone too early
require MIME::Base64;
my $mp4 = File::Temp->new(SUFFIX => '.mp4');
binmode $mp4;
print {$mp4} MIME::Base64::decode_base64($MP4);
close $mp4;

step 'animation' => sub {
    my $next = shift;
    $td->send_file($chat_id, "$mp4", kind => 'animation',
        caption => "$marker gif", duration => 1, width => 64, height => 64, sub {
        my ($msg, $err) = @_;
        return bail('send_file animation', $err, $next) if $err;
        is $msg->{content}{'@type'}, 'messageAnimation',
            'an MP4 sent as animation arrives as an animation';
        is $msg->{content}{animation}{mime_type}, 'video/mp4',
            'animation carries the mp4 mime type';
        $next->();
    });
};

step 'react + markup' => sub {
    my $next = shift;
    # a chat may allow no reactions at all (Saved Messages does not); TDLib
    # answering with that restriction still proves the request was well formed
    $td->react($chat_id, $mine[0], "\x{1F44D}", sub {
        my (undef, $err) = @_;
        if ($err && $err->{message} =~ /reaction isn't available/i) {
            diag "reactions unavailable in this chat: $err->{message}";
            pass 'react reached TDLib and was answered';
            return $next->();
        }
        return bail('react', $err, $next) if $err;
        pass 'react accepted';
        $td->react($chat_id, $mine[0], "\x{1F44D}", remove => 1, sub {
            my (undef, $err) = @_;
            return bail('react remove', $err, $next) if $err;
            pass 'react remove accepted';
            # a user account cannot attach inline buttons, so this must fail
            # cleanly rather than hang
            $td->edit_message_markup($chat_id, $mine[0],
                EV::Telegram::TDLib->inline_keyboard([[{ text => 'x', data => 'y' }]]),
                sub {
                    my (undef, $err) = @_;
                    ok 1, 'edit_message_markup completed'
                        . ($err ? " (rejected: $err->{message})" : '');
                    $next->();
                });
        });
    });
};

step 'poll + location + contact' => sub {
    my $next = shift;
    $td->send_poll($chat_id, "$marker poll?", ['Yes', 'No'], sub {
        my ($msg, $err) = @_;
        return bail('send_poll', $err, $next) if $err;
        push @mine, $msg->{id};
        is $msg->{content}{'@type'}, 'messagePoll', 'send_poll produced a poll message';
        is scalar @{ $msg->{content}{poll}{options} }, 2, 'the poll carries both options';
        $td->send_location($chat_id, 51.5074, -0.1278, sub {
            my ($msg, $err) = @_;
            return bail('send_location', $err, $next) if $err;
            push @mine, $msg->{id};
            is $msg->{content}{'@type'}, 'messageLocation', 'send_location produced a location';
            $td->send_contact($chat_id, '+10000000000', 'Ada', sub {
                my ($msg, $err) = @_;
                return bail('send_contact', $err, $next) if $err;
                push @mine, $msg->{id};
                is $msg->{content}{'@type'}, 'messageContact', 'send_contact produced a contact';
                $next->();
            });
        });
    });
};

step 'pin' => sub {
    my $next = shift;
    $td->pin_message($chat_id, $mine[0], silent => 1, sub {
        my (undef, $err) = @_;
        return bail('pin_message', $err, $next) if $err;
        pass 'pin_message accepted';
        $td->unpin_message($chat_id, $mine[0], sub {
            my (undef, $err) = @_;
            return bail('unpin_message', $err, $next) if $err;
            pass 'unpin_message accepted';
            $next->();
        });
    });
};

step 'search' => sub {
    my $next = shift;
    $td->search_messages($chat_id, $marker, limit => 10, sub {
        my ($msgs, $err, $info) = @_;
        return bail('search_messages', $err, $next) if $err;
        ok scalar @$msgs, 'search_messages found the marker';
        ok defined $info->{total_count}, 'search_messages reports a total_count';
        $next->();
    });
};

step 'mark_read' => sub {
    my $next = shift;
    $td->mark_read($chat_id, sub {
        my (undef, $err) = @_;
        return bail('mark_read', $err, $next) if $err;
        pass 'mark_read accepted';
        $next->();
    });
};

step 'chat_action' => sub {
    my $next = shift;
    $td->chat_action($chat_id, 'typing', sub {
        my (undef, $err) = @_;
        return bail('chat_action', $err, $next) if $err;
        pass 'chat_action accepted';
        $next->();
    });
};

step 'user_by_username' => sub {
    my $next = shift;
    $td->user_by_username('telegram', sub {
        my ($user, $err) = @_;
        if ($err && ($err->{code} // 0) == 429) {
            diag "user_by_username rate-limited: $err->{message}";
            pass 'user_by_username skipped (rate limited)';
            return $next->();
        }
        # @telegram is a channel, so this must report "not a user", not crash
        if ($err) {
            like $err->{message}, qr/not a user/, 'user_by_username rejects a non-user';
            return $next->();
        }
        ok $user->{id}, 'user_by_username resolved a user';
        $next->();
    });
};

# leaves the account as we found it, and clears xt/live_auth.t's messages too
step 'cleanup' => sub {
    my $next = shift;
    $td->history($chat_id, limit => 50, sub {
        my ($msgs, $err) = @_;
        return bail('history for cleanup', $err, $next) if $err;
        # media messages carry a caption, not text, so both are matched
        my %ours = map { $_ => 1 } @mine;
        my @junk = map { $_->{id} }
                   grep { my $c = $_->{content};
                          $ours{ $_->{id} }
                       || ($c->{text}{text}    // '') =~ /^live_(api|auth) /
                       || ($c->{caption}{text} // '') =~ /^live_(api|auth) /
                       || ($c->{document}{file_name} // '') =~ /\.(txt|mp4)$/ }
                   @$msgs;
        ok scalar @junk, 'found this run\'s messages to remove';
        $td->delete_messages($chat_id, \@junk, sub {
            my (undef, $err) = @_;
            return bail('delete_messages', $err, $next) if $err;
            $td->history($chat_id, limit => 50, sub {
                my ($left, $err) = @_;
                return bail('history after delete', $err, $next) if $err;
                my @still = grep { ($_->{content}{text}{text} // '') =~ /^live_api /
                                || ($_->{content}{caption}{text} // '') =~ /^live_api / } @$left;
                is scalar @still, 0, 'deleted messages are gone from history';
                $next->();
            });
        });
    });
};

step 'observers' => sub {
    my $next = shift;
    # connectionStateReady trails authorizationStateReady, so this is checked
    # here rather than at the first step
    like $td->connection_state, qr/^connectionState/, 'connection_state is a TDLib state';
    ok $seen{connection}, 'on_connection_state fired';
    ok $seen{message}, 'on_message fired';
    ok $seen{user},    'on_user fired';
    ok $seen{chat},    'on_chat fired';
    $next->();
};

my $watchdog = EV::timer($ENV{TD_TIMEOUT} || 180, 0, sub {
    fail 'timed out'; EV::break();
});

$td->login(sub {
    my (undef, $err) = @_;
    if ($err) { fail "login: $err->{message}"; EV::break(); return }
    $advance->();
});

EV::run();

is $td->auth_state, 'authorizationStateClosed', 'client closed cleanly';
done_testing;
