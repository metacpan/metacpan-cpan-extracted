package GMail::IMAPD::UserAgent;

# $Id: UserAgent.pm,v 2.32 2004/06/14 12:36:49 gisle Exp $

use strict;
use vars qw(@ISA $VERSION);

require LWP::MemberMixin;
@ISA = qw(LWP::MemberMixin);
$VERSION = sprintf("%d.%03d", q$Revision: 2.32 $ =~ /(\d+)\.(\d+)/);

use HTTP::Request ();
use HTTP::Response ();
use HTTP::Date ();

use LWP ();
use LWP::Debug ();
use LWP::Protocol ();

use Carp ();

if ($ENV{PERL_LWP_USE_HTTP_10}) {
    require LWP::Protocol::http10;
    LWP::Protocol::implementor('http', 'LWP::Protocol::http10');
    eval {
        require LWP::Protocol::https10;
        LWP::Protocol::implementor('https', 'LWP::Protocol::https10');
    };
}



sub new
{
    my($class, %cnf) = @_;
    LWP::Debug::trace('()');

    my $agent = delete $cnf{agent};
    $agent = $class->_agent unless defined $agent;

    my $from  = delete $cnf{from};
    my $timeout = delete $cnf{timeout};
    $timeout = 3*60 unless defined $timeout;
    my $use_eval = delete $cnf{use_eval};
    $use_eval = 1 unless defined $use_eval;
    my $parse_head = delete $cnf{parse_head};
    $parse_head = 1 unless defined $parse_head;
    my $max_size = delete $cnf{max_size};
    my $max_redirect = delete $cnf{max_redirect};
    $max_redirect = 7 unless defined $max_redirect;
    my $env_proxy = delete $cnf{env_proxy};

    my $cookie_jar = delete $cnf{cookie_jar};
    my $conn_cache = delete $cnf{conn_cache};
    my $keep_alive = delete $cnf{keep_alive};
    
    Carp::croak("Can't mix conn_cache and keep_alive")
	  if $conn_cache && $keep_alive;


    my $protocols_allowed   = delete $cnf{protocols_allowed};
    my $protocols_forbidden = delete $cnf{protocols_forbidden};
    
    my $requests_redirectable = delete $cnf{requests_redirectable};
    $requests_redirectable = ['GET', 'HEAD']
      unless defined $requests_redirectable;

    # Actually ""s are just as good as 0's, but for concision we'll just say:
    Carp::croak("protocols_allowed has to be an arrayref or 0, not \"$protocols_allowed\"!")
      if $protocols_allowed and ref($protocols_allowed) ne 'ARRAY';
    Carp::croak("protocols_forbidden has to be an arrayref or 0, not \"$protocols_forbidden\"!")
      if $protocols_forbidden and ref($protocols_forbidden) ne 'ARRAY';
    Carp::croak("requests_redirectable has to be an arrayref or 0, not \"$requests_redirectable\"!")
      if $requests_redirectable and ref($requests_redirectable) ne 'ARRAY';


    if (%cnf && $^W) {
	Carp::carp("Unrecognized LWP::UserAgent options: @{[sort keys %cnf]}");
    }

    my $self = bless {
		      from         => $from,
		      def_headers  => undef,
		      timeout      => $timeout,
		      use_eval     => $use_eval,
		      parse_head   => $parse_head,
		      max_size     => $max_size,
		      max_redirect => $max_redirect,
		      proxy        => undef,
		      no_proxy     => [],
                      protocols_allowed     => $protocols_allowed,
                      protocols_forbidden   => $protocols_forbidden,
                      requests_redirectable => $requests_redirectable,
		     }, $class;

    $self->agent($agent) if $agent;
    $self->cookie_jar($cookie_jar) if $cookie_jar;
    $self->env_proxy if $env_proxy;

    $self->protocols_allowed(  $protocols_allowed  ) if $protocols_allowed;
    $self->protocols_forbidden($protocols_forbidden) if $protocols_forbidden;

    if ($keep_alive) {
	$conn_cache ||= { total_capacity => $keep_alive };
    }
    $self->conn_cache($conn_cache) if $conn_cache;

    return $self;
}


