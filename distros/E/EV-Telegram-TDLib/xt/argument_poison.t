use strict;
use warnings;
use Test::More;

my %CALLER_ENV;
BEGIN {
    plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
    %CALLER_ENV = (EV_TDLIB_SHUTDOWN_TIMEOUT => $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT});
    # _send is stubbed, so the END block's close can never complete
    $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1;
}

use lib 'xt/lib';
use EV;
use EV::Telegram::TDLib;
use ArgumentPoison;
use MIME::Base64 ();
use Scalar::Util qw(refaddr);

# A reference where the module expects a scalar used to reach TDLib as its
# address: reply_to => $message numified to a pointer and Telegram sent a
# plain message instead of a reply, and a formattedText interpolated into a
# title named the album HASH(0x...). Nothing fails when that happens, so no
# ordinary test notices. xt/string_slots.t catches the shapes a regex can see;
# this one runs the code.
#
# Every public method is called for real, once as a test in t/ already calls
# it (harvested at run time, so a new test is a new baseline) and then again
# with one argument at a time replaced by a fresh reference: each positional,
# each element of an array argument, each field of a spec hash, and each
# option key the method or its helpers read, bare and wrapped in an arrayref.
# Every request that reaches tdjson -- including the ones sent only after a
# reply is injected, and the synchronous execute() ones -- is checked for the
# reference's address, its string form, base64 of either, and the reference
# itself where the method does not pass raw TL through by design.
#
# POISON_EXHAUSTIVE=1 widens the default sweep: every poison kind inside the
# arrayref wrapper, every harvested call that reaches the wire instead of
# those that exercise something the others do not, and every element of a
# list inside a list argument instead of its first two and its last.

my $EXHAUSTIVE = $ENV{POISON_EXHAUSTIVE} ? 1 : 0;
my $T0 = EV::time();
my @PHASE;
my $phase_at = $T0;
sub phase { my $now = EV::time(); push @PHASE, [ $_[0], $now - $phase_at ]; $phase_at = $now }

# ---------------------------------------------------------------- policy

# Not caller surface: the module drives these itself, with its own state.
my %INTERNAL = map { $_ => 1 } qw(
    abandon answer_ask ask_key auth_credential auth_fail_cb auth_parameters
    auth_reply_cb auth_update bootstrap cb_slot closed dispatch_raw
    downloads drain_error emit_error fail_login finish_ask guarded
    handle_update inject_raw is_registered merge_position need no_extra no_opts
    no_send_options not_a_number opts position_key posting posting_key
    resolve_my_username retry_attempt route_callback_data route_command
    send_once send_retrying sending sending_key uploads users
);

# Caller surface that neither reaches tdjson nor builds a TL object, so
# there is nothing for a poison to leak into. A method listed here that
# does reach the wire is a failure: the entry would be hiding it.
my %NO_WIRE = (
    (map { $_ => 'reads the local cache' }
        qw(auth_state chat connection_state my_id option user)),
    (map { $_ => 'registers a handler' }
        qw(on_active_stories on_business_connection on_business_message
           on_callback_data on_callback_query on_chat
           on_connection_state on_error on_inline_query on_join_request
           on_message on_pre_checkout_query on_shipping_query on_story
           on_story_deleted on_update on_upload on_user on_web_app_data)),
    cancel_ask             => 'drops a local wait',
    keepalive              => 'moves the loop reference',
    retry_after            => 'reads a number out of an error',
    entity_text            => 'slices a string out of a formattedText',
    check_application_name => 'validates a string it returns unchanged',
    json_bool              => 'returns a JSON boolean',
    (map { $_ => 'returns a scalar, checked in what its callers send' }
        qw(basic_group_id bot_id num plain_text real supergroup_id tl_bytes unix_time)),
);

# Driven by the constructor section below: their only caller data is the
# constructor's options and what the login handlers submit.
my %CTOR_DRIVEN = map { $_ => 1 } qw(new login);

# Raw TL by design: the arguments are the request.
my %RAW_METHOD = (
    call    => 'takes the function name and its arguments as given',
    send    => 'sends the request hash as given',
    execute => 'executes the request hash as given',
);

# TL slots documented to take a caller-built TL object, where a hashref (or
# an arrayref of them) reaching tdjson as given is the design rather than a
# leak. A reference is allowed when the field it lands in, or any field
# above it, is listed: a key added inside a raw reply_markup is still inside
# reply_markup. A field name common enough to mean something else elsewhere
# is listed as "method field", for that method only.
my %PASSTHROUGH_SLOT = (
    reply_markup           => 'a ReplyMarkup the caller built',
    scope                  => 'a BotCommandScope object',
    theme                  => 'a themeParameters object',
    areas                  => 'story areas reach TDLib as they are given',
    from_story_full_id     => 'the from_story option takes a storyFullId',
    privacy_settings       => 'a StoryPrivacySettings object',
    input_message_content  => 'an InputMessageContent object',
    input_message_contents => 'send_album takes InputMessageContent objects',
    user_location          => 'a location object',
    mask_position          => 'a maskPosition object',
    offset_member          => 'the cursor object a previous page returned',
    offset_request         => 'the cursor object a previous page returned',
    sticker_type           => 'a StickerType object instead of its short name',
    device_token           => 'a DeviceToken object',
    (map { $_ => 'a MessageSender hashref passes as given' }
        qw(sender_id owner_id message_sender_id new_owner_id)),
    (map { $_ => 'a chatAdministratorRights object' }
        qw(default_channel_administrator_rights default_group_administrator_rights)),
    'add_bot_media_preview content'    => 'an InputStoryContent object',
    'add_paid_reaction type'           => 'a PaidReactionType object',
    'answer_web_app_query result'      => 'an InputInlineQueryResult object',
    'business_features source'         => 'a BusinessFeature object',
    'edit_bot_media_preview content'   => 'an InputStoryContent object',
    'edit_inline_location location'    => 'a location object',
    'edit_message_location location'   => 'a location object',
    'markdown_text text'               => 'a formattedText object',
    'set_bot_access_settings settings' => 'a managed bot access settings object',
    'set_business_account_photo photo' => 'an InputChatPhoto object',
    'set_paid_reaction_type type'      => 'a PaidReactionType object',
    'set_privacy rules'                => 'userPrivacySettingRule objects',
);

