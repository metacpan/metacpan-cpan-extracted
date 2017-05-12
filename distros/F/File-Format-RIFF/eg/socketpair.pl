use File::Format::RIFF;
use Socket;
use IO::Handle;


socketpair( CHILD, PARENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
   or die "socketpair failed: $!";
CHILD->autoflush( 1 );
PARENT->autoflush( 1 );

my ( $pid );
if ( $pid = fork )
{
   close PARENT;
   my ( $riff ) = new File::Format::RIFF( 'uvwx' );
   $riff->addChunk( chk1 => 'datadata' );
   $riff->addList( lst1 )->addChunk( chk2 => 'datadatadata' );
   $riff->addChunk( chk3 => 'data' );
   $riff->write( \*CHILD );
   close CHILD;
   waitpid( $pid, 0 );
} else {
   die "fork failed: $!" unless ( defined $pid );
   close CHILD;
   my ( $riff ) = File::Format::RIFF->read( \*PARENT, undef );
   close PARENT;
   $riff->dump;
}