# private method.  check sanity of given $request
sub _request_sanity_check {
    my($self, $request) = @_;
    # some sanity checking
    if (defined $request) {
	if (ref $request) {
	    Carp::croak("You need a request object, not a " . ref($request) . " object")
	      if ref($request) eq 'ARRAY' or ref($request) eq 'HASH' or
		 !$request->can('method') or !$request->can('uri');
	}
	else {
	    Carp::croak("You need a request object, not '$request'");
	}
    }
    else {
        Carp::croak("No request object passed in");
    }
}


sub send_request
{
    my($self, $request, $arg, $size) = @_;
    $self->_request_sanity_check($request);

    my($method, $url) = ($request->method, $request->uri);

    local($SIG{__DIE__});  # protect against user defined die handlers

    # Check that we have a METHOD and a URL first
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "Method missing")
	unless $method;
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "URL missing")
	unless $url;
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "URL must be absolute")
	unless $url->scheme;

    LWP::Debug::trace("$method $url");

    # Locate protocol to use
    my $scheme = '';
    my $proxy = $self->_need_proxy($url);
    if (defined $proxy) {
	$scheme = $proxy->scheme;
    }
    else {
	$scheme = $url->scheme;
    }

    my $protocol;

    {
      # Honor object-specific restrictions by forcing protocol objects
      #  into class LWP::Protocol::nogo.
      my $x;
      if($x       = $self->protocols_allowed) {
        if(grep lc($_) eq $scheme, @$x) {
          LWP::Debug::trace("$scheme URLs are among $self\'s allowed protocols (@$x)");
        }
        else {
          LWP::Debug::trace("$scheme URLs aren't among $self\'s allowed protocols (@$x)");
          require LWP::Protocol::nogo;
          $protocol = LWP::Protocol::nogo->new;
        }
      }
      elsif ($x = $self->protocols_forbidden) {
        if(grep lc($_) eq $scheme, @$x) {
          LWP::Debug::trace("$scheme URLs are among $self\'s forbidden protocols (@$x)");
          require LWP::Protocol::nogo;
          $protocol = LWP::Protocol::nogo->new;
        }
        else {
          LWP::Debug::trace("$scheme URLs aren't among $self\'s forbidden protocols (@$x)");
        }
      }
      # else fall thru and create the protocol object normally
    }

    unless($protocol) {
      $protocol = eval { LWP::Protocol::create($scheme, $self) };
      if ($@) {
	$@ =~ s/ at .* line \d+.*//s;  # remove file/line number
	my $response =  _new_response($request, &HTTP::Status::RC_NOT_IMPLEMENTED, $@);
	if ($scheme eq "https") {
	    $response->message($response->message . " (Crypt::SSLeay not installed)");
	    $response->content_type("text/plain");
	    $response->content(<<EOT);
LWP will support https URLs if the Crypt::SSLeay module is installed.
More information at <http://www.linpro.no/lwp/libwww-perl/README.SSL>.
EOT
	}
	return $response;
      }
    }

    # Extract fields that will be used below
    my ($timeout, $cookie_jar, $use_eval, $parse_head, $max_size) =
      @{$self}{qw(timeout cookie_jar use_eval parse_head max_size)};

    my $response;
    if ($use_eval) {
	# we eval, and turn dies into responses below
	eval {
	    $response = $protocol->request($request, $proxy,
					   $arg, $size, $timeout);
	};
	if ($@) {
	    $@ =~ s/ at .* line \d+.*//s;  # remove file/line number
	    $response = _new_response($request,
				      &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
				      $@);
	}
    }
    else {
	$response = $protocol->request($request, $proxy,
				       $arg, $size, $timeout);
	# XXX: Should we die unless $response->is_success ???
    }

    $response->request($request);  # record request for reference
    $cookie_jar->extract_cookies($response) if $cookie_jar;
    $response->header("Client-Date" => HTTP::Date::time2str(time));
    return $response;
}


sub prepare_request
{
    my($self, $request) = @_;
    $self->_request_sanity_check($request);

    # Extract fields that will be used below
    my ($agent, $from, $cookie_jar, $max_size, $def_headers) =
      @{$self}{qw(agent from cookie_jar max_size def_headers)};

    # Set User-Agent and From headers if they are defined
    $request->init_header('User-Agent' => $agent) if $agent;
    $request->init_header('From' => $from) if $from;
    if (defined $max_size) {
	my $last = $max_size - 1;
	$last = 0 if $last < 0;  # there is no way to actually request no content
	$request->init_header('Range' => "bytes=0-$last");
    }
    $cookie_jar->add_cookie_header($request) if $cookie_jar;

    if ($def_headers) {
	for my $h ($def_headers->header_field_names) {
	    $request->init_header($h => [$def_headers->header($h)]);
	}
    }

    return($request);
}


sub simple_request
{
    my($self, $request, $arg, $size) = @_;
    $self->_request_sanity_check($request);
    my $new_request = $self->prepare_request($request);
    return($self->send_request($new_request, $arg, $size));
}


sub request
{
    my($self, $request, $arg, $size, $previous) = @_;

    LWP::Debug::trace('()');

    my $response = $self->simple_request($request, $arg, $size);

    my $code = $response->code;
    $response->previous($previous) if defined $previous;

    LWP::Debug::debug('Simple response: ' .
		      (HTTP::Status::status_message($code) ||
		       "Unknown code $code"));

    if ($code == &HTTP::Status::RC_MOVED_PERMANENTLY or
	$code == &HTTP::Status::RC_FOUND or
	$code == &HTTP::Status::RC_SEE_OTHER or
	$code == &HTTP::Status::RC_TEMPORARY_REDIRECT)
    {
	my $referral = $request->clone;

	# These headers should never be forwarded
        #Modified for GMail::IMAPD.  Cookies must be forwarded.
	$referral->remove_header('Host'); #, 'Cookie');
        #End Mod
	
	if ($referral->header('Referer') &&
	    $request->url->scheme eq 'https' &&
	    $referral->url->scheme eq 'http')
	{
	    # RFC 2616, section 15.1.3.
	    LWP::Debug::trace("https -> http redirect, suppressing Referer");
	    $referral->remove_header('Referer');
	}

	if ($code == &HTTP::Status::RC_SEE_OTHER ||
	    $code == &HTTP::Status::RC_FOUND) 
        {
	    my $method = uc($referral->method);
	    unless ($method eq "GET" || $method eq "HEAD") {
		$referral->method("GET");
		$referral->content("");
		$referral->remove_content_headers;
	    }
	}

	# And then we update the URL based on the Location:-header.
	my $referral_uri = $response->header('Location');
	{
	    # Some servers erroneously return a relative URL for redirects,
	    # so make it absolute if it not already is.
	    local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
	    my $base = $response->base;
	    $referral_uri = "" unless defined $referral_uri;
	    $referral_uri = $HTTP::URI_CLASS->new($referral_uri, $base)
		            ->abs($base);
	}
	$referral->url($referral_uri);

	# Check for loop in the redirects, we only count
	my $count = 0;
	my $r = $response;
	while ($r) {
	    if (++$count > $self->{max_redirect}) {
		$response->header("Client-Warning" =>
				  "Redirect loop detected (max_redirect = $self->{max_redirect})");
		return $response;
	    }
	    $r = $r->previous;
	}

	return $response unless $self->redirect_ok($referral, $response);
	return $self->request($referral, $arg, $size, $response);

    }
    elsif ($code == &HTTP::Status::RC_UNAUTHORIZED ||
	     $code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED
	    )
    {
	my $proxy = ($code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED);
	my $ch_header = $proxy ?  "Proxy-Authenticate" : "WWW-Authenticate";
	my @challenge = $response->header($ch_header);
	unless (@challenge) {
	    $response->header("Client-Warning" => 
			      "Missing Authenticate header");
	    return $response;
	}

	require HTTP::Headers::Util;
	CHALLENGE: for my $challenge (@challenge) {
	    $challenge =~ tr/,/;/;  # "," is used to separate auth-params!!
	    ($challenge) = HTTP::Headers::Util::split_header_words($challenge);
	    my $scheme = lc(shift(@$challenge));
	    shift(@$challenge); # no value
	    $challenge = { @$challenge };  # make rest into a hash
	    for (keys %$challenge) {       # make sure all keys are lower case
		$challenge->{lc $_} = delete $challenge->{$_};
	    }

	    unless ($scheme =~ /^([a-z]+(?:-[a-z]+)*)$/) {
		$response->header("Client-Warning" => 
				  "Bad authentication scheme '$scheme'");
		return $response;
	    }
	    $scheme = $1;  # untainted now
	    my $class = "LWP::Authen::\u$scheme";
	    $class =~ s/-/_/g;

	    no strict 'refs';
	    unless (%{"$class\::"}) {
		# try to load it
		eval "require $class";
		if ($@) {
		    if ($@ =~ /^Can\'t locate/) {
			$response->header("Client-Warning" =>
					  "Unsupported authentication scheme '$scheme'");
		    }
		    else {
			$response->header("Client-Warning" => $@);
		    }
		    next CHALLENGE;
		}
	    }
	    unless ($class->can("authenticate")) {
		$response->header("Client-Warning" =>
				  "Unsupported authentication scheme '$scheme'");
		next CHALLENGE;
	    }
	    return $class->authenticate($self, $proxy, $challenge, $response,
					$request, $arg, $size);
	}
	return $response;
    }
    return $response;
}


