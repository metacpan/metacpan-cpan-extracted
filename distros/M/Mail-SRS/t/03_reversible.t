use strict;
use warnings;
use blib;

use Test::More tests => 13;

BEGIN { use_ok('Mail::SRS::Reversible'); }
my $srs = new Mail::SRS::Reversible(
				Secret	=> "foo",
					);
ok(defined $srs, 'Created an object');
isa_ok($srs, 'Mail::SRS');
isa_ok($srs, 'Mail::SRS::Reversible');

my @secret = $srs->get_secret;
is($secret[0], 'foo', 'Can still call methods on new object');

my @addr = map { "user$_\@host$_\.tld$_" } (0..5);
my $new0 = $srs->forward($addr[0], $addr[1]);
ok(length $new0, 'Made a new address');
like($new0, qr/^SRS/, 'It is an SRS address');
my $old0 = $srs->reverse($new0);
ok(length $old0, 'Reversed the address');
is($old0, $addr[0], 'The reversal was idempotent');

my $new1 = $srs->forward($new0, $addr[2]);
# print STDERR "Composed is $new1\n";
ok(length $new1, 'Made another new address with the SRS address');
like($new1, qr/^SRS/, 'It is an SRS address');
my $old1 = $srs->reverse($new1);
ok(length $old1, 'Reversed the address again');
is($old1, $new0, 'The reversal was idempotent again');
