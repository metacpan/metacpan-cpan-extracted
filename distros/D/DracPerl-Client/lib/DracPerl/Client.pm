package DracPerl::Client;

our $VERSION = "0.20";

use Log::Any ();
use Log::Any::Adapter;

use LWP::UserAgent;
use Moose;

use DracPerl::Factories::DellDefaultCommand;
use DracPerl::Factories::CommandCollection;
use DracPerl::CollectionMappings;
use DracPerl::Models::Auth;

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

    return 0 unless $self->token;

    $self->log->info("Saving the session");
    return {
        token      => $self->token,
        cookie_jar => $self->ua->cookie_jar
    };
}

sub isAlive {
    my ($self) = @_;
    use Data::Dumper;
    my $response = $self->ua->get( $self->url . "TreeList.xml" );

    return 0 unless $response->is_success;

  # We don't really care about parsing the XML here, we just want to make sure
  # it is returning *something*
    return 0 unless $response->decoded_content =~ m/<TreeNodes>/;

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
    my $auth_model;
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
            $auth_model = DracPerl::Models::Auth->new(
                xml => $response_raw->decoded_content );
            $logged = !$auth_model->auth_result;
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

    my @tokens_parts = reverse split( "=", $auth_model->forward_url );

    $self->log->info( "Success while opening session / " . $tokens_parts[0] );

    $self->token( $tokens_parts[0] ) if $tokens_parts[0];
    $self->ua->default_header( "ST2", $self->token );
    return 1;
}

sub getCustomModel {
    my ( $self, $name ) = @_;

    my $result
        = $self->get(
        { custom_commands => DracPerl::CollectionMappings::get_query($name) }
        );
    return $result unless $result->{success};
    return $result->{$name};
}

sub get {
    my ( $self, $args ) = @_;

    $self->openSession() unless $self->token;

    my $commands    = $args->{commands};
    my $collections = $args->{collections};

    unless ( scalar @{$commands} || scalar @{$collections} ) {
        $self->log->error("No commands or collections specified");
        return 0;
    }

    my $query = $self->_build_query_string( $commands, $collections );

    my $response = $self->ua->post( $self->url . "/data?get=" . $query );

    if ( $response->is_success ) {
        $self->log->info("Sucessfully fetched $query");
    }
    else {
        $self->log->error("Error while fetching $query");
    }

    my $raw_response = $response->decoded_content;

    return $self->_parse_response( $commands, $collections, $raw_response );
}

sub _parse_response {
    my ( $self, $commands, $collections, $xml ) = @_;

    #TODO : Snake-case the commands before putting them in the hash
    my $result;

    foreach my $command ( @{$commands} ) {
        my $model = DracPerl::Factories::DellDefaultCommand->create( $command,
            { xml => $xml } );
        $result->{$command} = $model;
    }

    foreach my $collection ( @{$collections} ) {
        my $model
            = DracPerl::Factories::CommandCollection->create( $collection,
            { xml => $xml } );
        $result->{$collection} = $model;
    }

    return $result
        || {
        success => 0,
        message => 'XML returned matched no model',
        raw     => $xml
        };
}

sub _build_query_string {
    my ( $self, $commands, $collections ) = @_;

    my $query = '';

    $query = join( ',', @{$commands} );

    #TODO : Deduplicate
    my @collections_queries
        = map { DracPerl::CustomCommandsMappings::get_query($_) }
        @{$collections};

    $query .= join( ',', @collections_queries );

    return $query;
}

sub set {
    die("Not implemented yet");
}

=head1 NAME

DracPerl::Client - API Client for Dell's management interface (iDRAC)

=head1 AUTHOR

Jules Decol - @Apcros

=head1 SYNOPSIS

A client to interact with the iDRAC API on Dell Poweredge servers

    # Create the client
    my $drac_client = DracPerl::Client->new({
            user        => "username",
            password    => "password",
            url         => "https://dracip",
            });

    # Get what you're interested in
    # Login is done implicitly, you can save and resume sessions. See below
    my $parsed_xml = $drac_client->get({ commands => ['fans']});

=head1 DESCRIPTION

=head2 WHY ?

This been created because I find the web interface of iDrac slow and far from being easy to use. 
I have the project of creating a full new iDrac front-end, but of course that project required an API Client. 
Because this is something that seem to be quite lacking in the PowerEdge community, I made a standalone repo/project for that :)

=head2 PITFALLS

The DRAC API this client is exploiting is meant to be used only by the DRAC front-end and therefore comes with it loads of weirdness.

- A lot of fields have trailing whitespace in them (Possible update coming soon to clean theses)
- When no data is available some fields will be empty, some will be 'N/A', there seem to be no consistency there
- Some fields are padded (See L<DracPerl::Models::Abstract::PhysicalDisk> )

Please note that depending on your network config you might have trouble accessing DRAC from the server itself. (If you are inside a VM running on the Dell server for example)

=head1 OBJECT ARGUMENTS

=head2 max_retries

Login can be extremely capricious, Max retries avoid being too
annoyed by that. Defaulted to 5.

=head1 METHODS

=head2 get

Will return a hash containing models of all the methods or collection you called.

    my $result = $drac_client->get({
        commands => ['fans'],
        collections => ['lcd']
    });

    # $result will contain :
    {
        fans => .. #DracPerl::Models::Commands::DellDefault::Fans,
        lcd => .. #DracPerl::Models::Commands::Collection::LCD
    }

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

=head1 COMMANDS

A command is a single field defined by the DRAC API.
They can be send in the "commands" hash key on the get method

Here's the list of supported commands :

B<batteries> - L<DracPerl::Models::Commands::DellDefault::Batteries>

B<eventLogEntries> - L<DracPerl::Models::Commands::DellDefault::EventLogEntries>

B<racLogEntries> - L<DracPerl::Models::Commands::DellDefault::RacLogEntries>

B<fans> - L<DracPerl::Models::Commands::DellDefault::Fans>

B<fansRedundancy> - L<DracPerl::Models::Commands::DellDefault::FansRedundancy>

B<getInv> - L<DracPerl::Models::Commands::DellDefault::GetInv>

B<intrusion> - L<DracPerl::Models::Commands::DellDefault::Intrusion>

B<powerSupplies> - L<DracPerl::Models::Commands::DellDefault::PowerSupplies>

B<temperatures> - L<DracPerl::Models::Commands::DellDefault::Temperatures>

B<voltages> - L<DracPerl::Models::Commands::DellDefault::Voltages>

=head1 COLLECTIONS

Collections are groups of field. This is not a Dell terminology.
This was created because some interfaces pages (LCD information for example)
will need several commands and the commands themselves are too small to justify
having a standalone model for them.

B<systemInformations> - L<DracPerl::Models::Commands::Collection::SystemInformations>

B<lcd> - L<DracPerl::Models::Commands::Collection::LCD>

=cut

1;
