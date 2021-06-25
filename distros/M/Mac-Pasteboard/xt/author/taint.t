package main;

use 5.006002;

use strict;
use warnings;

use Mac::Pasteboard qw{ kPasteboardClipboard };
use Scalar::Util qw{ tainted };
use Test::More 0.88;	# Because of done_testing();

# NOTE this is an author test because the user tests need to be forced
# to run in the same process so I can control the order despite
# someone's desire to test in parallel.

# NOTE that we could use ${^TAINT} to see if we're in taint mode, but
# that does not work under 5.6.2, plus it's handy to have an actual
# tainted value around for testing.

open my $fh, '<', $0
    or plan skip_all => 'Can not determine whether taint mode is on';
my $taint_canary = <$fh>;
close $fh;

tainted( $taint_canary )
    or exec { $^X } $^X, qw{ -Mblib -T }, $0;

substr $taint_canary, 0, length $taint_canary, '';

tainted( $taint_canary )
    or plan skip_all => 'Truncating $taint_canary untainted it';

my $pb = Mac::Pasteboard->new();

$pb->clear();
$pb->copy( 'Able was I ere I saw Elba' );

note <<'EOD';

Test paste()
EOD

my ( $data, $flags ) = $pb->paste();
ok tainted( $data ), 'data are tainted';
ok ! tainted( $flags ), 'flags are not tainted';

my %do_not_invert = map { $_ => 1 } qw{ data };

note <<'EOD';

Test paste_all()
EOD

foreach my $datum ( $pb->paste_all() ) {
    note '';
    foreach my $key ( sort keys %{ $datum } ) {
	my $taint_check = tainted( $datum->{$key} );
	my $name;
	if ( $do_not_invert{$key} ) {
	    $name = "{$key} is tainted";
	} else {
	    $taint_check = ! $taint_check;
	    $name = "{$key} is not tainted";
	}
	ok $taint_check, $name;
    }
}

note <<'EOD';

Test tainted arguments
EOD

{
    local $@ = undef;
    if ( eval { Mac::Pasteboard->new(
		kPasteboardClipboard .  $taint_canary ); 1 } ) {
	fail 'Tainted pasteboard name did not produce exception';
    } else {
	like $@, qr/\APasteboard name is tainted\b/sm,
	'Got expected exception from tainted pasteboard name';
    }
}

done_testing;

1;

# ex: set textwidth=72 :