# An object that overloads "" must produce the same request as the string it
# stands for. Entries: method => { argument label => reason }.
my %OVERLOAD_OK = (
);

# Calls for the methods no t/ file drives to the wire. Each one must reach
# the wire: a baseline that stops doing so is a failure, not a skipped method.
my $ft = sub { { '@type' => 'formattedText', text => 'x', entities => [] } };
my %BASELINE = (
    active_stories   => [ [-100123] ],
    affiliate        => [ [{ bot => 5 }], [{ channel => -100123 }] ],
    archived_stories => [ [-100123, from_story_id => 1, limit => 5] ],
    away_schedule    => [ [{ start => 1_700_000_000, end => 1_700_000_100 }], ['always'] ],
    bot_rights       => [ [{ can_reply => 1, can_read_messages => 0 }] ],
    button_source    => [ [-100123, 5] ],
    can_post_story   => [ [-100123] ],
    chat_action      => [ [-100123, 'typing'] ],
    chat_list        => [ ['main'], [3] ],
    chat_story_interactions => [ [-100123, 5, offset => 'o', limit => 5, prefer_forwards => 1] ],
    chats_to_post_stories   => [ [] ],
    check_quick_reply_name  => [ ['hello'] ],
    close_story      => [ [-100123, 5] ],
    contact          => [ [{ phone => '+15550000', first_name => 'a', last_name => 'b', note => 'n' }] ],
    delete_file      => [ [5] ],
    delete_story     => [ [-100123, 5] ],
    delete_story_album => [ [-100123, 5] ],
    edit_bot_media_preview => [ [5, 6, { '@type' => 'inputStoryContentPhoto',
                                         photo => { '@type' => 'inputFileLocal', path => 'p' },
                                         added_sticker_file_ids => [] }, language_code => 'en'] ],
    edit_story       => [ [-100123, 5, content => 'p.jpg', caption => 'c'],
                          [-100123, 5, content => { video => 'v.mp4', duration => 1,
                                                    cover_frame_timestamp => 1, sticker_file_ids => [1] }] ],
    edit_story_cover => [ [-100123, 5, 1] ],
    favorite_stickers => [ [] ],
    format_text      => [ ['hi *b*', 'markdown'], ['hi'] ],
    icon             => [ [{ color => 1, custom_emoji_id => '5' }] ],
    input_chat_photo => [ ['p.jpg'], ['p.mp4', { animation => 1, main_frame_timestamp => 1 }] ],
    input_content    => [ ['p.jpg', { kind => 'photo', caption => 'c', width => 1, height => 2 }],
                          ['v.mp4', { kind => 'video', duration => 1, width => 1, height => 2 }],
                          ['a.mp3', { kind => 'audio', duration => 1, title => 't', performer => 'p' }],
                          ['s.webp', { kind => 'sticker', emoji => 'e' }] ],
    input_file       => [ ['p.jpg'] ],
    input_text       => [ ['hi', { parse_mode => 'markdown', disable_preview => 1 }] ],
    invoice_content  => [ [{ title => 't', description => 'd', payload => 'p', currency => 'USD',
                             prices => [['a', 100], { label => 'b', amount => 2 }], tips => [1],
                             max_tip => 5, photo_url => 'u', photo_size => 1, photo_width => 1,
                             photo_height => 1, provider_token => 'tok', provider_data => '{}',
                             start_parameter => 's', test => 1 }] ],
    link_info        => [ ['t', { title => 'x', parse_mode => 'markdown' }] ],
    markdown_text    => [ [$ft->()] ],
    new_sticker      => [ [{ file => 'p.webp', emojis => 'x', keywords => ['k', 'l'], format => 'webp' }] ],
    num_list         => [ ['ids', [1, 2]] ],
    open_story       => [ [-100123, 5] ],
    owned_sticker_sets => [ [offset_sticker_set_id => '1', limit => 5] ],
    page_stories     => [ [-100123, from_story_id => 1, limit => 5] ],
    paid_reaction_type => [ ['regular'], [-100123] ],
    ping_proxy       => [ [{ server => 's', port => 1, type => 'socks5', username => 'u', password => 'p' }],
                          [{ server => 's', port => 1, type => 'mtproto', secret => 'ab' }],
                          [{ server => 's', port => 1, type => 'http', username => 'u', password => 'p', http_only => 1 }] ],
    price_parts      => [ [[['a', 1], { label => 'b', amount => 2 }]] ],
    proxy            => [ [{ server => 's', port => 1, type => 'socks5', username => 'u', password => 'p' }] ],
    reaction_source  => [ ['source', 'all'] ],
    recent_stickers  => [ [attached => 1] ],
    recently_opened_chats => [ [limit => 5] ],
    recipients       => [ [{ chat_ids => [1], excluded_chat_ids => [2], select_contacts => 1 }] ],
    remove_favorite_sticker => [ ['p.webp'] ],
    remove_from_downloads   => [ [5, delete_cache => 1] ],
    remove_recent_sticker   => [ ['p.webp', attached => 1] ],
    reorder_bot_media_previews => [ [5, [1, 2], language_code => 'en'] ],
    report_story     => [ [-100123, 5, option_id => 'o', text => 't'] ],
    request_chat_type  => [ [{ id => 1, channel => 1, forum => 1, username => 1, created => 1,
                               bot_is_member => 1, want_title => 1,
                               user_rights => { '@type' => 'chatAdministratorRights', can_manage_chat => \1 } }] ],
    request_users_type => [ [{ id => 1, bot => 0, premium => 1, max => 2, want_name => 1 }] ],
    scope            => [ ['private'] ],
    search_messages  => [ [-100123, 'q', from_message_id => 1, offset => 0, limit => 5] ],
    send_business_file => [ ['conn', -100123, 'p.jpg', caption => 'c', reply_to => 5, kind => 'photo'],
                            ['conn', -100123, 'v.mp4', kind => 'video', duration => 1] ],
    send_content     => [ [-100123, { '@type' => 'inputMessageText', text => $ft->() },
                           { wait => 'accepted', reply_to => 5, silent => 1, topic => 3 }] ],
    send_options     => [ [{ silent => 1, schedule => 1_700_000_000 }] ],
    sender           => [ [7] ],
    set_business_account_photo => [ ['conn', 'p.jpg', public => 1] ],
    set_log_verbosity => [ [1] ],
    set_story_album_name => [ [-100123, 5, 'n'] ],
    set_story_privacy    => [ [5, 'contacts', except => [7]], [5, [7, 8]] ],
    sticker_format   => [ ['webp'] ],
    sticker_id_list  => [ ['ids', [1, 2]] ],
    sticker_type     => [ ['mask'] ],
    stickers         => [ ['q', type => 'custom_emoji', limit => 5, chat_id => -100123] ],
    story_album_stories => [ [-100123, 5, offset => 1, limit => 2] ],
    story_albums     => [ [-100123] ],
    story_content    => [ ['p.jpg'], [{ video => 'v.mp4', duration => 1, cover_frame_timestamp => 1,
                                        sticker_file_ids => [1] }] ],
    story_interactions => [ [5, query => 'q', offset => 'o', limit => 5] ],
    story_privacy    => [ ['contacts', [7]], [[7, 8]] ],
    story_public_forwards => [ [-100123, 5, offset => 'o', limit => 5] ],
    suggested_file_name   => [ [5, directory => 'd'] ],
    text_list        => [ ['names', ['a', 'b']] ],
    tl_class         => [ ['fileType', 'FileType', 'a file type', 'Video'] ],
    topic_id         => [ [{ topic => 5 }] ],
    trending_sticker_sets => [ [type => 'regular', offset => 1, limit => 2] ],
);

