use warnings;
use strict;
use Test::More tests => 20;

use Linux::Info::Distribution::OSRelease;
use Linux::Info::Distribution::BasicInfo;

my $class = 'Linux::Info::DistributionFinder';
require_ok($class);
can_ok( $class,
    qw(new _config_dir _search_release_file search_distro has_distro_info has_custom)
);
ok( $class->new, 'constructor works' );

my $instance = $class->new;
isa_ok( $instance, $class );

is( $instance->has_distro_info, 0, 'has_distro_info returns false' )
  or diag( explain($instance) );

SKIP: {
    skip 'default file not available on the file system', 2
      unless ( -f Linux::Info::Distribution::OSRelease->DEFAULT_FILE );
    isa_ok(
        $instance->search_distro,
        'Linux::Info::Distribution::BasicInfo',
        'search_distro returned value'
    );
    ok( $instance->has_distro_info, 'has_distro_info returns true' )
      or diag( explain($instance) );
    is( $instance->has_custom, '', 'found a OSRelease based file' )
      or diag( explain($instance) );
}

my $fixture = 't/samples/os-release';
note("Using custom file $fixture for search_distro");
my $info = $instance->search_distro(
    Linux::Info::Distribution::OSRelease->new($fixture) );

isa_ok(
    $info,
    'Linux::Info::Distribution::BasicInfo',
    'search_distro returned value'
);

is( $info->get_distro_id, 'ubuntu', 'got the expected distribution ID' );
is( $info->get_file_path, $fixture, 'got the expected file path' );

is( $instance->has_custom, '', 'found a OSRelease based file' )
  or diag( explain($instance) );

my $dir = 't/samples';
note("Forcing $dir as a custom config_dir");
my $another = Linux::Info::DistributionFinder->new;
$another->set_config_dir($dir);
my $config_dir_ref = $another->_config_dir;

is( ref($config_dir_ref), 'ARRAY',
    '_config_dir returns the expected reference type' );
is( ( scalar @{$config_dir_ref} ),
    1, '_config_dir returns the expected number of files' )
  or diag( explain($config_dir_ref) );

my $redhat_file = 't/samples/redhat_version';

is( $another->search_distro->get_file_path,
    $redhat_file,
    'a Finder with a custom config_dir should ignore /etc/os-release' );
is( $another->has_custom, 1, 'found a Custom based file' )
  or diag( explain($another) );

note("Forcing $dir as a custom config_dir and OSRelease");
my $other = $class->new();
$other->set_config_dir($dir);
my $result = $other->search_distro( Linux::Info::Distribution::OSRelease->new );

isa_ok( $result, 'Linux::Info::Distribution::BasicInfo' );

is( $result->get_file_path, $redhat_file,
    'search_distro returns a RedHat info' )
  or diag( explain($result) );
is( $other->has_custom, 1, 'found a Custom based file' )
  or diag( explain($other) );
ok( $other->has_distro_info, 'has_distro_info returns true' )
  or diag( explain($other) );
