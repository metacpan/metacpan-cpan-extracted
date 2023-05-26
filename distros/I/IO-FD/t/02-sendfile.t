use strict;
use warnings;
use feature ":all";
use Test::More;
use IO::FD;
use Fcntl qw<O_NONBLOCK F_SETFL O_RDWR O_CREAT>;
use POSIX qw<errno_h>;
use Socket ":all";


# Netbsd does not support sendfile
use Config;
my @vers=split /\./, $Config{osvers};
plan skip_all=>"No sendfile to test on NetBSD or OpenBSD" if $Config{osname}=~/netbsd|openbsd/i;





#create a socket pair
#====================
die "Could not create pair" unless defined IO::FD::socketpair my $s1, my $s2, AF_UNIX, SOCK_STREAM, 0;

#set both to non blocking mode

die unless defined IO::FD::fcntl $s1, F_SETFL, O_NONBLOCK;
die unless defined IO::FD::fcntl $s2, F_SETFL, O_NONBLOCK;




#Create a file with random data 
#=================
my $path="tmp_large_file_.txt";
unlink $path;
die unless defined IO::FD::sysopen my $file, $path, O_CREAT|O_RDWR;
my $count=0;
my $file_size=0;
for(1..10){
  my $data= join "", map { chr ord("A")+ rand(26)} 1..1024;
  $file_size+=$count=IO::FD::syswrite $file, $data;
  die "Could not write to file $!" unless defined $count;
}



#Read contents for test comparison
#=================================
my $data=do { local $/=undef; open my $fh, "<", $path; <$fh>};


ok $data, "Loading comparision/sendfile data";



#Do nonblocking sendfile and read via the socket pair
#=================
#NOTE: file position is not reset as sendfile uses an explicit offset

my $send_offset=0;
my $send_count=0;
my $run=2;

my $rv="";
my $wv="";

vec($rv, $s2, 1)=1;   #Monitor reading from s2
vec($wv, $s1, 1)=1;   #Monitor writing to s1

my $timeout=1;

my $recv_count=0;
my $recv_buffer="";
while($run){
  my $count=select my $rrv=$rv, my $wwv=$wv, undef, $timeout;
  if($count){
    if(vec $rrv, $s2, 1){
      #Socket readable
      $recv_count+=IO::FD::sysread $s2, my $buf="", 1024;
      $recv_buffer.=$buf;
      $run=$recv_count < $file_size;
    }
    if(vec $wwv, $s1, 1){
      #Socket writable
      if($send_offset<$file_size){
        $send_offset+=$send_count=IO::FD::sendfile $s1, $file, 1024, $send_offset;
      }
    }
  }
}

IO::FD::close $file;
IO::FD::close $s1;
IO::FD::close $s2;
ok $data eq $recv_buffer, 'Data received intact';

unlink $path;


local $SIG{__WARN__}=sub {
  ok $_[0] =~ /IO::FD::sendfile called with something other than a file descriptor/, "Got warning";
};

my $ret=IO::FD::sendfile "", undef, undef,undef;


ok !defined($ret), "Undef for bad fd";

ok $! == EBADF,"bad fd";

done_testing;
