package HTTP::Server::EV::CGI;

use strict;
use bytes;
use Encode;
use Carp;
use Time::HiRes qw(gettimeofday tv_interval);
use Scalar::Util qw/weaken/;
no warnings;

use HTTP::Server::EV::Buffer;
use HTTP::Server::EV::BufTie;

our $VERSION = '0.69';

=head1 NAME

HTTP::Server::EV::CGI - Contains http request data and some extra functions.  

=head1 GETTING DATA

=over
	
To get headers and CGI compatible ENV vars use

=item $cgi->{ headers }{ header_name } = value


To get last parsed from form value use

=item $cgi->{ get }{ url_filed_name }

=item $cgi->{ cookies }{ cookie_name }

=item $cgi->{ post }{ form_filed_name } 

=item $cgi->{ file }{ form_file-filed_name } - L<HTTP::Server::EV::MultipartFile> object

=back


To get reference to array of all elements with same name ( selects, checkboxes, ...) use

=over

=item $cgi->get('filed_name')

=item $cgi->post('filed_name')

=item $cgi->file('filed_name')

=back


=over

=item $cgi->param('filed_name');

=back

Returns one or list of elements depending on call context. 
Prefers returning GET values if exists.

Never returns L<HTTP::Server::EV::MultipartFile> files, use $cgi->{ file }{ filed_name } or $cgi->file('filed_name')

All values are utf8 encoded

=head1 NON BLOCKING OUTPUT

$cgi->{buffer} = L<HTTP::Server::EV::Buffer> object

$cgi->buffer - returns non blocking filehandle tied to L<HTTP::Server::EV::Buffer> object

$cgi->attach(*STDOUT) - attaches STDOUT to socket makes it non blocking 

=head1 METHODS

=cut



our $cookies_lifetime = 3600*24*31;

our $MAX_URLENCODED_FIELDS = 1024; 

#$cgi->new({ fd => sock fileno , post => {}, get => {} , headers => {} .... });

# new called only by HTTP::Server::EV 
sub new { # init all structures
	my($self) = @_;
	
	# $self->start_timer;
	$self->{timer} = EV::now;
	
	$self->{buffer} = HTTP::Server::EV::Buffer->new({ fd => $self->{fd} });
	$self->{stdout_guard} = [];
	
	## Parse headers. CGI.pm compatible
	( $self->{headers}{SCRIPT_NAME}, $self->{headers}{QUERY_STRING} ) =(split /\?/, $self->{headers}{REQUEST_URI});
	
	$self->{headers}{DOCUMENT_URI} = $self->{headers}{SCRIPT_NAME};
	
	$self->{headers}{REMOTE_ADDR} = $self->{headers}{'HTTP_X-REAL-IP'} if($HTTP::Server::EV::backend && $self->{headers}{'HTTP_X-REAL-IP'});
	$self->{headers}{CONTENT_TYPE} = $self->{headers}{'HTTP_CONTENT-TYPE'};
	$self->{headers}{CONTENT_LENGTH} = $self->{headers}{'HTTP_CONTENT-LENGTH'};
	
	

		## Reading get vars # copy-paste is for microoptimization
		my @pairs = split(/[;&]/,$self->{headers}{QUERY_STRING},$MAX_URLENCODED_FIELDS);
		foreach (@pairs) {
			my ($name, $data) = split /=/, $self->urldecode($_);
			Encode::_utf8_on($name);
			Encode::_utf8_on($data);
			
			$self->{get}{$name} = $data;
			
			$self->{get_a}{$name}=[] unless $self->{get_a}{$name};
			push @{$self->{get_a}{$name}},$data;
		}

		if($self->{REQUEST_BODY}){
			my @pairs = split(/[;&]/,$self->{REQUEST_BODY},$MAX_URLENCODED_FIELDS);
			foreach (@pairs) {
				my ($name, $data) = split /=/, $self->urldecode($_);
				Encode::_utf8_on($name);
				Encode::_utf8_on($data);
			
				$self->{post}{$name} = $data;
						
				$self->{post_a}{$name}=[] unless $self->{post_a}{$name};
				push @{$self->{post_a}{$name}},$data;
			}
		}	


		## Reading cookies
		@pairs = split(/; /,$self->{headers}{HTTP_COOKIE},100);
		foreach (@pairs) {
			my ($name, $data) = split /=/, $self->urldecode($_);
			Encode::_utf8_on($name);
			Encode::_utf8_on($data);
			
			$self->{cookies}{ $name } = $data;
		}
	

	## Parse urlencoded post
	
	
	return $self;
}

