use strict ;

use Test::More tests => 8 ;
BEGIN { use_ok('IO::Tty::Util') } ;

IO::Tty::Util->import(qw(openpty login_tty forkpty)) ;

my ($master, $slave) = openpty(25, 80) ;
ok($master->isa('IO::Handle')) ;
ok($slave->isa('IO::Handle')) ;


my $pid = fork() ;
die("Can't fork: $!") unless defined($pid) ;
if ($pid){
	ok(close($slave)) ;
	wait() ;
	is($?, 0) ;
}
else {
	exit(! login_tty($slave)) ;
}
ok(close($master)) ;


($pid, $master) = forkpty(25, 80) ;
die("Can't fork: $!") unless defined($pid) ;
if ($pid){
	wait() ;
	ok($master->isa('IO::Handle')) ;
	is($?, 0) ;
}
else {
	if (open(TTY, "/dev/tty")){
		close(TTY) ;
		exit(0) ;
	}
	else {
		exit(1) ;
	}
}



