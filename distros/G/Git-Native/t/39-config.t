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

done_testing;
