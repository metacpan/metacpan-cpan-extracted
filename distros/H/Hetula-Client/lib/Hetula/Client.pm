package Hetula::Client;

use Modern::Perl '2015';

our $VERSION = '0.008';

# ABSTRACT: Interface with Hetula
#
# Copyright 2018 National Library of Finland

=encoding utf8

=head1 NAME

Hetula::Client - Perl client implementation to communicate with Hetula.

=head1 DESCRIPTION

Perl client implementation to communicate with Hetula, the Patron data store

=head1 SYNOPSIS

 my $hc = Hetula::Client->new({baseURL => 'https://hetula.example.com'});

 my $loginResponse = $hc->login({username => 'master', password => 'blaster', organization => 'Administratoria'});
 die($loginResponse->{error}) if ($loginResponse->{error});

 my $loginActiveResp = $hc->loginActive();
 ok(! $loginActiveResp->{error}, "Login active");

 my $ssnAddResp = $hc->ssnAdd({ssn => 'bad-ssn'});
 ok($ssnAddResp->{error}, "SSN add failed - Bad SSN '$ssnAddResp->{error}'");

 my $ssnGetResp = $hc->ssnGet({id => 1});
 ok(! $ssnGetResp->{error}, "SSN got");

 my $ssnsBatchAddResp = $hc->ssnsBatchAdd(['101010-101A', '101010-102B']);
 is(@$ssnsBatchAddResp, 2, "SSNs batch add");

=cut

##Pragmas
use Modern::Perl;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Carp::Always;
use autodie;
use English; #Use verbose alternatives for perl's strange $0 and $\ etc.

##External modules
use Mojo::UserAgent;
use Storable;
use Regexp::Common;
use Data::Printer;

=head3 new

 @param1 {HASHRef} baseURL => https://hetula.example.com
                   credentials => filepath, Where to load the credentials file.
                                  see slurpCredentials() for more info.

=cut

sub new($class, $params) {
  slurpCredentials($params->{credentials}, $params) if ($params->{credentials});
  _detectKohaEnvironment($params);
  die("Hetula::Client::BadParam - parameter 'baseURL' is missing") unless $params->{baseURL};
  die("Hetula::Client::BadParam - parameter 'baseURL' '$params->{baseURL}' is not a valid URI") unless $params->{baseURL} =~ /$RE{URI}{HTTP}{-scheme=>qr!https?!}/;

  my $s = bless(Storable::dclone($params), $class);

  $s->{ua} = Mojo::UserAgent->new() unless $s->{ua};
  return $s;
}

=head2 API Access methods

=head3 login

See Hetula API doc for endpoint POST /api/v1/auth

 @param1 {HASHRef} username => String || undef if given via credentials during construction,
                   password => String || undef if given via credentials during construction,
                   organization => String || undef if given via credentials during construction,

=cut

sub login($s, $params={}) {
  $params->{username} = $s->{username} unless $params->{username};
  $params->{password} = $s->{password} unless $params->{password};
  $params->{organization} = $s->{organization} unless $params->{organization};

  my $tx = $s->ua->post( $s->baseURL().'/api/v1/auth', {Accept => '*/*'}, json => $params );
  my $json = _handleResponse($tx);
  return $json if $json->{error};

  my $cookies = $tx->res->cookies;
  my $sessionCookie = $cookies->[0];
  $s->ua->cookie_jar->add($sessionCookie);

  my $csrfHeader = $tx->res->headers->header('X-CSRF-Token');

  $s->ua->on(start => sub {
    my ($ua, $tx) = @_;
    $tx->req->headers->header('X-CSRF-Token' => $csrfHeader);
  });

  return $json;
}

=head3 loginActive

=cut

sub loginActive($s) {
  my $tx = $s->ua->get( $s->baseURL().'/api/v1/auth' );
  return _handleResponse($tx);
}

=head3 ssnAdd

See Hetula API doc for endpoint POST /api/v1/ssns

