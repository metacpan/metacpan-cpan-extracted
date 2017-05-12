package MP3::Icecast::Simple;

=head1 NAME

MP3::Icecast::Simple - Simple MP3::Icecast wrapper

=head1 SYNOPSIS

	use MP3::Icecast::Simple;

	$icy = MP3::Icecast::Simple->new(
		description	=> "Station",
		server		=> '127.0.0.1:8000',
		password	=> 'password',
		local_port	=> 1234,
		bitrate		=> 96
	);
	$icy->play("/path/to/files");

=head1 ABSTRACT

MP3::Icecast::Simple is a simple MP3::Icecast wrapper, that can be
used to create a SHOUTcast/Icecast broadcast source easy.

=head1 SEE ALSO

MP3::Icecast module by Allen Day (MP3::Icecast)

Nullsoft SHOUTcast DNAS home
http://www.shoutcast.com

=cut

use strict;
use base 'MP3::Icecast';
use Time::HiRes qw(sleep);
use IO::Socket;
use LWP::UserAgent;
use vars qw(@ISA $VERSION);

$VERSION = "0.2";

=head1 METHODS

=head2 new

 Title	 : new
 Usage   : $icy = MP3::Icecast::Simple->new(%arg)
 Function: Create a new MP3::Icecast::Simple instance
 Returns : MP3::Icecast::Simple object
 Args    : description	Name of the radiostation
	   server	Address and port of SHOUTcast server
	   password	Password to SHOUTcast server
	   local_port	Local port
	   bitrate	Initial bitrate

=cut

sub new {
	my ($class, %arg) = @_;
	my $self = bless {%arg}, $class;

	return $self;
}

=head2 play

 Title   : play
 Usage   : $icy->play($dir, $resursive);
 Function: Play a directory of .mp3 files
 Returns : 
 Args    : dirname	Path to direactory with .mp3 files
 	   recursive	Flag determining whether a directory is recursively searched for files (optional)

=cut

sub play {
	my $self = shift;
	my $dir = shift;
	my $recursive = shift || 0;

	my $listen_socket = IO::Socket::INET->new(
		LocalPort	=> $self->{local_port},
		Listen		=> 20,
		Proto		=> 'tcp',
		Reuse		=> 0,
		Timeout		=> 3600
	);

	$self->recursive($recursive);
	$self->add_directory($dir);

	my @files = $self->files;
	while(1) {
		next unless my $connection = $listen_socket->accept;
		defined(my $child = fork()) or die "Can't fork: $!";
		if($child == 0) {
			$listen_socket->close;
			$connection->print($self->header);
			$self->stream($_, $connection) || last for(@files);
		}
		$connection->close;
	}
	exit 0;
}

=head2 stream

 Title   : stream (rewrited from original MP3::Icecast package with improvements)
 Usage   : $icy->stream($file, $handle);
 Function: Play a file via socket
 Returns : 1 if file was transmitted successfully,
 	   undef if an error occured
 Args    : file		File to stream
 	   handle	Socket handler

=cut

sub stream {
	my ($self, $file, $handle) = @_;
	return undef unless -f $file;

	my $info = $self->_get_info($file);
	return undef unless defined($info);

	my $size = -s $file || 0;
	my $bitrate = $info->bitrate || 1;
	my $description = $self->description($file) || 'unknown';
	my $fh = $self->_open_file($file) || die "couldn't open file $file: $!";

	binmode $fh;

	if(ref($handle) and $handle->can('print')) {
		my $bytes = $size;
		print $description."\n";
		$self->updinfo($description);
		while($bytes > 0) {
			my $data;
			my $b = read($fh, $data, $bitrate * 128) || last;
			$bytes -= $b;
			$handle->print($data);
			sleep $b / ($bitrate * 128);
		}
		return 1;
	}
	return undef;
}

=head2 updinfo

 Title   : updinfo
 Usage   : Not a publick method
 Function: Update current song title on the SHOUTcast server
 Returns : 1 if song title updated successfully,
 	   undef if an error occured
 Args    : description	Name of current song

=cut

sub updinfo {
	my ($self, $songname) = @_;
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	$ua->agent('Mozilla/5.0');
	my $response = $ua->get("http://$self->{server}/admin.cgi?mode=updinfo&pass=$self->{password}&song=" . $songname);
	return undef unless ($response->is_success);
	return 1;
}

=head2 header

 Title   : header
 Usage   : Not a publick method
 Function: Create a ICY response header
 Returns : ICY response header
 Args    : none

=cut

sub header {
	my $self = shift;
	my $output = '';
	my $CRLF = "\015\012";

	$output .= "ICY 200 OK$CRLF";
	$output .= "icy-notice1:<BR>This stream requires a shoutcast/icecast compatible player.<BR>$CRLF";
	$output .= "icy-notice2:MP3::Icecast::Simple<BR>$CRLF";
	$output .= "icy-name:" . $self->{description} . $CRLF;
	$output .= "icy-pub:1$CRLF";
	$output .= "icy-br:" . $self->{bitrate} . $CRLF;
	$output .= "Accept-Ranges: bytes$CRLF";
	$output .= "Content-Type: audio/x-mp3$CRLF";
	$output .= "$CRLF";

	return $output;
}

1;

=head1 AUTHOR

 Gregory A. Rozanoff, rozanoff@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright 2006, Gregory A. Rozanoff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut