use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_json { $sent[-1] }
sub last_req  { Cpanel::JSON::XS->new->decode($sent[-1]) }
sub last_extra { last_req()->{'@extra'} }

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-stories');

# --- content coercion
$td->post_story(-100, 'photo.jpg', wait => 'accepted', sub {});
my $r = last_req();
is $r->{'@type'}, 'postStory', 'post_story sends postStory';
is $r->{content}{'@type'}, 'inputStoryContentPhoto', 'a bare path is a photo story';
is $r->{content}{photo}{'@type'}, 'inputFileLocal', 'wrapped in an inputFileLocal';
is $r->{content}{photo}{path}, 'photo.jpg', 'with the path given';
is $r->{privacy_settings}{'@type'}, 'storyPrivacySettingsEveryone',
    'privacy defaults to everyone';
is $r->{active_period}, 86400, 'active_period defaults to 24h';

$td->post_story(-100, { video => 'clip.mp4', duration => 5, cover_frame_timestamp => 1.5 },
                wait => 'accepted', sub {});
$r = last_req();
is $r->{content}{'@type'}, 'inputStoryContentVideo', 'the explicit form gives a video story';
is $r->{content}{duration}, 5, 'duration passed through';
is $r->{content}{cover_frame_timestamp}, 1.5, 'cover_frame_timestamp passed through';

# a video with no duration cannot be guessed: 0 would be wrong, so it must croak
eval { $td->post_story(-100, { video => 'clip.mp4' }, sub {}) };
like $@, qr/duration/, 'a video story without duration croaks';

# --- privacy coercion
$td->post_story(-100, 'p.jpg', privacy => 'close_friends', wait => 'accepted', sub {});
is last_req()->{privacy_settings}{'@type'}, 'storyPrivacySettingsCloseFriends',
    'close_friends privacy';

$td->post_story(-100, 'p.jpg', privacy => [7, 9], wait => 'accepted', sub {});
$r = last_req();
is $r->{privacy_settings}{'@type'}, 'storyPrivacySettingsSelectedUsers',
    'an arrayref selects users';
is_deeply $r->{privacy_settings}{user_ids}, [7, 9], 'and carries the ids';

eval { $td->post_story(-100, 'p.jpg', privacy => 'nobody', sub {}) };
like $@, qr/privacy/, 'an unknown privacy name croaks';

# --- story_id is int32 and must stay numeric
$td->story(-100, 5, sub {});
$r = last_req();
is $r->{'@type'}, 'getStory', 'story sends getStory';
is $r->{story_poster_chat_id}, -100, 'poster chat id passed through';
like last_json(), qr/"story_id":5[,}]/, 'story_id crosses as a JSON number, not a string';

# --- the asynchronous post: wait => sent resolves from the update
my ($got, $err);
$td->post_story(-100, 'p.jpg', sub { ($got, $err) = @_ });
my $extra = last_extra();
$td->inject_raw(qq({"\@type":"story","id":11,"is_being_posted":true,"\@extra":"$extra"}));
ok !defined $got, 'wait => sent does not resolve on the provisional story';

$td->inject_raw(
    q({"@type":"updateStoryPostSucceeded","old_story_id":11,)
  . q("story":{"@type":"story","id":22,"poster_chat_id":-100,)
  . q("is_being_posted":false}}));
ok defined $got, 'the callback fires when the post succeeds';
is $got->{id}, 22, 'and receives the final story id, not the provisional one';

# --- and a failed post reports through the same callback
my ($got2, $err2);
$td->post_story(-100, 'p.jpg', sub { ($got2, $err2) = @_ });
my $extra2 = last_extra();
$td->inject_raw(qq({"\@type":"story","id":33,"is_being_posted":true,"\@extra":"$extra2"}));
$td->inject_raw(
    q({"@type":"updateStoryPostFailed",)
  . q("story":{"@type":"story","id":33,"poster_chat_id":-100},)
  . q("error":{"@type":"error","code":400,"message":"STORY_SEND_FLOOD"}}));
ok $err2, 'a failed post reports an error';
like $err2->{message}, qr/STORY_SEND_FLOOD/, 'and carries the server message';

# --- wait => accepted resolves immediately
my $acc;
$td->post_story(-100, 'p.jpg', wait => 'accepted', sub { $acc = $_[0] });
my $extra3 = last_extra();
$td->inject_raw(qq({"\@type":"story","id":44,"is_being_posted":true,"\@extra":"$extra3"}));
is $acc->{id}, 44, 'wait => accepted resolves on the provisional story';

# --- updates reach the hook, which proves the %UPDATES merge was wired
my $seen;
$td->on_story(sub { $seen = $_[0] });
$td->inject_raw(q({"@type":"updateStory","story":{"@type":"story","id":77}}));
is $seen->{id}, 77, 'updateStory reaches on_story';

# --- albums
$td->create_story_album(-100, 'Trips', [1, 2], sub {});
$r = last_req();
is $r->{'@type'}, 'createStoryAlbum', 'create_story_album';
is_deeply $r->{story_ids}, [1, 2], 'story ids stay numeric int32';

$td->add_album_stories(-100, 3, [4], sub {});
is last_req()->{'@type'}, 'addStoryAlbumStories', 'add_album_stories';

$td->remove_album_stories(-100, 3, [4], sub {});
is last_req()->{'@type'}, 'removeStoryAlbumStories', 'remove_album_stories';

$td->reorder_album_stories(-100, 3, [4, 5], sub {});
is last_req()->{'@type'}, 'reorderStoryAlbumStories', 'reorder_album_stories';