#
# Now the shortcuts...
#
sub get {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::GET( @parameters ), @suff );
}


sub post {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,2);
    return $self->request( HTTP::Request::Common::POST( @parameters ), @suff );
}


sub head {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::HEAD( @parameters ), @suff );
}


sub _process_colonic_headers {
    # Process :content_cb / :content_file / :read_size_hint headers.
    my($self, $args, $start_index) = @_;

    my($arg, $size);
    for(my $i = $start_index; $i < @$args; $i += 2) {
	next unless defined $args->[$i];

	#printf "Considering %s => %s\n", $args->[$i], $args->[$i + 1];

	if($args->[$i] eq ':content_cb') {
	    # Some sanity-checking...
	    $arg = $args->[$i + 1];
	    Carp::croak("A :content_cb value can't be undef") unless defined $arg;
	    Carp::croak("A :content_cb value must be a coderef")
		unless ref $arg and UNIVERSAL::isa($arg, 'CODE');
	    
	}
	elsif ($args->[$i] eq ':content_file') {
	    $arg = $args->[$i + 1];

	    # Some sanity-checking...
	    Carp::croak("A :content_file value can't be undef")
		unless defined $arg;
	    Carp::croak("A :content_file value can't be a reference")
		if ref $arg;
	    Carp::croak("A :content_file value can't be \"\"")
		unless length $arg;

	}
	elsif ($args->[$i] eq ':read_size_hint') {
	    $size = $args->[$i + 1];
	    # Bother checking it?

	}
	else {
	    next;
	}
	splice @$args, $i, 2;
	$i -= 2;
    }

    # And return a suitable suffix-list for request(REQ,...)

    return             unless defined $arg;
    return $arg, $size if     defined $size;
    return $arg;
}


#
# This whole allow/forbid thing is based on man 1 at's way of doing things.
#
sub is_protocol_supported
{
    my($self, $scheme) = @_;
    if (ref $scheme) {
	# assume we got a reference to an URI object
	$scheme = $scheme->scheme;
    }
    else {
	Carp::croak("Illegal scheme '$scheme' passed to is_protocol_supported")
	    if $scheme =~ /\W/;
	$scheme = lc $scheme;
    }

    my $x;
    if(ref($self) and $x       = $self->protocols_allowed) {
      return 0 unless grep lc($_) eq $scheme, @$x;
    }
    elsif (ref($self) and $x = $self->protocols_forbidden) {
      return 0 if grep lc($_) eq $scheme, @$x;
    }

    local($SIG{__DIE__});  # protect against user defined die handlers
    $x = LWP::Protocol::implementor($scheme);
    return 1 if $x and $x ne 'LWP::Protocol::nogo';
    return 0;
}