# Constructor option sets, each with the credential its login handlers submit.
my @CTOR_BASE = (
    [ { phone_number => '+15550000', register => { first_name => 'a', last_name => 'b' },
        database_encryption_key => 'key', files_directory => 'files',
        system_language_code => 'en', device_model => 'model', system_version => 'sys',
        application_version => '1.0', application_name => 'app', use_test_dc => 1 }, '12345' ],
    [ { bot_token => '1:token' }, '12345' ],
);

# ---------------------------------------------------------------- setup

my $sw = ArgumentPoison->new(exhaustive => $EXHAUSTIVE);
phase('setup');
my %SUB = %{ $sw->{sub} };
my @surface = sort grep { $SUB{$_}{public} && !$SUB{$_}{update_handler} } keys %SUB;
cmp_ok scalar(@surface), '>', 300, 'the symbol tables yield the public surface';

{
    my @stale;
    for my $list ([INTERNAL => \%INTERNAL], [NO_WIRE => \%NO_WIRE],
                  [CTOR_DRIVEN => \%CTOR_DRIVEN], [RAW_METHOD => \%RAW_METHOD],
                  [BASELINE => \%BASELINE], [OVERLOAD_OK => \%OVERLOAD_OK]) {
        push @stale, map { "$list->[0]: $_" } grep { !$SUB{$_} } sort keys %{ $list->[1] };
    }
    push @stale, map { "PASSTHROUGH_SLOT: $_" }
                 grep { /\A(\w+) / && !$SUB{$1} } sort keys %PASSTHROUGH_SLOT;
    my %where;
    for my $list ([INTERNAL => \%INTERNAL], [NO_WIRE => \%NO_WIRE],
                  [CTOR_DRIVEN => \%CTOR_DRIVEN]) {
        push @{ $where{$_} }, $list->[0] for keys %{ $list->[1] };
    }
    push @stale, map { "$_ is in @{ $where{$_} }" } grep { @{ $where{$_} } > 1 } sort keys %where;
    is_deeply \@stale, [], 'every policy entry names an existing sub, in one list only'
        or diag join "\n", @stale;
}

