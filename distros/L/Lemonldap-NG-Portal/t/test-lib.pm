# Base library for portal tests
package main;

=pod

=encoding utf8

=head1 NAME

test-lib.pm - Test framework for LLNG portal

=head1 SYNOPSIS

  use Test::More;
  use strict;
  use IO::String;
  
  require 't/test-lib.pm';
  
  my $res;
  
  my $client = LLNG::Manager::Test->new( {
      ini => {
          logLevel => 'error',
          #...
      }
    }
  );
  
  ok(
      $res = $client->_post(
          '/',
          IO::String->new('user=dwho&password=dwho'),
          length => 23
      ),
      'Auth query'
  );
  count(1);
  expectOK($res);
  my $id = expectCookie($res);
  
  clean_sessions();
  done_testing( count() );

=head1 DESCRIPTION

This test library permits one to simulate browser navigation.

=head2 Functions

In these functions, C<$res> is the result of a C<LLNG::Manager::Test::_get()> or
C<LLNG::Manager::Test::_post()> call I<(see below)>.

=cut

use strict;
use Data::Dumper;
use File::Find;
use JSON;
use XML::LibXML;
use LWP::UserAgent;
use Time::Fake;
use URI::Escape;
use MIME::Base64;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Common::Util qw/getPSessionID/;

#use 5.10.0;

no warnings 'redefine';

BEGIN {
    use_ok('Lemonldap::NG::Portal::Main');
}

our $count = 1;
$Data::Dumper::Deparse  = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Useperl  = 1;
my $ini;

use File::Temp 'tempfile', 'tempdir';
use File::Copy 'copy';
our $tmpDir = $LLNG::TMPDIR
  || tempdir( 'tmpSessionXXXXX', DIR => 't/sessions', CLEANUP => 1 );
mkdir "$tmpDir/lock";
mkdir "$tmpDir/saml";
mkdir "$tmpDir/saml/lock";
copy( "t/lmConf-1.json", "$tmpDir/lmConf-1.json" );

=head4 count($inc)

Returns number of tests done. Increment test number if an argument is given

=cut

sub count {
    my $c = shift;
    $count += $c if ($c);
    return $count;
}

=head4 buildForm($params)

Convenience method that builds a url-encoded query string from a hash of arguments

=cut

sub buildForm {
    my $fields = shift;
    my $query  = join(
        '&',
        map {
            "$_="
              . (
                $fields->{$_}
                ? uri_escape( uri_unescape( $fields->{$_} ) )
                : ''
              )
          }
          keys(%$fields)
    );
    return $query;
}

=head4 explain( $result, $expected_result )

Used to display error if test fails:

  ok( $res->[0] == 302, 'Get redirection' ) or
    explain( $res->[0], 302 );

=cut

sub main::explain {
    my ( $get, $ref ) = @_;
    $get = Dumper($get) if ( ref $get );
    diag("Expect $ref, get $get\n");
}

=head4 clean_sessions()

Clean sessions created during tests

=cut

sub clean_sessions {
    find( sub { unlink if -f }, $tmpDir );
    foreach my $dir (qw(t/sessions/lock t/sessions/saml/lock t/sessions/saml)) {
        if ( -d $dir ) {
            opendir D, $dir or die $!;
            foreach ( grep { /^[^\.]/ } readdir(D) ) {
                unlink "$dir/$_";
            }
        }
    }
}

sub count_sessions {
    my ( $kind, $dir ) = @_;
    my $nbr = 0;
    $kind ||= 'SSO';
    $dir  ||= $tmpDir;

    opendir D, $dir or die $!;
    foreach ( grep { /^\w{64}$/ } readdir(D) ) {
        open( my $fh, '<', "$dir/$_" ) or die($!);
        while (<$fh>) {
            chomp;
            if ( $_ =~ /"_session_kind":"$kind"/ ) {
                $nbr++;
                last;
            }
        }
        close $fh;
    }
    $nbr;
}

sub getCache {
    require Cache::FileCache;
    return Cache::FileCache->new( {
            namespace   => 'lemonldap-ng-session',
            cache_root  => $tmpDir,
            cache_depth => 0,
        }
    );
}

