use strict ;
use warnings ;
use Test ;

BEGIN {
	plan(tests => 9) ;
}


use File::FDkeeper ;
use IO::Pipe ;

my $lifeline = new IO::Pipe() ;


sub start_server {
	my $starter = new IO::Pipe() ;
	my $pid = fork() ;
	die("Can't fork: $!") unless defined($pid) ;
	if (! $pid){
		# child
		local $SIG{__WARN__} = sub {} ;
		$starter->writer() ;
		$lifeline->reader() ;

		my $fdk = new File::FDkeeper(
			Local => 't/fdkeeper.sock'
		) ;
		close($starter) ;
		my $fd = fileno($starter) ;
		open(STDERR, ">t/STDERR") or die("Can't reopen STDERR to 't/STDERR': $!") ;
		$fdk->run($lifeline) ;

		exit() ;
	}

	$lifeline->writer() ;
	$starter->reader() ;
	<$starter> ; # wait until everything is well started
}


# invalid new
eval {
	my $fdk = new File::FDkeeper(
	) ;
} ;
ok($@, qr/specify/) ;

# invalid new (server)
eval {
	my $fdk = new File::FDkeeper(
		Local => 't/fdkeeper.sock',
		Bad => 1,
	) ;
} ;
ok($@, qr/^Invalid/) ;

# invalid new (server)
eval {
	my $fdk = new File::FDkeeper(
		Local => 't/not/there/fdkeeper.sock',
	) ;
} ;
ok($@, qr/^Error creating server/) ;


# invalid new (client)
eval {
	my $fdk = new File::FDkeeper(
		Peer => 't/not/there/fdkeeper.sock',
	) ;
} ;
ok($@, qr/^Error connecting/) ;


my $fdk = undef ;
start_server() ;
$fdk = new File::FDkeeper(Peer => 't/fdkeeper.sock') ;
ok($fdk) ;


# put bad filehandle
eval {
	$fdk->put("test") ;
} ;
ok($@, qr/^Invalid/) ;
$fdk = new File::FDkeeper(Peer => 't/fdkeeper.sock') ;

# put bad filehandle
eval {
	$fdk->put(12345) ;
} ;
ok($@, qr/^Error sending filehandle/) ;
$fdk = new File::FDkeeper(Peer => 't/fdkeeper.sock') ;


ok(! $fdk->get("invalid_id")) ;
ok(! $fdk->del("invalid_id")) ;


