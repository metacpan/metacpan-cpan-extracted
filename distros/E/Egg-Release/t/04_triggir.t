use Test::More tests=> 62;
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;

my $e= Egg::Helper->run('vtest');

ok $e->{namespace}, q{$e->{namespace}};
  can_ok $e, 'namespace';
  can_ok $e, 'project_name';
  is $e->namespace, ref($e), q{$e->namespace, ref($e)};
  is $e->namespace, $e->{namespace}, q{$e->namespace, $e->{namespace}};
  is $e->namespace, $e->project_name, q{$e->namespace, $e->project_name};

isa_ok $e, 'Egg';
isa_ok $e, 'Egg::Request';
isa_ok $e, 'Egg::Response';
isa_ok $e, 'Egg::Util';
isa_ok $e, 'Egg::Manager::Model';
isa_ok $e, 'Egg::Manager::View';
isa_ok $e, 'Egg::Component';
isa_ok $e, 'Egg::Component::Base';
isa_ok $e, 'Egg::Base';

can_ok $e, 'config';
can_ok $e, 'namespace';
can_ok $e, 'project_name';
can_ok $e, 'uc_namespace';
can_ok $e, 'lc_namespace';
can_ok $e, 'is_exception';
can_ok $e, '_dispatch_map';
can_ok $e, 'global';
can_ok $e, 'flag';

can_ok $e, 'run';
can_ok $e, 'new';
can_ok $e, 'handler';

can_ok $e, 'finished';
  is $e->finished, 0, '$e->finished';
  ok $e->finished('200 OK'), q{$e->finished('200 OK')};
  is $e->res->status, 200, q{$e->res->status};
  is $e->res->status_string, ' OK', q{$e->res->status_string};

can_ok $e, 'ixhash';
  isa_ok $e->ixhash, 'HASH';
  isa_ok tied(%{$e->ixhash}), 'Tie::Hash::Indexed';
  ok my $hash= $e->ixhash( 1=> 'foo', 2=> 'boo' ), q{my $hash= $e->ixhash( 1=> 'foo', 2=> 'boo' )};
  is $hash->{1}, 'foo', q{$hash->{1}};
  is $hash->{2}, 'boo', q{$hash->{2}};
  ok my @key= keys %$hash, q{my @key= keys %$hash};
  is $key[0], 1, q{$key[0], 1};

can_ok $e, 'error';
can_ok $e, 'errstr';
  $e->error('error 1');
  ok $e->errstr, q{$e->errstr};
  is $e->errstr, 'error 1', q{$e->errstr, 'error 1'};
  ok $e->stash('error'), q{$e->stash('error')};
  is $e->stash('error'), $e->errstr, q{$e->stash('error'), $e->errstr};
  $e->error('error 2');
  is $e->errstr, 'error 1, error 2', q{$e->errstr, 'error 1, error 2'};
  ok my @error= $e->errstr, q{my @error= $e->errstr};
  is $e->stash('error'), join(', ', @error), q{$e->stash('error'), join(', ', @error)};

can_ok $e, '_import';
can_ok $e, '_startup';
can_ok $e, '_setup_comp';
can_ok $e, '_setup';
can_ok $e, '_prepare';
can_ok $e, '_dispatch';
can_ok $e, '_action_start';
can_ok $e, '_action_end';
can_ok $e, '_finalize';
can_ok $e, '_finalize_error';
can_ok $e, '_output';
can_ok $e, '_finish';
can_ok $e, '_result';
