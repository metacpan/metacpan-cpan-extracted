use strict;
use warnings;
use Test::Identity;
use Test::More;
use Test::Needs;
use Future::Mojo;
use Mojo::IOLoop;
use Role::Tiny ();

my $loop = Mojo::IOLoop->new;

my $f = Future::Mojo->new($loop)->done('Success', 'extra', 'args');
my @results;
my $p = $f->promisify;
ok $p->isa('Mojo::Promise'), 'returned a Mojo::Promise';
my $t = $p->ioloop->timer(0.1 => sub { $p->ioloop->stop });
$p->then(sub { @results = @_ })->wait;
$p->ioloop->remove($t);
is_deeply \@results, ['Success', 'extra', 'args'], 'success';

$f = Future::Mojo->new($loop)->fail('Failure', 'extra', 'args');
my @failure;
$p = $f->promisify;
$t = $p->ioloop->timer(0.1 => sub { $p->ioloop->stop });
$p->catch(sub { @failure = @_ })->wait;
$p->ioloop->remove($t);
is_deeply \@failure, ['Failure', 'extra', 'args'], 'failure';

$f = Future::Mojo->new($loop);
$p = $f->promisify;
$loop->timer(0.1 => sub { $f->done('Delayed') });
$t = $p->ioloop->timer(0.5 => sub { $p->ioloop->stop });
$p->then(sub { @results = @_ })->wait;
$p->ioloop->remove($t);
is_deeply \@results, ['Delayed'], 'delayed success';

$f = Future::Mojo->new($loop);
$p = $f->promisify;
$loop->timer(0.1 => sub { $f->fail('Delayed') });
$t = $p->ioloop->timer(0.5 => sub { $p->ioloop->stop });
$p->catch(sub { @failure = @_ })->wait;
$p->ioloop->remove($t);
is_deeply \@failure, ['Delayed'], 'delayed failure';

$f = Future::Mojo->new;
$p = $f->promisify;
Mojo::IOLoop->timer(0.1 => sub { $f->done('Singleton') });
$t = $p->ioloop->timer(0.5 => sub { $p->ioloop->stop });
$p->then(sub { @results = @_ })->wait;
$p->ioloop->remove($t);
is_deeply \@results, ['Singleton'], 'singleton success';

$p = Mojo::Promise->new;
$f = Future::Mojo->new;
identical $p, $f->promisify($p), 'promise passed through';
Mojo::IOLoop->timer(0.1 => sub { $f->done('Passthrough') });
$t = $p->ioloop->timer(0.5 => sub { $p->ioloop->stop });
$p->then(sub { @results = @_ })->wait;
$p->ioloop->remove($t);
is_deeply \@results, ['Passthrough'], 'passthrough success';

subtest 'IO::Async::Loop::Mojo' => sub {
  test_needs { 'IO::Async::Loop' => '0.56', 'IO::Async::Loop::Mojo' => '0.04' };

  my $loop = IO::Async::Loop->new;
  my $f = $loop->new_future->done('Immediate');
  Role::Tiny->apply_roles_to_object($f, 'Future::Role::Promisify');
  my $p = $f->promisify;
  my $t = $p->ioloop->timer(0.1 => sub { $p->ioloop->stop });
  $p->then(sub { @results = @_ })->wait;
  $p->ioloop->remove($t);
  is_deeply \@results, ['Immediate'], 'immediate success with arbitrary IO::Async::Loop';

  $f = $loop->new_future->fail('Immediate');
  Role::Tiny->apply_roles_to_object($f, 'Future::Role::Promisify');
  $p = $f->promisify;
  $t = $p->ioloop->timer(0.1 => sub { $p->ioloop->stop });
  $p->catch(sub { @failure = @_ })->wait;
  $p->ioloop->remove($t);
  is_deeply \@failure, ['Immediate'], 'immediate failure with arbitrary IO::Async::Loop';

  $loop = IO::Async::Loop::Mojo->new;
  $f = $loop->delay_future(after => 0.1);
  Role::Tiny->apply_roles_to_object($f, 'Future::Role::Promisify');
  $p = $f->promisify;
  $t = $p->ioloop->timer(0.5 => sub { $p->ioloop->stop });
  my $completed;
  $p->then(sub { $completed++ })->wait;
  $p->ioloop->remove($t);
  is $completed, 1, 'success with IO::Async::Loop::Mojo singleton';

  $f = $loop->timeout_future(after => 0.1);
  Role::Tiny->apply_roles_to_object($f, 'Future::Role::Promisify');
  $p = $f->promisify;
  $t = $p->ioloop->timer(0.5 => sub { $p->ioloop->stop });
  my $failed;
  $p->catch(sub { $failed++ })->wait;
  $p->ioloop->remove($t);
  is $failed, 1, 'failure with IO::Async::Loop::Mojo singleton';

  done_testing;
};

done_testing;
