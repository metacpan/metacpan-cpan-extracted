#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Langertha::Skeid;
use Langertha::Skeid::KeyBroker::OpenBao;

# The OpenBao key broker with a token file (skeid k127): a starter runs many Skeid processes and
# keeps one periodic token current in a file, because an AppRole secret_id is single use. The
# broker reads the file, reads it again when it changes, and fails loudly without it.

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/openbao-token";
my $SEQ  = 1_000;
sub put_token {
  my ($text) = @_;
  open my $fh, '>', "$file.new" or die $!;
  print {$fh} $text;
  close $fh;
  rename "$file.new", $file or die $!;
  utime($SEQ, $SEQ += 10, $file);
}

# The double: a KV-v2 secret, readable with the current token only. No login, no renewal: with a
# token file neither may be called.
my $valid = 'tok-one';
my (@seen, $logins, $renewals);
my $bao = Mojolicious->new;
$bao->log->level('fatal');
$bao->routes->post('/v1/auth/approle/login' => sub { $logins++;   $_[0]->render(status => 500, text => '') });
$bao->routes->post('/v1/auth/token/renew-self' => sub { $renewals++; $_[0]->render(status => 500, text => '') });
$bao->routes->get('/v1/secret/data/skeid/remote/groq' => sub {
  my ($c) = @_;
  my $token = $c->req->headers->header('X-Vault-Token') // '';
  push @seen, $token;
  return $c->render(status => 403, json => { errors => ['permission denied'] }) unless $token eq $valid;
  $c->render(json => { data => { data => { api_key => "gsk-for-$token" } } });
});
my $daemon = Mojo::Server::Daemon->new(app => $bao, listen => ['http://127.0.0.1'], silent => 1);
$daemon->start;
my $addr = 'http://127.0.0.1:' . $daemon->ports->[0];

sub resolve {
  my ($broker) = @_;
  my @answer;
  Mojo::IOLoop->next_tick(sub {
    $broker->resolve_key_async('secret/skeid/remote/groq', sub { @answer = @_; Mojo::IOLoop->stop });
  });
  my $guard = Mojo::IOLoop->timer(5 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return @answer;
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

put_token("tok-one\n");
my $broker = Langertha::Skeid::KeyBroker::OpenBao->new(addr => $addr, token_file => $file);
my ($key, $error) = resolve($broker);
is $key, 'gsk-for-tok-one', 'the broker reads a secret with the token from the file';
is $seen[-1], 'tok-one', 'trimmed of its newline';

# The starter rotates the token: the next resolution reads the file again.
$valid = 'tok-two';
put_token("tok-two\n");
($key, $error) = resolve($broker);
is $key, 'gsk-for-tok-two', 'a changed file is read again before the next resolution';
ok !$logins && !$renewals, 'no AppRole login and no renew-self: renewing is the starter\'s';

# The timer reads the file whatever its stamp says.
{
  $valid = 'tok-thr';
  put_token("tok-thr\n");
  my $stamp = $broker->_token_file_stamp;
  $broker->_token_file_seen($stamp);           # as if the change were invisible to the stamp
  $broker->renew_secs(1);
  my $loop = $broker->start_renewal;
  my $guard = Mojo::IOLoop->timer(1.3 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($loop);
  $broker->_renewal_loop(undef);
  ($key) = resolve($broker);
  is $key, 'gsk-for-tok-thr', 'the renewal timer reads the file even when its stamp did not move';
  $valid = 'tok-two';
  put_token("tok-two\n");
  resolve($broker);
}

# A file that goes missing or empty later: loud, and the last token stays in use.
unlink $file;
($key, $error) = resolve($broker);
is $key, 'gsk-for-tok-two', 'a missing file keeps the token read before';
ok scalar(grep { /token file \Q$file\E is missing/ } @warnings), 'and says so, naming the path';
put_token("  \n");
($key) = resolve($broker);
is $key, 'gsk-for-tok-two', 'an empty file likewise';
ok scalar(grep { /is empty/ } @warnings), 'and says so';
unlike join('', @warnings), qr/tok-/, 'no token in any warning';

# At construction there is no token to keep: missing or empty dies.
unlink $file;
ok !eval { Langertha::Skeid::KeyBroker::OpenBao->new(addr => $addr, token_file => $file); 1 },
  'a missing token file at construction dies';
like $@, qr/is missing/, '...saying so';
put_token("\n");
ok !eval { Langertha::Skeid::KeyBroker::OpenBao->new(addr => $addr, token_file => $file); 1 },
  'an empty one too';
put_token("tok-two\n");
ok !eval { Langertha::Skeid::KeyBroker::OpenBao->new(addr => $addr, token_file => $file,
  role_id => 'r', secret_id => 's'); 1 }, 'a token file and AppRole values together die';
like $@, qr/exclude each other/, '...rather than one silently winning';

# The proxy: OPENBAO_TOKEN_FILE wires the broker; a bad setup stops build_app.
{
  require Langertha::Skeid::Proxy;
  local $ENV{OPENBAO_ADDR} = $addr;
  local $ENV{OPENBAO_TOKEN_FILE} = $file;
  local $ENV{OPENBAO_ROLE_ID};
  local $ENV{OPENBAO_SECRET_ID};
  my $app = Langertha::Skeid::Proxy->build_app;
  isa_ok $app->skeid->key_broker, 'Langertha::Skeid::KeyBroker::OpenBao', 'OPENBAO_TOKEN_FILE sets the broker';
  is $app->skeid->key_broker->token_file, $file, 'with the file';

  local $ENV{OPENBAO_ROLE_ID} = 'r';
  local $ENV{OPENBAO_SECRET_ID} = 's';
  ok !eval { Langertha::Skeid::Proxy->build_app; 1 }, 'with AppRole values as well, build_app dies';
  delete local $ENV{OPENBAO_ROLE_ID};
  delete local $ENV{OPENBAO_SECRET_ID};
  local $ENV{OPENBAO_TOKEN_FILE} = "$dir/nope";
  ok !eval { Langertha::Skeid::Proxy->build_app; 1 }, 'a missing token file stops build_app';
}

# The capability is queryable.
ok scalar(grep { $_ eq 'openbao_token_file' } Langertha::Skeid->capabilities), 'openbao_token_file is a capability';
my $out = qx{$^X -Ilib $FindBin::Bin/../bin/skeid capabilities};
like $out, qr/^openbao_token_file$/m, 'skeid capabilities prints it';

done_testing;
