package EV::Telegram::TDLib::Stickers;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

=head1 NAME

EV::Telegram::TDLib::Stickers - sticker methods for EV::Telegram::TDLib

=head1 DESCRIPTION

One of the mixins L<EV::Telegram::TDLib> inherits from. It has no
interface of its own and is not meant to be used directly: loading the
main module loads this one, and its methods are called on a client.

They are documented together with the rest of the API, under
L<EV::Telegram::TDLib/"Stickers mixin">.

=cut

sub CLONE_SKIP { 1 }


our %UPDATES;

# Sticker set ids and custom emoji ids are int64 and must cross the JSON
# interface as strings, including inside a vector.
sub sticker_id_list {
    my ($what, $ids) = @_;
    return text_list($what, $ids // []);
}

my %FORMAT = (webp => 'stickerFormatWebp',
              tgs  => 'stickerFormatTgs',
              webm => 'stickerFormatWebm');

my %TYPE = (regular      => 'stickerTypeRegular',
            mask         => 'stickerTypeMask',
            custom_emoji => 'stickerTypeCustomEmoji');

sub sticker_format {
    my ($fmt) = @_;
    $fmt = 'webp' unless defined $fmt;
    my $t = $FORMAT{$fmt} or croak "sticker format must be webp, tgs or webm";
    return { '@type' => $t };
}

sub sticker_type {
    my ($type) = @_;
    $type = 'regular' unless defined $type;
    return $type if ref $type eq 'HASH';
    my $t = $TYPE{$type}
        or croak "sticker type must be regular, mask or custom_emoji";
    return { '@type' => $t };
}

# newSticker, not inputSticker: the latter is the wrapper for sending a
# sticker message and carries thumbnail/width/height instead of the emoji
# and format a set member needs.
sub new_sticker {
    my ($spec) = @_;
    croak 'each sticker must be a hashref' unless ref $spec eq 'HASH';
    need('file, emojis', @{$spec}{qw(file emojis)});
    return {
        '@type'   => 'newSticker',
        sticker   => input_file($spec->{file}),
        format    => sticker_format($spec->{format}),
        emojis    => plain_text('emojis', $spec->{emojis}),
        keywords  => text_list('keywords', $spec->{keywords} // []),
        ($spec->{mask_position} ? (mask_position => $spec->{mask_position}) : ()),
    };
}

# --- reading

sub sticker_set {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('sticker_set', 1, \@args);
    my ($set_id) = @args;
    need('set_id', $set_id);
    $self->send({ '@type' => 'getStickerSet',
                  set_id => plain_text('a sticker set id', $set_id) }, $cb);
    return;
}

sub search_sticker_set {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($name, @rest) = @args;
    my %opt = opts(@rest);
    need('name', $name);
    $self->send({ '@type' => 'searchStickerSet',
                  name => plain_text('a sticker set name', $name),
                  ignore_cache => json_bool($opt{ignore_cache}) }, $cb);
    return;
}

sub search_sticker_sets {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($query, @rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'searchStickerSets',
                  sticker_type => sticker_type($opt{type}),
                  query => plain_text('a query', $query) }, $cb);
    return;
}

sub installed_sticker_sets {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'getInstalledStickerSets',
                  sticker_type => sticker_type($opt{type}) }, $cb);
    return;
}

