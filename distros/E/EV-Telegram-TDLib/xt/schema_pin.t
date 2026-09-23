use strict;
use warnings;
use Test::More;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

# The module names TDLib classes as string literals: request types it sends,
# update types it routes, and the field names it reads off them. A rename in a
# newer TDLib does not break the build -- the requests simply start failing, or
# the updates stop arriving, silently. This checks every literal against the
# schema header of the Alien::TDLib actually installed, so a version bump that
# moves the ground under us fails here instead of in production.

my $header = do {
    my $dir = eval { require Alien::TDLib; Alien::TDLib->dist_dir };
    plan skip_all => 'Alien::TDLib is not installed' unless $dir;
    my ($h) = glob "$dir/include/td/telegram/td_api.h";
    plan skip_all => 'no td_api.h in the Alien share dir' unless $h && -f $h;
    $h;
};

open my $fh, '<', $header or plan skip_all => "td_api.h: $!";
my %class;
while (<$fh>) {
    $class{$1} = 1 if /^class\s+([a-zA-Z]\w*)\s/;
}
close $fh;
ok scalar keys %class, 'read the pinned schema';

sub slurp { open my $h, '<', $_[0] or die "$_[0]: $!"; local $/; <$h> }
my @src = ('lib/EV/Telegram/TDLib.pm', glob 'lib/EV/Telegram/TDLib/*.pm');
# the docs and examples name TDLib classes too, and rot the same way
# the module's own POD names update types in prose as well
my @doc = (@src, 'lib/EV/Telegram/TDLib/Cookbook.pod', glob 'eg/*.pl');


# 1. every '@type' literal the module emits or matches on
my %emitted;
for my $f (@src, @doc) {
    my $s = slurp($f);
    # both spellings: '@type' => 'x' in a hash, and $req{'@type'} = 'x'
    $emitted{$1} = $f while $s =~ /'\@type'(?:\s*=>|}\s*=)\s*'([a-zA-Z]\w*)'/g;
}
my @bad_type = grep { !$class{$_} } sort keys %emitted;
diag "unknown: $_ (in $emitted{$_})" for @bad_type;
# each scan asserts its own yield: a regex that stops matching leaves the
# bad list empty and reports everything sound
cmp_ok scalar(keys %emitted), '>', 250, 'the @type scan found types';
is "@bad_type", '', 'every emitted @type exists in the pinned schema';

# 2. the update types the mixins route
my %updates;
for my $f (@src) {
    my $s = slurp($f);
    next unless $s =~ /our %UPDATES = \((.*?)\);/s;
    my $body = $1;
    $updates{$1} = $f while $body =~ /^\s*(\w+)\s*=>/mg;
}
my @bad_update = grep { !$class{$_} } sort keys %updates;
diag "unknown: $_ (in $updates{$_})" for @bad_update;
cmp_ok scalar(keys %updates), '>', 10, 'the %UPDATES scan found handlers';
is "@bad_update", '', 'every routed update type exists in the pinned schema';

# 3. the update types keyed in %CHAT_FIELDS, where most of them live
my %chat_updates;
for my $f (@src) {
    my $s = slurp($f);
    next unless $s =~ /%CHAT_FIELDS = \((.*?)\n\);/s;
    my $body = $1;
    $chat_updates{$1} = $f while $body =~ /^\s*(update\w+)\s*=>/mg;
}
my @bad_chat = grep { !$class{$_} } sort keys %chat_updates;
diag "unknown: $_ (in $chat_updates{$_})" for @bad_chat;
cmp_ok scalar(keys %chat_updates), '>', 10, 'the %CHAT_FIELDS scan found types';
is "@bad_chat", '', 'every %CHAT_FIELDS update type exists in the pinned schema';

# 4. the type names held in lookup tables (chat actions, member statuses,

#    and the per-kind media content and wrapper types)
my %tabled;
for my $f (@src) {
    my $s = slurp($f);
    $tabled{$1} = $f while $s =~ /=>\s*'(chatAction\w+|chatMemberStatus\w+|inputMessage\w+|input(?:Document|Photo|Video|Audio|Animation|VoiceNote|VideoNote|Sticker)|webAppOpenMode\w+|getBot(?:Name|Info\w+)|chatMembersFilter\w+|chatList(?:Main|Archive)|notificationSettingsScope\w+|blockList\w+|supergroupMembersFilter\w+)'/g;
}
for my $f (@src) {
    my $s = slurp($f);
    while ($s =~ /\[\s*'(inputMessage\w+)'\s*,\s*'\w+'\s*,\s*'(input\w+)'/g) {
        $tabled{$1} = $f;
        $tabled{$2} = $f;
    }
}
my @bad_tabled = grep { !$class{$_} } sort keys %tabled;

diag "unknown: $_ (in $tabled{$_})" for @bad_tabled;
cmp_ok scalar(keys %tabled), '>', 20, 'the lookup-table scan found types';
is "@bad_tabled", '', 'every tabled TDLib type exists in the pinned schema';

diag sprintf 'checked %d emitted, %d routed, %d chat-field, %d tabled types',
    scalar keys %emitted, scalar keys %updates, scalar keys %chat_updates,
    scalar keys %tabled;

# Update names appear in prose as well as code, and prose rots unnoticed:
# the Cookbook once promised updateMessagePoll, which no TDLib has ever had.
my %prose;
for my $f (@doc) {
    my $s = slurp($f);
    $prose{$1} = $f while $s =~ /\b(update[A-Z]\w+)\b/g;
}
my @bad_prose = grep { !$class{$_} } sort keys %prose;
diag "unknown: $_ (in $prose{$_})" for @bad_prose;
cmp_ok scalar(keys %prose), '>', 30, 'the prose scan found update names';
is "@bad_prose", '', 'every update type named in the docs exists in the schema';
diag sprintf 'checked %d update names in prose', scalar keys %prose;

done_testing;

