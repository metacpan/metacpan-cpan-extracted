use warnings;
use strict;
use Test::More tests => 18;

use Linux::Info::Distribution::OSRelease;

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
    is( ref( $instance->search_distro ),
        'HASH', 'search_distro returns the expected value' );
    ok( $instance->has_distro_info, 'has_distro_info returns true' )
      or diag( explain($instance) );
    is( $instance->has_custom, 0, 'found a OSRelease based file' )
      or diag( explain($instance) );
}

my $fixture = 't/samples/os-release';
note("Using custom file $fixture");
is_deeply(
    $instance->search_distro(
        Linux::Info::Distribution::OSRelease->new($fixture)
    ),
    {
        home_url           => 'https://www.ubuntu.com/',
        id                 => 'ubuntu',
        pretty_name        => 'Ubuntu 22.04.4 LTS',
        name               => 'Ubuntu',
        support_url        => 'https://help.ubuntu.com/',
        ubuntu_codename    => 'jammy',
        version_codename   => 'jammy',
        bug_report_url     => 'https://bugs.launchpad.net/ubuntu/',
        version            => '22.04.4 LTS (Jammy Jellyfish)',
        version_id         => '22.04',
        id_like            => 'debian',
        privacy_policy_url =>
          'https://www.ubuntu.com/legal/terms-and-policies/privacy-policy',
    },
    'search_distro returns the expected value with custom OSRelease'
);
is( $instance->has_custom, 0, 'found a OSRelease based file' )
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

my $redhat = {
    id            => 'redhat',
    file_to_parse => 't/samples/redhat_version',
};
is_deeply( $another->search_distro, $redhat,
    'a Finder with a custom config_dir should ignore /etc/os-release' );
is( $another->has_custom, 1, 'found a Custom based file' )
  or diag( explain($another) );

note("Forcing $dir as a custom config_dir and OSRelease");
my $other = $class->new();
$other->set_config_dir($dir);
my $result_ref =
  $other->search_distro( Linux::Info::Distribution::OSRelease->new );

is( ref($result_ref), 'HASH',
    'search_distro returns the expected reference type' )
  or diag( explain($other) );

is_deeply( $result_ref, $redhat, 'search_distro returns a RedHat info' )
  or diag( explain($result_ref) );
is( $other->has_custom, 1, 'found a Custom based file' )
  or diag( explain($other) );

ok( $other->has_distro_info, 'has_distro_info returns true' )
  or diag( explain($other) );