sub getSession {
    my $id           = shift;
    my @sessionsOpts = (
        storageModule        => "Apache::Session::File",
        storageModuleOptions => {
            Directory     => "$tmpDir",
            LockDirectory => "$tmpDir/lock",
        },
        kind => 'SSO'
    );

    return Lemonldap::NG::Common::Session->new( {
            @sessionsOpts, id => $id,
        }
    );
}

sub getPSession {
    my $uid          = shift;
    my @sessionsOpts = (
        storageModule        => "Apache::Session::File",
        storageModuleOptions => {
            Directory     => "$tmpDir",
            LockDirectory => "$tmpDir/lock",
        },
        kind => 'Persistent'
    );

    return Lemonldap::NG::Common::Session->new( {
            @sessionsOpts, id => getPSessionID($uid),
        }
    );
}

sub getSamlSession {
    my $id           = shift;
    my @sessionsOpts = (
        storageModule        => "Apache::Session::File",
        storageModuleOptions => {
            Directory     => "$tmpDir/saml",
            LockDirectory => "$tmpDir/saml/lock",
        },
    );

    return Lemonldap::NG::Common::Session->new( {
            @sessionsOpts, id => $id,
        }
    );
}

=head4 expectRedirection( $res, $location )

Verify that request result is a redirection to $location. $location can be:

=over

=item a string: location must match exactly

=item a regexp: location must match this regexp. In this case, the list of
matching strings are returned. Example:

  my( $uri, $query ) = expectRedirection( $res, qr#http://host(/[^\?]*)?(.*)$# );

=back

=cut

sub expectRedirection {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $location ) = @_;
    ok( $res->[0] == 302, ' Get redirection' )
      or explain( $res->[0], 302 );
    count(1);
    if ( ref $location ) {
        my @match;
        @match = ( getRedirection($res) =~ $location );
        ok( @match, ' Location header found' )
          or explain( $res->[1], "Location match: " . Dumper($location) );
        count(1);
        return @match;
    }
    else {
        ok( getRedirection($res) eq $location, " Location is $location" )
          or explain( $res->[1], "Location => $location" );
        count(1);
    }
}

=head4 expectAutoPost(@args)

Same behaviour as C<expectForm()> but verify also that form method is post.

TODO: verify javascript

=cut

sub expectAutoPost {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @r      = expectForm(@_);
    my $method = pop @r;
    ok( $method =~ /^post$/i, ' Method is POST' ) or explain( $method, 'POST' );
    count(1);
    return @r;
}

=head4 expectForm( $res, $hostRe, $uriRe, @requiredFields )

Verify form in HTML result and return ( $host, $uri, $query, $method ):

=over

=item verify that a GET/POST form exists

=item if a $hostRe regexp is given, verify that form target matches and
populates $host. Skipped if $hostRe eq "#"

=item if a $uriRe regexp is given, verify that form target matches and
populates $uri

=item if @requiredFields exists, verify that each element is an input name

=item build form-url-encoded string looking at parameters/values and store it
in $query

=back

=cut

sub expectForm {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $hostRe, $uriRe, @requiredFields ) = @_;
    expectOK($res);
    count(1);
    if (
        ok(
            $res->[2]->[0] =~
m@<form.+?action="(?:(?:https?://([^/]+))?(/.*?)?|(#))".+method="(post|get)"@is,
            ' Page contains a form'
        )
      )
    {
        my ( $host, $uri, $hash, $method ) = ( $1, $2, $3, $4 );
        if ( $hash and $hash eq '#' ) {
            $host = '#';
            $uri  = '';
        }
        if ($hostRe) {
            if ( ref $hostRe ) {
                ok( $host =~ $hostRe, ' Host match' )
                  or explain( $host, $hostRe );
            }
            else {
                ok( $host eq $hostRe, ' Host match' )
                  or explain( $host, $hostRe );
            }
            count(1);
        }
        if ($uriRe) {
            if ( ref $uriRe ) {
                ok( $uri =~ $uriRe, ' URI match' ) or explain( $uri, $uriRe );
            }
            else {
                ok( $uri eq $uriRe, ' URI match' ) or explain( $uri, $uriRe );
            }
            count(1);
        }

        # Fields with values
        my %fields =
          ( $res->[2]->[0] =~
              m#<input.+?name="([^"]+)"[^>]+(?:value="([^"]*?)")#gs );

        # Add fields without values
        %fields = (
            $res->[2]->[0] =~
              m#<input.+?name="([^"]+)"[^>]+(?:value="([^"]*?)")?#gs,
            %fields
        );

        # Add textarea
        %fields = (
            $res->[2]->[0] =~
              m#<textarea.+?name="([^"]+)"[^>]+(?:value="([^"]*?)")?#gs,
            %fields
        );
        my $query = buildForm( \%fields );
        foreach my $f (@requiredFields) {
            ok( exists $fields{$f}, qq{ Field "$f" is defined} );
            count(1);
        }
        exceptCspFormOK( $res, $host );
        return ( $host, $uri, $query, $method );
    }
    else {
        return ();
    }
}

