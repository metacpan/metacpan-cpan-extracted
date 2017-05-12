# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
use strict;
use warnings;
use utf8;
use 5.10.0;
use Test::More;
use Etherpad;

plan skip_all => 'set TEST_ETHERPAD to enable this test (developer only!)' unless $ENV{TEST_ETHERPAD};

my $ec = Etherpad->new(
    {
        url    => 'http://localhost:9001',
        apikey => '9ada672cd9e9d3d7f1d4b65f57dede90de5b84287721ba5994b370eb95969bc0'
    }
);

ok $ec->check_token, 'Check api key';

my $p  = 'testé ok';
my $p2 = 'test2';
my $p3 = 'test';
my $a  = 'luc';

$ec->delete_pad($p); # -> deletePad -- This gives us a guaranteed clear environment
$ec->delete_pad($p2); # -> deletePad -- This gives us a guaranteed clear environment

ok $ec->create_pad($p), 'createPad';

my $aid = $ec->create_author($a);

ok $aid, 'createAuthor';

is $ec->get_author_name($aid), $a, 'getAuthorName';

my $time = time.'000';
ok $ec->append_chat_message($p, 'Why would a robot need to drink?', $aid, $time), 'appendChatMessage';

isnt $ec->get_chat_head($p), -1, 'getChatHead';

my $c = $ec->get_chat_history($p);
is_deeply $c, [{text => 'Why would a robot need to drink?', userId => $aid, time => $time, userName => $a}], 'getChatHistory';

is $ec->get_revisions_count($p), 0, 'getRevisions';

is $ec->get_saved_revisions_count($p), 0, 'getSavedRevisionsCount';

is $ec->pad_users_count($p), 0, 'padUsersCount';

is $ec->get_users_count($p), 0, 'padUsersCount 2';

my $t = $ec->list_saved_revisions($p);
is_deeply $t, [], 'listSavedRevisions';

like $ec->get_html($p), qr(.*<!DOCTYPE HTML><html><body>Welcome to Etherpad!<br>This is a test pad.*</body></html>), 'getHTML';

ok $ec->delete_pad($p), 'deletePad';

is $ec->get_html($p), undef, 'getHTML 2';

ok $ec->create_pad($p, "Hello world\nI love Perl and accents: é"), 'createPad(withText)';

is $ec->get_text($p), "Hello world\nI love Perl and accents: é\n", 'getText';

ok $ec->set_text($p, "I'm an alien, alright? Let's drop the subject.\nAnd use accents: é"), 'setText';

is $ec->get_text($p), "I'm an alien, alright? Let's drop the subject.\nAnd use accents: é\n", 'getText 2';

is $ec->get_revisions_count($p), 1, 'getRevisions 2';

ok $ec->save_revision($p), 'saveRevision';

is $ec->get_saved_revisions_count($p), 1, 'getSavedRevisionsCount 2';

$t = $ec->list_saved_revisions($p);
is_deeply $t, [1], 'listSavedRevisions 2';

ok $ec->append_text($p, "\nFezes are cool"), 'appendText';

is $ec->get_text($p), "I'm an alien, alright? Let's drop the subject.\nAnd use accents: é\nFezes are cool\n", 'getText after appendText';

is $ec->get_users_count($p), 0, 'padUsersCount';

$t = $ec->get_read_only_id($p);
like $t, qr(.+), 'getReadOnlyId';

TODO: {
    local $TODO = 'My etherpad test server seems to be broken on getPadID API call';
    is $ec->get_pad_id($t), $p, 'getPadID';
}

$t = $ec->list_authors_of_pad($p);
is_deeply $t, [], 'listAuthorsOfPad';

my $t1 = $ec->get_last_edited($p);
like $t1, qr(\d+), 'getLastEdited';

ok $ec->set_text($p, 'Bite my shiny metal ass.'), 'setText 2';

my $t2 = $ec->get_last_edited($p);
like $t2, qr(\d+), 'getLastEdited 2';

ok $t1 < $t2, 'last getLastEdited should be when setText was performed';

ok $ec->move_pad($p, $p2), 'movePad';

$t = $ec->list_all_pads();
is_deeply $t, [$p2], 'listAllPads';

is $ec->get_text($p2), "Bite my shiny metal ass.\n", 'getText, check if the text is the same after movePad';

ok $ec->move_pad($p2, $p), 'movePad 2';

is $ec->get_text($p), "Bite my shiny metal ass.\n", 'getText, check if the text is still the same';

is $ec->get_last_edited($p), $t2, 'getLastEdited 3, check if it\'s the same time as before';

ok $ec->copy_pad($p, $p2), 'copyPad';

is $ec->get_text($p), $ec->get_text($p2), 'getText, check if both pads have the same text';

is $ec->get_text($p, 1), $ec->get_text($p2, 1), 'getText, check if both pads have the same text at rev 1';

$t = $ec->list_names_of_authors_of_pad($p);
is_deeply $t, [], 'list_names_of_authors_of_pad';

my $gid = $ec->create_group();
ok $gid, 'createGroup';

is $ec->list_sessions_of_group($gid), undef, 'listSessionsOfGroup';

ok $ec->delete_group($gid), 'deleteGroup';

$gid = $ec->create_group_if_not_exists_for('group');
ok $gid, 'createGroupIfNotExistsFor';

my $sid = $ec->create_session($gid, $aid, '999999999999');
ok $sid, 'createSession';

is_deeply $ec->get_session_info($sid), {authorID => $aid, groupID => $gid, validUntil => '999999999999'}, 'getSessionInfo';

$t = $ec->list_sessions_of_group($gid);
is_deeply $ec->list_sessions_of_group($gid), {$sid => {authorID => $aid, groupID => $gid, validUntil => '999999999999'}}, 'listSessionsOfGroup';

ok $ec->delete_session($sid), 'deleteSession';

is $ec->get_session_info($sid), undef, 'getSessionInfo';

$t = $ec->list_pads($gid);
is_deeply $t, [], 'listPads';

ok $ec->create_group_pad($gid, $p3, 'Young lady, I am an expert on humans. Now pick a mouth, open it and say "Bbrglgrglgrrr"!'), 'createGroupPad';

$t = $ec->list_pads($gid);
like $t->[0], qr(^g\.), 'listPads 2';

is $ec->get_text($t->[0]), qq(Young lady, I am an expert on humans. Now pick a mouth, open it and say "Bbrglgrglgrrr"!\n), 'getText 3';

is $ec->get_public_status($t->[0]), 0, 'getPublicStatus';

ok $ec->set_public_status($t->[0], 1), 'setPublicStatus';

ok $ec->get_public_status($t->[0]), 'getPublicStatus 2';

is $ec->is_password_protected($t->[0]), 0, 'isPasswordProtected';

ok $ec->set_password($t->[0], 'toto');

ok $ec->is_password_protected($t->[0]), 'isPasswordProtected 2';

$ec->delete_pad($t->[0]);
$ec->delete_group($gid);

done_testing;
