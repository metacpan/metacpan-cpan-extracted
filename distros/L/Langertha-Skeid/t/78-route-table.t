use strict;
use warnings;
use Test::More;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# The route table (skeid k105, ADR 0025). Every route of the app is registered from
# Langertha::Skeid::Proxy->route_table, and the OpenAPI documents are built from the same
# entries -- so a route that has no entry is a route the documents do not describe. This walks
# the real router and compares it with the table in both directions; it is the test that goes
# red when someone writes `$r->get('/v1/new' => ...)` beside the table.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY )};

sub app {
  my $skeid = Langertha::Skeid->new(config_loader => sub { {} });
  return Langertha::Skeid::Proxy->build_app(skeid => $skeid);
}

# "METHOD /pattern" of every leaf route of the router, bridges (under) walked through.
sub registered {
  my ($app) = @_;
  my %seen;
  my $walk;
  $walk = sub {
    my ($route, $prefix) = @_;
    for my $child (@{$route->children}) {
      my $pattern = $prefix . ($child->pattern->unparsed // '');
      if (@{$child->children}) {
        $walk->($child, $pattern);
        next;
      }
      my $methods = $child->methods;
      $seen{ "$_ $pattern" } = 1 for (ref($methods) eq 'ARRAY' && @$methods ? @$methods : ('ANY'));
    }
  };
  $walk->($app->routes, '');
  return \%seen;
}

sub tabled {
  my %t;
  for my $e (Langertha::Skeid::Proxy->route_table) {
    for my $path (@{$e->{paths}}) {
      $t{ "$_ $path" } = 1 for @{$e->{methods}};
    }
  }
  return \%t;
}

# What is in one set and not in the other.
sub difference {
  my ($app) = @_;
  my ($reg, $tab) = (registered($app), tabled());
  return (
    untabled   => [ sort grep { !$tab->{$_} } keys %$reg ],
    unregistered => [ sort grep { !$reg->{$_} } keys %$tab ],
  );
}

my $app = app();
my %diff = difference($app);
ok scalar(keys %{registered($app)}) > 15, 'the walk found the routes of the app';
is_deeply $diff{untabled}, [], 'every registered route has a route table entry'
  or diag explain $diff{untabled};
is_deeply $diff{unregistered}, [], 'every route table entry is registered'
  or diag explain $diff{unregistered};

# An entry marked websocket is registered as a WebSocket route, so only an upgrade request
# reaches it (skeid k95): the realtime route is the one, and nothing else is.
{
  my $app = app();
  my %ws;
  my $walk;
  $walk = sub {
    my ($route, $prefix) = @_;
    for my $child (@{$route->children}) {
      my $pattern = $prefix . ($child->pattern->unparsed // '');
      if (@{$child->children}) { $walk->($child, $pattern); next }
      $ws{$pattern} = $child->is_websocket ? 1 : 0;
    }
  };
  $walk->($app->routes, '');
  my @tabled = map { @{$_->{paths}} } grep { $_->{websocket} } Langertha::Skeid::Proxy->route_table;
  is_deeply [ sort @tabled ], ['/v1/realtime'], 'the realtime route is the one WebSocket entry';
  ok $ws{'/v1/realtime'}, 'and it is registered as a WebSocket route';
  is_deeply [ sort grep { $ws{$_} } keys %ws ], ['/v1/realtime'], 'no other route is a WebSocket route';
}

# The same walk has to see a route that is added beside the table -- otherwise the test above
# cannot fail, and a route without an entry would go unnoticed.
{
  my $rogue = app();
  $rogue->routes->get('/v1/rogue' => sub { $_[0]->render(text => 'x') });
  my %d = difference($rogue);
  is_deeply $d{untabled}, ['GET /v1/rogue'],
    'a route registered without an entry is reported (the detector can fail)';

  my $under = app();
  $under->routes->under(sub { 1 })->post('/api/sneaky' => sub { $_[0]->render(text => 'x') });
  %d = difference($under);
  is_deeply $d{untabled}, ['POST /api/sneaky'], 'so is one behind a bridge';

  my $wrong_method = app();
  $wrong_method->routes->delete('/v1/models' => sub { $_[0]->render(text => 'x') });
  %d = difference($wrong_method);
  is_deeply $d{untabled}, ['DELETE /v1/models'], 'and a method the entry does not list';
}

# Entries are well formed: what registration and the document builder both rely on.
{
  my @table = Langertha::Skeid::Proxy->route_table;
  my %ids;
  my @bad;
  for my $e (@table) {
    push @bad, "duplicate id $e->{id}" if $ids{$e->{id}}++;
    push @bad, "$e->{id}: handler is no coderef" unless ref($e->{handler}) eq 'CODE';
    push @bad, "$e->{id}: no paths" unless ref($e->{paths}) eq 'ARRAY' && @{$e->{paths}};
    push @bad, "$e->{id}: no methods" unless ref($e->{methods}) eq 'ARRAY' && @{$e->{methods}};
    push @bad, "$e->{id}: listed but has no tag or summary"
      if $e->{document} && !(defined $e->{tag} && defined $e->{summary});
  }
  is_deeply \@bad, [], 'route table entries are complete' or diag explain \@bad;
}

done_testing;