=head4 expectAuthenticatedAs($user)

Verify that result has a C<Lm-Remote-User> header and value is $user

=cut

sub expectAuthenticatedAs {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $user ) = @_;
    is( getHeader( $res, 'Lm-Remote-User' ), $user, "Authenticated as $user" );
    count(1);
}

=head4 expectSessionAttributes($app,$id,%attributes)

Verify that the session contains attributes with these values

=cut

sub expectSessionAttributes {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $app, $id, %attributes ) = @_;

    my $res = getSessionAttributes( $app, $id );

    for my $attr ( keys %attributes ) {
        is( $res->{$attr}, $attributes{$attr},
            "Session has correct value for $attr" );
        count(1);
    }
}

sub getSessionAttributes {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $app, $id ) = @_;
    my $res;
    ok(
        $res = $app->_get("/sessions/global/$id"),
        "Get session using restSessionServer"
    );
    count(1);
    expectOK($res);
    ok( $res = eval { from_json( $res->[2]->[0] ) },
        "Deserialize session content" );
    count(1);

    return $res;
}

=head4 expectOK($res)

Verify that returned code is 200

=cut

sub expectOK {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res) = @_;
    ok( $res->[0] == 200, ' HTTP code is 200' ) or explain( $res, 200 );
    count(1);
}

=head4 expectJSON($res)

Verify that the HTTP response contains valid JSON and returns the corresponding object

=cut

sub expectJSON {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res) = @_;
    is( $res->[0], 200, ' HTTP code is 200' ) or explain( $res, 200 );
    my %hdr = @{ $res->[1] };
    like( $hdr{'Content-Type'}, qr,^application/json,i,
        ' Content-Type is JSON' )
      or explain($res);
    my $json;
    eval { $json = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is valid JSON' );
    count(3);
    return $json;
}

=head4 expectForbidden($res)

Verify that returned code is 403.

=cut

sub expectForbidden {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res) = @_;
    ok( $res->[0] == 403, ' HTTP code is 403' ) or explain( $res->[0], 403 );
    count(1);
}

=head4 expectBadRequest($res)

Verify that returned code is 400. Note that it works only for Ajax request
(see below).

=cut

sub expectBadRequest {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res) = @_;
    ok( $res->[0] == 400, ' HTTP code is 400' ) or explain( $res->[0], 400 );
    count(1);
}

=head4 expectPortalError( $res, $errnum )

Verify that an error is displayed on the portal
=cut

sub expectPortalError {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $errnum, $message ) = @_;
    $errnum  ||= 9;
    $message ||= "Expected portal error code";
    my ($error) = $res->[2]->[0] =~ qr/<span trmsg="(\d+)">/;
    ok( $error, "$message: code found on page" ) or explain $res->[2]->[0];
    is( $error, $errnum, $message );
    count(2);
}

=head4 expectReject( $res, $status, $code )

Verify that returned code is 401 (or $status)  and JSON result contains
C<error:"$code">.  Note that it works only for Ajax request (see below).

=cut

sub expectReject {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $status, $code ) = @_;
    $status ||= 401;
    cmp_ok( $res->[0], '==', $status, " Response status is $status" );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), ' Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    if ( defined $code ) {
        is( $res->{error}, $code, " Error code is $code" );
    }
    else {
        pass("Error code is $res->{error}");
    }
    count(3);
}

=head4 expectCookie( $res, $cookieName )

Check if a C<Set-Cookie> exists and set a cookie named $cookieName. Return
its value.

=cut

