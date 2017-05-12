use strict;
use warnings;
use blib;

use Test::More tests => 22;

BEGIN { use_ok('Mail::SRS'); }

my $srs = new Mail::SRS(
				Secret	=> "foo",
					);
ok(defined $srs, 'Created an object');
isa_ok($srs, 'Mail::SRS');
my @secret = $srs->get_secret;
is($secret[0], 'foo', 'Secret was stored OK');
$srs->set_secret('bar', @secret);
@secret = $srs->get_secret;
is($secret[0], 'bar', 'Secret was updated OK');
is($secret[1], 'foo', 'Old secret was preserved');

my $h = $srs->hash_create("foo");
ok(defined $h, 'Hashing seems to work');
ok($srs->hash_verify($h, "foo"), 'Hashes verify OK');
ok(! $srs->hash_verify("random", "foo"), 'Bad hashes fail hash verify');
ok(! $srs->hash_verify($h, "bar"), 'Wrong data fails hash verify');

my $t = $srs->timestamp_create();
ok(defined $t, 'Created a timestamp');
ok(length $t == 2, 'Timestamp is 2 characters');
ok($srs->timestamp_check($t), 'Timestamp verifies');
my $notlong = 60 * 60 * 24 * 3;
my $ages = 60 * 60 * 24 * 50;
ok($srs->timestamp_check($srs->timestamp_create(time() - $notlong)),
		'Past timestamp is OK');
ok(! $srs->timestamp_check($srs->timestamp_create(time() - $ages)),
		'Antique timestamp fails');
ok(! $srs->timestamp_check($srs->timestamp_create(time() + $notlong)),
		'Future timestamp fails');
ok(! $srs->timestamp_check($srs->timestamp_create(time() + $ages)),
		'Future timestamp fails');

$srs = new Mail::SRS(
				Secret			=> "foo",
				IgnoreTimestamp	=> 1,
					);
ok($srs->timestamp_check($srs->timestamp_create()),
		'Timestamp verifies');
ok($srs->timestamp_check($srs->timestamp_create(time() - $notlong)),
		'Past timestamp is OK');
ok($srs->timestamp_check($srs->timestamp_create(time() - $ages)),
		'Antique timestamp ignored');
ok($srs->timestamp_check($srs->timestamp_create(time() + $notlong)),
		'Future timestamp ignored');
ok($srs->timestamp_check($srs->timestamp_create(time() + $ages)),
		'Future timestamp ignored');