=cut

sub ssnAdd($s, $params) {
  my $tx = $s->ua->post( $s->baseURL().'/api/v1/ssns', {Accept => '*/*'}, json => $params );
  return _handleResponse($tx);
}

=head3 ssnGet

See Hetula API doc for endpoint GET /api/v1/users/<id>

 @param1 {HASHRef} id => ssn id to get

=cut

sub ssnGet($s, $params) {
  die("Hetula::Client::BadParameter - parameter 'id' is not an integer") unless $params->{id} =~ /$RE{num}{int}/;
  my $tx = $s->ua->get( $s->baseURL().'/api/v1/ssns/'.$params->{id} );
  return _handleResponse($tx);
}

=head3 ssnsBatchAdd

See Hetula API doc for endpoint GET /api/v1/ssns/batch

 @param1 {ARRAYRef} of ssns

=cut

sub ssnsBatchAdd($s, $ssnArray) {
  my $tx = $s->ua->post( $s->baseURL().'/api/v1/ssns/batch', {Accept => '*/*'}, json => $ssnArray );
  return _handleResponse($tx);
}

=head2 ssnsBatchAddChunked

Invokes the ssnsBatchAdd()-method repeatedly in small chunks. Useful for
importing an inconveniently large amount of ssns that would otherwise timeout
the Hetula-server.

 @param1 {sub} Receives a feeder callback, which sends ssn-lists to the
               ssnsBatchAdd()-method.
               for ex.
                sub {
                  #Keep sending ssns while there are ssns to send
                  return ['ssn1','ssn2','ssn3'] if @ssns;
                  #When ssns run out, return false to signal the end of transmission
                  return undef || [];
                }

 @param2 {sub} Receives a digester callback, which receives the ssnsBatchAdd()-methods
               response|return value.
               for ex.
                sub {
                  my ($ssnReportsFromHetula) = @_;
                  print $FH_OUT "$_->{ssn}->{id},$_->{ssn}->{ssn},$_->{error}\n" for @$ssnReportsFromHetula;
                }

=cut

sub ssnsBatchAddChunked($s, $feederCallback, $digesterCallback) {
  while (my $ssns = $feederCallback->()) {
    last unless($ssns && @$ssns);
    $digesterCallback->($s->ssnsBatchAdd($ssns))
  }
}

=head2 ssnsBatchAddFromFile

Wrapper for ssnsBatchAddChunked(), where this manages the file IO as well.

 @param1 {filepath} Where to read ssns from.
                    This can be a simple .csv-file, in this case the last (or only)
                    column is expected to be one containing the ssn that is
                    intended to be migrated to Hetula.
                    If there are any extra columns, they are appended to the
                    ssn report/result .csv-file as ssn report context.
 @param2 {filepath} Where to write the ssn migration results/reports

=cut