sub expectCookie {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $cookieName ) = @_;
    $cookieName ||= 'lemonldap';
    my $cookies = getCookies($res);
    my $id;
    ok(
        defined( $id = $cookies->{$cookieName} ),
        " Get cookie $cookieName ($id)"
    ) or explain( $res->[1], "Set-Cookie: $cookieName=something" );
    count(1);
    return $id;
}

=head4 expectPdata( $res );

Check if the pdata cookie exists and returns its deserialized value.

=cut

sub expectPdata {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res) = @_;
    my $val = expectCookie( $res, "lemonldappdata" );
    ok( $val, "Pdata is not empty" );
    count(1);
    my $pdata;
    eval { $pdata = JSON::from_json( uri_unescape($val) ); };
    diag($@) if $@;
    return $pdata;
}

=head4 exceptCspFormOK( $res, $host )

Verify that C<Content-Security-Policy> header allows one to connect to $host.

=cut

sub exceptCspFormOK {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $host ) = @_;
    return 1 unless ($host);
    my $csp = getHeader( $res, 'Content-Security-Policy' );
    return 1 unless ($csp);
    unless ( $csp =~ s/^.*form-action (.*?)(?:;.*)?$/$1/ ) {
        $csp =~ s/^.*default-src (.*?)(?:;.*)?$/$1/;
    }
    if (   $csp =~ /\s\*(?:\s.*)?\s*$/
        or ( $host eq '#' and $csp =~ /'self'/ )
        or $csp =~ m#\bhttps?://$host\b#
        or $csp =~ m#\*# )
    {
        pass(" CSP header authorize POST request to $host");
    }
    else {
        fail(" CSP header authorize POST request to $host");
        explain( $res->[1], "form-action ... $host" );
    }
    count(1);
}

sub expectCspChildOK {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $host ) = @_;
    return 1 unless ($host);
    my $csp = getHeader( $res, 'Content-Security-Policy' );
    ok( $csp, "Content-Security-Policy header found" );
    count(1);
    like( $csp, qr/child-src[^;]*\Q$host\E/, "Found $host in CSP child-src" );
    count(1);
}

sub getHtmlElement {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $res, $xpath ) = @_;

    ok( $res->[2]->[0], "Response body is not empty" );
    count(1);

    # Use recover to ignore parsing errors
    my $doc =
      XML::LibXML->new->load_html( string => $res->[2]->[0], recover => 2 );

    return $doc->findnodes($xpath);
}

=head4 getCookies($res)

Returns an hash ref with names => values of cookies set by server.

=cut

sub getCookies {
    my ($resp) = @_;
    my @hdrs   = @{ $resp->[1] };
    my $res    = {};
    while ( my $name = shift @hdrs ) {
        my $v = shift @hdrs;
        if ( $name eq 'Set-Cookie' ) {
            if ( $v =~ /^(\w+)=([^;]*)/ ) {
                $res->{$1} = $2;
            }
        }
    }
    return $res;
}

=head4 getHeader( $res, $hname )

Returns value of first header named $hname in $res response.

=cut

sub getHeader {
    my ( $resp, $hname ) = @_;
    my @hdrs = @{ $resp->[1] };
    my $res  = {};
    while ( my $name = shift @hdrs ) {
        my $v = shift @hdrs;
        if ( $name eq $hname ) {
            return $v;
        }
    }
    return undef;
}

=head4 getRedirection($res)

Returns value of C<Location> header.

=cut

sub getRedirection {
    my ($resp) = @_;
    return getHeader( $resp, 'Location' );
}

=head4 getUser($res)

Returns value of C<Lm-Remote-User> header.

=cut

sub getUser {
    my ($resp) = @_;
    return getHeader( $resp, 'Lm-Remote-User' );
}

=head4 tempdb

Return a temporary file named XXXX.db

=cut

sub tempdb {
    return "$tmpDir/userdb.db";
}

my %handlerOR;

=head4 register

Registers a new LLNG instance

=cut

sub register {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $type, $constructor ) = @_;
    my $obj;
    @Lemonldap::NG::Handler::Main::_onReload = ();
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    ok( $obj = $constructor->(), 'Register $type' );
    count(1);
    $handlerOR{$type} = \@Lemonldap::NG::Handler::Main::_onReload;
    return $obj;
}

=head4 register

Switch to a registered instance

=cut

