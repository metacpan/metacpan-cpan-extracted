package File::Scan::ClamAV;
use strict;
use warnings;
use File::Find qw(find);
use IO::Socket;

our $VERSION = '1.95';

=head1 NAME

File::Scan::ClamAV - Connect to a local Clam Anti-Virus clamd service and send commands

=head1 SYNOPSIS

 my $av = new File::Scan::ClamAV;
 if($av->ping){
	my %found = $av->scan('/tmp');
	for my $file (keys %found){
		print "Found virus: $found{$file} in $file\n";
	}
 }

=head1 DESCRIPTION

This module provides a simplified perl interface onto a local clam anti-virus scanner, allowing you to do fast virus scans on files on your local hard drive, or streamed data.

=head1 METHODS

=head2 new()

Create a new File::Scan::ClamAV object. By default tries to connect to a local unix domain socket at F</tmp/clamd>. Options are passed in as key/value pairs.

B<Available Options:>

=over 4

=item * port

A port or socket to connect to if you do not wish to use the unix domain socket at F</tmp/clamd>. If the socket has been setup as a TCP/IP socket (see the C<TCPSocket> option in the F<clamav.conf> file), then specifying in a number will cause File::Scan::ClamAV to use a TCP socket.

Examples:

  my $av = new File::Scan::ClamAV; # Default - uses /tmp/clamd socket

  # Use the unix domain socket at /var/sock/clam
  my $av = new File::Scan::ClamAV(port => '/var/sock/clam');

  # Use tcp/ip at port 3310
  my $av = new File::Scan::ClamAV(port => 3310);

Note: Other than using streamscan, there is no way to connect to a clamd on another machine. The reason for this is that clamd can only scan local files unless using the streamscan method.

=item * find_all

By default the ClamAV clamd service will stop scanning at the first virus it detects. This is useful for performance, but sometimes you want to find all possible viruses in all of the files. To do that, specify a true value for find_all.

=item * host

Set what host to connect to if using TCP. Defaults to localhost. This can be handy to use with the C<streamscan> method to enable sending data to a remote ClamAV daemon.

Examples:

  # Stop at first virus
  use File::Scan::ClamAV;

  my $av = new File::Scan::ClamAV;
  my ($file, $virus) = $av->scan('/home/bob');



  # Return all viruses
  use File::Scan::ClamAV;
  my $av = new File::Scan::ClamAV(find_all => 1);
  my %caught = $av->scan('/home/bob');



  # Scan a file from command line:
  perl -MFile::Scan::ClamAV -e 'printf("%s: %s\n", File::Scan::ClamAV->new->scan($ARGV[0]))' /home/bob/file.zip



  # Preform a stream-scan on a scalar
  use File::Scan::ClamAV;

  if($ARGV[0] =~ /(.+)/){
	my $file = $1;

	if(-f $file){
		my $data;
		if(open(my $fh, $file)){
			local $/;
			$data = <$fh>;
			close($fh);
		} else {
			die "Unable to read file: $file $!\n";
		}

		my $av = new File::Scan::ClamAV;

		my ($code, $virus) = $av->streamscan($data);

		if($code eq 'OK'){
			print "The file: $file did not contain any virus known to ClamAV\n";
		} elsif($code eq 'FOUND'){
			print "The file: $file contained the virus: $virus\n";
		} else {
			print $av->errstr . "\n";
		}
	} else {
		print "Unknown file: $file\n";
	}
 }

=back

=cut

sub new {
    my $class = shift;
    my (%options) = @_;
    $options{port} ||= '/tmp/clamd';
    $options{find_all} ||= 0;
    $options{host} ||= 'localhost';
    return bless \%options, $class;
}

=head2 ping()

Pings the clamd to check it is alive. Returns true if it is alive, false if it is dead. Note that it is still possible for a race condition to occur between your test for ping() and any call to scan(). See below for more details.

