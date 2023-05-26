use strict;
use warnings;
use Test::More;
use IO::FD;
use File::Basename qw<dirname>;
use Fcntl qw<O_CREAT O_RDONLY O_WRONLY O_RDWR O_NONBLOCK F_SETFL F_GETFL>;
use Errno qw<EAGAIN>;

#fifo testing
{
  my $path=dirname(__FILE__);
  $path.="/test.fifo";
  if(-e $path){
    unlink $path;
  }
  use feature ":all";
  ok defined IO::FD::mkfifo $path;#, O_CREATE|O_WRONLY;

  my $fd;
  my $ret;
  my $counter=0;
  # Open first end in the fifo in RDWR and non block
  do {
    $ret=IO::FD::sysopen $fd, $path, O_RDWR|O_NONBLOCK;
    sleep 1;
    die "Waiting to long for non blocking fifo open" if $counter++>5;
  }

  while(!defined($fd));
  ok defined($fd), "Opened in non blocking mode";

  $counter=0;
  my $client_fd;
  do {
    $ret=IO::FD::sysopen $client_fd, $path, O_RDONLY|O_NONBLOCK;
    sleep 1;
    die "Waiting to long for non blocking fifo open" if $counter++>5;
  }while(!defined($client_fd));
  my $flags=IO::FD::fcntl $fd, F_GETFL,0;
  $flags&=~O_NONBLOCK;
  IO::FD::fcntl $fd, F_SETFL, $flags; 

  $flags=IO::FD::fcntl $client_fd, F_GETFL,0;
  $flags&=~O_NONBLOCK;

  IO::FD::fcntl $client_fd, F_SETFL, $flags;
  ok defined(IO::FD::syswrite $fd, "Hello"), "Write ok";
  my $buffer="";

  
  ok defined(IO::FD::sysread $client_fd, $buffer, 5), "Read ok";

  ok $buffer eq "Hello";
  IO::FD::close $client_fd;
  IO::FD::close $fd;
  unlink $path;
}
done_testing;
