use strict ;
use warnings ;
use Test ;

BEGIN {
	plan(tests => 16) ;
}


use File::FDkeeper ;
use IO::Pipe ;

my $starter = new IO::Pipe() ;
my $lifeline = new IO::Pipe() ;
my $pid = fork() ;
die("Can't fork: $!") unless defined($pid) ;
if (! $pid){
	# child
	$starter->writer() ;
	$lifeline->reader() ;

	my $fdk = new File::FDkeeper(
		Local => 't/fdkeeper.sock'
	) ;
	close($starter) ;
	$fdk->run($lifeline) ;

	exit() ;
}

$lifeline->writer() ;
$starter->reader() ;
<$starter> ; # wait until everything is well started
ok(1) ;

my $fdk = new File::FDkeeper(
	Peer => 't/fdkeeper.sock'
) ;
ok($fdk) ;

my $buf = '' ;
open(F,"<t/10bytes") or die("Can't open 't/10bytes' for reading: $!") ;
sysread(F, $buf, 1) ;
ok($buf, "1") ;

my $fhid = $fdk->put(\*F) ;
ok(defined($fhid)) ;
ok($fdk->cnt(), 1) ;

foreach my $l (2 .. 9){
	my $fh = $fdk->get($fhid) ;
	sysread($fh, $buf, 1) ;
	ok($buf, $l) ;
}

ok($fdk->del($fhid)) ;
ok($fdk->cnt(), 0) ;
ok(! $fdk->del($fhid)) ;