=head2 $cgi->next

Drops port listener callback processing. Don`t use it somewhere except HTTP::Server::EV port listener callback or set goto label NEXT_REQ: 

=cut

sub next { $_[0]->{received} ? goto(NEXT_REQ) : $_[0]->drop};

=head2 $cgi->fd

Returns file descriptor (int)

=cut

sub fd { $_[0]->{fd} }

=head2 $cgi->fh

Returns perl file handle attached to socket. 
Non buffered and blocking, use $cgi->{buffer}->print() or $cgi->buffer handle instead for sending data without attaching socket.

=cut

sub fh { 
	croak 'Can`t get fh of closed socket!' unless $_[0]->{buffer};
	
	$_[0]->{buffer}{fh}
}

=head2 $cgi->buffer

Returns handle tied to L<HTTP::Server::EV::Buffer> object. Writing to this handle buffered and non-blocking

=cut

sub buffer { 
	croak 'Can`t get buffered handle from closed socket!' unless $_[0]->{buffer};
	
	tie($_[0]->{buf_fh}, 'HTTP::Server::EV::Buffer', $_[0]->{buffer}) unless $_[0]->{buf_fh};
	
	return $_[0]->{buf_fh};
}

=head2 $cgi->attach(*FH)

Attaches client socket to FH.
Uses L<HTTP::Server::EV::BufTie> to support processing requests in L<Coro> threads when using L<Coro::EV>
Uses L<HTTP::Server::EV::Buffer> to provide non-blocking output.

	$server->listen( 8080 , sub {
		my $cgi = shift;
		
		$cgi->attach(*STDOUT); # attach STDOUT to socket
		
		$cgi->header; # print http headers
		
		print "Test page"; 
	});


=cut


sub attach {
	croak 'Can`t attach closed socket!' unless $_[0]->{buffer};
	
	push @{$_[0]->{stdout_guard}}, HTTP::Server::EV::BufTie->new($_[1], $_[0]->{buffer});
}


=head2 $cgi->copy(*FH)

Attaches socket to handle but doesn't use L<HTTP::Server::EV::BufTie> magick and buffered L<HTTP::Server::EV::Buffer> otput.

=cut


sub copy {
	croak 'Can`t attach closed socket!' unless $_[0]->{buffer};
	
	open($_[1], '>&', $_[0]->{fd} ) or croak 'Can`t attach socket handle';
	binmode $_[1];
}


=head2 $cgi->print($data)

Buffered non-blocking print to socket. Same as $cgi->{buffer}->print or $cgi->buffer handle

=cut


sub print {shift->{buffer}->print(@_)};


=head2 $cgi->flush and $cgi->flush_wait

Same as $cgi->{buffer}->flush and $cgi->{buffer}->flush_wait

=cut


sub flush {$_[0]->{buffer}->flush($_[1])};
sub flush_wait {$_[0]->{buffer}->flush_wait($_[1])};


=head2 $cgi->close

Flush all buffered data and close received connection.

=cut

sub close { 
	delete $_[0]->{buffer}; # HTTP::Server::EV::Buffer closes socket
	$_[0]->{stdout_guard} = []; # close all attached handles
};


=head2 $cgi->start_timer

Initialize a page generation timer. Called automatically on every request

=head2 $cgi->flush_timer

Returns string like '0.12345678' with page generation time	

=cut


### Page generation timer
sub start_timer { $_[0]->{timer} = EV::now }; # start/reset timer
sub flush_timer { return(EV::now - $_[0]->{timer}) }; # get generation time

