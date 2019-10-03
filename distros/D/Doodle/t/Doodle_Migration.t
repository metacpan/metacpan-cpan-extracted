use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Migration

=cut

=abstract

Database Migration Class

=cut

=includes

method: down
method: migrate
method: migrations
method: namespace
method: statements
method: up

=cut

=synopsis

  # in lib/Migration.pm

  package Migration;

  use parent 'Doodle::Migration';

  # in lib/My/Migration/Step1.pm

  package Migration::Step1;

  use parent 'Doodle::Migration';

  no warnings 'redefine';

  sub up {
    my ($self, $doodle) = @_;

    my $users = $doodle->table('users');
    $users->primary('id');
    $users->string('email');
    $users->create;
    $users->index(columns => ['email'])->unique->create;

    return $doodle;
  }

  sub down {
    my ($self, $doodle) = @_;

    my $users = $doodle->table('users');
    $users->delete;

    return $doodle;
  }

  # in lib/My/Migration/Step2.pm

  package Migration::Step2;

  use parent 'Doodle::Migration';

  no warnings 'redefine';

  sub up {
    my ($self, $doodle) = @_;

    my $users = $doodle->table('users');
    $users->string('first_name')->create;
    $users->string('last_name')->create;

    return $doodle;
  }

  sub down {
    my ($self, $doodle) = @_;

    my $users = $doodle->table('users');
    $users->string('first_name')->delete;
    $users->string('last_name')->delete;

    return $doodle;
  }

  # elsewhere

  package main;

  my $self = Migration->new;

  my $results = $self->migrate('up', 'sqlite', sub {
    my ($sql) = @_;

    # e.g. $dbi->do($_) for @$sql;

    return 1;
  });

  1;

=cut

=description

This package provides a migrator class and migration base class in one package.
The C<migrations> method loads and collects the classes that exists as children
of the namespace returned by the C<namespace> method (which defaults to the
current class) and returns the class names as an array-reference.

=cut

=libraries

Doodle::Library

=cut

=method down

The migrate "DOWN" method is invoked automatically by the migrator
L<Doodle::Migrator>.

=cut

=signature down

down(Doodle $doodle) : Doodle

=cut

=example-1 down

  # given: synopsis

  my $doodle = Doodle->new;

  $doodle = $self->down($doodle);

=cut

=method migrate

The migrate method collects all processed statements and iterates over the "UP"
or "DOWN" SQL statements, passing the set of SQL statements to the supplied
callback with each iteration.

=cut

=signature migrate

migrate(Str $updn, Str $grammar, CodeRef $callback) : Any

=cut

=example-1 migrate

  # given: synopsis

  my $migrate = $self->migrate('up', 'sqlite', sub {
    my ($sql) = @_;

    # do something ...

    return 1;
  });

=cut

=method migrations

The migrations method finds and loads child objects under the C<namespace> and
returns an array-reference which contains class names that have subclassed the
L<Doodle::Migration> base class.

=cut

=signature migrations

migrations() : ArrayRef[Str]

=cut

=example-1 migrations

  # given: synopsis

  my $doodle = Doodle->new;

  my $migrations = $self->migrations;

=cut

=method namespace

The namespace method returns the root namespace where all child
L<Doodle::Migration> classes can be found.

=cut

=signature namespace

namespace() : Str

=cut

=example-1 namespace

  # given: synopsis

  my $namespace = $self->namespace;

=cut

=method statements

The statements method loads and processes the migrations using the grammar
specified. This method returns a set of migrations, each containing a set of
"UP" and "DOWN" sets of SQL statements.

=cut

=signature statements

statements(Str $grammar) : ArrayRef[Tuple[ArrayRef[Str], ArrayRef[Str]]]

=cut

=example-1 statements

  # given: synopsis

  my $statements = $self->statements('sqlite');

=cut

=method up

The migrate "UP" method is invoked automatically by the migrator
L<Doodle::Migrator>.

=cut

=signature up

up(Doodle $doodle) : Doodle

=cut

=example-1 up

  # given: synopsis

  my $doodle = Doodle->new;

  $doodle = $self->up($doodle);

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->example(-1, 'down', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/meant to be overwritten by the subclass/, 'exception thrown';

  # force return doodle object
  Doodle->new;
});

$subtests->example(-1, 'migrate', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'migrations', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'namespace', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'statements', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'up', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/meant to be overwritten by the subclass/, 'exception thrown';

  # force return doodle object
  Doodle->new;
});

ok 1 and done_testing;