sub switch {
    my $type = shift;
    return [] unless $handlerOR{$type};
    note( '==> Switching to ' . uc($type) . ' <==' );
    @Lemonldap::NG::Handler::Main::_onReload = @{
        $handlerOR{$type};
    };
}

=head4 encodeUrl( $url );

Encode URL like the handler would, see ::Handler::Main

=cut

sub encodeUrl {
    my ($url) = @_;
    return encode_base64( $url, '' );
}

=head2 LLNG::Manager::Test Class

=cut

package LLNG::Manager::Test;

use strict;
use Mouse;
use IO::String;

extends 'Lemonldap::NG::Common::PSGI::Cli::Lib';

# try to find template dir in @INC
my $templateDir = "site/templates";
unless ( -d $templateDir ) {
    for (@INC) {
        if ( -d "$_/site/templates" ) {
            $templateDir = "$_/site/templates";
            last;
        }
    }
    unless ( -d $templateDir ) {
        die "Could not find template dir";
    }
}

our $defaultIni = {
    configStorage => {
        type    => 'File',
        dirName => "$tmpDir",
    },
    localSessionStorage        => 'Cache::FileCache',
    localSessionStorageOptions => {
        namespace   => 'lemonldap-ng-session',
        cache_root  => $tmpDir,
        cache_depth => 0,
    },
    logLevel              => 'error',
    cookieName            => 'lemonldap',
    domain                => 'example.com',
    templateDir           => $templateDir,
    staticPrefix          => '/static',
    tokenUseGlobalStorage => 0,
    securedCookie         => 0,

    # If lasso is too old, force algo to SHA1
    (
        eval
'use Lasso; Lasso::check_version( 2, 5, 1, Lasso::Constants::CHECK_VERSION_NUMERIC) ? 0:1'
        ? ( samlServiceSignatureMethod => "RSA_SHA1" )
        : ()
    ),
    https                => 0,
    globalStorageOptions => {
        Directory      => $tmpDir,
        LockDirectory  => "$tmpDir/lock",
        generateModule =>
          'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
    },
    casStorageOptions => {
        Directory      => "$tmpDir/saml",
        LockDirectory  => "$tmpDir/saml/lock",
        generateModule =>
          'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
    },
    samlStorageOptions => {
        Directory      => "$tmpDir/saml",
        LockDirectory  => "$tmpDir/saml/lock",
        generateModule =>
          'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
    },
    oidcStorageOptions => {
        Directory      => "$tmpDir/saml",
        LockDirectory  => "$tmpDir/saml/lock",
        generateModule =>
          'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
    },
};

=head3 Accessors

=over

=item app: built application

=cut

has app => (
    is  => 'rw',
    isa => 'CodeRef',
);

=item class: class to test (default Lemonldap::NG::Portal::Main)

=cut

has class => ( is => 'ro', default => 'Lemonldap::NG::Portal::Main' );

=item p: portal object

=cut

has p => ( is => 'rw' );

=item ini: initialization parameters ($defaultIni values + given parameters)

=cut

has accept => ( is => 'rw', default => 'application/json, text/plain, */*' );
has confFailure => ( is => 'rw' );

has ini => (
    is      => 'rw',
    lazy    => 1,
    default => sub { $defaultIni; },
    trigger => sub {
        my ( $self, $ini ) = @_;
        foreach my $k ( keys %$defaultIni ) {
            $ini->{$k} //= $defaultIni->{$k};
        }
        if ( $ENV{DEBUG} ) {
            $ini->{logLevel} = 'debug';
        }
        if ( $ENV{LLNGLOGLEVEL} ) {
            $ini->{logLevel} = $ENV{LLNGLOGLEVEL};
        }
        $self->{ini} = $ini;
        main::ok( $self->{p} = $self->class->new(), 'Portal object' );
        main::count(1);
        unless ( $self->confFailure ) {
            main::ok( $self->{p}->init($ini),           'Init' );
            main::ok( $self->{app} = $self->{p}->run(), 'Portal app' );
            main::count(2);
            no warnings 'redefine';
            eval
'sub Lemonldap::NG::Common::Logger::Std::error {return $_[0]->warn($_[1])}';
            $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{french} = {
                uid  => 'french',
                cn   => 'Frédéric Accents',
                mail => 'fa@badwolf.org',
                guy  => '',
                type => '',
            };
            $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{russian} = {
                uid  => 'russian',
                cn   => 'Русский',
                mail => 'ru@badwolf.org',
                guy  => '',
                type => '',
            };
            $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{davros} = {
                uid  => 'davros',
                cn   => 'Bad Guy',
                mail => 'davros@badguy.org',
                guy  => 'bad',
                type => 'character',
            };
            $Lemonldap::NG::Portal::UserDB::Demo::demoAccounts{dalek} = {
                uid  => 'dalek',
                cn   => 'The Daleks',
                mail => 'dalek@badguy.org',
                guy  => 'bad',
                type => 'mutant',
            };
            push
              @{ $Lemonldap::NG::Portal::UserDB::Demo::demoGroups{earthlings} },
              "french", "russian";
            push @{ $Lemonldap::NG::Portal::UserDB::Demo::demoGroups{users} },
              "french", "russian", "davros";
        }
        $self;
    }
);