sub protocols_allowed      { shift->_elem('protocols_allowed'    , @_) }
sub protocols_forbidden    { shift->_elem('protocols_forbidden'  , @_) }
sub requests_redirectable  { shift->_elem('requests_redirectable', @_) }


sub redirect_ok
{
    # RFC 2616, section 10.3.2 and 10.3.3 say:
    #  If the 30[12] status code is received in response to a request other
    #  than GET or HEAD, the user agent MUST NOT automatically redirect the
    #  request unless it can be confirmed by the user, since this might
    #  change the conditions under which the request was issued.

    # Note that this routine used to be just:
    #  return 0 if $_[1]->method eq "POST";  return 1;

    my($self, $new_request, $response) = @_;
    my $method = $response->request->method;
    return 0 unless grep $_ eq $method,
      @{ $self->requests_redirectable || [] };
    
    if ($new_request->url->scheme eq 'file') {
      $response->header("Client-Warning" =>
			"Can't redirect to a file:// URL!");
      return 0;
    }
    
    # Otherwise it's apparently okay...
    return 1;
}


sub credentials
{
    my($self, $netloc, $realm, $uid, $pass) = @_;
    @{ $self->{'basic_authentication'}{lc($netloc)}{$realm} } =
	($uid, $pass);
}


sub get_basic_credentials
{
    my($self, $realm, $uri, $proxy) = @_;
    return if $proxy;

    my $host_port = lc($uri->host_port);
    if (exists $self->{'basic_authentication'}{$host_port}{$realm}) {
	return @{ $self->{'basic_authentication'}{$host_port}{$realm} };
    }

    return (undef, undef);
}


sub agent {
    my $self = shift;
    my $old = $self->{agent};
    if (@_) {
	my $agent = shift;
	$agent .= $self->_agent if $agent && $agent =~ /\s+$/;
	$self->{agent} = $agent;
    }
    $old;
}


sub _agent       { "libwww-perl/$LWP::VERSION" }

sub timeout      { shift->_elem('timeout',      @_); }
sub from         { shift->_elem('from',         @_); }
sub parse_head   { shift->_elem('parse_head',   @_); }
sub max_size     { shift->_elem('max_size',     @_); }
sub max_redirect { shift->_elem('max_redirect', @_); }


sub cookie_jar {
    my $self = shift;
    my $old = $self->{cookie_jar};
    if (@_) {
	my $jar = shift;
	if (ref($jar) eq "HASH") {
	    require HTTP::Cookies;
	    $jar = HTTP::Cookies->new(%$jar);
	}
	$self->{cookie_jar} = $jar;
    }
    $old;
}

sub default_headers {
    my $self = shift;
    my $old = $self->{def_headers} ||= HTTP::Headers->new;
    if (@_) {
	$self->{def_headers} = shift;
    }
    return $old;
}

sub default_header {
    my $self = shift;
    return $self->default_headers->header(@_);
}


sub conn_cache {
    my $self = shift;
    my $old = $self->{conn_cache};
    if (@_) {
	my $cache = shift;
	if (ref($cache) eq "HASH") {
	    require LWP::ConnCache;
	    $cache = LWP::ConnCache->new(%$cache);
	}
	$self->{conn_cache} = $cache;
    }
    $old;
}


# depreciated
sub use_eval   { shift->_elem('use_eval',  @_); }
sub use_alarm
{
    Carp::carp("LWP::UserAgent->use_alarm(BOOL) is a no-op")
	if @_ > 1 && $^W;
    "";
}


sub clone
{
    my $self = shift;
    my $copy = bless { %$self }, ref $self;  # copy most fields

    # elements that are references must be handled in a special way
    $copy->{'proxy'} = { %{$self->{'proxy'}} };
    $copy->{'no_proxy'} = [ @{$self->{'no_proxy'}} ];  # copy array

    # remove reference to objects for now
    delete $copy->{cookie_jar};
    delete $copy->{conn_cache};

    $copy;
}