$td->reorder_story_albums(-100, [3, 4], sub {});
is last_req()->{'@type'}, 'reorderStoryAlbums', 'reorder_story_albums';

# --- story reactions live here, not in Messages
$td->set_story_reaction(-100, 5, "\x{1F44D}", sub {});
$r = last_req();
is $r->{'@type'}, 'setStoryReaction', 'set_story_reaction';
is $r->{reaction_type}{'@type'}, 'reactionTypeEmoji', 'and shares the reaction coercion';

$td->story_reactions(sub {});
is last_req()->{'@type'}, 'getStoryAvailableReactions', 'story_reactions';

# --- load_active_stories takes a story list, not a chat
$td->load_active_stories(sub {});
$r = last_req();
is $r->{'@type'}, 'loadActiveStories', 'load_active_stories';
is $r->{story_list}{'@type'}, 'storyListMain', 'defaulting to the main list';

$td->load_active_stories(list => 'archive', sub {});
is last_req()->{story_list}{'@type'}, 'storyListArchive', 'archive list selectable';

# TDLib answers 404 once every story is loaded: the end, not a failure
{
    my @got;
    $td->load_active_stories(sub { @got = @_ });
    my $x = last_req()->{'@extra'};
    $td->inject_raw(qq({"\@type":"error","code":404,"message":"Not found","\@extra":"$x"}));
    is scalar(@got), 2, 'load_active_stories callback fired on 404';
    ok !defined $got[1], 'an exhausted story list is not reported as an error';
    # the result is what a paging loop tests, so it must still be empty here
    # while a load that found something answers with an ok object
    ok !defined $got[0], 'and has no result, so a paging loop stops';
    @got = ();
    $td->load_active_stories(sub { @got = @_ });
    my $x2 = last_req()->{'@extra'};
    $td->inject_raw(qq({"\@type":"ok","\@extra":"$x2"}));
    is $got[0] && $got[0]{'@type'}, 'ok', 'a load with more to come answers ok';
}

# --- a parse_mode failure must reach the caller, not be embedded in the request
{
    my $n = scalar @sent;
    my $err;
    $td->post_story(-100, 'p.jpg', caption => '*bold', parse_mode => 'markdown',
                    wait => 'accepted', sub { $err = $_[1] });
    is scalar(@sent), $n, 'post_story sends nothing when the caption fails to parse';
    is $err->{'@type'}, 'error', 'and reports the parse error to the caller';

    $n = scalar @sent;
    undef $err;
    $td->edit_story(-100, 5, caption => '*bold', parse_mode => 'markdown',
                    sub { $err = $_[1] });
    is scalar(@sent), $n, 'edit_story sends nothing when the caption fails to parse';
    is $err->{'@type'}, 'error', 'and reports the parse error to the caller';
}

# --- a post waiting on its update must be failed by close(), not orphaned
{
    my $td2 = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-stories2');
    my ($res, $err);
    $td2->post_story(-100, 'p.jpg', sub { ($res, $err) = @_ });
    my $ex = last_extra();
    $td2->inject_raw(qq({"\@type":"story","id":11,"is_being_posted":true,"\@extra":"$ex"}));
    ok !defined $err, 'the post is waiting for its update';
    $td2->closed;
    is $err->{message}, 'client closed',
        'close fails a post still waiting for updateStoryPostSucceeded';
}

# --- a provisional story id is unique only within one chat, so two chats
# posting at once must not share a pending slot
{
    @sent = ();
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-xstory');
    my @fired;
    $c->post_story(-111, 'a.jpg', sub { push @fired, 'A:' . ($_[0] ? $_[0]{id} : 'err') });
    my $xa = Cpanel::JSON::XS->new->utf8->decode($sent[-1])->{'@extra'};
    $c->post_story(-222, 'b.jpg', sub { push @fired, 'B:' . ($_[0] ? $_[0]{id} : 'err') });
    my $xb = Cpanel::JSON::XS->new->utf8->decode($sent[-1])->{'@extra'};

    $c->inject_raw(qq({"\@type":"story","id":2000000000,"poster_chat_id":-111,)
                  . qq("is_being_posted":true,"\@extra":"$xa"}));
    $c->inject_raw(qq({"\@type":"story","id":2000000000,"poster_chat_id":-222,)
                  . qq("is_being_posted":true,"\@extra":"$xb"}));
    is scalar(keys %{ $c->{cache}{posting} || {} }), 2,
        'two chats posting at once are tracked separately';

    $c->inject_raw(q({"@type":"updateStoryPostSucceeded","old_story_id":2000000000,)
                  . q("story":{"@type":"story","id":7,"poster_chat_id":-111}}));
    $c->inject_raw(q({"@type":"updateStoryPostSucceeded","old_story_id":2000000000,)
                  . q("story":{"@type":"story","id":8,"poster_chat_id":-222}}));
    is_deeply [sort @fired], ['A:7', 'B:8'],
        'and each callback receives its own story';

    # a bot's repost is answered with the final story, and no post-succeeded
    # update ever follows: waiting for one parked the callback for good
    my $got;
    $c->post_story(-333, 'c.jpg', from_story => { '@type' => 'storyFullId',
        poster_chat_id => 5, story_id => 9 }, sub { $got = $_[0] });
    my $xc = Cpanel::JSON::XS->new->utf8->decode($sent[-1])->{'@extra'};
    $c->inject_raw(qq({"\@type":"story","id":88,"poster_chat_id":-333,)
                  . qq("is_being_posted":false,"\@extra":"$xc"}));
    is $got && $got->{id}, 88, 'a story answered as already posted calls back at once';
}

done_testing;
