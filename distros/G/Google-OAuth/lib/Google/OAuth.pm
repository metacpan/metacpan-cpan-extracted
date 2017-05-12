package Google::OAuth ;
use base NoSQL::PL2SQL ;
use Google::OAuth::Config ;
use LWP::UserAgent ;
use JSON ;

use 5.008009;
use strict;
use warnings;

require Exporter;

push @Google::OAuth::ISA, 
		qw( Exporter Google::OAuth::Request Google::OAuth::Client ) ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Google::OAuth ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw();

our $VERSION = '0.05';


# Preloaded methods go here.

my $duplicate = sub {
	my ( $emailkey, $errorcode, $perldata, $zero, $obj, $errorstring ) 
			= @_ ;

	my $package = ref $obj ;
	my $u = $package->SQLObject( $emailkey ) ;
	my %keys = map { $_ => 1 } keys %$u, keys %$obj ;

	map { exists $obj->{$_}? 
			( $u->{$_} = $obj->{$_} ):
			( delete $u->{$_} ) } keys %keys ;
	return bless $u, $package ;
	} ;

sub SQLClone {
	my $arg = shift ;
	my ( $self, $package ) = ref $arg? ( $arg, ref $arg ): ( undef, $arg ) ;
	$self ||= $package->SQLObject( @_ ) ;

	return bless NoSQL::PL2SQL::SQLClone( $self ), $package ;
	}

sub classID {
	return 0 ;
	}

sub grant_type {
	return 'refresh_token' ;
	}

sub SQLObject {
	my $package = shift ;
	my $email = shift ;
	NoSQL::PL2SQL::SQLError( $email, 
			DuplicateObject => $duplicate ) ;
	my @args = ( $email, $package->dsn, $package->classID ) ;

	push @args, bless $_[0], $package if @_ ;
	my $out = NoSQL::PL2SQL::SQLObject( @args ) ;
	return $out? bless( $out, $package ): undef ;
	}

sub grant_code {
	my $package = shift @_ ;
	my $code = shift ;
	my $token = $package->get_token( 'redirect_uri', { code => $code }, 
			{ grant_type => 'authorization_code' } ) ;

	my $key = $token->emailkey 
			if ref $token && $token->{access_token} ;
	return $key? $package->SQLObject( $key => $token ): $token ;
	}

sub token_list {
	my $package = shift ;

	return map { $_->{objecttype} } $package->dsn->fetch( 
			[ reftype => 'perldata', 1 ], 
			[ objectid => $package->classID ] 
			) ;
	}

sub token {
	my $arg = shift ;
	my ( $self, $package ) = ref $arg? ( $arg, ref $arg ): ( undef, $arg ) ;

	my $object = $self ;
	$self ||= $package->SQLObject( @_ ) ;

	my $rr = $package->grant_type ;
	my $token = $package->get_token( 
			{ $rr => $self->{$rr} }, 
			{ grant_type => $rr } 
			) ;

	if ( ref $token && $token->{access_token} ) {
		map { $self->{$_} = $token->{$_} } keys %$token ;
		}
	else {
		my $error = ref $token? join( "\n", %$token ): $token ;
		warn join "\n", 'Access renewal failed:', $error, '' ;
		}

	## Object may be a clone
	unless ( defined $self->SQLObjectID ) {
		my $package = ref $self ;
		my $temp = $package->SQLObject( $self->{emailkey} ) ;
		map { $temp->{$_} = $self->{$_} } keys %$self ;
		$self = $temp->SQLClone ;
		}

	return $object || $self->SQLClone ;
	}

sub headers {
	my $self = shift ;
	my $method = shift ;

	return Google::OAuth::Request::headers( $method ),
			Authorization =>
			  join ' ', @$self{ qw( token_type access_token ) } ;
	}

sub emailkey {
	my $self = shift ;
	my $url = 'https://www.googleapis.com'
				.'/calendar/v3/users/me/calendarList' ;
	my $calinfo = $self->content( GET => $url ) ;
	my @owner = grep $_->{accessRole} eq 'owner', @{ $calinfo->{items} } ;
	return $self->{emailkey} = $owner[0]->{summary} ;
	}


