use strict;
use warnings;
use Test2::V0;

# k76: the proxy key is compared without an early exit. The helper decides
# equality only; the timing property is by construction (whole digests).
use Langertha::Knarr;

my $same = \&Langertha::Knarr::_same_key;

ok( $same->( 'sk-proxy-key', 'sk-proxy-key' ), 'equal keys match' );
ok( !$same->( 'sk-proxy-key', 'sk-proxy-kez' ), 'a last-byte difference does not match' );
ok( !$same->( 'sk-proxy', 'sk-proxy-key' ), 'a prefix does not match' );
ok( !$same->( 'sk-proxy-key-and-more', 'sk-proxy-key' ), 'a longer value does not match' );
ok( !$same->( '', 'sk-proxy-key' ), 'empty does not match' );
ok( !$same->( undef, 'sk-proxy-key' ), 'undef does not match' );
ok( $same->( "k\x{e4}y", "k\x{e4}y" ), 'equal non-ASCII keys match' );
ok( !$same->( "k\x{e4}y", "kay" ), 'different non-ASCII does not match' );

done_testing;