### Get params as array refs. Ex: $cgi->post('checkboxes') - ['one','two']
sub get { $_[0]->{get_a}{$_[1]} || [] }
sub post { $_[0]->{post_a}{$_[1]} || [] }
sub file { $_[0]->{file_a}{$_[1]} || [] }
sub param {
	if(wantarray){
		return( (@{$_[0]->{get_a}{$_[1]} || []}) ? @{$_[0]->{get_a}{$_[1]}}  : @{$_[0]->{post_a}{$_[1]} || []} );
	}else{
		return $_[0]->{get}{$_[1]} || $_[0]->{post}{$_[1]};
	}
}


=head2 $cgi->set_cookies({ name=> 'value', name2=> 'value2' }, $sec_lifetime );

Takes hashref with cookies as first argumet. Second(optional) argument is cookies lifetime in seconds(1 month by default)

=cut



sub set_cookies {
	my ($self,$cookies, $lifetime)=@_;
	my ($name,$value);
	my @days=qw(Sun Mon Tue Wed Thu Fri Sat);
	my @months=qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday)=gmtime( time + ( defined($lifetime) ? $lifetime :  $HTTP::Server::EV::CGI::cookies_lifetime ) );
	my $date = sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",$days[$wday],$mday,$months[$mon],$year+1900,$hour,$min,$sec);
	$self->{cookiesbuffer}.="Set-Cookie: $name=$value; path=/; expires=$date;\r\n" while(($name,$value)=each %{$cookies});
};

# generate headers

=head2 $cgi->header( \%args );

Prints http headers and cookies buffer to socket

Args:

=over

=item STATUS 

HTTP status string. '200 OK' by default

=item Server 

Server header. 'Perl HTTP::Server::EV' by default

=item Content-Type

Content-Type header. 'text/html' by default

=back

All other args will be converted to headers.

=cut


sub header {
	my ($self,$params)=@_;
	croak 'Can`t print headers to closed socket!' unless $_[0]->{buffer};
	
	my $headers = 'HTTP/1.1 '.($params->{'STATUS'} ? delete($params->{'STATUS'}) : '200 OK')."\r\n";
	$headers .= 'Server: '.($params->{'Server'} ? delete($params->{'Server'}) : 'Perl HTTP::Server::EV')."\r\n";
	$headers .= $self->{cookiesbuffer};
	$headers .= 'Content-Type: '.($params->{'Content-Type'} ? delete($params->{'Content-Type'}) : 'text/html')."\r\n";
	
	$headers .= $_.': '.$params->{$_}."\r\n" for(keys %{$params});
	
	$self->{buffer}->print($headers."\r\n");
}


=head2 $cgi->urldecode( $str );

Returns urldecoded utf8 string

=cut

sub urldecode {
	my ($output, $is_utf) = HTTP::Server::EV::url_decode($_[1]);
	$output = decode( $is_utf ? 'utf8' : 'cp1251', $output); 
	Encode::_utf8_on($output);
	$output;
};

	





=head1 NOT RECEIVED REQUEST METHODS

You should call these methods only after HTTP::Server::EV::PortListener on_multipart callback, when server receives POST data. You shouldn`t call them after request has been received. 

=head2 $cgi->stop;

Stop request processing

=head2 $cgi->start;

Starts stopped request processing. 

=head2 $cgi->drop;

Drop user connection

=cut


sub stop { HTTP::Server::EV::stop_req($_[0]->{stack_pos}); 1}

sub start {
	my $fd = HTTP::Server::EV::start_req($_[0]->{stack_pos});
	EV::feed_fd_event($fd, EV::READ) if defined $fd;
	1;
}

sub drop { 
	HTTP::Server::EV::drop_req($_[0]->{stack_pos});
	EV::feed_fd_event($_[0]->{fd}, EV::READ);
}






sub DESTROY {
	HTTP::Server::EV::start_listen($_[0]->{parent_listener}{ptr}) unless $_[0]->{parent_listener}{stopped};
}

1;