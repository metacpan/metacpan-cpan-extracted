use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Time::HiRes ();
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# GET /skeid/config shows what the customer source's rows did (ADR 0026): customer_names (key id
# => the row's name) and customer_report (accepted, rejected and shadowed rows, by label and
# reason). Only key ids and labels: never a key, never a DSN password.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY )};
$SIG{__WARN__} = sub { };

my $ADMIN  = 'admin-test-key';
my $ALICE  = Langertha::Skeid->key_id_for_key('sk-alice-secret-key');
my $BOB    = Langertha::Skeid->key_id_for_key('sk-bob-secret-key');
my $FILE   = Langertha::Skeid->key_id_for_key('sk-file-secret-key');
my $PASS   = 's3cr3t-db-password';

{
  package FakeFetcher;
  sub new { my ($class, %a) = @_; return bless { rows => [], %a }, $class }
  sub fetch {
    my ($self, $cb) = @_;
    my $rows = [ map { {%$_} } @{$self->{rows}} ];
    Mojo::IOLoop->timer(0.001 => sub { $cb->(undef, $rows) });
    return;
  }
}

sub wait_until {
  my ($cond, $max) = @_;
  my $end  = Time::HiRes::time() + ($max // 3);
  my $tick = Mojo::IOLoop->recurring(0.005 => sub { });
  Mojo::IOLoop->one_tick until $cond->() || Time::HiRes::time() > $end;
  Mojo::IOLoop->remove($tick);
  return $cond->() ? 1 : 0;
}

my $fake = FakeFetcher->new(rows => [
  { key_id => $ALICE, name => 'alice', policy => undef, models => undef },
  { key_id => $BOB,   name => undef,   policy => undef, models => undef },
  { key_id => $FILE,  name => 'filecustomer', policy => undef, models => undef },
  { key_id => 'sk-not-a-key-id', name => 'broken', policy => undef, models => undef },
]);
my $cfg = {
  policies       => { basic => {} },
  default_policy => 'basic',
  keys           => { $FILE => 'basic' },
  client_auth    => { keys => [ $FILE ] },
  admin_api_key  => $ADMIN,
  customer_source => { dsn => 'dbi:Pg:dbname=console', password_env => 'SKEID_T89_PW',
    relation => 'skeid.customer_keys', refresh_interval_s => 0.1, connect_timeout_s => 1 },
};
my $skeid = Langertha::Skeid->new(
  config_reload_interval  => 0,
  config_loader           => sub { $cfg },
  customer_source_fetcher => sub { $fake },
  store_usage_event       => sub { return { ok => 1 } },
);
my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$app->log->level('fatal');
my $t = Test::Mojo->new($app);
local $ENV{SKEID_T89_PW} = $PASS;

ok wait_until(sub { $skeid->client_key_allowed($ALICE) }), 'the source rows are in force';

$t->get_ok('/skeid/config' => { Authorization => "Bearer $ADMIN" })->status_is(200)
  ->json_is('/customer_names' => { $ALICE => 'alice', $FILE => 'filecustomer' },
    'customer_names: id => name, nameless rows absent, rejected rows absent')
  ->json_is('/customer_report/accepted' => 3)
  ->json_is('/customer_report/rejected/0/row' => "'broken'")
  ->json_like('/customer_report/rejected/0/reason' => qr/full key id/)
  ->json_is('/customer_report/shadowed' => [ "'filecustomer'" ], 'the file wins: shadowed by label');

my $body = $t->tx->res->body;
for my $secret ('sk-alice-secret-key', 'sk-bob-secret-key', 'sk-file-secret-key', $PASS, 'sk-not-a-key-id') {
  unlike $body, qr/\Q$secret\E/, 'no secret or raw value in /skeid/config: ' . substr($secret, 0, 8);
}

$t->get_ok('/skeid/config' => { Authorization => 'Bearer wrong' })->status_is(401);
$t->get_ok('/health')->status_is(200);
ok !exists $t->tx->res->json->{customer_names} && !exists $t->tx->res->json->{customer_report},
  '/health carries neither';
$skeid->stop_customer_source;

# Without a customer_source the admin config has neither.
{
  my $plain = Langertha::Skeid->new(config_loader => sub { { admin_api_key => $ADMIN } },
    store_usage_event => sub { { ok => 1 } });
  my $t2 = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $plain));
  $t2->get_ok('/skeid/config' => { Authorization => "Bearer $ADMIN" })->status_is(200);
  ok !exists $t2->tx->res->json->{customer_names}, 'no customer_names without a source';
  ok !exists $t2->tx->res->json->{customer_report}, 'no customer_report without a source';
}
done_testing;
