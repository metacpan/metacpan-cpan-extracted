package DracPerl::Client;

our $VERSION = "0.10";

use Log::Any ();
use Log::Any::Adapter;

use LWP::UserAgent;
use Moose;
use XML::Simple qw(XMLin);

has 'ua' => ( lazy => 1, is => 'ro', builder => '_build_ua' );

has 'url'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'user'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'password' => ( is => 'ro', isa => 'Str', required => 1 );

has 'max_retries' => ( is => 'ro', isa => 'Int', default => 5 );
has 'token'       => ( is => 'rw', isa => 'Str', default => 0 );

has 'log' => (
    is      => 'ro',
    default => sub {
        Log::Any::Adapter->set('Stdout');
        return Log::Any->get_logger;
    }
);

sub _build_ua {
    my $ua = LWP::UserAgent->new();
    $ua->ssl_opts( verify_hostname => 0 );
    $ua->cookie_jar( {} );

    #Thanks Spotify for theses two headers.
    #https://github.com/spotify/moob/blob/master/lib/moob/idrac7.rb#L23
    $ua->default_header( 'Accept-Encoding' => 'gzip,deflate,sdch' );
    $ua->default_header( 'Accept-Language' => 'en-US,en;q=0.8,sv;q=0.6' );

    $ua->default_header( 'Accept' => '*/*' );

    return $ua;
}

sub openSession {
    my ( $self, $saved_session ) = @_;

    unless ($saved_session) {
        $self->log->debug("Opening new session");
        return $self->_login;
    }

    $self->log->debug("Resuming opened session");
    $self->token( $saved_session->{token} );
    $self->ua->cookie_jar( $saved_session->{cookie_jar} );
    $self->ua->default_header( "ST2", $self->token );
    return 1;
}

sub closeSession {
    my ($self) = @_;

    my $logout_page = $self->ua->post( $self->url . "/data/logout" );

    $self->token(0);
    $self->ua->default_header( "ST2", $self->token );
    $self->log->debug( "Logging out : " . $logout_page->decoded_content );
    return 1;
}

sub saveSession {
    my ($self) = @_;
    my %saved_session;

    return 0 unless $self->token;

    $self->log->info("Saving the session");
    $saved_session{token}      = $self->token;
    $saved_session{cookie_jar} = $self->ua->cookie_jar;

    return \%saved_session;
}

sub isAlive {
    my ($self) = @_;
    use Data::Dumper;
    my $response = $self->ua->get( $self->url . "TreeList.xml" );

    return 0 unless $response->is_success;

    my $treelist = XMLin( $response->decoded_content );

    return 0 unless $treelist->{TreeNode};
    return 1;

}

sub _login {
    my $self = shift;

    my $login_form = $self->ua->get( $self->url . "/login.html" );

    if ( $login_form->is_success ) {
        $self->log->info("Login Step 0 success");
    }
    else {
        $self->log->error( "iDrac login page is unreacheable : "
                . $self->url
                . "/login.html" );
        die();
    }

    my $response_raw;
    my $response_xml;
    my $need_to_retry = 1;
    my $current_tries = 1;
    my $logged;

    while ($need_to_retry) {

        $response_raw = $self->ua->post(
            $self->url . "/data/login",
            {   user     => $self->user,
                password => $self->password
            }
        );

        if ( $response_raw->is_success ) {
            $response_xml = XMLin( $response_raw->decoded_content );
            $logged       = !$response_xml->{authResult};
        }

        $need_to_retry = 0 if $logged;
        $need_to_retry = 0 if $current_tries > $self->max_retries - 1;

        if ($logged) {
            $self->log->info( "Sucessfully performed login step 1 ( Attempt "
                    . $current_tries . "/"
                    . $self->max_retries
                    . ")" );
        }
        else {
            $self->log->error( "Failed login step 1. ( Attempt "
                    . $current_tries . "/"
                    . $self->max_retries
                    . ")" );
        }

        $current_tries++;
    }

    die( "Logging failed after " . $self->max_retries . " attempts" )
        unless $logged;

    $self->log->debug(
        "Login Step 1 response : " . $response_raw->decoded_content );

    my @tokens_parts = reverse split( "=", $response_xml->{forwardUrl} );

    $self->log->info( "Success while opening session / " . $tokens_parts[0] );

    $self->token( $tokens_parts[0] ) if $tokens_parts[0];
    $self->ua->default_header( "ST2", $self->token );
    return 1;
}

sub get {
    my ( $self, $query ) = @_;

    $self->openSession() unless $self->token;

    my $response = $self->ua->post( $self->url . "/data?get=" . $query );

    if ( $response->is_success ) {
        $self->log->info("Sucessfully fetched $query");
    }
    else {
        $self->log->error("Error while fetching $query");
    }

    my $parsed_response;

    $parsed_response = XMLin( $response->decoded_content )
        if $response->is_success;

    return $parsed_response || 0;
}

sub set {
    die("Not implemented yet");
}

=head1 NAME

DracPerl::Client - API Client for Dell's management interface (iDRAC)

=head1 AUTHOR

Jules Decol (@Apcros)

=head1 SYNOPSIS

A client to interact with the iDRAC API on Dell Poweredge servers

	# Create the client
	my $drac_client = DracPerl::Client->new({
			user 		=> "username",
			password 	=> "password",
			url 		=> "https://dracip",
			});

	# Get what you're interested in
	# Login is done implicitly, you can save and resume sessions. See below
	my $parsed_xml = $drac_client->get("fans");

=head1 DESCRIPTION

=head2 WHY ?

This been created because I find the web interface of iDrac slow and far from being easy to use. 
I have the project of creating a full new iDrac front-end, but of course that project required an API Client. 
Because this is something that seem to be quite lacking in the PowerEdge community, I made a standalone repo/project for that :)

=head2 TODO

What's to come ? 

- Better error handling

- Integration with Log4Perl

- Full list of supported Method 

- Few method to abstract commons operations

=head1 OBJECT ARGUMENTS


=head2 max_retries

Login can be extremely capricious, Max retries avoid being too
annoyed by that. Defaulted to 5.

=head1 METHODS

=head2 openSession

Can be called explicitly or is called by default if get is called and no session is available
You can pass it a saved session in order to restore it. 

	$drac_client->openSession($saved_session) #Will restore a session
	$drac_client->openSession() #Will open a new one

=head2 saveSession

This will return the current session. (Basically the token and the cookie jar).

=head2 closeSession

Invalidate the current session

=head2 isAlive

Check with a quick api call if your current session is still useable.


=cut

1;