=back

=head3 Methods

=head4 login($client, $uid, $getParams)
Do a simple login using the Demo backend
=cut

sub login {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $uid, $getParams ) = @_;
    my $res;
    $getParams ||= {};

    my $query = main::buildForm( {
            user     => $uid,
            password => $uid,
            %$getParams,
        }
    );
    main::ok(
        $res = $self->_post(
            '/',
            IO::String->new($query),
            length => length($query),
        ),
        'Auth query'
    );
    main::count(1);
    main::expectOK($res);
    my $id = main::expectCookie($res);
    return $id;
}

=head4 logout($id)

Launch a C</?logout=1> request an test:

=over

=item if response is 200

=item if cookie $cookieName and "${cookieName}pdata" have no value

=item if a GET request with previous cookie value I<($i)> is rejected

=back

=cut

sub logout {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $id, $cookieName ) = @_;
    my $res;
    $cookieName ||= 'lemonldap';

    main::ok(
        $res = $self->_get(
            '/',
            query  => 'logout',
            cookie => "$cookieName=$id",
            accept => 'text/html'
        ),
        'Logout request'
    );
    main::ok( $res->[0] == 200, ' Response is 200' )
      or main::explain( $res->[0], 200 );
    my $c;
    main::ok(
        ( defined( $c = main::getCookies($res)->{$cookieName} ) and not $c ),
        ' Cookie is deleted' )
      or main::explain( $res->[1], "Set-Cookie => 'lemonldap='" );
    main::ok( not( main::getCookies($res)->{"${cookieName}pdata"} ),
        ' No pdata' );
    main::ok( $res = $self->_get( '/', cookie => "$cookieName=$id" ),
        'Disconnect request' )
      or explain( $res, '[<code>,<hdrs>,<content>]' );
    main::ok( $res->[0] == 401, ' Response is 401' )
      or main::explain( $res, 401 );
    main::count(6);

}

=head4 _get( $path, %args )

Simulates a GET requests to $path. Accepted arguments:

=over

=item accept: accepted content, default to Ajax request. Use 'text/html'
to test content I<(to launch a C<expectForm()> for example)>.

=item cookie: full cookie string

=item custom: additional headers (hash ref only)

=item ip: remote address. Default to 127.0.0.1

=item method: default to GET. Only GET/DELETE values are acceptable
(use C<_post()> if you want to launch a POST/PUT request)

=item query: query string

=item referer

=item remote_user: REMOTE_USER header value

=back

=cut