On error nothing is returned and the errstr() error handler is set.

=cut

sub ping {
 my ($self) = @_;
 my $conn = $self->_get_connection || return;

 $self->_send($conn, "PING\n");
 my $response = $conn->getline;
 $response = q{} unless defined $response;

 chomp $response ;

 # Run out the buffer?
 1 while (<$conn>);

 $conn->close;

 return ($response eq 'PONG' ? 1 : $self->_seterrstr("Unknown reponse from ClamAV service: $response"));
}

=head2 scan($dir_or_file)

Scan a directory or a file. Note that the resource must be readable by the user the ClamdAV clamd service is running as.

Returns a hash of C<< filename => virusname >> mappings.

On error nothing is returned and the errstr() error handler is set. If no virus is found nothing will be returned and the errstr() error handle won't be set.

=cut

sub scan {
 my $self = shift;
 $self->_seterrstr;
 my @results;

 if($self->{find_all}){
	@results = $self->_scan('SCAN', @_);
 } else {
	@results = $self->_scan_shallow('SCAN', @_);
 }

 my %f;
 for(@results){
	$f{ $_->[0] } = $_->[1];
 }

 if(%f){
	return %f;
 } else {
	return;
 }
}

=head2 rawscan($dir_or_file)

This method has been deprecated - use scan() instead

=cut

sub rawscan {
 warn 'The rawscan() method is deprecated - using scan() instead';
 return shift->scan(@_);
}

=head2 streamscan($data);

Preform a scan on a stream of data for viruses with the ClamAV clamd module.

Returns a list of two arguments: the first being the response which will be 'OK' or 'FOUND' the second being the virus found - if a virus is found.

On failure it sets the errstr() error handler.

=cut

sub streamscan {
 my $self = shift;
 my $data = shift;

 if(@_){ #don't join unless needed [cpan #78769]
    $data = join q{},($data,@_);
 }

 $self->_seterrstr;

 my $conn = $self->_get_connection || return;
 $self->_send($conn, "nINSTREAM\n");
 $self->_send($conn, pack("N", length($data)));
 $self->_send($conn, $data);
 $self->_send($conn, pack("N", 0));

 chomp(my $r = $conn->getline);

 my @return;
 if($r =~ /stream:\ (.+)\ FOUND/ix){
	@return = ('FOUND', $1);
 } else {
	@return = ('OK');
 }
 $conn->close;
 return @return;
}

=head2 quit()

Sends the QUIT message to clamd, causing it to cleanly exit.

This may or may not work, I think due to bugs in clamd's C code (it does not waitpid after a child exit, so you get zombies). However it seems to be fine on BSD derived operating systems (i.e. it's just broken under Linux). -ms

The test file t/03quit.t will currently wait 5 seconds before trying a kill -9 to get rid of the process. You may have to do something similar on Linux, or just don't use this method to kill Clamd - use C<kill `cat /path/to/clamd.pid`> instead which seems to work fine. -ms

=cut

sub quit {
 my $self = shift;
 my $conn = $self->_get_connection || return;
 $self->_send($conn, "QUIT\n");
 1 while (<$conn>);
 $conn->close;
 return 1;
}

=head2 reload()

Cause ClamAV clamd service to reload its virus database.

=cut

sub reload {
 my $self = shift;
 my $conn = $self->_get_connection || return;
 $self->_send($conn, "RELOAD\n");

 my $response = $conn->getline;
 1 while (<$conn>);
 $conn->close;
 return 1;
}

=head2 errstr()

Return the last error message.

=cut

sub errstr {
 my ($self, $err) = @_;
 $self->{'.errstr'} = $err if $err;
 return $self->{'.errstr'};
}

=head2 host()

Return current host used for TCP connections.

If passed an IP or Hostname, will set and return.

=cut

sub host {
 my ($self, $host) = @_;

 if($host){
    $self->{host} = $host;
 }

 return $self->{host};
}

