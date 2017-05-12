use strict;
use warnings;
use blib;

use Test::More tests => 17;

BEGIN { use_ok('Mail::SRS::Shortcut'); }

my $srs = new Mail::SRS::Shortcut(
				Secret	=> "foo",
					);
ok(defined $srs, 'Created an object');
isa_ok($srs, 'Mail::SRS');
isa_ok($srs, 'Mail::SRS::Shortcut');
my @secret = $srs->get_secret;
is($secret[0], 'foo', 'Can still call methods on new object');

my $source = "user\@host.tld";
my @alias = map { "alias$_\@host$_\.tld$_" } (0..5);
my $new0 = $srs->forward($source, $alias[0]);
ok(length $new0, 'Made a new address');
like($new0, qr/^SRS/, 'It is an SRS address');
my $old0 = $srs->reverse($new0);
ok(length $old0, 'Reversed the address');
is($old0, $source, 'The reversal was idempotent');

my $new1 = $srs->forward( $new0, $alias[1]);
# print STDERR "Composed is $new1\n";
ok(length $new1, 'Made another new address with the SRS address');
like($new1, qr/^SRS/, 'It is an SRS address');
my $old1 = $srs->reverse($new1);
ok(length $old1, 'Reversed the address again');
is($old1, $source, 'Got back the original sender');

my @tests = qw(
	user@domain-with-dash.com
	user-with-dash@domain.com
	user+with+plus@domain.com
	user%with!everything&everything=@domain.somewhere
		);
my $alias = "alias\@host.com";
foreach (@tests) {
	my $srsaddr = $srs->forward($_, $alias);
	my $oldaddr = $srs->reverse($srsaddr);
	is($oldaddr, $_, 'Idempotent on ' . $_);
}
