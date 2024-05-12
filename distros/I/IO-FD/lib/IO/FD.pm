package IO::FD;

use strict;
use warnings;
use Carp;

use Exporter "import";
use AutoLoader;

#our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use IO::FD ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	accept
	accept_multiple
  accept4
	listen
	socket
  sockatmark
	bind
	connect

	sysopen
	sysopen4
  openat
  open
	close

	sysread
  sysread3
	sysread4

	syswrite
	syswrite2
	syswrite3
	syswrite4

  pread
  pwrite

  mkfifo
  mkfifoat

	pipe
	socketpair
	sysseek

	dup
	dup2

	fcntl
	ioctl

  stat
  lstat

	getsockopt
	setsockopt
  getpeername
  getsockname
  shutdown
	select
	poll

	mkstemp
	mktemp

	readline
	fileno


  pread
  pwrite

  recv
  send
  sendfile

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = 'v0.3.9';

use constant::more();
#use constant();
#use Socket qw<SOCK_NONBLOCK SOCK_CLOEXEC>;
my $non_block;
my $cloexec;
#Define constants for non linux systems (looked up from a ubuntu machine...)
BEGIN {
  if($^O =~ /darwin/i){
    #Make belive values
    $cloexec=0x10000000;
    $non_block=0x20000000;
    constant::more->import(SOCK_NONBLOCK=> $non_block);
    constant::more->import(SOCK_CLOEXEC=>  $cloexec);
	}
	else {
		$cloexec=0;
		$non_block=0;
	}
}



sub fileno :prototype($) {
	ref($_[0])
		?fileno $_[0]
		: $_[0];
}

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&IO::FD::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('IO::FD', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