package Google::OAuth::Client ;

require Exporter;

@Google::OAuth::Client::ISA = qw( Exporter ) ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Google::OAuth ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw() ;

our $VERSION = '0.01';

our %google ;
$google{oauth} = 'https://accounts.google.com/o/oauth2/auth';
$google{token} = 'https://accounts.google.com/o/oauth2/token';

my %client = () ;
setclient() ;

sub setclient {
	my $package = shift ;
	%client = ( Google::OAuth::Config->setclient, @_ ) ;
	return undef ;
	}

sub dsn {
	return $client{dsn} ;
	}

my %scopes = (
	'm8.feeds' 
			=> 'https://www.google.com/m8/feeds',
	'calendar' 
			=> 'https://www.googleapis.com/auth/calendar',
	'calendar.readonly' 
			=> 'https://www.googleapis.com/auth/calendar.readonly',
	'drive.readonly' 
			=> 'https://www.googleapis.com/auth/drive.readonly',
	'drive' 
			=> 'https://www.googleapis.com/auth/drive',
        ) ;

sub new {
	my $package = shift ;
	my $self = {} ;
	$self->{args} = $package->queryargs( @_ ) if @_ ;
	return bless $self, $package ;
	}

sub scope {
	shift @_ if $_[0] eq __PACKAGE__ ;
	my $self = ref $_[0] eq __PACKAGE__? shift @_: undef ;
	my %args = map { $_ => 1 } ( @_, 'calendar.readonly' ) ;

	my $scope = join ' ', map { $scopes{$_} } keys %args ;
	return $scope unless $self ;

	$self->{scope} = $scope ;
	return $self ;
	}

sub queryargs {
	my $package = shift ;
	my %out = map { ref $_? %$_: ( $_ => $client{$_} ) } @_ ; 
	return \%out ;
	}

sub token_request {
	my $self = shift ;
	my $args = $self->{args} || $self->queryargs( 
			'client_id', 'redirect_uri',
			{ response_type => 'code' },
			{ approval_prompt => 'force' },
			{ access_type => 'offline' }
			) ;
	$args->{scope} = $self->{scope} if $self->{scope} ;
	
	my $kurl = @_? shift @_: 'oauth' ;
	return join '?', $google{$kurl} || $kurl, 
			Google::OAuth::CGI->new( $args )->query_string ;
	}

sub get_token {
	my $arg = shift ;
	my ( $package, $self ) = ref $arg?
			( ref $arg, $arg ):
			( $arg, 
			  new( $arg, 'client_id', 'client_secret', @_ ) ) ;

	my $out = Google::OAuth::Request->content( 
			POST => $google{token},
			Google::OAuth::CGI->new( $self->{args} )->query_string
			) ;

	return $out unless ref $out ;
	$out->{requested} = time ;
	return bless $out, $package ;
	}

sub expired {
	my $self = shift ;
	return $self->{requested} +$self->{expires_in} < time ;
	}


package Google::OAuth::Request ;

my %content_type = () ;
$content_type{POST} = 'application/x-www-form-urlencoded' ;
$content_type{GET} = 'application/http' ;

sub request {
	my $self = shift ;
	my $method = @_ > 1? shift @_: 'GET' ;
	my $url = shift ;

	my %hh = $self->headers( $method ) ;
	$hh{'Content-Type'} = shift @_ if @_ > 1 ;
	$hh{'Content-Length'} = length $_[0] if $method eq 'POST' ;

	my @args = grep defined $_, ( [ %hh ], @_ ) ;
	return new HTTP::Request( $method, $url, @args ) ;
	}

sub response {
	my $self = shift ;
	my $r = $self->request( @_ ) ;
	return LWP::UserAgent->new->request( $r ) ;
	}

