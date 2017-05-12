# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 3;

$SIG{'CHLD'} = sub { wait; };

BEGIN { use_ok('Db::GTM') };
$ENV{'GTMCI'}="/usr/local/gtm/xc/calltab.ci" unless $ENV{'GTMCI'};

my($childpid); if( $childpid = fork ) {

  my $db = new GTMDB('SPZ');
  sleep 1; # Give the child process a chance to obtain its lock
  ok( !$db->lock("LOCKFREE",0), "OK to lock something no-one else wants" );
  ok( $db->lock("LOCKTAKEN",0), 
      "Can\'t lock something already locked by another process."
  );

} else {

  my $db = new GTMDB('SPZ');
  $db->lock("LOCKTAKEN",0);
  sleep 3; # Give parent process a chance to try locking it while we have it
  exit;
}