sub archived_sticker_sets {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'getArchivedStickerSets',
                  sticker_type => sticker_type($opt{type}),
                  offset_sticker_set_id =>
                      plain_text('a sticker set id',
                                 $opt{offset_sticker_set_id} // 0),
                  limit => num('limit', $opt{limit} // 100) }, $cb);
    return;
}

sub trending_sticker_sets {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'getTrendingStickerSets',
                  sticker_type => sticker_type($opt{type}),
                  offset => num('offset', $opt{offset} // 0),
                  limit => num('limit', $opt{limit} // 20) }, $cb);
    return;
}

sub owned_sticker_sets {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'getOwnedStickerSets',
                  offset_sticker_set_id =>
                      plain_text('a sticker set id',
                                 $opt{offset_sticker_set_id} // 0),
                  limit => num('limit', $opt{limit} // 100) }, $cb);
    return;
}

sub stickers {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($query, @rest) = @args;
    my %opt = opts(@rest);
    $self->send({ '@type' => 'getStickers',
                  sticker_type => sticker_type($opt{type}),
                  query => plain_text('a query', $query),
                  limit => num('limit', $opt{limit} // 20),
                  chat_id => num('chat_id', $opt{chat_id} // 0) }, $cb);
    return;
}

sub search_stickers {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($emojis, @rest) = @args;
    my %opt = opts(@rest);
    need('emojis', $emojis);
    $self->send({
        '@type'                => 'searchStickers',
        sticker_type           => sticker_type($opt{type}),
        emojis                 => plain_text('emojis', $emojis),
        query                  => plain_text('a query', $opt{query}),
        input_language_codes   => text_list('languages', $opt{languages} // []),
        offset                 => num('offset', $opt{offset} // 0),
        limit                  => num('limit', $opt{limit} // 20),
    }, $cb);
    return;
}

sub favorite_stickers {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('favorite_stickers', 0, \@args);
    $self->send({ '@type' => 'getFavoriteStickers' }, $cb);
    return;
}

sub recent_stickers {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'getRecentStickers',
                  is_attached => json_bool($opt{attached}) }, $cb);
    return;
}

sub custom_emoji_stickers {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('custom_emoji_stickers', 1, \@args);
    my ($ids) = @args;
    need('custom_emoji_ids', $ids);
    $self->send({ '@type' => 'getCustomEmojiStickers',
                  custom_emoji_ids => sticker_id_list('custom_emoji_ids', $ids) }, $cb);
    return;
}

sub default_emoji_statuses {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('default_emoji_statuses', 0, \@args);
    $self->send({ '@type' => 'getDefaultEmojiStatuses' }, $cb);
    return;
}

sub check_sticker_set_name {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('check_sticker_set_name', 1, \@args);
    my ($name) = @args;
    need('name', $name);
    $self->send({ '@type' => 'checkStickerSetName',
                  name => plain_text('a sticker set name', $name) }, $cb);
    return;
}

# --- favourites and recents

sub add_favorite_sticker {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('add_favorite_sticker', 1, \@args);
    my ($sticker) = @args;
    need('sticker', $sticker);
    $self->send({ '@type' => 'addFavoriteSticker',
                  sticker => input_file($sticker) }, $cb);
    return;
}

sub remove_favorite_sticker {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('remove_favorite_sticker', 1, \@args);
    my ($sticker) = @args;
    need('sticker', $sticker);
    $self->send({ '@type' => 'removeFavoriteSticker',
                  sticker => input_file($sticker) }, $cb);
    return;
}

sub add_recent_sticker {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($sticker, @rest) = @args;
    my %opt = opts(@rest);
    need('sticker', $sticker);
    $self->send({ '@type' => 'addRecentSticker',
                  is_attached => json_bool($opt{attached}),
                  sticker => input_file($sticker) }, $cb);
    return;
}

sub remove_recent_sticker {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($sticker, @rest) = @args;
    my %opt = opts(@rest);
    need('sticker', $sticker);
    $self->send({ '@type' => 'removeRecentSticker',
                  is_attached => json_bool($opt{attached}),
                  sticker => input_file($sticker) }, $cb);
    return;
}

sub clear_recent_stickers {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my %opt = opts(@args);
    $self->send({ '@type' => 'clearRecentStickers',
                  is_attached => json_bool($opt{attached}) }, $cb);
    return;
}

# --- set management

sub install_sticker_set {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($set_id, $installed, @rest) = @args;
    my %opt = opts(@rest);
    need('set_id', $set_id);
    # TDLib refuses a set that is installed and archived at once, so asking
    # for the archive implies leaving the installed list
    my $install = json_bool(defined $installed ? $installed : 1);
    my $archived = json_bool($opt{archived});
    $self->send({ '@type' => 'changeStickerSet',
                  set_id => plain_text('a sticker set id', $set_id),
                  is_installed => $$archived ? json_bool(0) : $install,
                  is_archived => $archived }, $cb);
    return;
}

sub reorder_sticker_sets {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($ids, @rest) = @args;
    my %opt = opts(@rest);
    need('sticker_set_ids', $ids);
    $self->send({ '@type' => 'reorderInstalledStickerSets',
                  sticker_type => sticker_type($opt{type}),
                  sticker_set_ids => sticker_id_list('sticker_set_ids', $ids) }, $cb);
    return;
}

# a set is built from uploaded files, not from local paths: upload each
# sticker first and pass the returned remote file to create_sticker_set
sub upload_sticker_file {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($user_id, $sticker, @rest) = @args;
    my %opt = opts(@rest);
    need('user_id, sticker', $user_id, $sticker);
    $self->send({ '@type' => 'uploadStickerFile', user_id => 0 + $user_id,
                  sticker_format => sticker_format($opt{format}),
                  sticker => input_file($sticker) }, $cb);
    return;
}

sub create_sticker_set {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($user_id, $title, $name, $stickers, @rest) = @args;
    my %opt = opts(@rest);
    need('user_id, title, name, stickers', $user_id, $title, $name, $stickers);
    croak 'stickers must be an arrayref' unless ref $stickers eq 'ARRAY';
    croak 'a sticker set needs at least one sticker' unless @$stickers;
    $self->send({
        '@type'           => 'createNewStickerSet',
        user_id           => 0 + $user_id,
        title             => plain_text('a title', $title),
        name              => plain_text('a sticker set name', $name),
        sticker_type      => sticker_type($opt{type}),
        needs_repainting  => json_bool($opt{needs_repainting}),
        stickers          => [ map { new_sticker($_) } @$stickers ],
        source            => plain_text('a source', $opt{source}),
    }, $cb);
    return;
}

sub add_sticker_to_set {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('add_sticker_to_set', 3, \@args);
    my ($user_id, $name, $sticker) = @args;
    need('user_id, name, sticker', $user_id, $name, $sticker);
    $self->send({ '@type' => 'addStickerToSet', user_id => 0 + $user_id,
                  name => plain_text('a sticker set name', $name),
                  sticker => new_sticker($sticker) }, $cb);
    return;
}

sub replace_sticker_in_set {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('replace_sticker_in_set', 4, \@args);
    my ($user_id, $name, $old, $new) = @args;
    need('user_id, name, old_sticker, new_sticker', $user_id, $name, $old, $new);
    $self->send({ '@type' => 'replaceStickerInSet', user_id => 0 + $user_id,
                  name => plain_text('a sticker set name', $name),
                  old_sticker => input_file($old),
                  new_sticker => new_sticker($new) }, $cb);
    return;
}

sub remove_sticker_from_set {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('remove_sticker_from_set', 1, \@args);
    my ($sticker) = @args;
    need('sticker', $sticker);
    $self->send({ '@type' => 'removeStickerFromSet',
                  sticker => input_file($sticker) }, $cb);
    return;
}

sub set_sticker_position {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_sticker_position', 2, \@args);
    my ($sticker, $position) = @args;
    need('sticker, position', $sticker, $position);
    $self->send({ '@type' => 'setStickerPositionInSet',
                  sticker => input_file($sticker),
                  position => num('position', $position) }, $cb);
    return;
}

sub set_sticker_set_title {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('set_sticker_set_title', 2, \@args);
    my ($name, $title) = @args;
    need('name, title', $name, $title);
    $self->send({ '@type' => 'setStickerSetTitle',
                  name => plain_text('a sticker set name', $name),
                  title => plain_text('a title', $title) }, $cb);
    return;
}

sub set_sticker_set_thumbnail {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($user_id, $name, $thumb, @rest) = @args;
    my %opt = opts(@rest);
    need('user_id, name, thumbnail', $user_id, $name, $thumb);
    $self->send({ '@type' => 'setStickerSetThumbnail', user_id => 0 + $user_id,
                  name => plain_text('a sticker set name', $name),
                  thumbnail => input_file($thumb),
                  format => sticker_format($opt{format}) }, $cb);
    return;
}

sub delete_sticker_set {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    no_extra('delete_sticker_set', 1, \@args);
    my ($name) = @args;
    need('name', $name);
    $self->send({ '@type' => 'deleteStickerSet',
                  name => plain_text('a sticker set name', $name) }, $cb);
    return;
}

# passing undef clears the status; Premium accounts only
sub set_emoji_status {
    my ($self, @args) = @_;
    my $cb = ref $args[-1] eq 'CODE' ? pop @args : sub {};
    my ($custom_emoji_id, @rest) = @args;
    my %opt = opts(@rest);
    my %status = ('@type' => 'emojiStatus',
                  expiration_date => unix_time('expires', $opt{expires} // 0));
    $status{type} = { '@type' => 'emojiStatusTypeCustomEmoji',
                      custom_emoji_id =>
                          plain_text('a custom emoji id', $custom_emoji_id) }
        if defined $custom_emoji_id;
    $self->send({ '@type' => 'setEmojiStatus', emoji_status => \%status }, $cb);
    return;
}

1;
