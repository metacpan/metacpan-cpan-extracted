package EV::Telegram::TDLib::Stories;

use strict;
use warnings;
use Carp qw(croak);
use overload ();

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Stories - story methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Stories mixin">.

=cut

sub CLONE_SKIP { 1 }


# a story id is int32 and stays numeric; only the poster chat id is int53
our %UPDATES = (
    updateStory              => \&update_story,
    updateStoryDeleted       => \&update_story_deleted,
    updateStoryPostSucceeded => \&update_post_succeeded,
    updateStoryPostFailed    => \&update_post_failed,
    updateChatActiveStories  => \&update_active_stories,
);

sub posting { $_[0]{cache}{posting} ||= {} }

sub update_story {
    my ($self, $obj) = @_;
    if (my $cb = $self->{on_story}) { $cb->($obj->{story}) }
}

# The schema says a canceled post yields updateStoryDeleted instead of
# updateStoryPostFailed. That comment is stale for 1.8.66: on_delete_story
# returns early unless the id is a server one (<= 1999999999), while a
# yet-unsent story is numbered from 2000000000 up, so this update never
# carries a provisional id. A cancelled post takes the 406 "Canceled" path
# into delete_pending_story, which emits updateStoryPostFailed -- already
# handled. So there is nothing to resolve here.
sub update_story_deleted {
    my ($self, $obj) = @_;
    if (my $cb = $self->{on_story_deleted}) {
        $cb->($obj->{story_poster_chat_id}, $obj->{story_id});
    }
}

# a provisional story id is unique only among one chat's stories, so two
# chats posting at once would otherwise share a key
sub posting_key {
    my ($chat_id, $story_id) = @_;
    return unless defined $chat_id && defined $story_id;
    return (0 + $chat_id) . ':' . (0 + $story_id);
}

sub update_post_succeeded {
    my ($self, $obj) = @_;
    my $key = posting_key($obj->{story}{poster_chat_id}, $obj->{old_story_id})
        or return;
    my $cb = delete $self->posting->{$key} or return;
    $cb->($obj->{story}, undef);
}

sub update_post_failed {
    my ($self, $obj) = @_;
    my $key = posting_key($obj->{story}{poster_chat_id}, $obj->{story}{id})
        or return;
    my $cb = delete $self->posting->{$key} or return;
    $cb->(undef, $obj->{error} // { '@type' => 'error', code => -1,
                                    message => 'story post failed' });
}

sub update_active_stories {
    my ($self, $obj) = @_;
    if (my $cb = $self->{on_active_stories}) { $cb->($obj->{active_stories}) }
}

sub on_story {
    my ($self, $cb) = @_;
    $self->{on_story} = $cb if @_ > 1;
    return $self->{on_story};
}

sub on_story_deleted {
    my ($self, $cb) = @_;
    $self->{on_story_deleted} = $cb if @_ > 1;
    return $self->{on_story_deleted};
}

sub on_active_stories {
    my ($self, $cb) = @_;
    $self->{on_active_stories} = $cb if @_ > 1;
    return $self->{on_active_stories};
}

