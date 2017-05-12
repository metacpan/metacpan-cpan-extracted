use strict;
use warnings;
use Test::More tests => 15;
use Test::Deep;

use Email::Simple;

require_ok('Mail::ThreadKiller');

my $tk = Mail::ThreadKiller->new();

unlink('t/threadkiller.db');

ok ($tk->open_db_file('t/threadkiller.db'), 'Successfully opened DB file');

my $mid = '<abcdef@cabbage.org>';
my $mid2 = '<xyzwyvbd@cucumber.net>';
my $mid3 = '<azmcozmdsomw@tomato.org>';

ok (!$tk->any_ids_in_database($mid), "$mid is not in database yet");

my $email = Email::Simple->create(
	header => [
		From => 'dfs@roaringpenguin.com',
		To => 'wookie@example.org',
		Subject => 'This is my message',
		"Message-ID" => $mid,
	],
	body => 'Barfbag');


my $now = $tk->kill_message($email);
ok($now, "$mid was successfully added to database with timestamp $mid");
is ($tk->any_ids_in_database($mid), $now, "$mid read back from database with correct timestamp $now");

ok($tk->should_kill_message($email), 'Yes, should kill message based on Message-ID header');

$email = Email::Simple->create(
	header => [
		From => 'dfs@roaringpenguin.com',
		To => 'wookie@example.org',
		Subject => 'This is my message',
		"Message-ID" => $mid2,
	],
	body => 'Barfbag');

ok(!$tk->should_kill_message($email), 'No, no reason to kill message');

$email = Email::Simple->create(
	header => [
		From => 'dfs@roaringpenguin.com',
		To => 'wookie@example.org',
		Subject => 'This is my message',
		"Message-ID" => $mid2,
		"In-Reply-To" => $mid,
	],
	body => 'Barfbag');
ok($tk->should_kill_message($email), 'Yes, should kill message based on In-Reply-To header');
ok($tk->any_ids_in_database($mid2), "And now $mid2 is in the kill database");

$email = Email::Simple->create(
	header => [
		From => 'dfs@roaringpenguin.com',
		To => 'wookie@example.org',
		Subject => 'This is my message',
		"Message-ID" => $mid3,
		References => "<blort\@gmail.com> <snot\@wookie.org> $mid2 <bogus\@snorf.net>",
	],
	body => 'Barfbag');

ok($tk->should_kill_message($email), 'Yes, should kill message based on References header');
ok($tk->any_ids_in_database($mid3), "And now $mid3 is in the kill database");

$now = time();

$tk->{tied}->{$mid3} = $now - 8 * 86400;

my $num_cleaned = $tk->clean_db(6);
is($num_cleaned, 1, '1 entry was cleaned from database');

my %copy =  %{ $tk->{tied} };
cmp_deeply(\%copy,
	   { $mid => re('^\d+$'),
	     $mid2 => re('\d+$') },
	   'Database has expected contents after cleaning');
$tk->close_db_file();

undef $tk;

$tk = Mail::ThreadKiller->new();
ok ($tk->open_db_file('t/threadkiller.db'), 'Successfully opened DB file');
my %copy2 =  %{ $tk->{tied} };
cmp_deeply(\%copy2,
	   { $mid => re('^\d+$'),
	     $mid2 => re('\d+$') },
	   'Database contents have persisted on disk');
$tk->close_db_file();
