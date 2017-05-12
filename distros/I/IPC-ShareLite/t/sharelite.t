use strict;
use warnings;
use Test::More tests => 14;
use File::Spec;

my $log_file = $ENV{IPC_SHARELITE_LOG}
 = File::Spec->catfile( 't', "sl-$$.log" );

use_ok 'IPC::ShareLite', qw( LOCK_EX LOCK_SH LOCK_UN LOCK_NB );

######################### End of black magic.

# If a semaphore or shared memory segment already uses this
# key, all tests will fail
my $KEY = 192;

# Test object construction
ok my $share = IPC::ShareLite->new(
  -key     => $KEY,
  -create  => 'yes',
  -destroy => 'yes',
  -size    => 100
 ),
 'new';

isa_ok $share, 'IPC::ShareLite';

is $share->version, 1, 'version';

# Store value
ok $share->store( 'maurice' ), 'store';

is $share->version, 2, 'version inc';

# Retrieve value
is $share->fetch, 'maurice', 'fetch';

# Fragmented store
ok $share->store( "X" x 200 ), 'frag store';

is $share->version, 3, 'version inc';

# Check number of segments
is $share->num_segments, 3, 'num_segments';

# Fragmented fetch
is $share->fetch, ( 'X' x 200 ), 'frag fetch';

$share->store( 0 );

is $share->version, 4, 'version inc';

my $pid = fork;
defined $pid or die $!;
if ( $pid == 0 ) {
  $share->destroy( 0 );
  for ( 1 .. 1000 ) {
    $share->lock( LOCK_EX() ) or die $!;
    my $val = $share->fetch;
    $share->store( ++$val ) or die $!;
    $share->unlock or die $!;
  }
  exit;
}
else {
  for ( 1 .. 1000 ) {
    $share->lock( LOCK_EX() ) or die $!;
    my $val = $share->fetch;
    $share->store( ++$val ) or die $!;
    $share->unlock or die $!;
  }
  wait;
}

is $share->fetch,   2000, 'lock';
is $share->version, 2004, 'version inc';

if ( -f $log_file ) {
  if ( -s $log_file ) {
    open my $lh, '<', $log_file or die "Can't read $log_file ($!)\n";
    while ( <$lh> ) {
      chomp;
      diag $_;
    }
  }
  unlink $log_file;
}

