package IPC::Session;

use strict;
use FileHandle;
use IPC::Open3;

use vars qw($VERSION);

$VERSION = '0.05';

=head1 NAME

IPC::Session - Drive ssh or other interactive shell, local or remote (like 'expect')

=head1 SYNOPSIS

 use IPC::Session;

 # open ssh session to fred
 # -- set timeout of 30 seconds for all send() calls
 my $session = new IPC::Session("ssh fred",30);
 
 $session->send("hostname");  # run `hostname` command on fred
 print $session->stdout();  # prints "fred"
 $session->send("date");  # run `date` within same ssh
 print $session->stdout();  # prints date
 
 # use like 'expect':
 $session->send("uname -s");
 for ($session->stdout)
 {
 	/IRIX/ && do { $netstat = "/usr/etc/netstat" };
 	/ConvexOS/ && do { $netstat = "/usr/ucb/netstat" };
 	/Linux/ && do { $netstat = "/bin/netstat" };
 }
 
 # errno returned in scalar context:
 $errno = $session->send("$netstat -rn");
 # try this:
 $session->send("grep '^$user:' /etc/passwd") 
	 && warn "$user not there";
 
 # hash returned in array context:
 %netstat = $session->send("$netstat -in");
 print "$netstat{'stdout'}\n";  # prints interface table
 print "$netstat{'stderr'}\n";  # prints nothing (hopefully)
 print "$netstat{'errno'}\n";   # prints 0

=head1 DESCRIPTION

This module encapsulates the open3() function call (see L<IPC::Open3>)
and its associated filehandles.  This makes it easy to maintain
multiple interactive command sessions, such as multiple persistent
'ssh' and/or 'rsh' sessions, within the same perl script.  

The remote shell session is kept open for the life of the object; this
avoids the overhead of repeatedly opening remote shells via multiple
ssh or rsh calls.  This persistence is particularly useful if you are 
using ssh for your remote shell invocation; it helps you overcome 
the high ssh startup time.

For applications requiring remote command invocation, this module 
provides functionality that is similar to 'expect' or Expect.pm,
but in a lightweight more Perlish package, with discrete STDOUT, 
STDERR, and return code processing.

By the way, there's nothing inherently ssh-ish about IPC::Session -- it
doesn't even know anything about ssh, as a matter of fact.  It will
work with any interactive shell that supports 'echo'.  For instance,
'make test' just drives a local /bin/sh session.

=head1 METHODS

=head2 my $session = new IPC::Session("ssh fred",30);  

The constructor accepts the command string to be used to open the remote 
shell session, such as ssh or rsh; it also accepts an optional timeout
value, in seconds.  It returns a reference to the unique session object.  

If the timeout is not specified then it defaults to 60 seconds.  
The timeout value can also be changed later; see L<"timeout()">.

=cut

sub new
{
  my $class=shift;
  $class = (ref $class || $class);
  my $self={};
  bless $self, $class;

  my ($cmd,$timeout,$handler)=@_;
  $self->{'handler'} = $handler || sub {die @_};
  $timeout=60 unless defined $timeout;
  $self->{'timeout'} = $timeout;

  local(*IN,*OUT,*ERR);  # so we can use more than one of these objects
    open3(\*IN,\*OUT,\*ERR,$cmd) || &{$self->{'handler'}}($!);

  ($self->{'stdin'},$self->{'stdout'},$self->{'stderr'}) = (*IN,*OUT,*ERR);

  # Set to autoflush.
  for (*IN,*OUT,*ERR) {
    select;
    $|++;
  }
  select STDOUT;

  # determine target shell
  $self->{'shell'} = $self->getshell();

  return $self;
}

sub getshell
{
  my $self=shift;
  my ($tag, $shout);

  $tag=$self->tx('stdin', "echo;echo csherrno=\$status\n");
  $shout=$self->rx('stdout', $tag);
  return "csh" if $shout =~ /csherrno=0/;

  $tag=$self->tx('stdin', "echo;echo bsherrno=\$?\n");
  $shout=$self->rx('stdout', $tag);
  return "bsh" if $shout =~ /bsherrno=0/;

  die "unable to determine remote shell\n";
}

sub tx
{
  my ($self,$handle,$cmd) = @_;
  my $fh=$self->{$handle};
  my $shell = $self->{'shell'} || "";

  my $eot="_EoT_" . rand() . "_";

  # run command
  print $fh "$cmd\n";

  print $fh "echo $eot";
  print $fh " errno=\$?" if $shell eq "bsh";
  print $fh " errno=\$status" if $shell eq "csh";
  print $fh "\n";

  # call /bin/sh to work around csh stupidity -- csh doesn't support
  # redirection of stderr...  BUG this will only work if there is a
  # /bin/sh on target machine
  my $stderrcmd;
  $stderrcmd="/bin/sh -c 'echo $eot >&2'\n" if $shell eq "csh";
  $stderrcmd=            "echo $eot >&2\n"  if $shell eq "bsh";
  print $fh $stderrcmd if $shell;
  return $eot;
}