sub _get {
    my ( $self, $path, %args ) = @_;

    # Automatically serialize query if given as HASHREF
    if ( ref( $args{query} ) eq "HASH" ) {
        $args{query} = main::buildForm( $args{query} );
    }

    my $res = $self->app->( {
            'HTTP_ACCEPT'          => $args{accept} // $self->accept,
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            ( $args{cookie} ? ( HTTP_COOKIE => $args{cookie} ) : () ),
            'HTTP_HOST' => ( $args{host} ? $args{host} : 'auth.example.com' ),
            'HTTP_USER_AGENT' =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'PATH_INFO' => $path,
            ( $args{referer} ? ( REFERER => $args{referer} ) : () ),
            (
                $args{ip} ? ( 'REMOTE_ADDR' => $args{ip} )
                : ( 'REMOTE_ADDR' => '127.0.0.1' )
            ),
            (
                $args{remote_user} ? ( 'REMOTE_USER' => $args{remote_user} )
                : ()
            ),
            'REQUEST_METHOD' => $args{method} || 'GET',
            'REQUEST_URI'    => $path . ( $args{query} ? "?$args{query}" : '' ),
            ( $args{query} ? ( QUERY_STRING => $args{query} ) : () ),
            'SCRIPT_NAME'     => '',
            'SERVER_NAME'     => 'auth.example.com',
            'SERVER_PORT'     => '80',
            'SERVER_PROTOCOL' => 'HTTP/1.1',
            'psgi.url_scheme' => ( $args{secure} ? 'https' : 'http' ),
            ( $args{custom} ? %{ $args{custom} } : () ),
        }
    );
    return $res;
}

=head4 _post( $path, $body, %args )

Same as C<_get> except that a body is required. $body must be a file handle.
Example with IO::String:

  ok(
      $res = $client->_post(
          '/',
          IO::String->new('user=dwho&password=dwho'),
          length => 23
      ),
      'Auth query'
  );

=cut

sub _post {
    my ( $self, $path, $body, %args ) = @_;

    # If $body is a HASHREF, serialize as string
    if ( ref($body) eq "HASH" ) {
        $body = main::buildForm($body);
    }

    # If $body is a string, wrap in IO::Handle
    unless ( ref($body) ) {
        $args{length} = length($body);

        # We must force a string copy here to avoid circular references
        $body = IO::String->new("$body");
    }

    die "$body must be a IO::Handle"
      unless ( ref($body) and $body->can('read') );
    my $res = $self->app->( {
            'HTTP_ACCEPT'          => $args{accept} // $self->accept,
            'HTTP_ACCEPT_LANGUAGE' => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            'HTTP_CACHE_CONTROL'   => 'max-age=0',
            ( $args{cookie} ? ( HTTP_COOKIE => $args{cookie} ) : () ),
            'HTTP_HOST' => ( $args{host} ? $args{host} : 'auth.example.com' ),
            'HTTP_USER_AGENT' =>
              'Mozilla/5.0 (VAX-4000; rv:36.0) Gecko/20350101 Firefox',
            'PATH_INFO' => $path,
            ( $args{query}   ? ( QUERY_STRING => $args{query} )   : () ),
            ( $args{referer} ? ( REFERER      => $args{referer} ) : () ),
            (
                $args{ip} ? ( 'REMOTE_ADDR' => $args{ip} )
                : ( 'REMOTE_ADDR' => '127.0.0.1' )
            ),
            (
                $args{remote_user} ? ( 'REMOTE_USER' => $args{remote_user} )
                : ()
            ),
            'REQUEST_METHOD' => $args{method} || 'POST',
            'REQUEST_URI'    => $path . ( $args{query} ? "?$args{query}" : '' ),
            'SCRIPT_NAME'    => '',
            'SERVER_NAME'    => 'auth.example.com',
            'SERVER_PORT'    => '80',
            'SERVER_PROTOCOL' => 'HTTP/1.1',
            'psgi.url_scheme' => ( $args{secure} ? 'https' : 'http' ),
            ( $args{custom} ? %{ $args{custom} } : () ),
            'psgix.input.buffered' => 0,
            'psgi.input'           => $body,
            'CONTENT_LENGTH'       => $args{length},
            'CONTENT_TYPE'         => $args{type}
              || 'application/x-www-form-urlencoded',
        }
    );
    return $res;
}

=head4 _delete( $path, %args )

Call C<_get()> with method set to DELETE.

=cut

sub _delete {
    my ( $self, $path, %args ) = @_;
    $args{method} = 'DELETE';
    $self->_get( $path, %args );
}

=head4 _options( $path, %args )

Call C<_get()> with method set to OPTIONS.

=cut

sub _options {
    my ( $self, $path, %args ) = @_;
    $args{method} = 'OPTIONS';
    $self->_get( $path, %args );
}

=head4 _put( $path, $body, %args )

Call C<_post()> with method set to PUT

=cut

sub _put {
    my ( $self, $path, $body, %args ) = @_;
    $args{method} = 'PUT';
    return $self->_post( $path, $body, %args );
}

1;