=head2 port()

Return current port used.

If passed a digit or socket file, will set and return.

Values that contain non-digits will be treated as a local UNIX socket.

=cut

sub port {
 my ($self, $port) = @_;

 if($port){
    $self->{port} = $port;
 }

 return $self->{port};
}


sub _scan {
 my $self = shift;
 my $cmd = shift;
 my $options = {};

 if(ref($_[-1]) eq 'HASH') {
	$options = pop @_;
 }

 # Ugh - a bug in clamd makes us do every file
 # on a separate connection! So we will do a File::Find
 # ourselves to get all the files, then do each on
 # a separate connection to the daemon. Hopefully
 # this bug will be fixed and I can remove this horrible
 # hack. -ms

 # Files
 my @files = grep { -f } @_;

 # Directories
 for my $dir (@_){
	next unless -d $dir;
    find({untaint =>1, wanted=>  sub {
		if(-f $File::Find::name) {
			push @files, $File::Find::name;
		}
	}}, $dir);
 }

 if(!@files) {
	return $self->_seterrstr('scan() requires that you specify a directory or file to scan');
 }

 my @results;

 for(@files){
	push @results, $self->_scan_shallow($cmd, $_, $options);
 }

 return @results;
}

sub _scan_shallow {
 # same as _scan, but stops at first virus
 my $self = shift;
 my $cmd = shift;
 my $options = {};

 if(ref($_[-1]) eq 'HASH') {
        $options = pop @_;
 }

 my @dirs = @_;
 my @results;

 for my $file (@dirs){
	my $conn = $self->_get_connection || return;
	$self->_send($conn, "$cmd $file\n");

	for my $result ($conn->getline){
		chomp $result;

		my @result = split /\s/x, $result;

		chomp(my $code = pop @result);
		if($code !~ /^(?:ERROR|FOUND|OK)$/x){
			$conn->close;

			return $self->_seterrstr("Unknown response code from ClamAV service: $code - " . join q{ }, @result);
		}

		my $virus = pop @result;
		my $file = join q{ }, @result;
		$file =~ s/:$//gx;

		if($code eq 'ERROR'){
			$conn->close;

			return $self->_seterrstr("Error while processing file: $file $virus");
		} elsif($code eq 'FOUND'){
			push @results, [$file, $virus, $code];
		}
	}

	$conn->close;
 }

 return @results;
}

sub _seterrstr {
 my ($self, $err) = @_;
 $self->{'.errstr'} = $err;
 return;
}

#TODO: set a timeout and fork so we don't
#get stuck waiting too long on clamd?
sub _send {
 my $self = shift;
 my $fh = shift;

 #use alias to save mem [cpan #78769]
 return syswrite $fh, $_[0], length $_[0];
}

sub _get_connection {
 my ($self) = @_;
 if($self->{port} =~ /\D/x){
	return $self->_get_unix_connection;
 } else {
	return $self->_get_tcp_connection;
 }
}

sub _get_tcp_connection {
 my ($self, $port) = @_;
 my $host = $self->host;
 $port ||= $self->{port};

 return IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Type     => SOCK_STREAM,
        Timeout  => 10,
 ) || $self->_seterrstr("Cannot connect to '$host:$port': $@");
}

sub _get_unix_connection {
 my ($self) = @_;
 return IO::Socket::UNIX->new(
	Type => SOCK_STREAM,
	Peer => $self->{port}
 ) || $self->_seterrstr("Cannot connect to unix socket '$self->{port}': $@");
}

1;
__END__

=head1 CAVEATS

=head2 Supported Operating Systems

Currenly only Linux-like systems are supported. Patches are welcome.

=head1 AUTHOR

Colin Faber <cfaber@fpsn.net> All Rights Reserved.

Originally based on the Clamd module authored by Matt Sergeant.

=head1 LICENSE

This is free software and may be used and distribute under terms of perl itself.

=cut
