package MMM::Text::Search::Inet;
#$Id: Inet.pm,v 1.9 1999/11/24 18:46:27 maxim Exp $

package HTTPRequest;
use strict;
use IO::Socket::INET;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $verbose_flag  );
require Exporter;
@ISA = qw(Exporter );
@EXPORT = qw( GetHTTP );
$VERSION = '1.0';

$verbose_flag = 1;
my $ERROR = undef;
my $AGENT = "Mozzarilla/1.0 [it] (CPM/80 1.0 Z81)";
sub DEBUG (@) { $verbose_flag && print STDERR @_, "\n" };

sub new {
	my ($pak,$opt) =@_;	
	my $req = {
		Status      => 0,
		Content     => '',		
		Header => { },
		AutoRedirect => $opt->{AutoRedirect}
	};
	bless $req;
	return $req;	
}


sub reset { $_[0]->{_URL} = $_[0]->{URL} = $_[0]->{Status} = undef };

sub get_page {
	my ($self, $url ) = @_;
	my $rc = $self->get_http($url);
	return $rc unless $self->{AutoRedirect};
	while ($self->{Status} == 301 || $self->{Status} == 302) {
		$url = $self->{Header}->{location};
		DEBUG("Redirected to $url...");
		$rc = $self->get_http($url);
	}
	return $rc;
}

sub set_url {
	my ($self, $url) = @_;
	$url =~ m|(\w+)://([^/]+)(:(\d+))?(.*)|;
	my ($proto, $host,$port, $path) = ($1,$2,$4,$5);
	$self->{_URL} ||= $url;
	$path =~ s|[^/]+/\.\.||g;
	$path =~ s|/\.||g;	
	$path =~ s|/+|/|g;
	$path =~ s:^([^/]|$):/$1:;
	$port ||= 80;
	$url = "http://".$host.($port!=80?":$port":"").$path;
#DEBUG("set_url(): $url");
	$self->{URL} = $url;
	$self->{URL} =~ m|(.*)/|;
	$self->{BaseURL} = $1;
	$self->{Host} = $host;
	$self->{Path} = $path,
	$self->{Port} = $port
}



sub get_http {
	my ($self, $url ) = @_;
	$self->{Status} = 0;
	if ($url) {
		$self->set_url($url);
	}
	my ($host,$port, $path) = @{$self}{qw/Host Port Path/} ;
	DEBUG("Retrieving http://$host:$port$path...");
	my $s = _open_socket_timeout( 20,
	       PeerAddr => $host,
               PeerPort => $port, Proto    => 'tcp' );
	return undef unless $s;
	print $s "GET $path HTTP/1.0\r\n";
	print $s "Host: $host\r\n";
	print $s "User-Agent: $AGENT\r\n";
	print $s "\r\n";
	my $line = _read_from_socket($s,"\n", 60);
	return undef unless $line;
	DEBUG($line);
	my ($proto, $status, $msg) = split ' ', $line, 3;
	$self->{Status} = int $status;
	my $header = _read_from_socket($s,"\r\n\r\n",60);
	return undef unless $header;
	my %header;
	for ( split /\r*\n/, $header) {
		my ($k,$v) = split ":\s*", $_,2;
		$header{lc $k} = $v;
	}
	$self->{Header} = \%header;
	my $text;
	while ( $line = _read_from_socket($s,"\n",60) ) {
		$text .= $line;	
	}
	$s->close();
	$self->{Content} = $text;
	return 1;
}

sub header   	{ $_[0]->{Header} };
sub content  	{ $_[0]->{Content} };
sub content_ref { \$_[0]->{Content} };
sub status   	{ $_[0]->{Status} };
sub url      	{ $_[0]->{URL} };
sub base_url 	{ $_[0]->{BaseURL} };
sub host      	{ $_[0]->{Host} };
sub port      	{ $_[0]->{Port} };
sub path      	{ $_[0]->{Path} };
	
	
	


sub _read_from_socket {
	undef $@;
	my ($socket, $separator, $timeout)  = @_;
	my $line;
	my $r = eval  {
		$SIG{ALRM} = sub { die "read TIMEOUT\n" };
		local $/ = $separator;
		alarm $timeout;
		my $content = scalar <$socket>;
		alarm 0;
		return $content;
	};
	if ( $@ =~ /read TIMEOUT/ ) {
		$ERROR = 'read TIMEOUT';
		return undef;
	}
	return $r;
}


sub _open_socket_timeout {
# wrapper per  IO:Socket::INET con gestione di timeout ed errori vari
	my $timeout = shift;
	my $s; 
	my $error;
	DEBUG( "_open_socket_timeout() ", join(',', @_));
	undef $!; undef $@;
	$@ = eval {
		$SIG{ALRM} = sub { die "connection TIMED OUT" };
		alarm $timeout;
		$s = IO::Socket::INET->new( @_ );
		alarm 0;
		$@ =~ s/IO::Socket::INET:\s+//;
		return $@;
	};
	
	undef $ERROR;
	if ($@ =~ /connection TIMED OUT/ ) {
			$ERROR = 'connection TIMED OUT' ;
			undef $s;
	}
	$ERROR ||= $@||$!  unless $s;
	DEBUG("\$s=$s -- \$!='$!' -- \$\@='$@'  -- \$ERROR=$ERROR");
	return $s;
}

__END__
