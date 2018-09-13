#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use Modern::Perl '2018';
#use feature qw(signatures);
#no warnings qw(experimental::signatures);

use Test::Most tests => 15;

use Mojolicious;
use File::Slurp;
use File::Temp;

use Hetula::Client;


#$ENV{HETULA_DEBUG} = 1;
#$ENV{MOJO_INSECURE} = 1;
$ENV{MOJO_LOG_LEVEL} = 'info';

## Get credentials to use. Alternatively one can temporarily test with real credentials this predesigned test suite.
my $realCredentials = 0;
my $credentialsFile = "$FindBin::Bin/credentials";
my @credentials = File::Slurp::read_file($credentialsFile, chomp => 1);

my $username     = $credentials[0];
my $password     = $credentials[1];
my $organization = $credentials[2];
my $baseURL      = $credentials[3];
if ($realCredentials) { #test with real credentials here
  $username     = '';
  $password     = '';
  $organization = '';
  $baseURL      = '';
}
## Credentials dealt with.


my $hc = Hetula::Client->new({baseURL => $baseURL});
mockServer($hc) unless $realCredentials;


my $resp = $hc->login({username => 'master', password => 'blaster', organization => $organization});
ok($resp->{error}, "Login failed - Using bad credentials, got error '$resp->{error}'");


$resp = $hc->login({username => $username, password => $password, organization => $organization});
ok(! $resp->{error}, "Login success");


$resp = $hc->loginActive();
ok(! $resp->{error}, "Login active");


$resp = $hc->ssnAdd({ssn => 'bad-ssn'});
ok($resp->{error}, "SSN add failed - Bad SSN '$resp->{error}'");


$resp = $hc->ssnGet({id => 1});
ok(! $resp->{error}, "SSN got");


$resp = $hc->ssnsBatchAdd(['101010-101A', '101010-102B']);
is(@$resp, 2, "SSNs batch add");


$resp = $hc->userBasicAdd({username => 'kivi', password => 'secret', realname => 'Olvar Alfons'});
ok(! $resp->{error}, "User Basic add succeeded");


$resp = $hc->userReadAdd({username => 'kiviReader', password => 'secretReader', realname => 'Olvar Alfons'});
ok(! $resp->{error}, "User Read add succeeded");


$resp = $hc->userDisableAccount({username => $username});
ok(! $resp->{error}, "User disable account succeeded");


$resp = $hc->userChangePassword({username => $username, password => $password});
ok(! $resp->{error}, "User change password succeeded");


subtest "New Hetula::Client with a credentials file", sub {
  plan tests => 1;
  my $hc = Hetula::Client->new({baseURL => $baseURL, credentials => $credentialsFile});
  mockServer($hc) unless $realCredentials;

  $resp = $hc->login();
  ok(! $resp->{error}, "Login success");
};


subtest "ssnsBatchAddFromFile()", sub {
  plan tests => 11;
  my ($FH, $tempFilename) = File::Temp::tempfile();
  $resp = $hc->ssnsBatchAddFromFile("$FindBin::Bin/ssns.txt", $tempFilename, 3);
  ok(1, "SSNs added from file");
  my $report = File::Slurp::read_file($tempFilename);
  like($report, qr/ssn$_/, "ssn$_ reported") for 0..9;
};


subtest "ssnsBatchAddFromFile() with context", sub {
  plan tests => 21;
  my ($FH, $tempFilename) = File::Temp::tempfile();
  $resp = $hc->ssnsBatchAddFromFile("$FindBin::Bin/ssnsWithContext.txt", $tempFilename, 3);
  ok(1, "SSNs added from file");
  my $report = File::Slurp::read_file($tempFilename);
  like($report, qr/ssn$_/sm, "ssn$_ reported") for 0..9;
  like($report, qr/,$_{3},$_{4}$/sm, "context $_ preserved and appended") for 0..9;
};


subtest "ssnsBatchAddFromFile() with context, using error recovery", sub {
  $ENV{MOCK_BAD_CONNECTION} = 1;
  plan tests => 21;

  my ($FH, $tempFilename) = File::Temp::tempfile();
  $resp = $hc->ssnsBatchAddFromFile("$FindBin::Bin/ssnsWithContext.txt", $tempFilename, 3);
  ok(1, "SSNs added from file");
  my $report = File::Slurp::read_file($tempFilename);
  like($report, qr/ssn$_/sm, "ssn$_ reported") for 0..9;
  like($report, qr/,$_{3},$_{4}$/sm, "context $_ preserved and appended") for 0..9;

  $ENV{MOCK_BAD_CONNECTION} = 0;
};