sub ssnsBatchAddFromFile($s, $filenameIn, $filenameOut, $batchSize=500) {
  open(my $FH_IN,  "<:encoding(UTF-8)", $filenameIn)  or die("Hetula::Client::File - Opening the given file '$filenameIn' for reading ssns failed: $!\n");
  open(my $FH_OUT, ">:encoding(UTF-8)", $filenameOut) or die("Hetula::Client::File - Opening the given file '$filenameOut' for writing ssns results failed: $!\n");

  print $FH_OUT "ssnId,ssn,error,context\n";

  my $i = 0; #Keep track of how many ssns are processed.
  my $retry = 0;
  my @ssns;
  my @context;
  my $feeder = sub { #Feeds ssns to the batch grinder
    if ($retry == 0) { #Do not reset the input if retrying
      @ssns = ();
      @context = ();
      while (<$FH_IN>) {
        $i++;
        chomp;
        my @cols = split(',', $_);
        push(@ssns, pop(@cols)); #The last value is expected to be the ssn
        push(@context, \@cols); #always push the context, even if cols is empty. This makes sure the order of contexts is preserved!
        last if @ssns >= $batchSize;
      }
    }
    if (@ssns) {
      print __PACKAGE__."::ssnsBatchAddFromFile() :> '$i' ssns fed.\n";
    }
    else {
      print __PACKAGE__."::ssnsBatchAddFromFile() :> All '$i' ssns fed.\n";
    }

    return \@ssns;
  };
  my $digester = sub { #digests ssn reports from Hetula
    my ($ssnReports) = @_;

    if (ref($ssnReports) ne 'ARRAY') { #There is something wrong!
      Data::Printer::p($ssnReports);
      $retry++;

      sleep($ENV{MOCK_BAD_CONNECTION}||10); #Wait a bit, maybe the pipi goes away.
      $ENV{MOCK_BAD_CONNECTION_RETRIES} = $retry if $ENV{MOCK_BAD_CONNECTION}; #Awkwardly mix test hooks here, sorry about that.

      return if $retry <= 3;
      die("Hetula::Client::Connection - Retried '".($retry-1)."' times, but still cannot succeed. Sorry... Exception from Hetula: ".Data::Printer::np($ssnReports));
    }
    $retry = 0; #Presumably we have succeeded in something here.

    for (my $i=0 ; $i<@$ssnReports ; $i++) {
      my $res = $ssnReports->[$i];
      my $ssn = $ssns[$i];

      die("Hetula::Client::SSN - Local ssns and Hetula ssns are out of sync at batch file row='$i', local ssn='$ssn', Hetula ssn='$res->{ssn}->{ssn}'?") unless ($res->{ssn}->{ssn} eq $ssn);

      print $FH_OUT join(",", $res->{ssn}->{id}//'', $ssn, $res->{error}//'',
                              @{$context[$i]} #Add what is left of the given file columns as a context for the ssn report file. This makes it easier for possible next processing steps in the migration pipeline.
                        )."\n";
    }
    print __PACKAGE__."::ssnsBatchAddFromFile() :> '$i' reports digested.\n";
  };
  $s->ssnsBatchAddChunked($feeder, $digester);
}

=head3 userAdd

See Hetula API doc for endpoint POST /api/v1/users

=cut

sub userAdd($s, $params) {
  my $tx = $s->ua->post( $s->baseURL().'/api/v1/users', {Accept => '*/*'}, json => $params );
  return _handleResponse($tx);
}

=head3 userBasicAdd

Adds a user with only the most minimum permisions needed to push records into Hetula.
Organization the user belongs to is implied from the currently logged in organization.

 @param {HASHRef} username => 'MattiM',
                  password => 'Secret',
                  realname => 'Matti Meikäläinen',

=cut

sub userBasicAdd($s, $params) {
  $params->{permissions} = [
    'ssns-post',
    'auth-get',
  ];
  return $s->userAdd($params);
}

=head3 userReadAdd

Adds a user with read access to Hetula.
Organization the user belongs to is implied from the currently logged in organization.

 @param {HASHRef} username => 'MattiM',
                  password => 'Secret',
                  realname => 'Matti Meikäläinen',

=cut

sub userReadAdd($s, $params) {
  $params->{permissions} = [
    'ssns-post',
    'ssns-id-get',
    'auth-get',
  ];
  return $s->userAdd($params);
}

=head3 userMod

See Hetula API doc for endpoint PUT /api/v1/users/<id>

 @param {HASHRef} username or id => mandatory,
                  other patron attributes => and values,
                  ...

=cut

sub userMod($s, $params) {
  my $id = $params->{id} || $params->{username};
  die("Hetula::Client::BadParameter - parameter 'id' or 'username' is missing") unless ($id);
  my $tx = $s->ua->put( $s->baseURL()."/api/v1/users/$id", {Accept => '*/*'}, json => $params );
  return _handleResponse($tx);
}

=head3 userChangePassword

 @param {HASHRef} username or id => mandatory,
                  password => mandatory - the new password,

=cut