# ---------------------------------------------------------------- detector

# the checker on hand-built requests: each shape a leak can take must be seen
{
    my $p = {};
    my $a = refaddr $p;
    my @shapes = (
        [ stringified => { '@type' => 'x', title => "$p" } ],
        [ stringified => { '@type' => 'x', title => lc "a $p b" } ],
        [ address     => { '@type' => 'x', id => 0 + $p } ],
        [ address     => { '@type' => 'x', id => 1 + $p } ],
        [ address     => { '@type' => 'x', id => "$a" } ],
        [ address     => { '@type' => 'x', name => sprintf('%x', $a) } ],
        [ base64      => { '@type' => 'x', data => MIME::Base64::encode_base64("$p", '') } ],
        [ base64      => { '@type' => 'x', data => MIME::Base64::encode_base64("$a", '') } ],
        [ stringified => { '@type' => 'x', "$p" => 1 } ],
        [ 'passed-through' => { '@type' => 'x', slot => $p } ],
    );
    my @missed;
    for my $s (@shapes) {
        my ($class, $req) = @$s;
        my $json = Cpanel::JSON::XS->new->utf8->allow_nonref->encode($req);
        $p->{$ArgumentPoison::MARK} = 1 if $class eq 'passed-through';
        my $res = { wire => [ { req => $req, json => $json } ], ret => [] };
        my @f = $sw->check($res, [$p], $p);
        push @missed, "$class in $json" unless grep { $_->{class} eq $class } @f;
        delete $p->{$ArgumentPoison::MARK};
    }
    my @r = $sw->check({ wire => [], ret => [ { '@type' => 'x', id => 0 + $p } ] }, [$p], $p);
    push @missed, 'address in a returned TL object' unless grep { $_->{class} eq 'address' } @r;
    my $arr = ['x'];
    my $req = { '@type' => 'x', ids => $arr };
    @r = $sw->check({ wire => [ { req => $req, json => Cpanel::JSON::XS->new->encode($req) } ],
                      ret => [] }, [$arr], $arr);
    push @missed, 'an ARRAY passed through intact' unless grep { $_->{class} eq 'passed-through' } @r;
    my $clean = { '@type' => 'x', id => 12345, title => 'HASHED', data => 'aGVsbG8gd29ybGQ=' };
    my @f = $sw->check({ wire => [ { req => $clean, json => Cpanel::JSON::XS->new->encode($clean) } ],
                         ret => [] }, [$p], $p);
    is_deeply \@missed, [], 'the checker sees every leak shape in a hand-built request'
        or diag join "\n", @missed;
    is scalar(@f), 0, 'and nothing in a clean one';
}

# ---------------------------------------------------------------- baselines

my ($rows, $harvest_failed) = $sw->harvest(\%CALLER_ENV, sort glob 't/*.t');
phase('harvest');
cmp_ok scalar(@$rows), '>', 500, 'the t/ files yielded calls to harvest';
diag "t/ file that exited non-zero under the harvest hook: $_" for @$harvest_failed;
diag $sw->{schema_source} eq 'td_api.h'
   ? 'replies to pending requests: built from td_api.h'
   : 'replies to pending requests: no td_api.h, so the reply a t/ file injected for the same '
   . 'function (' . scalar(keys %{ $sw->{replies} || {} }) . ' functions) or a bare ok; a request '
   . 'sent only after a reply to a function no t/ file answers is not reached';

