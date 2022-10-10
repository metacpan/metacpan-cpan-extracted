use Test::More tests=>1;
use feature ":all";

use IO::FD;

use Fcntl;
ok defined IO::FD::pipe(my $read,my $write);
for($read,$write){
	my $flags=IO::FD::fcntl( $_, F_GETFL,0);
	IO::FD::fcntl($_, F_SETFL, $flags|O_NONBLOCK);
}


for(0..10){
	my $rvec="";
	my $wvec="";
	vec($rvec, $read,1)=1;	#
	vec($wvec, $write,1)=1;
	
	my $count=select( $rvec, $wvec, undef, 1);
	#say STDERR "COUNT fds ready $count";
	#say STDERR "Read: ",unpack "B*", $rvec;
	#say STDERR "Write: ",unpack "B*", $wvec;
	#say STDERR $write;
	if(vec($rvec, $read,1)){
		IO::FD::sysread($read,my $buffer="",20);
		#say STDERR "READ FROM PIPE: $buffer";
	}

	if(vec($wvec, $write, 1)){
		IO::FD::syswrite($write, "Writing..\n");
	}
}

