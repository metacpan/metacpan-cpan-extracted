package Doodle::Migrator;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

use Carp;
use Data::Object::Space;
use Doodle;

our $VERSION = '0.04'; # VERSION

# METHODS

method namespace() {
  # this method could be overwritten

  return ref $self;
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

1;

=encoding utf8

=head1 NAME

Doodle::Migrator

=cut

=head1 ABSTRACT

Database Migrator Class

=cut

=head1 SYNOPSIS

  # in lib/My/Migrator.pm

  package My::Migrator;

  use parent 'Doodle::Migrator';

  sub namespace {
    return 'My::Migration';
  }

  # in lib/My/Migration/Step1.pm

  package My::Migration::Step1;

  use parent 'Doodle::Migration';

  sub up {
    my ($self, $doodle) = @_;

    # add something ...

    return $doodle;
  }

  sub down {
    my ($self, $doodle) = @_;

    # subtract something ...

    return $doodle;
  }

  # in script

  package main;

  my $migrator = My::Migrator->new;

  my $results = $migrator->migrate('up', 'sqlite', sub {
    my ($sql) = @_;

    # e.g. $dbi->do($_) for @$sql;

    return 1;
  });

  1;

=cut

=head1 DESCRIPTION

This package provides a migrator class which collects the specified
L<Doodle::Migration> classes and processes them.

=cut

=head1 METHODS

This package implements the following methods.

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

  migrations() : [Object]

The migrations method find and loads child objects under the C<namespace> and
returns a set of L<Data::Object::Space> objects representing classes that have
subclassed the L<Doodle::Migration> base class.

=over 4

=item migrations example

  my $migrations = $self->migrations();

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
