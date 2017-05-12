package HTTP::DAV::Comms;

use strict;
use vars qw($VERSION $DEBUG);

$VERSION = q(0.23);

use HTTP::DAV::Utils;
use HTTP::DAV::Response;
use LWP;
use URI;

####
# Construct a new object and initialize it
sub new {
    my $class = shift;
    my $self = bless {}, ref($class) || $class;

    #print Data::Dumper->Dump( [$self] , [ '$self' ] );
    $self->_init(@_);
    return $self;
}

# Requires a reusable HTTP Agent.
# and some default headers, like, the user agent
sub _init {
    my ( $self, @p ) = @_;
    my ( $headers, $useragent )
        = HTTP::DAV::Utils::rearrange( [ 'HEADERS', 'USERAGENT' ], @p );

    # This is cached in this object here so that each http request
    # doesn't have to invoke a new useragent.
    $self->init_user_agent($useragent);

    $self->set_headers($headers);
}

sub init_user_agent {
    my ( $self, $useragent ) = @_;
    if ( defined $useragent ) {
        $self->{_user_agent} = $useragent;
    }
    else {
        $self->{_user_agent} = HTTP::DAV::UserAgent->new;
        $self->set_agent("DAV.pm/v$HTTP::DAV::VERSION");
    }
}

####
# GET/SET

# Sets a User-Agent as specified by user or as the default
sub set_agent {
    my ( $self, $agent ) = @_;
    $self->{_user_agent}->agent($agent);
}

sub set_header {
    my ( $self, $var, $val ) = @_;
    $self->set_headers() unless defined $self->{_headers};
    $self->{_headers}->header( $var, $val );
}

sub get_user_agent { $_[0]->{_user_agent}; }
sub get_headers    { $_[0]->{_headers}; }

sub set_headers {
    my ( $self, $headers ) = @_;

    my $dav_headers;

    if ( defined $headers && ref($headers) eq "HTTP::Headers" ) {
        $dav_headers = HTTP::DAV::Headers->clone($headers);
    }
    elsif (defined $headers && ref($headers) eq "HASH") {
        $dav_headers = HTTP::DAV::Headers->new();
        for (keys %{ $headers }) {
            $dav_headers->header($_ => $headers->{$_});
        }
    } else {
        $dav_headers = HTTP::DAV::Headers->new;
    }

    $self->{_headers} = $dav_headers;
}

sub _set_last_request  { $_[0]->{_last_request}  = $_[1]; }
sub _set_last_response { $_[0]->{_last_response} = $_[1]; }

# Save the Server: header line into this object instance
# We will want to use it later to workaround server bugs.
# For instance mod_dav has a bug in the Destination: header
# whereby it incorrectly throws "Bad Gateway" errors.
# The only way we can munge around this is if the copy() routine
# has some idea of the server it is talking to.
# So this routine stores the "Server: Apache..." line into a host:port hash (i.e. localhost:443).
# so $comms->_set_server_type( "host.org:443", "Apache/1.3.22 (Unix) DAV/1.0.2 ")
# yields
#     %_server_type = {
#        "host.org:443" => "Apache/1.3.22 (Unix) DAV/1.0.2 SSL"
#        "host.org:80" =>  "Apache/1.3.22 (Unix) DAV/1.0.2 "
#        };
# Note that this is an instance hash NOT a class hash.
# So each comms object will be learning independently.
sub _set_server_type { $_[0]->{_server_type}{ $_[1] } = $_[2]; }

# $server = $comms->get_server_type( "host.org:443" )
sub get_server_type { $_[0]->{_server_type}{ $_[1] } }

# Returns an HTTP::Request object
sub get_last_request { $_[0]->{_last_request}; }

# Returns an HTTP::DAV::Response object
sub get_last_response { $_[0]->{_last_response}; }