subtest "ssnsBatchAddFromFile(), no connection...", sub {
  $ENV{MOCK_NO_CONNECTION} = 1;
  $ENV{MOCK_BAD_CONNECTION} = 1;
  plan tests => 2;

  my ($FH, $tempFilename) = File::Temp::tempfile();
  throws_ok( sub { $hc->ssnsBatchAddFromFile("$FindBin::Bin/ssnsWithContext.txt", $tempFilename, 3) }, qr/Hetula::Client::Connection.+?3/, "Retried some times and then died");
  my $report = File::Slurp::read_file($tempFilename);
  is($report, "ssnId,ssn,error,context\n", "Report file is empty");

  $ENV{MOCK_NO_CONNECTION} = 0;
  $ENV{MOCK_BAD_CONNECTION} = 0;
};


sub mockServer {
  my ($hc) = @_;
  $hc->{baseURL} = '';
  $hc->ua->server->app(Mojolicious->new);
  my $r = $hc->ua->server->app->routes;

  $r->get('/api/v1/auth' => sub {
    my ($c) = @_;
    if ($c->session()->{userid}) {
      $c->render(status => '204', text => '');
    }
    else {
      $c->render(status => '404', text => 'Session not found');
    }
  });

  $r->post('/api/v1/auth' => sub {
    my ($c) = @_;
    my $jsonParams = $c->req->json;
    if ($jsonParams->{username} && $jsonParams->{username} eq $username) {
      $c->session(userid => $jsonParams->{username});
      $c->res->headers->header('X-CSRF-Token' => '$c->csrf_token');
      $c->render(status => '201', headers => [], json => {msg => 'Session created'});
    }
    else {
      $c->render(status => '404', text => '');
    }
  });

  $r->post('/api/v1/ssns' => sub {
    my ($c) = @_;
    my $jsonParams = $c->req->json;
    if ($jsonParams->{ssn} eq '101010-102C') {
      $c->render(status => '200', json => {ssn => $jsonParams->{ssn}, id => 1});
    }
    else {
      $c->render(status => '400', text => 'Invalid ssn');
    }
  });

  $r->get('/api/v1/ssns/:id' => sub {
    my ($c) = @_;
    $c->render(status => '200', json => {ssn => '101010-102C', id => $c->param('id')});
  });

  $r->post('/api/v1/ssns/batch' => sub {
    my ($c) = @_;
    my $jsonParams = $c->req->json;
    if ($ENV{MOCK_NO_CONNECTION}) {
      return $c->render(status => '500', text => 'Bad connectiong mocked');
    }
    if ($ENV{MOCK_BAD_CONNECTION} && (not($ENV{MOCK_BAD_CONNECTION_RETRIES}) || time % 2)) { #Every other second, the connection is bad, but atleast once
      return $c->render(status => '500', text => 'Bad connectiong mocked');
    }
    if (ref($jsonParams) eq 'ARRAY') {
      my $id = 1;
      my @jsonParams = map {
        if ($id++ % 3) {
          {status => 200, ssn => {ssn => $_, id => $id}};
        }
        else {
          {status => 400, error => 'invalid ssn', ssn => {ssn => $_}};
        }
      } @$jsonParams;
      $c->render(status => '200', json => \@jsonParams);
    }
    else {
      $c->render(status => '400', text => 'Invalid batch');
    }
  });

  $r->post('/api/v1/users' => sub {
    my ($c) = @_;
    my $jsonParams = $c->req->json;
    $c->render(status => '200', json => $jsonParams);
  });

  $r->put('/api/v1/users/:id/password' => sub {
    my ($c) = @_;
    my $jsonParams = $c->req->json;
    if ($c->session && $c->session->{userid} eq $c->param('id')) {
      return $c->render(status => '204', text => '');
    }
    $c->render(status => '403', text => 'unauthorized');
  });

  $r->delete('/api/v1/users/:id/password' => sub {
    my ($c) = @_;
    my $jsonParams = $c->req->json;
    if ($c->session && $c->session->{userid} eq $c->param('id')) {
      return $c->render(status => '204', text => '');
    }
    $c->render(status => '403', text => 'unauthorized');
  });
}