sub userChangePassword($s, $params) {
  my $id = $params->{id} || $params->{username};
  die("Hetula::Client::BadParameter - parameter 'id' or 'username' is missing") unless ($id);
  die("Hetula::Client::BadParameter - parameter 'password' is missing") unless $params->{password};
  my $tx = $s->ua->put( $s->baseURL()."/api/v1/users/$id/password", {Accept => '*/*'}, json => $params );
  return _handleResponse($tx);
}

=head3 userDisableAccount

To recover from a disabled account, change the password

 @param {String} username or id

=cut

sub userDisableAccount($s, $params) {
  my $id = $params->{id} || $params->{username};
  die("Hetula::Client::BadParameter - parameter 'id' or 'username' is missing") unless ($id);
  my $tx = $s->ua->delete( $s->baseURL()."/api/v1/users/$id/password", {Accept => '*/*'} );
  return _handleResponse($tx);
}

=head2 HELPERS

=head3 slurpCredentials
@static

Reads the contents of a credentials file.

The credentials file must consist of up to 4 lines, with each line
specifying the following commandline argument replacements:
  username
  password
  organization
  url

 @param1 {String} Path to the credentials file
 @param2 {HASHRef} Optional, HASHRef where to inject the found credentials

=cut

sub slurpCredentials($credentialsFile, $injectHere=undef) {
  open(my $FH, '<:encoding(UTF-8)', $credentialsFile) or die("Couldn't read '$credentialsFile': $!");
  my $username     = <$FH>; if ($username)     { chomp($username);     $injectHere->{username}     = $username     if $username && $injectHere; }
  my $password     = <$FH>; if ($password)     { chomp($password);     $injectHere->{password}     = $password     if $password && $injectHere; }
  my $organization = <$FH>; if ($organization) { chomp($organization); $injectHere->{organization} = $organization if $organization && $injectHere; }
  my $baseURL      = <$FH>; if ($baseURL)      { chomp($baseURL);      $injectHere->{baseURL}      = $baseURL      if $baseURL && $injectHere; }
  return ($username, $password, $organization, $baseURL);
}

=head2 ATTRIBUTES

=head3 ua

=cut

sub ua { return $_[0]->{ua} }

=head3 baseURL

=cut

sub baseURL { return $_[0]->{baseURL} }

################
#######################
### Private methods ###
####################

sub _handleResponse($tx) {
  if (my $res = $tx->success) {
    if ($ENV{HETULA_DEBUG}) {
      print "Request success:\n";
      Data::Printer::p($res->json);
    }
    return $res->json || { OK => $tx->res->code };
  }
  else {
    my $error = $tx->error;
    $error->{error} = $tx->res->body || $error->{message} || $error->{code};
    if ($ENV{HETULA_DEBUG}) {
      print "Request error:\n";
      Data::Printer::p($error);
    }
    return $error;
  }
}

## @static
## If you are using https://koha-community.org/
## Hetula::Client tries to pick configurations from there automatically.
##
sub _detectKohaEnvironment($params) {
  eval "use C4::Context;"; #This way the Dist::Zilla ::Plugin::AutoPrereqs doesn't think this is a mandatory requirement
  unless ($@) {
    print "Koha detected. ";
    if (my $hetulaConfig = C4::Context->config('hetula')) {
      if (my $url = $hetulaConfig->{url}) {
          $params->{baseURL} = $url unless $params->{baseURL};
          print "Hetula baseURL found '$url'. ";
      }
      else {
          die "KOHA_CONF: hetula->url is missing!" unless $url;
      }

      if (my $org = $hetulaConfig->{organization}) {
          $params->{organization} = $org unless $params->{organization};
          print "Hetula organization found '$org'.\n";
      }
      else {
          die "KOHA_CONF: hetula->organization is missing!";
      }
    }
    else {
      die("Koha detected, but 'hetula' is not configured in the \$KOHA_CONF='$ENV{KOHA_CONF}'");
    }
  };
}

1;
