use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More;
BEGIN { use_ok('Lemonldap::NG::Common::Conf') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $confAcc;
ok(
    $confAcc = new Lemonldap::NG::Common::Conf( {
            type             => 'Overlay',
            dirName          => 't/overlay_test',
            overlayRealtype  => 'File',
            overlayDirectory => 't/overlay_test/overlay',
            overlayWrite     => 1,
        }
    ),
    'type => Overlay',
);

my $cfg;
unlink 't/overlay_test/lmConf-2.json', 't/overlay_test/lmConf-3.json';

# READ
ok( $cfg = $confAcc->load(1), 'Load conf' )
  or print STDERR "$Lemonldap::NG::Common::Conf::msg $!";
my $count = 2;

ok( ( $cfg->{a} eq 'string' && $cfg->{b} == 1 ), 'Normal parameters' );

ok( $cfg->{globalStorage} eq 'Test::GlobalStorage', 'Scalar override' );
ok(
    ref $cfg->{globalStorageOptions} eq 'HASH'
      && $cfg->{globalStorageOptions}->{param} eq 'parameter',
    'Hash override'
);

$count += 4;

# WRITE
$cfg->{cfgNum}               = 2;
$cfg->{globalStorage}        = 'Test2';
$cfg->{globalStorageOptions} = { param => 'parameter2' };

ok( $confAcc->store($cfg) == 2, 'Save' );
$count += 1;

# READ
ok( $cfg = $confAcc->load(2), 'Load conf' )
  or print STDERR "$Lemonldap::NG::Common::Conf::msg $!";
ok(
    $cfg->{globalStorage} eq 'Test2'
      && $cfg->{globalStorageOptions}->{param} eq 'parameter2',
    'Succeed to update overwrite'
);
$count += 2;

$cfg->{cfgNum}               = 3;
$cfg->{globalStorage}        = 'Test::GlobalStorage';
$cfg->{globalStorageOptions} = { param => 'parameter' };
ok( $confAcc->store($cfg) == 3, 'Restore' );
ok( $cfg = $confAcc->load(3),   'Load conf' )
  or print STDERR "$Lemonldap::NG::Common::Conf::msg $!";
ok(
    ref $cfg->{globalStorageOptions} eq 'HASH'
      && $cfg->{globalStorageOptions}->{param} eq 'parameter',
    'Hash override'
);
$count += 3;

done_testing($count);
unlink 't/overlay_test/lmConf-2.json', 't/overlay_test/lmConf-3.json';
