use strict;
use warnings;
use Test::Most;

use constant CLASS     => 'Linux::Info::KernelRelease';
use constant TEST_DESC => 'works for instance without mainline version';

require_ok(CLASS);
can_ok( CLASS,
    qw(new get_raw get_mainline_version get_abi_bump get_flavour get_major get_minor get_patch)
);
dies_ok { CLASS->new } 'must die without the release parameter';
dies_ok { CLASS->new('xyz') } 'must die with a invalid release parameter';

my $instance =
  CLASS->new( '6.5.0-28-generic', 'Ubuntu 6.5.0-28.29~22.04.1-generic 6.5.13' );
isa_ok( $instance, CLASS );

cmp_ok( $instance->get_patch, '>=', 0,
    'get_patch returns the expected value with mainline information' )
  or diag( explain($instance) );

my $other =
  CLASS->new( '6.5.0-28-generic', 'Ubuntu 6.5.0-28.29~22.04.1-generic 6.5.12' );

cmp_ok( $instance, '>=', $other,
        $instance->get_mainline_version
      . ' is higher or equal '
      . $other->get_mainline_version );

cmp_ok( $instance, '>', $other,
        $instance->get_mainline_version
      . ' is higher than '
      . $other->get_mainline_version );

$other =
  CLASS->new( '6.5.0-28-generic', 'Ubuntu 6.5.0-28.29~22.04.1-generic 6.5.13' );
cmp_ok( $instance, '>=', $other,
        $instance->get_mainline_version
      . ' is higher or equal '
      . $other->get_mainline_version );

$other =
  CLASS->new( '6.5.0-28-generic', 'Ubuntu 6.5.0-28.29~22.04.1-generic 6.5.16' );
cmp_ok( $instance, '<', $other,
        $instance->get_mainline_version
      . ' is less than '
      . $other->get_mainline_version );

$other = CLASS->new( '6.6.0-28-generic', undef );
cmp_ok( $instance, '<', $other,
        $instance->get_mainline_version
      . ' is less than '
      . $other->get_mainline_version );

is( $other->get_major, 6, 'get_major ' . TEST_DESC );
is( $other->get_minor, 6, 'get_minor ' . TEST_DESC );
is( $other->get_patch, 0, 'get_patch ' . TEST_DESC );
is( $other->get_mainline_version, '6.6.0',
    'get_mainline_version ' . TEST_DESC );

my $without_mainline = CLASS->new('6.5.0-28-generic');
is( $without_mainline->get_patch,
    0, 'get_patch returns the expected value without mainline information' )
  or diag( explain($without_mainline) );

done_testing;
