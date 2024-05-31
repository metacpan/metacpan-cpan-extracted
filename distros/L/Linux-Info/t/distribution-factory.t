use warnings;
use strict;
use Test::More;
use File::Copy;
use Test::TempDir::Tiny;

use Linux::Info::DistributionFinder;

my $class   = 'Linux::Info::DistributionFactory';
my $tmp_dir = tempdir();
my $finder  = Linux::Info::DistributionFinder->new;
$finder->set_config_dir($tmp_dir);
my $source_dir = 't/samples/custom';

my @custom_fixtures = (
    {
        source_filename => 'redhat',
        dest_filename   => 'redhat-release',
        distro_name     => 'Red Hat Linux Enterprise Server',
        class_suffix    => 'RedHat',
    },
    {
        source_filename => 'amazon',
        dest_filename   => 'system-release',
        distro_name     => 'Amazon Linux',
        class_suffix    => 'Amazon',
    },
    {
        source_filename => 'centos-stream',
        dest_filename   => 'centos-release',
        distro_name     => 'CentOS',
        class_suffix    => 'CentOS',
    },
    {
        source_filename => 'cloudlinux',
        dest_filename   => 'CloudLinux-release',
        distro_name     => 'CloudLinux Server',
        class_suffix    => 'CloudLinux',
    }
);

my @standard_fixtures = (
    {
        source_filename => 'alpine',
        distro_name     => 'Alpine Linux',
        class_suffix    => 'Alpine',
    },
    {
        source_filename => 'rocky',
        distro_name     => 'Rocky Linux',
        class_suffix    => 'Rocky',
    },
    {
        source_filename => 'ubuntu',
        distro_name     => 'Ubuntu',
        class_suffix    => 'Ubuntu',
    },
    {
        source_filename => 'redhat',
        distro_name     => 'Red Hat Enterprise Linux',
        class_suffix    => 'RedHat',
    },
    {
        source_filename => 'amazon',
        distro_name     => 'Amazon Linux',
        class_suffix    => 'Amazon',
    },
    {
        source_filename => 'centos',
        distro_name     => 'CentOS Linux',
        class_suffix    => 'CentOS',
    },
    {
        source_filename => 'raspbian',
        distro_name     => 'Raspbian GNU/Linux',
        class_suffix    => 'Raspbian',
    },
);

plan tests => ( scalar(@custom_fixtures) * 2 ) +
  ( scalar(@standard_fixtures) * 2 ) + 3;

require_ok($class);

can_ok( $class, qw(create new distro_name) );
isa_ok( Linux::Info::DistributionFactory->new($finder), $class );
note('Testing distributions with customized files');

foreach my $fixture (@custom_fixtures) {
    my $dest_path   = "$tmp_dir/$fixture->{dest_filename}";
    my $source_path = "$source_dir/$fixture->{source_filename}";
    copy( $source_path, $dest_path ) or die "Copy failed: $!";

    note( 'Testing ' . $fixture->{distro_name} );
    my $instance = Linux::Info::DistributionFactory->new($finder);
    is(
        $instance->distro_name,
        $fixture->{distro_name},
        'distro_name returns the expected value'
    ) or diag( explain($instance) );
    my $expected_class =
      "Linux::Info::Distribution::Custom::$fixture->{class_suffix}";
    isa_ok( $instance->create, $expected_class ) or diag( explain($instance) );
    unlink $dest_path or die "Cannot remove file: $!";
}

note('Testing distributions with os-release files');
my $dest_path = "$tmp_dir/os-release";
$source_dir = 't/samples/os-releases';

foreach my $fixture (@standard_fixtures) {
    my $source_path = "$source_dir/$fixture->{source_filename}";
    copy( $source_path, $dest_path ) or die "Copy failed: $!";
    note( 'Testing ' . $fixture->{distro_name} );
    my $instance = Linux::Info::DistributionFactory->new($finder);
    is(
        $instance->distro_name,
        $fixture->{distro_name},
        'distro_name returns the expected value'
    ) or diag( explain($instance) );
    my $expected_class =
      "Linux::Info::Distribution::OSRelease::$fixture->{class_suffix}";
    isa_ok( $instance->create, $expected_class ) or diag( explain($instance) );
    unlink $dest_path or die "Cannot remove file: $!";
}

done_testing;
