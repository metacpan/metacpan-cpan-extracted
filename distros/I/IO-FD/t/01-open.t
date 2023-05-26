use Test::More;

use IO::FD;
use Fcntl;
use POSIX "errno_h";
use File::Basename qw<dirname>;


#Additional tests for open openat

{
  #Open
  
  my $path=IO::FD::mktemp("open_temp_XXXXXXXX");
  unlink $path if -e $path;

  my $fd=IO::FD::open($path, O_CREAT|O_RDWR);
  ok defined $fd, "Open ok";
  
  ok defined IO::FD::syswrite($fd,"hello");

	#seek back to start
	ok defined(IO::FD::sysseek($fd,0,0)), "Seek file";

  my $buf="";
  ok defined IO::FD::sysread($fd, $buf, 1024);
  ok $buf eq "hello";
  
  IO::FD::close $fd;
  unlink $path;
  
}
{
  #Open at
  my $path=dirname __FILE__;

  my $dir_fd=IO::FD::open($path, O_RDONLY);
  ok defined $dir_fd, "Open dir ok";

  $path.="/my_at_file";
  unlink $path if -e $path;

  my $fd=IO::FD::openat($dir_fd, "my_at_file", O_CREAT|O_RDWR);

  ok defined $fd, "Open at ok";

  ok defined IO::FD::syswrite($fd, "hello");

	#seek back to start
	ok defined(IO::FD::sysseek($fd,0,0)), "Seek file";

  my $buf="";
  ok defined IO::FD::sysread($fd, $buf, 1024);
  ok $buf eq "hello";
  
  IO::FD::close $fd;
  IO::FD::close $dir_fd;
  unlink $path;
  
}

done_testing;
