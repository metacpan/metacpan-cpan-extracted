use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Kubernetes::Comb;
use Kubernetes::Comb::Client::Fake;
use TestComb::Fixtures qw( comb_cr );

# TestComb::Mailer and TestComb::Mailer::Stub live in t/lib and are loaded by
# from_crd, not here.

{
  package TestComb::Cache;
  use Moo;
  extends 'Kubernetes::Comb';
  sub endpoints { { name => 'redis', port => 6379 }, { name => 'metrics', port => 9121 } }
}

{
  # a stub defined next to its original, never in a file of its own
  package TestComb::Cache::Stub;
  use Moo;
  extends 'TestComb::Cache';
  sub endpoints { { name => 'redis', port => 6379 } }
}

{
  package TestComb::Queue;
  use Moo;
  extends 'Kubernetes::Comb';
  sub endpoints { { name => 'amqp', port => 5672 } }
  sub stub_class { 'TestComb::FakeQueue' }
}

{
  # not a subclass of its original: the contract is checked on endpoints alone
  package TestComb::FakeQueue;
  use Moo;
  extends 'Kubernetes::Comb';
  sub endpoints { { name => 'amqp', port => 5672 }, { name => 'extra', port => 1 } }
}

{
  package TestComb::Loose;
  use Moo;
  extends 'Kubernetes::Comb';
  sub endpoints { { name => 'http', port => 80 } }
}

{
  # named like a stub of TestComb::Loose, but not one
  package TestComb::Loose::Stub;
  use Moo;
  extends 'Kubernetes::Comb';
}

{
  package TestComb::Lonely;
  use Moo;
  extends 'Kubernetes::Comb';
}

{
  package Not::A::Comb;
  sub new { bless {}, shift }
}

my $k8s = Kubernetes::Comb::Client::Fake->new;
my $resolver = sub { undef };

subtest 'builds spec.class, loaded at runtime' => sub {
  ok !TestComb::Mailer->can('new'), 'the class is not loaded yet';
  my $cr = comb_cr( name => 'mailer', class => 'TestComb::Mailer' );
  my $comb = Kubernetes::Comb->from_crd( $cr,
    k8s      => $k8s,
    resolver => $resolver,
    upstream => undef
  );
  isa_ok $comb, 'TestComb::Mailer';
  is $comb->crd, $cr, 'with the custom resource';
  is $comb->k8s, $k8s, 'k8s passed on';
  is $comb->resolver, $resolver, 'resolver passed on';
  ok $comb->_has_upstream, 'upstream passed on';
  is $comb->name, 'mailer', 'name from the CR';
  ok !$comb->is_stub, 'no stub asked for';

  my $again = TestComb::Mailer->from_crd( $cr, k8s => $k8s, label_prefix => 'x/' );
  isa_ok $again, 'TestComb::Mailer', 'invoked on the class itself';
  is $again->label_prefix, 'x/', 'other constructor arguments pass through';
};

subtest 'refuses what is no Comb' => sub {
  ok !eval { Kubernetes::Comb->from_crd( { spec => { class => 'X' } } ); 1 }, 'a hashref';
  like $@, qr/from_crd needs a Comb custom resource object/, 'says what it needs';

  ok !eval { Kubernetes::Comb->from_crd( comb_cr( name => 'x', class => 'Not::A::Comb' ) ); 1 },
    'spec.class that is no Comb';
  like $@, qr/Not::A::Comb is not a Kubernetes::Comb/, 'names it';

  ok !eval { TestComb::Cache->from_crd( comb_cr( name => 'x', class => 'TestComb::Lonely' ) ); 1 },
    'spec.class outside the invocant';
  like $@, qr/TestComb::Lonely is not a TestComb::Cache/, 'names both';

  ok !eval { Kubernetes::Comb->from_crd( comb_cr( name => 'x', class => 'TestComb::Does::Not::Exist' ) ); 1 },
    'a class that does not load';
  like $@, qr{TestComb/Does/Not/Exist\.pm}, 'the loader says which';

  ok !eval { Kubernetes::Comb->from_crd( comb_cr( name => 'x', class => 'TestComb::Lonely' ), stub => 1 ); 1 },
    'stub must be a coderef';
  like $@, qr/stub must be a coderef/, 'says so';
};

