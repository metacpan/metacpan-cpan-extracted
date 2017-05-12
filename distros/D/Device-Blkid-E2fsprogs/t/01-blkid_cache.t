use Test::More tests => 3;
BEGIN { use_ok( 'Device::Blkid::E2fsprogs', ':funcs' ) };

#########################

# Verify Cache object type
$c = get_cache("/etc/blkid/blkid.tab");
isa_ok($c, 'Cache',    'Cache object match');

# Verify cleanup
undef $c;
ok(ref($c) eq '',      'Cache object cleanup, mem freed');