####
# Ensure there is a Host: header based on the URL
#
sub do_http_request {
    my ( $self, @p ) = @_;

    my ( $method, $url, $newheaders, $content, $save_to, $callback_func,
        $chunk )
        = HTTP::DAV::Utils::rearrange(
        [   'METHOD', [ 'URL', 'URI' ], 'HEADERS', 'CONTENT',
            'SAVE_TO', 'CALLBACK', 'CHUNK'
        ],
        @p
        );

    # Method management
    if ( !defined $method || $method eq "" || $method !~ /^\w+$/ ) {
        die "Incorrect HTTP Method specified in do_http_request: \"$method\"";
    }
    $method = uc($method);

    # URL management
    my $url_obj;
    $url_obj = ( ref($url) =~ /URI/ ) ? $url : URI->new($url);

    die "Comms: Bad HTTP Url: \"$url_obj\"\n"
        if ( $url_obj->scheme !~ /^http/ );

    # If you see user:pass detail embedded in the URL. Then get it out.
    if ( $url_obj->userinfo ) {
        $self->{_user_agent}
            ->credentials( $url, undef, split( ':', $url_obj->userinfo ) );
    }

    # Header management
    if ( $newheaders && ref($newheaders) !~ /Headers/ ) {
        die "Bad headers object: "
            . Data::Dumper->Dump( [$newheaders], ['$newheaders'] );
    }

    my $headers = HTTP::DAV::Headers->new();
    $headers->add_headers( $self->{_headers} );
    $headers->add_headers($newheaders);

    #$headers->header("Host", $url_obj->host);
    $headers->header( "Host", $url_obj->host_port );

    my $length = ($content) ? length($content) : 0;
    $headers->header( "Content-Length", $length );

    #print "HTTP HEADERS\n" . $self->get_headers->as_string . "\n\n";

    # It would be good if, at this stage, we could prefill the
    # username and password values to prevent the client having
    # to submit 2 requests, submit->401, submit->200
    # This is the same kind of username, password remembering
    # functionality that a browser performs.
    #@userpass = $self->{_user_agent}->get_basic_credentials(undef, $url);

    # Add a Content-type of text/xml if the body has <?xml in it
    if ( $content && $content =~ /<\?xml/i ) {
        $headers->header( "Content-Type", "text/xml" );
    }

    ####
    # Do the HTTP call
    my $req
        = HTTP::Request->new( $method, $url_obj, $headers->to_http_headers,
        $content );

    # It really bugs me, but libwww-perl doesn't honour this call.
    # I'll leave it here anyway for future compatibility.
    $req->protocol("HTTP/1.1");

    my $resp;

    # If a callback is set and it is a ref to a function
    # then pass it through to LWP::UserAgent::request.
    # See man page of LWP for more details of callback.
    # callback is primarily used by DAV::get();
    #
    if ( defined $save_to && $save_to ne "" ) {
        $resp = $self->{_user_agent}->request( $req, $save_to );
    }
    elsif ( ref($callback_func) =~ /CODE/ ) {
        $resp = $self->{_user_agent}->request( $req, $callback_func, $chunk );
    }
    else {
        $resp = $self->{_user_agent}->request($req);
    }

    # Redirect loop {{{
    my $code = $resp->code;
    if (   $code == &HTTP::Status::RC_MOVED_PERMANENTLY
        or $code == &HTTP::Status::RC_MOVED_TEMPORARILY )
    {

        # And then we update the URL based on the Location:-header.
        my ($referral_uri) = $resp->header('Location');
        {

            # Some servers erroneously return a relative URL for redirects,
            # so make it absolute if it not already is.
            local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
            my $base = $resp->base;
            $referral_uri
                = $HTTP::URI_CLASS->new( $referral_uri, $base )->abs($base);
        }

        # Check for loop in the redirects
        my $count    = 0;
        my $r        = $resp;
        my $bad_loop = 0;
        while ($r) {
            if ( ++$count > 13
                || $r->request->url->as_string eq $referral_uri->as_string )
            {
                $resp->header( "Client-Warning" => "Redirect loop detected" );

#if ( $HTTP::DAV::DEBUG ) {
#   print "*** CLIENT AND SERVER STUCK IN REDIRECT LOOP OR MOVED PERMENANTLY. $count. BREAKING ***\n";
#   print "***    " . $r->request->url->as_string . "***\n";
#   print "***    " . $referral_uri->as_string . "***\n";
#}
                $bad_loop = 1;
                last;
            }
            $r = $r->previous;
        }
        $resp = $self->do_http_request(
            -method   => $method,
            -url      => $referral_uri,
            -headers  => $newheaders,
            -content  => $content,
            -saveto   => $save_to,
            -callback => $callback_func,
            -chunk    => $chunk,
        ) unless $bad_loop;
    }

    # }}}

    if ($HTTP::DAV::DEBUG > 1) {
        no warnings;
        #open(DEBUG, ">&STDOUT") || die ("Can't open STDERR");;
        my $old_umask = umask 0077;
        open( DEBUG, ">>/tmp/perldav_debug.txt" );
        print DEBUG "\n" . "-" x 70 . "\n";
        print DEBUG localtime() . "\n";
        print DEBUG "$method REQUEST>>\n" . $req->as_string();

        if ( $resp->headers->header('Content-Type') =~ /xml/ ) {
            my $body = $resp->as_string();
            #$body =~ s/>\n*/>\n/g;
            print DEBUG "$method XML RESPONSE>>$body\n";
        #} elsif ( $resp->headers->header('Content-Type') =~ /text.html/ ) {
        #require HTML::TreeBuilder;
        #require HTML::FormatText;
        #my $tree = HTML::TreeBuilder->new->parse($resp->content());
        #my $formatter = HTML::FormatText->new(leftmargin => 0);
        #print DEBUG "$method RESPONSE (HTML)>>\n" . $resp->headers->as_string();
        #print DEBUG $formatter->format($tree);
        }
        else {
            print DEBUG "$method RESPONSE>>\n" . $resp->as_string();
        }
        close DEBUG;
        umask $old_umask;
    }

    ####
    # Copy the HTTP:Response into a HTTP::DAV::Response. It specifically
    # knows details about DAV Status Codes and their associated
    # messages.
    my $dav_resp = HTTP::DAV::Response->clone_http_resp($resp);
    $dav_resp->set_message( $resp->code );

    ####
    # Save the req and resp objects as the "last used"
    $self->_set_last_request($req);
    $self->_set_last_response($dav_resp);

    $self->_set_server_type( $url_obj->host_port,
        $dav_resp->headers->header("Server") );

    return $dav_resp;
}

