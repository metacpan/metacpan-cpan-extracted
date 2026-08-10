use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Git::Native::Config;

my ( $repo, $tmp ) = TestRepo::new_repo();   # keep $tmp alive

# Live config: write a couple of values.
my $cfg = $repo->config;
isa_ok( $cfg, ['Git::Native::Config'], 'config returns a Config' );
$cfg->set_string( 'user.name',  'Native Tester' );
$cfg->set_string( 'user.email', 'native@example.invalid' );

# config_string reads off a fresh snapshot.
is( $repo->config_string('user.name'),  'Native Tester',           'config_string user.name' );
is( $repo->config_string('user.email'), 'native@example.invalid',  'config_string user.email' );

# Unset key -> undef (not an exception).
is( $repo->config_string('does.not.exist'), undef, 'missing key is undef' );

# Explicit snapshot object.
my $snap = $repo->config_snapshot;
isa_ok( $snap, ['Git::Native::Config'], 'config_snapshot returns a Config' );
is( $snap->get_string('user.name'), 'Native Tester', 'snapshot get_string' );

# ---- get_bool: git's boolean rules over a string value ----
# Write a spread of values, then read them off ONE fresh snapshot
# (get_string/get_bool are only reliable on a snapshot).
$cfg->set_string( "truthy.$_", $_ ) for qw( true yes on 1 17 );
$cfg->set_string( "falsy.$_",  $_ ) for qw( false no off 0 );
$cfg->set_string( 'bool.empty', '' );        # empty string value -> false (libgit2)
$cfg->set_string( 'bool.mixed', 'TrUe' );    # case-insensitive
$cfg->set_string( 'bool.bad',   'banana' );  # not a boolean -> throws

my $b = $repo->config_snapshot;
is( $b->get_bool("truthy.$_"), 1, "get_bool '$_' is true" )  for qw( true yes on 1 17 );
is( $b->get_bool("falsy.$_"),  0, "get_bool '$_' is false" ) for qw( false no off 0 );
is( $b->get_bool('bool.empty'), 0, 'empty string value is false' );
is( $b->get_bool('bool.mixed'), 1, 'get_bool is case-insensitive' );

# Unset key -> undef, mirroring get_string (not an exception).
is( $b->get_bool('does.not.exist'), undef, 'missing key -> undef' );

# A present-but-non-boolean value makes libgit2 error, surfaced as a
# Git::Native::Error (not a silent undef).
my $bad = dies { $b->get_bool('bool.bad') };
isa_ok( $bad, ['Git::Native::Error'], 'non-boolean value throws Git::Native::Error' );

# Repository->config_bool convenience mirrors config_string: reads off a
# fresh snapshot, undef when unset.
is( $repo->config_bool('truthy.true'), 1,     'config_bool reads a true value' );
is( $repo->config_bool('falsy.off'),   0,     'config_bool reads a false value' );
is( $repo->config_bool('does.not.exist'), undef, 'config_bool undef when unset' );

# get_string now throws on a real error too (only ENOTFOUND -> undef). The
# unset case stays undef, as the existing assertions above already pin.
is( $repo->config_string('does.not.exist'), undef, 'config_string still undef when unset' );

done_testing;
