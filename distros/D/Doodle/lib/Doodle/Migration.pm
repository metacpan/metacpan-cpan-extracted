package Doodle::Migration;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

use Carp;
use Data::Object::Space;
use Doodle;

our $VERSION = '0.05'; # VERSION

# METHODS

method down(Doodle $d) {
  # this class is meant to be overwritten

  confess("This method is meant to be overwritten by the subclass");
}

method migrate(Str $updn, Str $grammar, CodeRef $callback) {
  my $results = [];

  my $statements = $self->statements($grammar);

  $statements = [reverse(@$statements)] if $updn eq 'down';

  for my $set (@$statements) {
    my $up_set = $set->[0];
    my $dn_set = $set->[1];

    push @$results, $callback->($updn eq 'up' ? $up_set : $dn_set);
  }

  return $results;
}

method migrations() {
  my $migrations = [];

  my $namespace = $self->namespace;

  my $space = Data::Object::Space->new($namespace);

  for my $item (sort { $a->name cmp $b->name } @{$space->children}) {
    my $class = eval { $item->load };

    next if !$class;
    next if !$class->isa('Doodle::Migration');

    push @$migrations, $item->name;
  }

  return $migrations;
}

method namespace() {
  # this method could be overwritten

  return ref $self;
}

method statements(Str $grammar) {
  my $statements = [];

  my $doodle = Doodle->new;
  my $migrations = $self->migrations;
  my $handler = $doodle->grammar($grammar);

  for my $migration (@$migrations) {
    my $object = $migration->new;

    my $up_object = $object->up(Doodle->new);
    my $dn_object = $object->down(Doodle->new);

    my $up_statements = $up_object->statements($handler);
    my $dn_statements = $dn_object->statements($handler);

    push @$statements, [
      [map { $_->sql } @{$up_statements}],
      [map { $_->sql } @{$dn_statements}]
    ];
  }

  return $statements;
}

method up(Doodle $d) {
  # this class is meant to be overwritten

  confess("This method is meant to be overwritten by the subclass");
}

1;

=encoding utf8

=head1 NAME

Doodle::Migration

=cut

=head1 ABSTRACT

Database Migration Class

=cut

=head1 SYNOPSIS

  # in lib/My/Migration.pm

  package My::Migration;

  use parent 'Doodle::Migration';

  # in lib/My/Migration/Step1.pm

  package My::Migration::Step1;

  use parent 'Doodle::Migration';

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

  package My::Migration::Step2;

  use parent 'Doodle::Migration';

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

  # in script

  package main;

  my $migrator = My::Migration->new;

  my $results = $migrator->migrate('up', 'sqlite', sub {
    my ($sql) = @_;

    # e.g. $dbi->do($_) for @$sql;

    return 1;
  });

  1;

=cut

=head1 DESCRIPTION

This package provides a migrator class and migration base class in one package.
The C<migrations> method loads and collects the classes that exists as children
of the namespace returned by the C<namespace> method (which defaults to the
current class) and returns the class names as an array-reference.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 down

  down(Doodle $doodle) : Doodle

The migrate "DOWN" method is invoked automatically by the migrator
L<Doodle::Migrator>.

=over 4

=item down example

  $doodle = $self->down($doodle);

=back

=cut

=head2 migrate

  migrate(Str $updn, Str $grammar, CodeRef $callback) : [Any]

The migrate method collects all processed statements and iterates over the "UP"
or "DOWN" SQL statements, passing the set of SQL statements to the supplied
callback with each iteration.

=over 4

=item migrate example

  my $migrate = $self->migrate('up', 'sqlite', sub {
    my ($sql) = @_;

    # do something ...

    return 1;
  });

=back

=cut

=head2 migrations

  migrations() : [Str]

The migrations method finds and loads child objects under the C<namespace> and
returns an array-reference which contains class names that have subclassed the
L<Doodle::Migration> base class.

=over 4

=item migrations example

  my $migrations = $self->migrations;

=back

=cut

=head2 namespace

  namespace() : Str

The namespace method returns the root namespace where all child
L<Doodle::Migration> classes can be found.

=over 4

=item namespace example

  my $namespace = $self->namespace();

=back

=cut

=head2 statements

  statements(Str $grammar) : [[[Str],[Str]]]

The statements method loads and processes the migrations using the grammar
specified. This method returns a set of migrations, each containing a set of
"UP" and "DOWN" sets of SQL statements.

=over 4

=item statements example

  my $statements = $self->statements('sqlite');

=back

=cut

=head2 up

  up(Doodle $doodle) : Doodle

The migrate "UP" method is invoked automatically by the migrator
L<Doodle::Migrator>.

=over 4

=item up example

  $doodle = $self->up($doodle);

=back

=cut
