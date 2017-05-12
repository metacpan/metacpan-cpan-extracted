use Test::More tests => 40;
use lib qw( ../lib ./lib );
use Egg::Helper;

$ENV{VTEST_DISPATCH_CLASS}= 'Egg::Dispatch::Fast';

my $e= Egg::Helper->run('Vtest');

can_ok $e, 'dispatch_map';
  ok $e->dispatch_map(
    _default => sub {},
    test1    => sub { $_[1]->{flag}{test1}= 1 },
    test2    => sub { $_[0]->finished(403) },
    test3    => sub { $_[0]->template('test3.tt') },
    ), q{$e->dispatch_map( .......... };

can_ok $e, '_dispatch_map';
  is $e->_dispatch_map, $e->dispatch_map, q{$e->_dispatch_map, $e->dispatch_map};
  ok my $map= $e->dispatch_map, q{my $map= $e->dispatch_map};

ok $map->{_default}, q{$map->{_default}};
isa_ok $map->{_default}, 'CODE';
ok $map->{test1}, q{$map->{test1}};
isa_ok $map->{test1}, 'CODE';
ok $map->{test2}, q{$map->{test2}};
isa_ok $map->{test2}, 'CODE';
ok $map->{test3}, q{$map->{test3}};
isa_ok $map->{test3}, 'CODE';

can_ok $e, 'dispatch';
 ok my $dispatch= $e->dispatch, q{my $dispatch= $e->dispatch};
 isa_ok $dispatch, 'Egg::Dispatch::Fast::handler';

my($d, $flag);
my $reset= sub {
  $d= Egg::Dispatch::Fast::handler->new($e);
  $flag= $d->{flag}= {};
  };

$reset->();
ok $d->_start,    q{$d->_start};
ok $d->_action,   q{$d->_action};
ok @{$d->action}, q{@{$d->action}};
is join('/', @{$d->action}), 'index', q{join('/', @{$d->action}), 'index'};
ok $d->_finish,   q{$d->_finish};

$reset->();
ok $d->mode('test1'), q{$d->mode('test1')};
ok $d->_start,        q{$d->_start};
ok $d->_action,       q{$d->_action};
ok $flag->{test1},    q{$flag->{test1}};
ok @{$d->action},     q{@{$d->action}};
is join('/', @{$d->action}), 'test1', q{join('/', @{$d->action}), 'test1'};

$reset->();
ok $d->mode('test2'), q{$d->mode('test2')};
ok $d->_start,        q{$d->_start};
ok $d->_action,       q{$d->_action};
ok $e->finished,      q{$e->finished};
ok $e->response->status, q{$e->response->status};
is $e->response->status, 403, q{$e->response->status, 403};
ok @{$d->action},     q{@{$d->action}};
is join('/', @{$d->action}), 'test2', q{join('/', @{$d->action}), 'test2'};

$reset->();
ok $d->mode('test3'), q{$d->mode('test3')};
ok $d->_start,        q{$d->_start};
ok $d->_action,       q{$d->_action};
ok $e->template,      q{$e->template};
is $e->template, 'test3.tt', q{$e->template, 'test3.tt'};
