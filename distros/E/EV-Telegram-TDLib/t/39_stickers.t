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
# the module encodes with ->utf8, so decoding without it would hand back
# bytes and make any non-ASCII comparison below fail on encoding alone
sub last_req  { Cpanel::JSON::XS->new->utf8->decode($sent[-1]) }

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-stickers');

# --- int64 set ids must cross as strings, singly and in vectors
$td->sticker_set('1358476933002673', sub {});
my $r = last_req();
is $r->{'@type'}, 'getStickerSet', 'sticker_set sends getStickerSet';
like last_json(), qr/"set_id":"1358476933002673"/, 'set_id crosses as a JSON string';

$td->install_sticker_set('1358476933002673', sub {});
$r = last_req();
is $r->{'@type'}, 'changeStickerSet', 'install_sticker_set';
like last_json(), qr/"set_id":"1358476933002673"/, 'and stringifies set_id too';
like last_json(), qr/"is_installed":true/, 'installing by default';

$td->install_sticker_set('1358476933002673', 0, sub {});
like last_json(), qr/"is_installed":false/, 'and uninstalling when told to';

$td->reorder_sticker_sets([1, 2], sub {});
$r = last_req();
is $r->{'@type'}, 'reorderInstalledStickerSets', 'reorder_sticker_sets';
like last_json(), qr/"sticker_set_ids":\["1","2"\]/,
    'a vector<int64> is an array of strings';

$td->custom_emoji_stickers([5, 6], sub {});
$r = last_req();
is $r->{'@type'}, 'getCustomEmojiStickers', 'custom_emoji_stickers';
like last_json(), qr/"custom_emoji_ids":\["5","6"\]/,
    'custom_emoji_ids is also a vector of strings';

$td->archived_sticker_sets(offset_sticker_set_id => '99', sub {});
like last_json(), qr/"offset_sticker_set_id":"99"/,
    'offset_sticker_set_id crosses as a string';

# --- sticker_type coercion
$td->installed_sticker_sets(sub {});
$r = last_req();
is $r->{'@type'}, 'getInstalledStickerSets', 'installed_sticker_sets';
is $r->{sticker_type}{'@type'}, 'stickerTypeRegular', 'sticker type defaults to regular';

$td->installed_sticker_sets(type => 'custom_emoji', sub {});
is last_req()->{sticker_type}{'@type'}, 'stickerTypeCustomEmoji',
    'custom_emoji type coerces';

$td->installed_sticker_sets(type => 'mask', sub {});
is last_req()->{sticker_type}{'@type'}, 'stickerTypeMask', 'mask type coerces';

eval { $td->installed_sticker_sets(type => 'bogus', sub {}) };
like $@, qr/sticker type/, 'an unknown sticker type croaks';

# --- searching
$td->search_sticker_set('AnimatedEmojies', sub {});
$r = last_req();
is $r->{'@type'}, 'searchStickerSet', 'search_sticker_set is the exact-name call';
is $r->{name}, 'AnimatedEmojies', 'name passed through';

$td->search_sticker_sets('cats', sub {});
is last_req()->{'@type'}, 'searchStickerSets', 'search_sticker_sets is the discovery call';

$td->search_stickers("\x{1F431}", sub {});
is last_req()->{'@type'}, 'searchStickers', 'search_stickers';

$td->check_sticker_set_name('my_pack_by_bot', sub {});
$r = last_req();
is $r->{'@type'}, 'checkStickerSetName', 'check_sticker_set_name';
is $r->{name}, 'my_pack_by_bot', 'name passed through';

# --- favourites and recents take an InputFile, not an id
$td->add_favorite_sticker('cat.webp', sub {});
$r = last_req();
is $r->{'@type'}, 'addFavoriteSticker', 'add_favorite_sticker';
is $r->{sticker}{'@type'}, 'inputFileLocal', 'a bare path becomes an inputFileLocal';
is $r->{sticker}{path}, 'cat.webp', 'with the path given';

$td->add_recent_sticker('cat.webp', sub {});
$r = last_req();
is $r->{'@type'}, 'addRecentSticker', 'add_recent_sticker';
like last_json(), qr/"is_attached":false/, 'is_attached defaults false';

$td->clear_recent_stickers(sub {});
is last_req()->{'@type'}, 'clearRecentStickers', 'clear_recent_stickers';

# --- uploading, then creating: a set is built from uploaded files
$td->upload_sticker_file(7, 'cat.webp', sub {});
$r = last_req();
is $r->{'@type'}, 'uploadStickerFile', 'upload_sticker_file';
is $r->{sticker_format}{'@type'}, 'stickerFormatWebp', 'format defaults to webp';
is $r->{user_id}, 7, 'user_id is int53 and stays numeric';

