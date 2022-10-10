use Time::HiRes qw<time>;

use Fcntl;

use Socket ":all";

my $back_log=100;
my $limit=1000;



#Server
my $sock_file="test.sock";
unlink($sock_file);

my $addr=pack_sockaddr_un($sock_file);

die "$!" unless socket my $listener_fd, AF_UNIX, SOCK_STREAM, 0;
say STDERR "LISTENING FD: ", fileno $listener_fd;
die "$!" unless bind($listener_fd, $addr);
my $flags=fcntl $listener_fd, F_GETFL, 0;            #

fcntl $listener_fd, F_SETFL, $flags|O_NONBLOCK;      #


die "Could not listen: $!" unless listen $listener_fd, $back_log;
sub do_server {
	my $rvec="";
	vec($rvec, fileno($listener_fd),1)=1;	#
	my $rate;

	my ($count, $time_left)=select($rvec, undef, undef, 1);
	if($count){
		my $counter=0;
		my $end_time;
		my $start_time;
		$start_time=time;
		if(vec $rvec, fileno($listener_fd), 1){
			while(my $addr=accept my $fd, $listener_fd){
				#close right away
				close $fd;
				$counter++;
			}
		}
		$end_time=time;
		return($end_time-$start_time, $counter);
	}
	else {
		#Presume timeout
		return undef;
	}
}

my $counter=0;
my $sum=0;
while(1){
	#say STDERR "DOING SERvER: $counter";

	my ($res, $count)=do_server;
	if(defined $res){
		$sum+=$res;
		$counter+=$count;
	}

	last if $counter >= $limit;

}
say STDERR "Accept rate: ",$counter/$sum;