# A bare path is always a photo. Video needs duration and cover_frame_timestamp,
# which TDLib requires and nothing can infer, so it takes the explicit form.
sub story_content {
    my ($content) = @_;
    need('content', $content);
    return $content if ref $content eq 'HASH' && $content->{'@type'};
    if (ref $content eq 'HASH') {
        my $video = $content->{video}
            or croak 'story content must be a path or { video => ... }';
        need('duration, cover_frame_timestamp',
              @{$content}{qw(duration cover_frame_timestamp)});
        return {
            '@type'                 => 'inputStoryContentVideo',
            video                   => input_file($video),
            added_sticker_file_ids  => num_list('sticker_file_ids',
                                                $content->{sticker_file_ids} // []),
            duration                => real('duration', $content->{duration}),
            cover_frame_timestamp   => real('cover_frame_timestamp',
                                            $content->{cover_frame_timestamp}),
            is_animation            => json_bool($content->{is_animation}),
        };
    }
    croak 'story content must be a path or a hashref'
        if ref $content && !overload::Method($content, '""');
    return { '@type' => 'inputStoryContentPhoto',
             photo => input_file($content),
             added_sticker_file_ids => [] };
}

my %PRIVACY = (everyone      => 'storyPrivacySettingsEveryone',
               contacts      => 'storyPrivacySettingsContacts',
               close_friends => 'storyPrivacySettingsCloseFriends');

sub story_privacy {
    my ($privacy, $except) = @_;
    $privacy = 'everyone' unless defined $privacy;
    return $privacy if ref $privacy eq 'HASH';
    if (ref $privacy eq 'ARRAY') {
        return { '@type'   => 'storyPrivacySettingsSelectedUsers',
                 user_ids  => num_list('privacy', $privacy) };
    }
    my $t = $PRIVACY{$privacy}
        or croak "story privacy must be 'everyone', 'contacts', "
               . "'close_friends' or an arrayref of user ids";
    return { '@type' => $t } if $privacy eq 'close_friends';   # takes no exceptions
    return { '@type' => $t,
             except_user_ids => num_list('except', $except // []) };
}

# postStory answers with a provisional story whose id changes: the real
# outcome arrives as updateStoryPostSucceeded/Failed, so 'sent' waits for it
# exactly as send_message does.
sub post_story {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $content, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, content', $chat_id, $content);
    my $wait = $opt{wait} // 'sent';
    croak "unknown wait mode '$wait'"
        unless $wait eq 'sent' || $wait eq 'accepted';
    my %req = (
        '@type'                 => 'postStory',
        chat_id                 => 0 + $chat_id,
        content                 => story_content($content),
        privacy_settings        => story_privacy($opt{privacy}, $opt{except}),
        album_ids               => num_list('album_ids', $opt{album_ids} // []),
        active_period           => num('active_period', $opt{active_period} // 86400),
        is_posted_to_chat_page  => json_bool($opt{post_to_page}),
        protect_content         => json_bool($opt{protect_content}),
    );
    if (defined $opt{caption}) {
        my $caption = $self->format_text($opt{caption}, $opt{parse_mode});
        if (($caption->{'@type'} // '') eq 'error') {
            $cb->(undef, $caption);
            return;
        }
        $req{caption} = $caption;
    }
    $req{areas} = $opt{areas} if $opt{areas};
    $req{from_story_full_id} = $opt{from_story} if $opt{from_story};
    $self->send(\%req, sub {
        my ($story, $err) = @_;
        if ($err) { $cb->(undef, $err); return }
        if ($wait eq 'accepted') { $cb->($story, undef); return }
        # TDLib marks a story still being posted with a non-server id and
        # is_being_posted; one with neither is final already -- a bot's repost
        # is answered that way, and no post-succeeded update follows it
        my $id = $story->{id} // 0;
        if (!$story->{is_being_posted} && $id > 0 && $id <= 1999999999) {
            $cb->($story, undef);
            return;
        }
        my $key = posting_key($story->{poster_chat_id} // $chat_id,
                               $story->{id});
        if (!defined $key) { $cb->($story, undef); return }
        $self->posting->{$key} = $cb;
    });
    return;
}

sub edit_story {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $story_id, @rest) = @args;
    my %opt = opts(@rest);
    need('story_poster_chat_id, story_id', $chat_id, $story_id);
    my %req = ('@type' => 'editStory',
               story_poster_chat_id => 0 + $chat_id,
               story_id => 0 + $story_id);
    $req{content} = story_content($opt{content}) if defined $opt{content};
    if (defined $opt{caption}) {
        my $caption = $self->format_text($opt{caption}, $opt{parse_mode});
        if (($caption->{'@type'} // '') eq 'error') {
            $cb->(undef, $caption);
            return;
        }
        $req{caption} = $caption;
    }
    $req{areas} = $opt{areas} if $opt{areas};
    $self->send(\%req, $cb);
    return;
}

sub edit_story_cover {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('edit_story_cover', 3, \@args);
    my ($chat_id, $story_id, $ts) = @args;
    need('story_poster_chat_id, story_id, cover_frame_timestamp',
          $chat_id, $story_id, $ts);
    $self->send({ '@type' => 'editStoryCover',
                  story_poster_chat_id => 0 + $chat_id,
                  story_id => 0 + $story_id,
                  cover_frame_timestamp => real('cover_frame_timestamp', $ts) }, $cb);
    return;
}

sub delete_story {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_story', 2, \@args);
    my ($chat_id, $story_id) = @args;
    need('story_poster_chat_id, story_id', $chat_id, $story_id);
    $self->send({ '@type' => 'deleteStory',
                  story_poster_chat_id => 0 + $chat_id,
                  story_id => 0 + $story_id }, $cb);
    return;
}

sub story {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $story_id, @rest) = @args;
    my %opt = opts(@rest);
    need('story_poster_chat_id, story_id', $chat_id, $story_id);
    $self->send({ '@type' => 'getStory',
                  story_poster_chat_id => 0 + $chat_id,
                  story_id => 0 + $story_id,
                  only_local => json_bool($opt{only_local}) }, $cb);
    return;
}

sub active_stories {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('active_stories', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatActiveStories',
                  chat_id => 0 + $chat_id }, $cb);
    return;
}

my %STORY_LIST = (main => 'storyListMain', archive => 'storyListArchive');

# the callback carries a bare Ok: the stories themselves arrive through
# updateChatActiveStories, so watch on_active_stories for them
sub load_active_stories {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    my $list = $opt{list} // 'main';
    my $t = $STORY_LIST{$list} or croak "story list must be 'main' or 'archive'";
    $self->send({ '@type' => 'loadActiveStories',
                  story_list => { '@type' => $t } }, sub {
        my ($res, $err) = @_;
        # 404 is the end of the list, as for load_chats
        $err = undef if $err && ($err->{code} // 0) == 404;
        $cb->($res, $err);
    });
    return;
}

sub archived_stories {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatArchivedStories',
                  chat_id => 0 + $chat_id,
                  from_story_id => num('from_story_id', $opt{from_story_id} // 0),
                  limit => num('limit', $opt{limit} // 50) }, $cb);
    return;
}

sub page_stories {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatPostedToChatPageStories',
                  chat_id => 0 + $chat_id,
                  from_story_id => num('from_story_id', $opt{from_story_id} // 0),
                  limit => num('limit', $opt{limit} // 50) }, $cb);
    return;
}

sub chats_to_post_stories {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('chats_to_post_stories', 0, \@args);
    $self->send({ '@type' => 'getChatsToPostStories' }, $cb);
    return;
}

sub can_post_story {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('can_post_story', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'canPostStory', chat_id => 0 + $chat_id }, $cb);
    return;
}

# takes only a story id: it reads interactions with our own stories
sub story_interactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($story_id, @rest) = @args;
    my %opt = opts(@rest);
    need('story_id', $story_id);
    $self->send({
        '@type'               => 'getStoryInteractions',
        story_id              => 0 + $story_id,
        query                 => plain_text('a query', $opt{query}),
        only_contacts         => json_bool($opt{only_contacts}),
        prefer_forwards       => json_bool($opt{prefer_forwards}),
        prefer_with_reaction  => json_bool($opt{prefer_with_reaction}),
        offset                => plain_text('an offset', $opt{offset}),
        limit                 => num('limit', $opt{limit} // 50),
    }, $cb);
    return;
}

sub chat_story_interactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $story_id, @rest) = @args;
    my %opt = opts(@rest);
    need('story_poster_chat_id, story_id', $chat_id, $story_id);
    my %req = (
        '@type'               => 'getChatStoryInteractions',
        story_poster_chat_id  => 0 + $chat_id,
        story_id              => 0 + $story_id,
        prefer_forwards       => json_bool($opt{prefer_forwards}),
        offset                => plain_text('an offset', $opt{offset}),
        limit                 => num('limit', $opt{limit} // 50),
    );
    $req{reaction_type} = $self->reaction_type($opt{reaction})
        if defined $opt{reaction};
    $self->send(\%req, $cb);
    return;
}

sub set_story_privacy {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($story_id, $privacy, @rest) = @args;
    my %opt = opts(@rest);
    # story_privacy defaults to everyone, which is right for a new story and
    # wrong for a setter: leaving the value out widened who could see it
    need('story_id, privacy', $story_id, $privacy);
    $self->send({ '@type' => 'setStoryPrivacySettings',
                  story_id => 0 + $story_id,
                  privacy_settings => story_privacy($privacy, $opt{except}) }, $cb);
    return;
}

sub post_story_to_page {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $story_id, $on, @rest) = @args;
    no_opts('post_story_to_page', @rest);
    need('story_poster_chat_id, story_id', $chat_id, $story_id);
    $self->send({ '@type' => 'toggleStoryIsPostedToChatPage',
                  story_poster_chat_id => 0 + $chat_id,
                  story_id => 0 + $story_id,
                  is_posted_to_chat_page =>
                      json_bool(defined $on ? $on : 1) }, $cb);
    return;
}

sub open_story {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('open_story', 2, \@args);
    my ($chat_id, $story_id) = @args;
    need('story_poster_chat_id, story_id', $chat_id, $story_id);
    $self->send({ '@type' => 'openStory',
                  story_poster_chat_id => 0 + $chat_id,
                  story_id => 0 + $story_id }, $cb);
    return;
}

sub close_story {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('close_story', 2, \@args);
    my ($chat_id, $story_id) = @args;
    need('story_poster_chat_id, story_id', $chat_id, $story_id);
    $self->send({ '@type' => 'closeStory',
                  story_poster_chat_id => 0 + $chat_id,
                  story_id => 0 + $story_id }, $cb);
    return;
}

sub report_story {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $story_id, @rest) = @args;
    my %opt = opts(@rest);
    need('story_poster_chat_id, story_id', $chat_id, $story_id);
    $self->send({ '@type' => 'reportStory',
                  story_poster_chat_id => 0 + $chat_id,
                  story_id => 0 + $story_id,
                  option_id => plain_text('a report option id', $opt{option_id}),
                  text => plain_text('the report text', $opt{text}) }, $cb);
    return;
}

sub story_public_forwards {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $story_id, @rest) = @args;
    my %opt = opts(@rest);
    need('story_poster_chat_id, story_id', $chat_id, $story_id);
    $self->send({ '@type' => 'getStoryPublicForwards',
                  story_poster_chat_id => 0 + $chat_id,
                  story_id => 0 + $story_id,
                  offset => plain_text('an offset', $opt{offset}),
                  limit => num('limit', $opt{limit} // 50) }, $cb);
    return;
}

sub story_reactions {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'getStoryAvailableReactions',
                  row_size => num('row_size', $opt{row_size} // 8) }, $cb);
    return;
}

sub set_story_reaction {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $story_id, $reaction, @rest) = @args;
    my %opt = opts(@rest);
    need('story_poster_chat_id, story_id, reaction', $chat_id, $story_id, $reaction);
    $self->send({
        '@type'                   => 'setStoryReaction',
        story_poster_chat_id      => 0 + $chat_id,
        story_id                  => 0 + $story_id,
        reaction_type             => $self->reaction_type($reaction),
        update_recent_reactions   =>
            json_bool(exists $opt{update_recent} ? $opt{update_recent} : 1),
    }, $cb);
    return;
}

# --- albums

sub story_albums {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('story_albums', 1, \@args);
    my ($chat_id) = @args;
    need('chat_id', $chat_id);
    $self->send({ '@type' => 'getChatStoryAlbums',
                  chat_id => 0 + $chat_id }, $cb);
    return;
}

sub create_story_album {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('create_story_album', 3, \@args);
    my ($chat_id, $name, $ids) = @args;
    need('story_poster_chat_id, name', $chat_id, $name);
    $self->send({ '@type' => 'createStoryAlbum',
                  story_poster_chat_id => 0 + $chat_id,
                  name => plain_text('an album name', $name),
                  story_ids => num_list('story_ids', $ids // []) }, $cb);
    return;
}

sub delete_story_album {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_story_album', 2, \@args);
    my ($chat_id, $album_id) = @args;
    need('chat_id, story_album_id', $chat_id, $album_id);
    $self->send({ '@type' => 'deleteStoryAlbum',
                  chat_id => 0 + $chat_id,
                  story_album_id => 0 + $album_id }, $cb);
    return;
}

sub set_story_album_name {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_story_album_name', 3, \@args);
    my ($chat_id, $album_id, $name) = @args;
    need('chat_id, story_album_id, name', $chat_id, $album_id, $name);
    $self->send({ '@type' => 'setStoryAlbumName',
                  chat_id => 0 + $chat_id,
                  story_album_id => 0 + $album_id,
                  name => plain_text('an album name', $name) }, $cb);
    return;
}

sub story_album_stories {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($chat_id, $album_id, @rest) = @args;
    my %opt = opts(@rest);
    need('chat_id, story_album_id', $chat_id, $album_id);
    $self->send({ '@type' => 'getStoryAlbumStories',
                  chat_id => 0 + $chat_id,
                  story_album_id => 0 + $album_id,
                  offset => num('offset', $opt{offset} // 0),
                  limit => num('limit', $opt{limit} // 50) }, $cb);
    return;
}

sub add_album_stories {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('add_album_stories', 3, \@args);
    my ($chat_id, $album_id, $ids) = @args;
    need('chat_id, story_album_id, story_ids', $chat_id, $album_id, $ids);
    $self->send({ '@type' => 'addStoryAlbumStories',
                  chat_id => 0 + $chat_id,
                  story_album_id => 0 + $album_id,
                  story_ids => num_list('story_ids', $ids) }, $cb);
    return;
}

sub remove_album_stories {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('remove_album_stories', 3, \@args);
    my ($chat_id, $album_id, $ids) = @args;
    need('chat_id, story_album_id, story_ids', $chat_id, $album_id, $ids);
    $self->send({ '@type' => 'removeStoryAlbumStories',
                  chat_id => 0 + $chat_id,
                  story_album_id => 0 + $album_id,
                  story_ids => num_list('story_ids', $ids) }, $cb);
    return;
}

sub reorder_album_stories {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('reorder_album_stories', 3, \@args);
    my ($chat_id, $album_id, $ids) = @args;
    need('chat_id, story_album_id, story_ids', $chat_id, $album_id, $ids);
    $self->send({ '@type' => 'reorderStoryAlbumStories',
                  chat_id => 0 + $chat_id,
                  story_album_id => 0 + $album_id,
                  story_ids => num_list('story_ids', $ids) }, $cb);
    return;
}

sub reorder_story_albums {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('reorder_story_albums', 2, \@args);
    my ($chat_id, $ids) = @args;
    need('chat_id, story_album_ids', $chat_id, $ids);
    $self->send({ '@type' => 'reorderStoryAlbums',
                  chat_id => 0 + $chat_id,
                  story_album_ids => num_list('story_album_ids', $ids) }, $cb);
    return;
}

1;