sub rx	
{
  my ($self,$handle, $eot, $timeout) = @_;
  $timeout = $self->{'timeout'} unless defined($timeout);
  my $fh=$self->{$handle};

  my $rin = my $win = my $ein = '';
  vec($rin,fileno($fh),1) = 1;
  $ein = $rin;

  # Why two nested loops?  So we can do eot pattern match (below)
  # against a full line at a time, while getting one character at a
  # time.  Do we need to get only one character at a time?  Probably
  # not, but it evolved this way.  It does let us parse and linebreak
  # on the \n character, include newlines in the output, but not
  # include the eot marker.   

  # get full text
  my $out="";  
  my $errno="";  
  while (!select(undef,undef,my $eout=$ein,0))  # while !eof()
  {
    # get one line of text
    my $outl = "";  
    while (!select(undef,undef,my $eout=$ein,0))  # while !eof()
    {
      # wait for output on handle
      my $nready=select(my $rout=$rin, undef, undef, $timeout);
      return $nready if $timeout==0;

      # handle timeout
      &{$self->{'handler'}}("timeout on $handle") unless $nready;

      # read one char
      my $outc;  
      sysread($self->{$handle},$outc,1) 
	|| &{$self->{'handler'}}("read error from $handle");

      # include newlines in output
      $outl .= $outc;  
      last if $outc eq "\n";
    }
    # store snarfed return code
    $outl =~ /$eot errno=(\d+)/ && ($errno = $1);

    # eot pattern match -- don't include eot tag in output
    last if $outl =~ /$eot/; 
    $out .= $outl;
  }

  return $out unless wantarray;
  return $out,$errno;
}

sub rxready
{
  my $self=shift;
  my $handle = shift;
  return $self->rx($handle,"dummy",0);
}

sub rxflush
{
  my $self=shift;
  my $handle = shift;
  my $tag = shift || ".*";
  while($self->rxready($handle))
  {
    $self->rx($handle,$tag)
  }
}

=head2 $commandhandle = $session->send("hostname");  

The send() method accepts a command string to be executed on the remote
host.  The command will be executed in the context of the default shell
of the remote user (unless you start a different shell by sending the
appropriate command...).  All shell escapes, command line terminators, pipes, 
redirectors, etc. are legal and should work, though you of course will 
have to escape special characters that have meaning to Perl.

In a scalar context, this method returns the return code produced by the
command string.

In an array context, this method returns a hash containing the return code
as well as the full text of the command string's output from the STDOUT 
and STDERR file handles.  The hash keys are 'stdout', 'stderr', and 
'errno'.

=cut

sub send
{
	my $self=shift;
	my $cmd=join(' ',@_);

	# send the command
        $self->rxflush('stdout');
        $self->rxflush('stderr');
	my $tag = $self->tx('stdin',$cmd);

	# snarf the output until we hit eot marker on both streams
	my ($stdout,$errno) = $self->rx('stdout', $tag);
	my $stderr = $self->rx('stderr', $tag);

	$self->{'out'}{'stdout'} = $stdout;
	$self->{'out'}{'stderr'} = $stderr;
	$self->{'out'}{'errno'}  = $errno;

	return $self->{'out'}{'errno'} unless wantarray;
	return ( 
	    errno => $self->{'out'}{'errno'}, 
	    stdout => $self->{'out'}{'stdout'}, 
	    stderr => $self->{'out'}{'stderr'}
	       );
}

=head2 print $session->stdout();  

Returns the full STDOUT text generated from the last send() command string.

Also available via array context return codes -- see L<"send()">.

=cut

sub stdout
{
	my $self=shift;
	return $self->{'out'}{'stdout'};
}

=head2 print $session->stderr();  

Returns the full STDERR text generated from the last send() command string.

Also available via array context return codes -- see L<"send()">.

=cut

sub stderr
{
	my $self=shift;
	return $self->{'out'}{'stderr'};
}

=head2 print $session->errno();  

Returns the return code generated from the last send() command string.

Also available via array context return codes -- see L<"send()">.

=cut

sub errno  
{
	my $self=shift;
	return $self->{'out'}{'errno'};
}

=head2 $session->timeout(90);  

Allows you to change the timeout for subsequent send() calls.

The timeout value is in seconds.  Fractional seconds are allowed.  
The timeout applies to all send() calls.  

Returns the current timeout if called with no args.

=cut

sub timeout  
{
	my $self=shift;
	$self->{'timeout'} = ( shift || $self->{'timeout'});
	return $self->{'timeout'};
}

sub handler
{
	my $self=shift;
	$self->{'handler'} = ( shift || $self->{'handler'});
	return $self->{'handler'};
}

=head1 BUGS/RESTRICTIONS

=over 4

=item *

The remote shell command you specify in new() is assumed to not prompt
for any passwords or present any challenge codes; i.e.; you must use
.rhosts, authorized_keys, ssh-agent, or the equivalent, and must be
prepared to answer any passphrase prompt if using ssh.  You can
either run ssh-add ahead of time and provide the passphrase, have
your script do that itself, or simply set the passphrase to null (if
your security model allows it).  

=item *

There must be a working /bin/sh on the target machine. 

=back

=head1 AUTHOR

 Steve Traugott <stevegt@TerraLuna.Org>

=head1 SEE ALSO

L<IPC::Open3>,
L<rsh(1)>,
L<ssh(1)>,
L<Expect>,
L<expect(1)>

=cut

1;

__END__
  my $vec = '';
  vec($vec,fileno($self->{'stdout'}),1) = 1;
  warn unpack("b*",$vec) . "\n";
  select($vec, undef, undef, $self->{'timeout'})
    && sysread($self->{'stdout'},my $shout,9999);
  $shell="bsh" if $shout =~ /bsherrno=0/;


  my $vstderr = '';
  vec($vstderr,fileno($self->{'stdout'}),1) = 1;
  warn unpack("b*",$rin) . "\n";
  select($vstderr, undef, undef, $self->{'timeout'})


    warn unpack("b*",$rin) . "\n";
  vec($rin,fileno($self->{'stderr'}),1) = 1;


  die;