sub credentials {
    my ( $self, @p ) = @_;
    my ( $user, $pass, $url, $realm )
        = HTTP::DAV::Utils::rearrange( [ 'USER', 'PASS', 'URL', 'REALM' ],
        @p );
    $self->{_user_agent}->credentials( $url, $realm, $user, $pass );
}

###########################################################################
# We make our own specialization of LWP::UserAgent
# called HTTP::DAV::UserAgent.
# The variations allow us to have various levels of protection.
# Where the user hasn't specified what Realm to use we pass the
# userpass combo to all realms of that host
# Also this UserAgent remembers a user on the next request.
# The standard UserAgent doesn't.
{

    package HTTP::DAV::UserAgent;

    use strict;
    use vars qw(@ISA);

    @ISA = qw(LWP::UserAgent);

    #require LWP::UserAgent;

    sub new {
        my $self = LWP::UserAgent::new(@_);
        $self->agent("lwp-request/$HTTP::DAV::VERSION");
        $self;
    }

    sub credentials {
        my ( $self, $netloc, $realm, $user, $pass ) = @_;

        $realm = 'default' unless $realm;

        if ($netloc) {
            $netloc = "http://$netloc" unless $netloc =~ m{^http};
            my $uri = URI->new($netloc);
            $netloc = $uri->host_port;
        }
        else {
            $netloc = 'default';
        }

        {
          	no warnings;
			if ($HTTP::DAV::DEBUG > 2) {
				if (defined $user) {
					print "Setting auth details for $netloc, $realm to '$user', '$pass'\n";
				}
				else {
					print "Resetting user and password for $netloc, $realm\n";
				}
			}
        }

		# Pay attention to not autovivify the hash value (RT #47500)
		my $cred;
		if (
			exists $self->{basic_authentication}->{$netloc} &&
			exists $self->{basic_authentication}->{$netloc}->{$realm}) {
			$cred = $self->{basic_authentication}->{$netloc}->{$realm};
		}
		else {
			$cred = [];
		}

        # Replace with new credentials (if any)
        if (defined $user) {
            $self->{basic_authentication}->{$netloc}->{$realm}->[0] = $user;
            $self->{basic_authentication}->{$netloc}->{$realm}->[1] = $pass;
			$cred = $self->{basic_authentication}->{$netloc}->{$realm};
        }

        # Return current values
		if (! @{$cred}) {
			return wantarray ? () : undef;
		}

        # User/password pair
        if (wantarray) { return @{$cred} }

        # As string: 'user:password'
        return join( ':', @{$cred} );
    }

    sub get_basic_credentials {
        my ( $self, $realm, $uri ) = @_;

        $uri = HTTP::DAV::Utils::make_uri($uri);
        my $netloc = $uri->host_port;

        my $userpass;
        {
            no warnings;    # SHUTUP with your silly warnings.
            $userpass 
                = $self->{'basic_authentication'}{$netloc}{$realm}
                || $self->{'basic_authentication'}{default}{$realm}
                || $self->{'basic_authentication'}{$netloc}{default}
                || [];

            print "Using user/pass combo: @$userpass. For $realm, $uri\n"
                if $HTTP::DAV::DEBUG > 2;

        }
        return @$userpass;
    }

    # Override to disallow redirects. Also, see RT #19616
    sub redirect_ok {
        return 0;
    }

}

###########################################################################
# We make our own special version of HTTP::Headers
# called HTTP::DAV::Headers. This is because we want to add
# a new method called add_headers
{

    package HTTP::DAV::Headers;

    use strict;
    use vars qw(@ISA);

    @ISA = qw( HTTP::Headers );
    require HTTP::Headers;

    # $dav_headers = HTTP::DAV::Headers->clone( $http_headers );

    sub to_http_headers {
        my ($self) = @_;
        my %clone = %{$self};
        bless {%clone}, "HTTP::Headers";
    }

    sub clone {
        my ( $class, $headers ) = @_;
        my %clone = %{$headers};
        bless {%clone}, ref($class) || $class;
    }

    sub add_headers {
        my ( $self, $headers ) = @_;
        return unless ( defined $headers && ref($headers) =~ /Headers/ );

        #print "About to add headers!!\n";
        #print Data::Dumper->Dump( [$headers] , [ '$headers' ] );
        foreach my $key ( sort keys %$headers ) {
            $self->header( $key, $headers->{$key} );
        }
    }
}

1;