my (%cand, %seen_dump);
for my $r (@$rows) {
    next if $r->{died} || $r->{dump} =~ /__TD__|__DEEP__/;
    # a test's own stringifying class is not loaded here, and as a bare
    # blessed ref it would read as a poison of its own
    (my $unbooled = $r->{dump})
        =~ s/bless\( do\{\\\(my \$o = [01]\)\}, '(?:JSON::PP|Cpanel::JSON::XS)::Boolean' \)//g;
    next if $unbooled =~ /\bbless\(/;
    next if $seen_dump{"$r->{name}\t$r->{kind}\t$r->{dump}"}++;
    push @{ $cand{ $r->{name} } }, $r;
}

# What a call exercises, for choosing among a method's harvested calls: the
# option names it passes, the shape of each argument, and each string the
# code itself knows (kind => 'video' reads duration, kind => 'photo' does not).
sub features {
    my ($m, $args) = @_;
    my %known = map { $_ => 1 } @{ $m->{keys} };
    my %f;
    my $walk;
    $walk = sub {
        my ($v, $path) = @_;
        if (ref $v eq 'ARRAY') {
            $f{"$path:ARRAY"} = 1;
            $walk->($v->[$_], $path =~ /\[/ ? "$path\[]" : "$path\[$_]") for 0 .. $#$v;
        } elsif (ArgumentPoison::is_spec_hash($v)) {
            $walk->($v->{$_}, "$path\{$_}") for keys %$v;
        } elsif (ref $v) {
            $f{"$path:" . ref $v} = 1;
        } elsif (defined $v && $known{$v}) {
            $f{"$path=$v"} = 1;
            $f{"has $v"} = 1;
        }
    };
    $walk->($args->[$_], "[$_]") for 0 .. $#$args;
    undef $walk;
    return \%f;
}

my (%base, @bad_baseline, @no_wire_reached);
my ($replayed, $dropped) = (0, 0);
for my $name (@surface) {
    next if $INTERNAL{$name} || $CTOR_DRIVEN{$name};
    my $m = $SUB{$name};
    my @c = sort { length $b->{dump} <=> length $a->{dump} || $a->{dump} cmp $b->{dump} }
            @{ $cand{$name} || [] };
    my @reached;
    for my $c (@c) {
        my $args = do { no strict; local $SIG{__WARN__} = sub {}; eval $c->{dump} };
        next unless ref $args eq 'ARRAY';
        my $mm = { %$m, kind => $c->{kind} };
        my $res = $sw->invoke($mm, ArgumentPoison::dclone($args));
        $replayed++;
        unless (ArgumentPoison::reached($res)) { $dropped++; next }
        if ($NO_WIRE{$name}) {
            push @no_wire_reached, ArgumentPoison::render_call($mm, $args);
            last;
        }
        push @reached, { m => $mm, args => $args, res => $res, from => 't/',
                         features => features($mm, $args) };
    }
    # every reached call in exhaustive mode; otherwise the longest, then each
    # call that exercises something the chosen ones do not
    if ($EXHAUSTIVE) {
        $base{$name} = [ @reached ] if @reached;
    } else {
        my %have;
        while (@reached) {
            my ($best, $gain) = (0, -1);
            for my $i (0 .. $#reached) {
                my $g = grep { !$have{$_} } keys %{ $reached[$i]{features} };
                ($best, $gain) = ($i, $g) if $g > $gain;
            }
            last if $gain == 0 && $base{$name};
            my $pick = splice @reached, $best, 1;
            $have{$_} = 1 for keys %{ $pick->{features} };
            push @{ $base{$name} }, $pick;
        }
    }
    next if $NO_WIRE{$name};
    for my $args (@{ $BASELINE{$name} || [] }) {
        my $res = $sw->invoke($m, ArgumentPoison::dclone($args));
        if (!ArgumentPoison::reached($res)) {
            push @bad_baseline, ArgumentPoison::render_call($m, $args) . ': '
                . ($res->{err} ? 'croaks: ' . (split /\n/, $res->{err})[0] : 'nothing sent or built');
            next;
        }
        push @{ $base{$name} }, { m => $m, args => $args, res => $res, from => 'BASELINE' };
    }
}

is_deeply \@bad_baseline, [], 'every checked-in baseline reaches the wire unpoisoned'
    or diag join "\n", map { "BASELINE: $_" } @bad_baseline;
is_deeply \@no_wire_reached, [], 'no method listed as no-wire reaches the wire'
    or diag join "\n", map { "NO_WIRE entry reaches the wire: $_" } @no_wire_reached;

my @uncovered = grep { !$base{$_} && !$INTERNAL{$_} && !$NO_WIRE{$_} && !$CTOR_DRIVEN{$_} } @surface;
is_deeply \@uncovered, [], 'every public method has a call that reaches the wire'
    or diag join "\n", map { "no baseline for $_: add a t/ test that calls it, or an entry "
                           . 'in %BASELINE (or %NO_WIRE if it truly sends and builds nothing)' }
                       @uncovered;
diag 'calls that closed the sweep client, which was reopened: '
   . join ', ', sort keys %{ $sw->{closed_by} } if $sw->{closed_by};

my $n_bases = 0;
$n_bases += @$_ for values %base;
phase('baselines');

# ---------------------------------------------------------------- sweep

my @BARE    = @ArgumentPoison::KINDS;
my @WRAPPED = $EXHAUSTIVE ? @ArgumentPoison::KINDS : qw(HASH ARRAY SCALAR);

sub allowed {
    my ($name, $f) = @_;
    return 0 unless $f->{class} eq 'passed-through';
    return 1 if $RAW_METHOD{$name};
    my (undef, @fields) = split /\./, $f->{field} =~ s/\[\d+\]//gr;
    return scalar grep { $PASSTHROUGH_SLOT{$_} || $PASSTHROUGH_SLOT{"$name $_"} } @fields;
}

# one sweep over the given baselines; returns { key => finding } for the
# failures, and counts every call it makes into %$count
sub sweep {
    my (%o) = @_;
    my (%fail, %seen_class);
    for my $name (sort keys %base) {
        for my $b (@{ $base{$name} }[0 .. ($o{first_only} ? 0 : $#{ $base{$name} })]) {
            my ($m, $args) = @$b{qw(m args)};
            my %in_base;
            for my $f ($sw->check($b->{res}, $args, undef)) {
                $in_base{"$f->{class} $f->{field}"} = 1;
                failure(\%fail, $name, 'unpoisoned', $f, ArgumentPoison::render_call($m, $args));
            }
            for my $site ($sw->sites($m, $args)) {
                next if $o{sites} && !$o{sites}->($site);
                for my $wrap (0, 1) {
                    for my $kind ($wrap ? @{ $o{wrapped} } : @{ $o{bare} }) {
                        my $p = ArgumentPoison::poison($kind);
                        my $outer = $wrap ? [$p] : $p;
                        my $a = ArgumentPoison::apply_site($args, $site, $outer);
                        my $res = $sw->invoke($m, $a);
                        $o{count}{calls}++;
                        $o{count}{reached}++ if @{ $res->{wire} };
                        for my $f ($sw->check($res, $a, $outer, $wrap ? $p : undef)) {
                            next if $in_base{"$f->{class} $f->{field}"};
                            (my $field = $f->{field}) =~ s/\[\d+\]//g;
                            $seen_class{ $f->{class} }{"$name $field"} = 1;
                            $seen_class{followup}{"$name $field"} = 1 if $f->{followup};
                            $seen_class{execute}{"$name $field"} = 1 if $f->{sync};
                            next if allowed($name, $f);
                            failure(\%fail, $name,
                                    ArgumentPoison::site_label($site) . ($wrap ? ' => [poison]' : ''),
                                    $f, ArgumentPoison::render_call($m, $a, $p), $kind);
                        }
                    }
                }
            }
        }
    }
    return (\%fail, \%seen_class);
}

# one entry per distinct method, argument and TL field, however many poison
# kinds and leak shapes hit it
sub failure {
    my ($fail, $name, $label, $f, $call, $kind) = @_;
    (my $field = $f->{field}) =~ s/\[\d+\]//g;
    my $e = $fail->{"$name\t$label\t$field"} //= { %$f, call => $call, classes => [], kinds => [] };
    push @{ $e->{classes} }, $f->{class} unless grep { $_ eq $f->{class} } @{ $e->{classes} };
    push @{ $e->{kinds} }, $kind if defined $kind && !grep { $_ eq $kind } @{ $e->{kinds} };
}

sub report {
    my ($fail) = @_;
    diag join "\n", map {
        my ($name, $label, $field) = split /\t/, $_;
        my $f = $fail->{$_};
        sprintf "LEAK %s %s -> %s [%s%s%s]: %s  wire: %s", $name, $label, $field,
            join(', ', @{ $f->{classes} }),
            (@{ $f->{kinds} } ? ' of ' . join(',', @{ $f->{kinds} }) : ''),
            ($f->{followup} ? '; follow-up request' : $f->{sync} ? '; execute()' : ''),
            $f->{call}, ArgumentPoison::trim_wire($f->{wire}, $f->{needle});
    } sort keys %$fail;
}

{
    package ArgumentPoison::Stringy;
    use overload '""' => sub { ${ $_[0] } }, fallback => 1;
    sub new { my ($c, $v) = @_; bless \(my $s = $v), $c }
}

# The positive control, run before the real sweep every time: the unguarded
# helpers the round-20 conversion replaced are swapped into every symbol
# table that aliases them, and the same sweep, on a slice, must report leaks
# of each kind it claims to catch. plain_text here also ignores an overloaded
# "", so the overload rerun has something to catch too.
my %LEAKY = (
    plain_text => sub { !defined $_[1] ? '' : ref $_[1] ? overload::StrVal($_[1]) : $_[1] },
    num        => sub { no warnings; 0 + $_[1] },
    real       => sub { no warnings; 0 + $_[1] },
    unix_time  => sub { no warnings; 0 + $_[1] },
    num_list   => sub { no warnings; [ map { 0 + $_ } ref $_[1] eq 'ARRAY' ? @{ $_[1] } : $_[1] ] },
    text_list  => sub { [ map { "$_" } ref $_[1] eq 'ARRAY' ? @{ $_[1] } : $_[1] ] },
    tl_bytes   => sub { MIME::Base64::encode_base64("$_[1]", '') },
    input_file => sub { ref $_[0] ? $_[0] : { '@type' => 'inputFileLocal', path => "$_[0]" } },
    # only definedness, as need() checked before it refused a ref in an id
    # slot: history() then carries the address into the pages it fetches
    # after a reply, which is what proves follow-up requests are checked
    need       => sub { my ($what, @v) = @_; defined or die "required\n" for @v; 1 },
);
{
    my (%saved, $control, $classes, $cdiverge, $ctor, %ccount, %cocount);
    {
        no strict 'refs';
        no warnings 'redefine';
        for my $h (sort keys %LEAKY) {
            for my $pkg ($sw->helper_globs($h)) {
                $saved{"${pkg}::$h"} = \&{"${pkg}::$h"};
                *{"${pkg}::$h"} = $LEAKY{$h};
            }
        }
    }
    my $ok = eval {
        ($control, $classes) = sweep(bare => ['HASH'], wrapped => ['HASH'], first_only => 1,
                                     count => \%ccount,
                                     sites => sub { !$_[0]{added} });
        $cdiverge = overload_sweep(first_only => 1, count => \%cocount);
        $ctor = ctor_sweep(bare => ['HASH'], wrapped => []);
        1;
    };
    my $err = $@;
    {
        no strict 'refs';
        no warnings 'redefine';
        *{$_} = $saved{$_} for keys %saved;
    }
    ok $ok, 'the positive control ran' or diag $err;
    ok !(grep { no strict 'refs'; \&{$_} != $saved{$_} } keys %saved),
        'and every helper it swapped is restored';
    cmp_ok scalar(keys %saved), '>', 50, 'the control swapped the helpers in every mixin';
    my %n = map { $_ => scalar keys %{ $classes->{$_} || {} } }
            qw(stringified address base64 passed-through followup execute);
    cmp_ok $n{stringified}, '>=', 100, "leaky plain_text is caught as a stringified ref at $n{stringified} sites";
    cmp_ok $n{address}, '>=', 150, "leaky num is caught as an address at $n{address} sites";
    cmp_ok $n{base64}, '>=', 2, "leaky tl_bytes is caught as base64 at $n{base64} sites";
    cmp_ok $n{'passed-through'}, '>=', 20, "leaky input_file is caught passing the ref through at $n{'passed-through'} sites";
    cmp_ok $n{execute}, '>=', 1, "a leak in a synchronous execute() request is caught at $n{execute} sites";
    cmp_ok $n{followup}, '>=', 1, "a leak in a request sent only after a reply is caught at $n{followup} sites";
    cmp_ok scalar(keys %$cdiverge), '>=', 50, 'leaky plain_text is caught by the overload rerun at '
        . scalar(keys %$cdiverge) . ' sites';
    my %nc = map { $_ => scalar keys %{ $ctor->{classes}{$_} || {} } } qw(stringified base64);
    cmp_ok $nc{stringified}, '>=', 5, "and in the constructor options and credentials at $nc{stringified} sites";
    cmp_ok $nc{base64}, '>=', 1, "including the base64 encryption key at $nc{base64} sites";
    cmp_ok scalar(keys %{ $ctor->{diverge} }), '>=', 5, 'and the constructor overload rerun at '
        . scalar(keys %{ $ctor->{diverge} }) . ' sites';
    diag sprintf 'positive control: %d poisoned and %d overload calls; %d distinct leaks (%s); %d divergences',
        $ccount{calls} // 0, $cocount{calls} // 0, scalar(keys %$control),
        join(', ', map { "$_ $n{$_}" } sort keys %n), scalar keys %$cdiverge;
}

phase('control');

# the real sweep
my %count;
my $followups_before = $sw->{stat}{followups} // 0;
my ($fail) = sweep(bare => \@BARE, wrapped => \@WRAPPED, count => \%count);
$count{followups} = ($sw->{stat}{followups} // 0) - $followups_before;
phase('sweep');
is scalar(keys %$fail), 0, 'no poisoned argument reaches tdjson as an address, a string form or itself'
    or report($fail);

# the overload rerun: every plain string leaf of a baseline replaced by an
# object that stringifies to it, and the whole capture compared
sub overload_sweep {
    my (%o) = @_;
    my %diverge;
    for my $name (sort keys %base) {
        for my $b (@{ $base{$name} }[0 .. ($o{first_only} ? 0 : $#{ $base{$name} })]) {
            my ($m, $args) = @$b{qw(m args)};
            my $want = ArgumentPoison::canon_wire($b->{res});
            my %optname = map { $_ => 1 } @{ $m->{keys} }, qw(timeout retry);
            my @leaf;
            my $walk;
            $walk = sub {
                my ($v, $path) = @_;
                if (ref $v eq 'ARRAY') {
                    $walk->($v->[$_], [ @$path, $_ ]) for 0 .. $#$v;
                } elsif (ArgumentPoison::is_spec_hash($v)) {
                    $walk->($v->{$_}, [ @$path, "{$_}" ]) for sort keys %$v;
                } elsif (defined $v && !ref $v && $v !~ /\A\s*[+-]?[0-9.]+(?:[eE][+-]?[0-9]+)?\s*\z/) {
                    return if @$path == 1 && $optname{$v} && $path->[0] < $#$args;
                    push @leaf, $path;
                }
            };
            $walk->($args, []);
            undef $walk;
            for my $path (@leaf) {
                my $a = ArgumentPoison::dclone($args);
                ArgumentPoison::set_at($a, $path, ArgumentPoison::Stringy->new(ArgumentPoison::get_at($args, $path)));
                my $res = $sw->invoke($m, $a);
                $o{count}{calls}++;
                next if $res->{err} && $res->{err} =~ /option name must be a string/;
                my $got = ArgumentPoison::canon_wire($res);
                next if !$res->{err} && $got eq $want;
                # a request that embeds the clock can differ from its own rerun
                next if ArgumentPoison::canon_wire($sw->invoke($m, ArgumentPoison::dclone($args))) ne $want;
                my $label = ArgumentPoison::label($path);
                next if $OVERLOAD_OK{$name} && $OVERLOAD_OK{$name}{$label};
                $diverge{"$name $label"} = sprintf "%s: %s", ArgumentPoison::render_call($m, $a),
                    $res->{err} ? 'croaks: ' . (split /\n/, $res->{err})[0]
                                : 'sends ' . ArgumentPoison::trim_wire($got, undef, 200)
                                . ' instead of ' . ArgumentPoison::trim_wire($want, undef, 200);
            }
        }
    }
    return \%diverge;
}

my %ocount;
my $diverge = overload_sweep(count => \%ocount);
phase('overload');
is scalar(keys %$diverge), 0, 'an object that stringifies sends what its string would'
    or diag join "\n", map { "OVERLOAD $_: $diverge->{$_}" } sort keys %$diverge;

# ---------------------------------------------------------------- constructor

# new() and login(): the options reach the wire only as the login states are
# walked, and a credential only through the handler that submits it
sub ctor_sweep {
    my (%o) = @_;
    my (%fail, %classes, @bad, %diverge);
    my @opts = sort grep { !/\Aon_/ } ArgumentPoison::captured_strings($SUB{new}{cv});
    for my $cb (@CTOR_BASE) {
        my ($opt, $cred) = @$cb;
        my $base = $sw->drive_ctor($opt, \$cred);
        my %types = map { (ArgumentPoison::decode_wire($_) || {})->{'@type'} // '' => 1 } @{ $base->{wire} };
        push @bad, 'new(' . ArgumentPoison::render($opt) . '): sends only ' . join(' ', sort keys %types)
            unless $types{setTdlibParameters} && ($types{setAuthenticationPhoneNumber}
                                                  || $types{checkAuthenticationBotToken});
        failure(\%fail, 'new', 'unpoisoned', $_, 'new(' . ArgumentPoison::render($opt) . ')')
            for $sw->check($base, [$opt, $cred], undef);
        my $want = ArgumentPoison::canon_wire($base);
        my @sites = ((map { [ "{$_}" ] } @opts),
                     ($opt->{register} ? ([ '{register}', '{first_name}' ], [ '{register}', '{last_name}' ]) : ()),
                     [ 'credential' ]);
        for my $path (@sites) {
            for my $wrap (0, 1) {
                for my $kind ($wrap ? @{ $o{wrapped} } : @{ $o{bare} }) {
                    my $p = ArgumentPoison::poison($kind);
                    my $outer = $wrap ? [$p] : $p;
                    my ($opt2, $cred2) = (ArgumentPoison::dclone($opt), $cred);
                    if ($path->[0] eq 'credential') { $cred2 = $outer }
                    else { ArgumentPoison::set_at($opt2, $path, $outer) }
                    my $res = $sw->drive_ctor($opt2, \$cred2);
                    for my $f ($sw->check($res, [$opt2, $cred2], $outer, $wrap ? $p : undef)) {
                        (my $field = $f->{field}) =~ s/\[\d+\]//g;
                        $classes{ $f->{class} }{"new $field"} = 1;
                        failure(\%fail, 'new', join('', @$path) . ($wrap ? ' => [poison]' : ''), $f,
                                'new(' . ArgumentPoison::render($opt2, $p) . ') submitting '
                                . ArgumentPoison::render($cred2, $p), $kind);
                    }
                }
            }
            my $orig = $path->[0] eq 'credential' ? $cred : ArgumentPoison::get_at($opt, $path);
            next if !defined $orig || ref $orig || $orig =~ /\A[0-9]+\z/;
            my ($opt2, $cred2) = (ArgumentPoison::dclone($opt), $cred);
            if ($path->[0] eq 'credential') { $cred2 = ArgumentPoison::Stringy->new($orig) }
            else { ArgumentPoison::set_at($opt2, $path, ArgumentPoison::Stringy->new($orig)) }
            my $res = $sw->drive_ctor($opt2, \$cred2);
            my $got = ArgumentPoison::canon_wire($res);
            $diverge{ 'new ' . join('', @$path) } = $res->{err} ? 'croaks: ' . (split /\n/, $res->{err})[0]
                : 'sends ' . ArgumentPoison::trim_wire($got, undef, 200)
                unless !$res->{err} && $got eq $want;
        }
    }
    return { fail => \%fail, classes => \%classes, bad => \@bad, diverge => \%diverge,
             options => scalar @opts };
}

my $ctor_calls = -($sw->{stat}{ctor_calls} // 0);
{
    my $c = ctor_sweep(bare => \@BARE, wrapped => \@WRAPPED);
    $ctor_calls += $sw->{stat}{ctor_calls};
    phase('constructor');
    cmp_ok $c->{options}, '>', 10, 'the constructor options are read from new() itself';
    is_deeply $c->{bad}, [], 'the constructor baselines reach the login requests'
        or diag join "\n", @{ $c->{bad} };
    is scalar(keys %{ $c->{fail} }), 0, 'no poisoned constructor option or credential reaches tdjson'
        or report($c->{fail});
    is scalar(keys %{ $c->{diverge} }), 0, 'a constructor option that stringifies sends what its string would'
        or diag join "\n", map { "OVERLOAD $_: $c->{diverge}{$_}" } sort keys %{ $c->{diverge} };
}

# ---------------------------------------------------------------- summary

diag sprintf 'methods %d (%d with baselines, %d internal, %d no-wire, %d constructor-driven); '
           . 'baselines %d (%d from t/, %d from %%BASELINE; %d harvested calls replayed, '
           . '%d of them did not reach the wire here); poisoned calls %d (%d reached tdjson, '
           . 'with %d follow-up requests); overload calls %d; constructor calls %d; '
           . '%s mode; %.1fs (%s)',
    scalar @surface, scalar keys %base, scalar keys %INTERNAL, scalar keys %NO_WIRE,
    scalar keys %CTOR_DRIVEN, $n_bases,
    scalar(grep { $_->{from} eq 't/' } map { @$_ } values %base),
    scalar(grep { $_->{from} eq 'BASELINE' } map { @$_ } values %base),
    $replayed, $dropped, $count{calls} // 0, $count{reached} // 0,
    $count{followups}, $ocount{calls} // 0, $ctor_calls,
    $EXHAUSTIVE ? 'exhaustive' : 'default', EV::time() - $T0,
    join ', ', map { sprintf '%s %.1fs', @$_ } @PHASE;

done_testing;