sub content {
	my $self = shift ;
	my $content = $self->response( @_ )->content ;
	return $content unless $content =~ /^{/s ;
	return JSON::from_json( $content ) ;
	}

sub headers {
	shift @_ if $_[0] eq __PACKAGE__ ;
	shift @_ if ref $_[0] eq __PACKAGE__ ;

	my $method = shift ;

	return (
		'Content-Type' => $content_type{$method},
		) ;
	}


## stupid CGI::Simple fails on mod_perl
## replace with a published distro
package Google::OAuth::CGI ;

sub new {
	my $package = shift ;
	my $source = shift ;
	return bless { source => $source }, $package ;
	}

sub encode {
	shift @_ if $_[0] eq __PACKAGE__ ;
	my $text = shift ;
	$text =~ s|([^_0-9A-Za-z\. ])|sprintf "%%%02X", ord($1)|seg ;
	$text =~ s/ /+/g ;
	return $text ;
	}

sub args {
	my ( $key, $value ) = @_ ;
	$value ||= '' ;
	return join '=', $key, encode( $value ) unless ref $value ;

	if ( ref $value eq 'ARRAY' ) {}
	elsif ( grep ref $value eq $_, qw( HASH SCALAR ) ) {
		return '' ;
		}
	elsif ( $value->isa('ARRAY') ) {}
	else {
		return '' ;
		}

	return join '&', map { join '=', $key, encode( $_ ) } @$value ;
	}

sub query_string {
	my $self = shift ;
	my $source = $self->{source} ;

	return join '&', map { args( $_, $source->{$_} ) } keys %$source ;
	}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Google::OAuth - Maintains a database for Google Access Tokens

=head1 SYNOPSIS

  use Google::OAuth ;

  ## show a list of users 
  print join "\n", @users = Google::OAuth->token_list, '' ;

  ## eg $users[0] = 'perlmonster@gmail.com'
  $token = Google::OAuth->token( $users[0] ) ;

  ## Get Google Calendar data for this user
  $calobject = $token->content( GET => 'https://www.googleapis.com'
		.'/calendar/v3/users/me/calendarList' 
		) ;

  ## Insert a calendar event
  %event = ( ... ) ;  ## See Google documentation
  $url = sprintf 'https://www.googleapis.com'
		.'/calendar/v3/calendars/%s/events', $token->{emailkey} ;
  $token->content( POST => $url, 
		Google::OAuth::CGI->new( \%event )->query_string ) ;


=head1 DESCRIPTION

Google::OAuth provides the capability to utilize the Google App's published 
API.  The link below (to Google's Calendar reference) demonstrates their
API in the form of HTTP REST requests.  This API is consistent with the 
arguments of a Google::OAuth token's methods.

  https://developers.google.com/google-apps/calendar/v3/reference/

Based on the documentation, the integration process looks deceptively easy.  
Google::OAuth takes the same approach by providing a framework that also 
looks deceptively easy.  Notwithstanding, this package includes the tools 
to get you set up and running.


=head1 BACKGROUND

The complete installation will probably take several hours.  If you're
lucky or already have some experience with the Google API, you can save 
time and skip this section.

The Google Apps API provides a mechanism to access the private and personal 
information in Google accounts.  Naturally, there's a significant amount of 
complexity to authorize and authenticate an integration process.  Although 
the Google::OAuth package handles all this complexity, the following describes
the background activity.


=head2 Credentials

The first part of the authorization process requires establishing, and then
presenting, your credentials for authorization.  These credentials start 
out with a personal Google account, followed by a registration process
that describes your integration project.  When registration is complete, 
Google will generate and display several string values that will be used later
in the installation process.  These string values are refered to as I<client 
credentials>.

Create a Google account if necessary, log in, then visit Google's developer
site:

  http://developers.google.com/

At the bottom of the page (as of April 2013) there is a link to the API
Console.  Use the API Console to register an application.  The information
in your registration will be visible to users when they authorize your 
access.  When the registration is complete, Google assigns three credential
values:

=over 8

=item 1.  A I<Client ID>

=item 2.  A I<Client Secret>

=item 3.  One or more I<Redirect URIs>

=back 8

A fourth value, the "Email address" is not used to establish credentials.


=head2 User Authorization

Once you've established credentials, you request that Google users 
authorize your application to access their account information.  Your
request is in the form of a URL link.  For example, during the installation
(described below), you'll email yourself a request link in order to test 
your installation.

Google uses three values as part of the authorization/authentication process:

=over 8

=item 1.  A I<Grant Code>:  The Grant Code is a ticket that can only be used once.

=item 2.  An I<Access Token>:  The Access Token is transmitted in the header of the REST requests.  Access Tokens are only valid for one hour.

=item 3.  A I<Refresh Token>:  The Refresh Token is the permanent ticket, and is the only value that needs to persist from session to session.

=back 8

A Google::OAuth token is a Hash object that maintains several values in 
addition to the I<Access Token> and I<Refresh Token>.  Unless otherwise 
specified, this document always uses the term I<token> to refer to a 
Google::OAuth token.


=head2 NoSQL::PL2SQL

I released L<NoSQL::PL2SQL> as part of an entire solution for advanced web 
applications, particularly those that use a distributed app technology such
as Google Apps.  L<NoSQL::PL2SQL> is particularly well suited for the 
amorphous data objects used in these processes.

Essentially, the only persistent data requirements are a set of NVP pairs that 
associate a Google Account with a I<Refresh Token>- everything else can be
generated at run-time.  However, Authentication is only a small piece
of integration with a service such as Google Apps, and NoSQL::PL2SQL is
appropriate for the larger, more complex data persistence needs.


=head1 INSTALLATION

After building this package using Make or CPAN, additional installation
tasks are required:

=over 8

=item 1.  Define the application credentials

=item 2.  Set up the data persistence component

=back 8

These tasks are divided into five additional steps that must be peformed 
before this package is ready to use:

=over 8

=item 1.  perl -MGoogle::OAuth::Install -e config configfile

=item 2.  perl -MGoogle::OAuth::Install -e settings configfile

=item 3.  perl -MGoogle::OAuth::Install -e grantcode configfile | mail

=item 4.  perl -MGoogle::OAuth::Install -e test configfile

=item 5.  perl -MGoogle::OAuth::Install -e install configfile

=back 8

The additional configuration is performed by editing the configfile created
in Step 1.  During the final installation in Step 5, the configfile will
replace the distributed Google::OAuth::Config module.  Mostly, the configfile 
consists of commented instructions.  The remainder needs to be legal perl
syntax so that the following command succeeds:

  perl -cw configfile

I run Google::OAuth on a secure server that can only be accessed by an
administrator.  This is the appropriate environment for the default 
installation.  Otherwise, in a multi-user environment, see the section 
L<SECURE INSTALLATION>.

Upon installation, the package has at least one persistent token, which 
should be a Google account owned by you, the installer.  During installation, 
the Google Calendar API is used to recover the account ID.  So this token has
already been tested and used.  But it's important to test your entire
integration process using Google's API and the methods described in the
L<SYNOPSIS> section.  It'll be practically impossible to test or troubleshoot
on other users' accounts.


=head1 CREATING TOKENS

Most likely, your API tests will fail.  By default Google's tokens do not 
allow data access without explicitly defining scope. The token created during
installation is only capable of reading your calendar data.  For additional 
access, you'll need to generate a new token.

As described above, this process consists of 3 phases:

=over 8

=item 1. Generate a request

=item 2. Acquire Google's ticket, the I<Grant Code>

=item 3. Use the I<Grant Code> to generate a token

=back 8

=head2 Generate a request

First, there are some non-technical considerations.  You need to make the 
request available to the user; and the user needs to trust you enough to 
approve the request.  The request is not user specific, the same request
can be used by anyone.  Nevertheless, given the personal nature, it's 
probably best to email your request.  Naturally gaining trust is trickier.

Most of this package's methods operate on C<Google::OAuth> tokens.  Since
these requests are more generic, and independent of any token, the token
request method uses a more general superclass, C<Google::OAuth::Client>.

  print Google::OAuth::Client->new->scope(
    		'calendar.readonly' )->token_request ;

The token_request method is detailed below.  There are numerous internal 
definitions described within the method.  Based on my experience, these 
default values are sufficient.  However, the default values can be 
overridden using arguments passed to the constructor.

On the other hand, the list elements passed as arguments to the C<scope()> 
method must be explicit.  Each element must be a value from the list below.
This list hasn't been verified for completeness, and more options may be added 
in the next revision:

=over 8

=item I<m8.feeds>

=item I<calendar>

=item I<calendar.readonly>

=item I<drive.readonly>

=item I<drive>

=back 8

The C<token_request()> method output is a legal, functional URL.  The 
caller is responsible for wrapping the HTML.

=head2 Acquire the Grant Code

Google transmits the I<Grant Code> via HTTP using the redirect_uri defined in
the client credentials.  Google provides the option to define multiple
redirects, but Google::OAuth's installation process requires only one.  

There are two approaches to using an alternative I<redirect_uri> definition.  
In either case the definition must match one of the values in Google's API
registration.  First, the I<redirect_uri> element in the client credentials
can be redefined, as with any element, using the C<setclient()> method as
follows:

  my @redirect = ( ... ) ;
  Google::OAuth->setclient( redirect_uri => $redirect[1] ) ;

Second, in each specific instance, any component to the token request url can 
be modified by overriding C<token_request>'s defaults.  The resulting code is
fairly elaborate (and not illustrated here) because I<all> of the internal
values must be defined in the Google::OAuth::Client constructor when
overriding any default.

After approval, Google returns the I<Grant Code> as a query argument to 
the redirect_uri.  Any output generated by the redirect_uri is displayed to
the user. 

=head2 Generate a token

The best way to generate a token is to load the following code into a 
CGI script or a similar technique that allows the HTTP server to initiate
this sequence (such as tailing the server log).

    use Google::OAuth ;
    ## SECURE INSTALLATION overrides are loaded here

    $token = Google::OAuth->grant_code( $query{code} ) ;

    ## Preferred method
    %token = %{ Google::OAuth->grant_code( $query{code} ) } ;

The C<grant_code()> method performs the following tasks:

=over 8

=item 1. Acquires the token from Google

=item 2. Uses the token to request the account ID via the Google Calendar API

=item 3. Saves the token as a persistent object keyed on the account ID

=back 8

The C<grant_code()> method is pretty unreliable, primarily because Google is
so restrictive about issuing a token.  Confirm a successful operation by
examining the method's result, which should contain an I<emailkey> value. 
When Google is being overly fussy, the result will look like:

  ## The 'requested' value is not part of Google's response
  $token = {
          'requested' => 1366389672,
          'error' => 'Invalid Grant'
        };

Another problem may occur if the token has insufficient privileges to 
access calendar data:

  $token = bless( {
                 'refresh_token' => '1/1v3Tvzj31e5M',
                 'expires_in' => '3600',
                 'requested' => 1366390047,
                 'access_token' => 'ya29.AHES6ZS',
                 'token_type' => 'Bearer'
               }, 'Google::OAuth' );

In this case, Google issued a valid token, but C<grant_code()> was not able to
use the token to access the account ID.

The value returned by C<grant_code()> is volatile, which means it must be 
explicitly destroyed.  If the response is only used to confirm success (or
to log operations) it is safer to use the preferred method shown in the 
example.


=head1 USING A TOKEN

The code example under the L<SYNOPSIS> section illustrates how to use a
token to access data from Google.  The most important caveat is that 
Google tokens expire after an hour. In applications where a session may last
longer than a typical HTTP request, it's probably better to rewrite that
example as follows:

  use Google::OAuth;

  ## show a list of users 
  print join "\n", @users = Google::OAuth->token_list, '' ;

  ## eg $users[0] = 'perlmonster@gmail.com'
  $token = Google::OAuth->token( $users[0] ) ;

  ## Intervening operations of an hour or longer

  $token = $token->token if $token->expired ;

  ## Get Google Calendar data for this users
  $calobject = $token->content( GET => 'https://www.googleapis.com'
		.'/calendar/v3/users/me/calendarList' ) ;

Persistent objects in L<NoSQL::PL2SQL> can be either volatile or non-volatile.
Volatile objects cache write operations until the object is destroyed, and 
therefore must be explicitly destroyed.  As mentioned above, the 
C<grant_code()> method returns a volatile object.  As a convenience, the
C<token()> method returns non-volatile objects.  This adds a small
inefficency of a database write on every subsequent C<token()> method call.
Given how infrequently that method must be called, this is not a significant
concern.  Here is the volatile object approach nonetheless:

  use Google::OAuth;

  ## show a list of users 
  print join "\n", @users = Google::OAuth->token_list, '' ;

  ## eg $users[0] = 'perlmonster@gmail.com'
  $token = Google::OAuth->SQLObject( $users[0] )->token ;

  ## Intervening operations of an hour or longer

  $token->token if $token->expired ;

  ## Get Google Calendar data for this users
  $calobject = $token->content( GET => 'https://www.googleapis.com'.
		'/calendar/v3/users/me/calendarList' ) ;

  ## Somewhere before exiting
  undef $token ;


=head1 METHOD SUMMARY

=head2 Google::OAuth

C<Google::OAuth> subclasses the following:

=over 8

=item C<NoSQL::PL2SQL>

=item C<Google::OAuth::Client>

=item C<Google::OAuth::Request>

=back 8

=head3 SQLClone()

C<< Google::OAuth->SQLClone() >> overrides C<< NoSQL::PL2SQL->SQLClone >> 
and takes only an account ID as an argument.

=head3 SQLObject()

C<< Google::OAuth->SQLObject() >> overrides C<< NoSQL::PL2SQL->SQLObject >> 
and takes only an account ID as an argument.

=head3 grant_code()

C<< Google::OAuth->grant_code() >> creates a token using a I<Grant Code> 
issued by Google.

=head3 token_list()

C<< Google::OAuth->token_list() >> returns a list of account ID's whose 
tokens are saved in the DSN.

=head3 token()

C<< Google::OAuth->token() >> returns a token as a non-volatile object using
an account ID argument.

C<< $token->token() >> refreshes the I<Access Token> member and returns the 
result.  If the object is non-volatile, the new token is returned by this 
method.  If the object is volatile, the member is replaced with a refreshed 
value.

=head3 headers()

C<< $token->headers() >> overrides C<< Google::OAuth::Request->headers() >>
to add the I<Access Token> to the HTTP::Request headers.

=head3 emailkey()

C<< $token->emailkey() >> queries the Google Calendar account data and 
returns the account ID.

=head3 classID()

C<< Google::OAuth->classID >> returns a constant integer that must be 
overridden by subclasses.  This constant satisfies the key requirements
of L<NoSQL::PL2SQL> objects: a string and integer.  The string
component contains an email address, so the class must be represented 
by an integer constant.  Consequently, multiple tokens may be keyed by 
the same email address if they are accessed using subclasses with different
I<classID> values.

=head3 grant_type()

C<< Google::OAuth->grant_type >> returns a string constant to satisfy two 
different API's:

=over 8

=item google => refresh_token

=item facebook => fb_exchange_token

=back 8

=head2 Google::OAuth::Client

Methods that need to access the client credentials are defined under
the C<Google::OAuth::Client> module.  In the context of this package,
the methods are independent of token object data.

=head3 setclient()

C<< Google::OAuth->setclient() >> is called automatically.  It must be 
explicitly called again to manually set the client_secret in secure 
installations:

  Google::OAuth->setclient( client_secret => 'xAtN' ) ;

=head3 dsn()

C<< Google::OAuth->dsn() >> can be used to access the DSN.  In secure
installations, use this method to connect the data source.  Other access 
methods are described in L<NoSQL::PL2SQL::DBI>.

=head3 new()

C<< Google::OAuth::Client->new() >> accepts the same arguments as 
C<queryargs()>.  These arguments are used to override any predefined defaults.

=head3 scope()

C<< $client->scope() >> is used in conjunction with the C<token_request()>
method.  C<scope()> returns its calling object, and can be invoked inline.

=head3 queryargs()

C<< Google::OAuth::Client->queryargs() >> returns its arguments as an NVP
list, according to the following rules:  Scalar arguments are assumed 
to key reference one of the client credential elements.  The name and 
value of that element are returned.  An NVP pair is passed straight-through 
if it is encapsulated inside a hash reference:

  Google::OAuth->setclient( foo => 'bar' ) ;
  my %out = Google::OAuth->queryargs( 'foo', { hello => 'world' } ) ;
  print join( '-', %out ), "\n" ;	## prints the following:
  # foo-bar-hello-world

=head3 token_request()

C<< $client->token_request >> generates a URL used for a token request.  This 
URL consists of the following definitions:

=over 8

=item 1. Overrides passed as arguments to the Google::OAuth::Client constructor.

=item 2. Default values defined within the C<token_request()> method.

=item 3. Scope definitions defined by the C<scope()> method.

=item 4. Client credentials defined in C<Google::OAuth::Config>.

=item 5. Client credentials defined by C<< Google::OAuth->setclient() >>.

=back 8

=head3 get_token()

C<get_token()> retrieves a token from Google using a HTTP::Request based on
the following definitions:

C<< $client->get_token() >> If this method is invoked with an object, 
definitions are passed to the object's constructor and override any internal
defaults.

C<< Google::OAuth->get_token() >> Otherwise, definitions are passed as 
arguments like C<queryargs()>'s.  Some of these definitions are defined 
internally as defaults.

After C<get_token()> retrieves a token, it adds the I<requested> element to 
record a timestamp and blesses the returned object.

=head3 expired()

I<Access Tokens> are valid for only a short period of time.  
C<< $token->expired() >> estimates the expiration time based on the
I<requested> and I<expires_in> token properties.

=head2 Google::OAuth::Request

C<Google::OAuth::Request> contains methods that generate or use an 
C<HTTP::Request> object built with specific header rules.  Subclasses, such
as C<Google::OAuth> are expected to define their own C<header()> methods.

=head3 request()

C<< $token->request >> creates an L<HTTP::Request> object whose headers are 
constructed, in part, using token data.

C<< Google::OAuth::Request->request >> creates an L<HTTP::Request> object 
whose default headers are compatible with Google.

C<request()> takes one, two, three or four arguments:  A string representing
an HTTP method (GET, POST, etc.), a URL, and an optional string representing
POST data.  To override the default "Content-Type", the third argument should 
reflect this header value.

  $r = Google::OAuth::Request->request( $url ) ;	## Default: GET
  $r = Google::OAuth::Request->request( GET => $url ) ;
  $r = Google::OAuth::Request->request( POST => $url, $content ) ;
  $r = Google::OAuth::Request->request( POST => $url, $type, $content ) ;
  $r = Google::OAuth::Request->request( GET => $url, $type, undef ) ;

This internal method is available for debugging.

=head3 response()

C<< $token->response >> and C<< Google::OAuth::Request->response >> 
are nearly identical to the C<request()> method except that this method 
returns an L<HTTP::Response> object.  This internal method is available 
for debugging.

=head3 content()

C<< $token->content >> and C<< Google::OAuth::Request->content >> 
also behaves like C<request()> and accepts the same arguments.  It's
named after C<< HTTP::Response->content >> and returns the body of the
HTTP response.

If the response body is a JSON definition, C<content()> returns a
perl object based on that definition.  Otherwise it returns a scalar
representation of the HTTP response.

	## Don't use this statement in production.  Why not?
	print "invalid JSON\n" if $token->content( @args ) 
			eq $token->response( @args )->content ;

	## prints raw JSON data
	print $token->response( @args )->content ;

A scalar value returned by this method indicates an error and may be 
helpful for debugging.

=head3 headers()

The C<headers()> method returns default headers compatible with Google.


=head2 Google::OAuth::Headers

C<Google::OAuth::Headers> is a trivial subclass for C<Google::OAuth::Request>.
Originally intended for testing, this class is currently unused but may be 
useful for modifying request headers.  

  $o = Google::OAuth::Headers->new( $token 
		)->add( %headernvps 
		)->content( GET => $url ) ;

=head3 new()

The object uses a token and includes authentication in the resulting headers.  
Pass the token as an argument to this constructor.

=head3 add()

Pass any custom headers to the C<add()> method.  C<add()> returns its calling
object for inline use.

=head3 headers()

The overridden C<headers()> method returns the same header values as 
C<Google::OAuth::headers()> in addition to those specified by C<add()>.


=head2 Google::OAuth::Install

C<Google::OAuth::Install> is intended only for command line use, see the
L<INSTALLATION> section.  The following functions are defined and exported:

=over 8

=item  config()

=item  settings()

=item  grantcode()

=item  test()

=item  install()

=back 8


=head2 Google::OAuth::Config

C<Google::OAuth::Config> is generated during the installation process, and
contains the definitions of the client credentials and DSN.

C<Google::OAuth::Config::setclient()> is its only defined method.


=head1 SECURE INSTALLATION

Since the client credentials are built into the installation, some
tweaking is required to use Google::OAuth in a shared environment.

The easiest would be a simple launch script as follows:

  use Google::OAuth ;

  $dsn = define_a_dsn() ;

  Google::OAuth->setclient( 
		client_id => '...',
		client_secret => '...',
		redirect_uri => '...',
		dsn => $dsn,
		) ;

In an shared space like mod_perl, a user might inherit an environment where
this configuration has already been defined by another user.  In this case, 
the adventurous can subclass Google::OAuth and override the 
Google::OAuth::Client methods.  mod_perl has a variety of configuration 
strategies that could be applied, but not an obvious universal solution.
For the time being, the foremost concern of this initial release is simplicity.

A more urgent concern is restricting access to Google::OAuth data in a 
multi-user environment.  There are basically two concerns:

=over 8

=item 1. Access to the client credentials

=item 2. Access to user tokens in the DSN

=back 8

The solution is to simply leave those definitions incomplete in the 
configuration file.  Define the DSN in the config file, but leave the DSN 
unconnected until run-time.  Then, during run-time, load the missing 
configuration definitions and connect the data source as follows:

  use Google::OAuth ;

  Google::OAuth->setclient( client_secret => 'xAtN' ) ;
  Google::OAuth->dsn->connect( 'DBI:mysql:'.$dbname, @login ) ;

However, these definitions are required to complete the installation.  If 
you know your way around your perl installation, leave the installation 
definitions intact and then simply edit the Config.pm file in place.  

Otherwise, this modified installation procedure uses a local configuration
file to hide any secrets.  This file should be named I<local.pm> and 
written in the current working directory.  A template is included in this 
distribution.  The file contents look like:

  package local ;
  use Google::Auth ;

  sub Google::OAuth::setclient {
	my %client = Google::OAuth::Config->setclient ;
	$client{client_secret} = 'xAtN' ;
	$client{dsn}->connect( 'DBI:mysql:'.$dbname, @login ) ;
	Google::OAuth::Client->setclient( %client ) ;
	}

  1
  
Now, perform the installation using these slightly modified steps:

=over 8

=item 1.  perl -MGoogle::OAuth::Install -Mlocal -e config configfile

=item 2.  perl -MGoogle::OAuth::Install -Mlocal -e settings configfile

=item 3.  perl -MGoogle::OAuth::Install -Mlocal -e grantcode configfile | mail

=item 4.  perl -MGoogle::OAuth::Install -Mlocal -e test configfile

=item 5.  perl -MGoogle::OAuth::Install -Mlocal -e install configfile

=back 8

Upon completion, delete the local.pm file.  Or if secure, use it for future
reference.


=head1 EXPORT

none

=head1 SEE ALSO

=over 8

=item  http://developers.google.com/

=item  http://www.tqis.com/eloquency/googlecalendar.htm

=back 8

There is a page on my developer site to discuss Google::OAuth

=over 8

=item  http://pl2sql.tqis.com/pl2sql/GoogleOAuth/

=back 8

This web page includes a forum.  But until I am confident enough to
release this distro for production, please contact me directly, at the
email address below, with questions, problems, or suggestions.

=head1 AUTHOR

Jim Schueler, E<lt>jim@tqis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jim Schueler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

