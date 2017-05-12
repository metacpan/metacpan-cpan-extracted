#!perl

use Test::More;
use Test::File::Contents;

use IO::ReStoreFH;

use POSIX ();

use File::Temp;

# file descriptor
{
	my ($fd, $fd2 );
    my $tmp = File::Temp->new;
    my $tmp2 = File::Temp->new;

	$fd = POSIX::open( $tmp->filename, POSIX::O_WRONLY, 0644 )
	  or die( "error creating $tmp: $!\n" );

    my $buf = "write $fd\n";
    POSIX::write( $fd, $buf, length($buf) )
        or die( "error writing first semaphore for fd to $tmp: $!\n" );

  {
	  my $s = IO::ReStoreFH->new;
	  $s->store( $fd );

	  # create a new fd and dup2 it back to $fd
	  $fd2 = POSIX::open( $tmp2->filename, POSIX::O_WRONLY, 0644 )
	    or die( "error creating fd2: $tmp2: $!\n" );

	  POSIX::dup2( $fd2, $fd );
	  POSIX::close( $fd2 )
	      or die( "error closing fd2: $fd2: $!\n" );

	  # write to $fd; should be writing to $tmp2;
	  my $buf = "write $fd2\n";
	  POSIX::write( $fd, $buf, length($buf) )
	      or die( "error writing semaphore for fd2 to $tmp2: $!\n" );

  }

	# should be writing back at $tmp;
	POSIX::write( $fd, $buf, length($buf) )
	    or die( "error writing second semaphore for fd to $tmp: $!\n" );

	POSIX::close( $fd);

    file_contents_eq( $tmp->filename, "write $fd\nwrite $fd\n",
        "redirect fd; initial file" );

    file_contents_eq( $tmp2->filename, "write $fd2\n",
        "redirect fd; redirected file" );

}

done_testing;