subtest 'stub_class' => sub {
  is( TestComb::Cache->stub_class, 'TestComb::Cache::Stub', 'an inline ::Stub counts' );
  is( TestComb::Mailer->stub_class, 'TestComb::Mailer::Stub', '::Stub loaded from its file' );
  ok( TestComb::Mailer::Stub->can('new'), 'and is loaded now' );
  is( TestComb::Lonely->stub_class, undef, 'no ::Stub, no stub class' );
  is( TestComb::Queue->stub_class, 'TestComb::FakeQueue', 'overridable' );
  my $comb = TestComb::Lonely->new;
  is $comb->stub_class, undef, 'works on an instance too';
};

subtest 'stub selection' => sub {
  my @asked;
  my $select = sub { push @asked, $_[0]; $_[0]->name eq 'mailer' };

  my $mailer = Kubernetes::Comb->from_crd( comb_cr( name => 'mailer', class => 'TestComb::Mailer' ),
    k8s  => $k8s,
    stub => $select
  );
  isa_ok $mailer, 'TestComb::Mailer::Stub';
  ok $mailer->is_stub, 'is a stub';
  isa_ok $mailer->stub_of, 'TestComb::Mailer', 'stub_of';
  ok !$mailer->stub_of->is_stub, 'the original is not';
  is $mailer->k8s, $k8s, 'same arguments as the original';
  is $mailer->name, 'mailer', 'same custom resource';
  isa_ok $asked[0], 'TestComb::Mailer', 'the selector gets the original instance';

  my $cache = Kubernetes::Comb->from_crd( comb_cr( name => 'cache', class => 'TestComb::Cache' ),
    stub => $select
  );
  is ref $cache, 'TestComb::Cache', 'not selected, not stubbed';

  my $queue = Kubernetes::Comb->from_crd( comb_cr( name => 'queue', class => 'TestComb::Queue' ),
    stub => sub { 1 }
  );
  isa_ok $queue, 'TestComb::FakeQueue', 'an overridden stub_class';

  ok !eval {
    Kubernetes::Comb->from_crd( comb_cr( name => 'lonely', class => 'TestComb::Lonely' ), stub => sub { 1 } );
    1;
  }, 'asking for a stub that does not exist dies';
  like $@, qr/a stub was asked for lonely, but TestComb::Lonely has no stub class/, 'saying so';
};

subtest 'the stub contract is checked at construction' => sub {
  ok !eval {
    Kubernetes::Comb->from_crd( comb_cr( name => 'cache', class => 'TestComb::Cache' ), stub => sub { 1 } );
    1;
  }, 'a stub missing an endpoint dies';
  like $@, qr/TestComb::Cache::Stub does not keep the contract of TestComb::Cache: missing endpoint\(s\) metrics/,
    'naming the missing endpoint';

  my $original = TestComb::Mailer->new( crd => comb_cr( name => 'mailer', class => 'TestComb::Mailer' ) );
  ok !eval { TestComb::Lonely->new( stub_of => $original ); 1 }, 'direct construction checks too';
  like $@, qr/missing endpoint\(s\) smtp, http/, 'naming every missing endpoint';

  ok eval { TestComb::Mailer::Stub->new( stub_of => $original ); 1 }, 'the same endpoints pass';
  ok eval { TestComb::FakeQueue->new( stub_of => TestComb::Queue->new ); 1 },
    'more endpoints than the original pass';
};

subtest 'a Foo::Stub that is a Foo is checked however it was selected' => sub {
  ok !eval {
    Kubernetes::Comb->from_crd( comb_cr( name => 'cache', class => 'TestComb::Cache::Stub' ) );
    1;
  }, 'spec.class naming the stub directly';
  like $@, qr/TestComb::Cache::Stub does not keep the contract of TestComb::Cache: missing endpoint\(s\) metrics/,
    'is checked against the class it is named after';

  ok !eval { TestComb::Cache::Stub->new( namespace => 'platform' ); 1 }, 'plain construction too';
  like $@, qr/missing endpoint\(s\) metrics/, 'naming the missing endpoint';

  my $mailer = eval { Kubernetes::Comb->from_crd( comb_cr( name => 'mailer', class => 'TestComb::Mailer::Stub' ) ) };
  isa_ok $mailer, 'TestComb::Mailer::Stub', 'a stub that keeps the contract' or diag $@;

  ok eval { TestComb::Loose::Stub->new; 1 }, 'a ::Stub that is no subclass of its namesake is an ordinary Comb'
    or diag $@;
};

done_testing;