sub mirror
{
    my($self, $url, $file) = @_;

    LWP::Debug::trace('()');
    my $request = HTTP::Request->new('GET', $url);

    if (-e $file) {
	my($mtime) = (stat($file))[9];
	if($mtime) {
	    $request->header('If-Modified-Since' =>
			     HTTP::Date::time2str($mtime));
	}
    }
    my $tmpfile = "$file-$$";

    my $response = $self->request($request, $tmpfile);
    if ($response->is_success) {

	my $file_length = (stat($tmpfile))[7];
	my($content_length) = $response->header('Content-length');

	if (defined $content_length and $file_length < $content_length) {
	    unlink($tmpfile);
	    die "Transfer truncated: " .
		"only $file_length out of $content_length bytes received\n";
	}
	elsif (defined $content_length and $file_length > $content_length) {
	    unlink($tmpfile);
	    die "Content-length mismatch: " .
		"expected $content_length bytes, got $file_length\n";
	}
	else {
	    # OK
	    if (-e $file) {
		# Some dosish systems fail to rename if the target exists
		chmod 0777, $file;
		unlink $file;
	    }
	    rename($tmpfile, $file) or
		die "Cannot rename '$tmpfile' to '$file': $!\n";

	    if (my $lm = $response->last_modified) {
		# make sure the file has the same last modification time
		utime $lm, $lm, $file;
	    }
	}
    }
    else {
	unlink($tmpfile);
    }
    return $response;
}


sub proxy
{
    my $self = shift;
    my $key  = shift;

    LWP::Debug::trace("$key @_");

    return map $self->proxy($_, @_), @$key if ref $key;

    my $old = $self->{'proxy'}{$key};
    $self->{'proxy'}{$key} = shift if @_;
    return $old;
}


sub env_proxy {
    my ($self) = @_;
    my($k,$v);
    while(($k, $v) = each %ENV) {
	if ($ENV{REQUEST_METHOD}) {
	    # Need to be careful when called in the CGI environment, as
	    # the HTTP_PROXY variable is under control of that other guy.
	    next if $k =~ /^HTTP_/;
	    $k = "HTTP_PROXY" if $k eq "CGI_HTTP_PROXY";
	}
	$k = lc($k);
	next unless $k =~ /^(.*)_proxy$/;
	$k = $1;
	if ($k eq 'no') {
	    $self->no_proxy(split(/\s*,\s*/, $v));
	}
	else {
	    $self->proxy($k, $v);
	}
    }
}


sub no_proxy {
    my($self, @no) = @_;
    if (@no) {
	push(@{ $self->{'no_proxy'} }, @no);
    }
    else {
	$self->{'no_proxy'} = [];
    }
}


# Private method which returns the URL of the Proxy configured for this
# URL, or undefined if none is configured.
sub _need_proxy
{
    my($self, $url) = @_;
    $url = $HTTP::URI_CLASS->new($url) unless ref $url;

    my $scheme = $url->scheme || return;
    if (my $proxy = $self->{'proxy'}{$scheme}) {
	if (@{ $self->{'no_proxy'} }) {
	    if (my $host = eval { $url->host }) {
		for my $domain (@{ $self->{'no_proxy'} }) {
		    if ($host =~ /\Q$domain\E$/) {
			LWP::Debug::trace("no_proxy configured");
			return;
		    }
		}
	    }
	}
	LWP::Debug::debug("Proxied to $proxy");
	return $HTTP::URI_CLASS->new($proxy);
    }
    LWP::Debug::debug('Not proxied');
    undef;
}


sub _new_response {
    my($request, $code, $message) = @_;
    my $response = HTTP::Response->new($code, $message);
    $response->request($request);
    $response->header("Client-Date" => HTTP::Date::time2str(time));
    $response->header("Client-Warning" => "Internal response");
    $response->header("Content-Type" => "text/plain");
    $response->content("$code $message\n");
    return $response;
}


1;

__END__