$td->upload_sticker_file(7, 'anim.tgs', format => 'tgs', sub {});
is last_req()->{sticker_format}{'@type'}, 'stickerFormatTgs', 'tgs format coerces';

# --- newSticker, not inputSticker
$td->create_sticker_set(7, 'My Pack', 'my_pack_by_bot',
    [ { file => 'cat.webp', emojis => "\x{1F431}", keywords => ['cat'] } ],
    sub {});
$r = last_req();
is $r->{'@type'}, 'createNewStickerSet', 'create_sticker_set';
is $r->{stickers}[0]{'@type'}, 'newSticker',
    'the vector element is newSticker, not inputSticker';
is $r->{stickers}[0]{format}{'@type'}, 'stickerFormatWebp', 'per-sticker format';
is $r->{stickers}[0]{emojis}, "\x{1F431}", 'emojis carried';
is_deeply $r->{stickers}[0]{keywords}, ['cat'], 'keywords carried';
is $r->{stickers}[0]{sticker}{'@type'}, 'inputFileLocal', 'file becomes an InputFile';

eval { $td->create_sticker_set(7, 'T', 'n', [ { file => 'c.webp' } ], sub {}) };
like $@, qr/emojis/, 'a sticker without emojis croaks';

eval { $td->create_sticker_set(7, 'T', 'n', [ 'not-a-hash' ], sub {}) };
like $@, qr/hashref/, 'a non-hashref sticker croaks';

$td->add_sticker_to_set(7, 'my_pack_by_bot',
    { file => 'dog.webp', emojis => "\x{1F436}" }, sub {});
$r = last_req();
is $r->{'@type'}, 'addStickerToSet', 'add_sticker_to_set';
is $r->{sticker}{'@type'}, 'newSticker', 'and uses newSticker as well';

$td->replace_sticker_in_set(7, 'my_pack_by_bot', 'old.webp',
    { file => 'new.webp', emojis => "\x{1F436}" }, sub {});
$r = last_req();
is $r->{'@type'}, 'replaceStickerInSet', 'replace_sticker_in_set';
is $r->{old_sticker}{'@type'}, 'inputFileLocal', 'old sticker is a plain InputFile';
is $r->{new_sticker}{'@type'}, 'newSticker', 'new sticker is a newSticker';

$td->set_sticker_set_thumbnail(7, 'my_pack_by_bot', 'thumb.webp', sub {});
$r = last_req();
is $r->{'@type'}, 'setStickerSetThumbnail', 'set_sticker_set_thumbnail';
is $r->{format}{'@type'}, 'stickerFormatWebp', 'thumbnail format coerces';

$td->set_sticker_position(   'cat.webp', 3, sub {});
is last_req()->{'@type'}, 'setStickerPositionInSet', 'set_sticker_position';

$td->remove_sticker_from_set('cat.webp', sub {});
is last_req()->{'@type'}, 'removeStickerFromSet', 'remove_sticker_from_set';

$td->set_sticker_set_title('my_pack_by_bot', 'Nicer', sub {});
is last_req()->{'@type'}, 'setStickerSetTitle', 'set_sticker_set_title';

$td->delete_sticker_set('my_pack_by_bot', sub {});
is last_req()->{'@type'}, 'deleteStickerSet', 'delete_sticker_set';

# --- emoji status nests an int64 inside a union inside an object
$td->set_emoji_status('5312536423851630001', sub {});
$r = last_req();
is $r->{'@type'}, 'setEmojiStatus', 'set_emoji_status';
is $r->{emoji_status}{'@type'}, 'emojiStatus', 'wrapped in an emojiStatus';
is $r->{emoji_status}{type}{'@type'}, 'emojiStatusTypeCustomEmoji', 'with a custom emoji type';
like last_json(), qr/"custom_emoji_id":"5312536423851630001"/,
    'and the nested int64 crosses as a string';

$td->set_emoji_status(undef, sub {});
$r = last_req();
ok !exists $r->{emoji_status}{type}, 'passing undef clears the status';

$td->default_emoji_statuses(sub {});
is last_req()->{'@type'}, 'getDefaultEmojiStatuses', 'default_emoji_statuses';

# --- TDLib refuses a set that is installed and archived at once, so asking
# for the archive has to imply leaving the installed list
{
    # the flag is a positional, so archived comes after it
    $td->install_sticker_set('123', undef, archived => 1, sub {});
    my $r = last_req();
    like last_json(), qr/"is_archived":true/, 'archived was requested';
    like last_json(), qr/"is_installed":false/,
        'and installed is forced off rather than sent alongside it';
}

done_testing;
