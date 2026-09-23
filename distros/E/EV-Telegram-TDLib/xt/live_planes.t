use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
}

plan skip_all => 'set TD_API_ID and TD_API_HASH'
    unless $ENV{TD_API_ID} && $ENV{TD_API_HASH};
plan skip_all => 'set TD_DATABASE_DIRECTORY to an authenticated user session'
    unless $ENV{TD_DATABASE_DIRECTORY} && -d $ENV{TD_DATABASE_DIRECTORY};

use EV;
use EV::Telegram::TDLib;

# The stubbed suite in t/ asserts request shape. It cannot tell a wrong nested
# @type from a right one, because nothing parses the request but TDLib -- which
# is how 0.03 shipped set_draft and the contact builder dead, both green. This
# file sends the real thing and reads the result back.
#
# Everything here is self-cleaning: the folder it creates is deleted, the draft
# is cleared, the mute is restored, and the contact it imports is a number that
# matches no account.

my $td = EV::Telegram::TDLib->new(
    api_id             => $ENV{TD_API_ID},
    api_hash           => $ENV{TD_API_HASH},
    database_directory => $ENV{TD_DATABASE_DIRECTORY},
    on_error           => sub { },
    on_code     => sub { BAIL_OUT 'user session is not authenticated' },
    on_password => sub { BAIL_OUT 'user session is not authenticated' },
);

my $nonce = sprintf '%d_%d', $$, time;
# a chat folder name is silently truncated to 12 characters server-side,
# so the folder probe needs a tag that survives it
my $short = 'P' . substr $nonce, -6;
my ($me, $folder_id);
my @step;
sub next_step { my $s = shift @step; $s ? $s->() : $td->close(sub { EV::break }) }

# fail the test and keep going rather than hanging the queue
sub checked {
    my ($label, $err) = @_;
    return 1 unless $err;
    fail "$label: $err->{code} $err->{message}";
    return 0;
}

$td->login(sub {
    my (undef, $e) = @_;
    BAIL_OUT("login: $e->{message}") if $e;
    $me = $td->my_id;

    @step = (
        # --- drafts: draftMessageContentText, and it must actually persist
        sub { $td->set_draft($me, "live probe $nonce", sub {
            my (undef, $err) = @_;
            checked('set_draft', $err);
            next_step();
        }) },
        sub { $td->send({ '@type' => 'getChat', chat_id => 0 + $me }, sub {
            my ($chat, $err) = @_;
            if (checked('getChat', $err)) {
                my $d = $chat->{draft_message};
                ok $d, 'a draft was actually stored';
                is +($d->{content}{'@type'} // ''), 'draftMessageContentText',
                    'the draft content is a DraftMessageContent';
                like +($d->{content}{text}{text} // ''), qr/\Q$nonce\E/,
                    'and carries the text we set';
            }
            next_step();
        }) },
        sub { $td->set_draft($me, '', sub { next_step() }) },

        # --- contacts: importedContact, not contact
        sub { $td->import_contacts([
                { phone => '+10000000042', first_name => "Probe$nonce" } ], sub {
            my ($res, $err) = @_;
            if (checked('import_contacts', $err)) {
                ok defined $res->{user_ids}, 'import_contacts returned a result';
                is +($res->{user_ids}[0] // -1), 0,
                    'an unmatched number resolves to no user, and nothing was added';
            }
            next_step();
        }) },

        # --- folders: chatFolderName wrapping a formattedText
        sub { $td->create_folder({ name => $short, include_groups => 1 }, sub {
            my ($f, $err) = @_;
            if (checked('create_folder', $err)) {
                $folder_id = $f->{id};
                ok $folder_id, 'create_folder returned a folder id';
            }
            next_step();
        }) },
        sub {
            return next_step() unless $folder_id;
            $td->folder($folder_id, sub {
                my ($f, $err) = @_;
                if (checked('folder', $err)) {
                    like +($f->{name}{text}{text} // $f->{title} // ''), qr/\Q$short\E/,
                        'the folder reads back with the name we gave it';
                }
                next_step();
            });
        },
        sub {
            return next_step() unless $folder_id;
            $td->delete_folder($folder_id, sub {
                my (undef, $err) = @_;
                checked('delete_folder', $err);
                pass 'the probe folder was removed';
                next_step();
            });
        },

        # --- scope notification settings: all nine fields, written back unchanged
        sub { $td->scope_settings('private', sub {
            my ($s, $err) = @_;
            return next_step() unless checked('scope_settings', $err);
            is +($s->{'@type'} // ''), 'scopeNotificationSettings',
                'scope settings read back';
            $td->mute_scope('private', $s->{mute_for},
                preview           => $s->{show_preview},
                sound_id          => $s->{sound_id},
                no_pinned         => $s->{disable_pinned_message_notifications},
                no_mentions       => $s->{disable_mention_notifications},
                mute_stories      => $s->{mute_stories},
                story_sound_id    => $s->{story_sound_id},
                show_story_poster => $s->{show_story_poster},
                sub {
                    my (undef, $e2) = @_;
                    checked('mute_scope', $e2);
                    $td->scope_settings('private', sub {
                        my ($s2, $e3) = @_;
                        if (checked('scope_settings re-read', $e3)) {
                            is $s2->{mute_for}, $s->{mute_for},
                                'writing the settings back left mute_for unchanged';
                            is +($s2->{show_story_poster} ? 1 : 0),
                               +($s->{show_story_poster} ? 1 : 0),
                                'and did not clobber the story settings';
                        }
                        next_step();
                    });
                });
        }) },

        # --- call(): the escape hatch reaches something real
        sub { $td->call(getChatMember => {
                chat_id   => 0 + $me,
                member_id => { '@type' => 'messageSenderUser', user_id => 0 + $me },
            }, sub {
                my ($m, $err) = @_;
                if (checked('call(getChatMember)', $err)) {
                    is +($m->{'@type'} // ''), 'chatMember', 'call() returned a chatMember';
                }
                next_step();
            }) },

        # --- message_count: needs a filter, and TDLib rejects the empty one
        sub { $td->message_count($me, filter => 'Photo', sub {
            my ($c, $err) = @_;
            if (checked('message_count', $err)) {
                ok defined $c->{count}, 'message_count returned a count';
            }
            next_step();
        }) },
    );
    next_step();
});

my $timeout = EV::timer 180, 0, sub { fail 'live plane probe timed out'; EV::break };
EV::run;

done_testing;
