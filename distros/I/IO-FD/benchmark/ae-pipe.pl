use v5.36;
use lib "lib";
use lib "blib/lib";
use lib "blib/arch";

use IO::FD;
use Fcntl;
#use Benchmark qw<timeth>;
use Socket ":all";
use Time::HiRes qw<time>;

use AnyEvent;
my $limit=1000000;
my $data="x" x (4096);
{
	say "Filehandles";
	my $start=time;
	my $cv=AE::cv;
	my $rcounter=0;
	my $wcounter=0;
	die "Error making pipe" unless pipe my $read, my $write;
	fcntl $read, F_SETFL, O_NONBLOCK;
	fcntl $write, F_SETFL, O_NONBLOCK;
	my $rw; $rw=AE::io $read, 0, sub {
		#read the file handle
		sysread $read,my $buffer="", 4096;
		$rcounter++;
		if($rcounter >= $limit){
			$rw=undef ;
			$cv->send;
		}
	};
	
	my $ww; $ww=AE::io $write, 1, sub {
		#write
		syswrite $write, $data; 	
		$wcounter++;
		$ww=undef if $wcounter >= $limit;
		
	};
	$cv->recv;
	my $end=time;
	say "TIME: ", $end-$start;
}
{
	say "IO::FD";
	my $start=time;
	my $cv=AE::cv;
	my $rcounter=0;
	my $wcounter=0;
	die "Error making pipe" unless IO::FD::pipe my $read, my $write;
	IO::FD::fcntl $read, F_SETFL, O_NONBLOCK;
	IO::FD::fcntl $write, F_SETFL, O_NONBLOCK;
	my $rw; $rw=AE::io $read, 0, sub {
		#read the file handle
		IO::FD::sysread $read,my $buffer="", 4096;
		$rcounter++;
		if($rcounter >= $limit){
			$rw=undef ;
			$cv->send;
		}
	};
	
	my $ww; $ww=AE::io $write, 1, sub {
		#write
		IO::FD::syswrite $write, $data; 	
		$wcounter++;
		$ww=undef if $wcounter >= $limit;
		
	};
	$cv->recv;
	my $end=time;
	say "TIME: ", $end-$start;
}
