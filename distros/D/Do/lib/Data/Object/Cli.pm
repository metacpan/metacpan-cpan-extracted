package Data::Object::Cli;

use 5.014;

use strict;
use warnings;

use Moo;

use Data::Object::Args;
use Data::Object::Data;
use Data::Object::Opts;
use Data::Object::Vars;

our $VERSION = '1.80'; # VERSION

has args => (
  is => 'ro',
  builder => 'BUILD_ARGS',
  lazy => 1
);

has data => (
  is => 'ro',
  builder => 'BUILD_DATA',
  lazy => 1
);

has opts => (
  is => 'ro',
  builder => 'BUILD_OPTS',
  lazy => 1
);

has vars => (
  is => 'ro',
  builder => 'BUILD_VARS',
  lazy => 1
);

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  return $self; # noop
}

sub BUILD_ARGS {
  my ($self) = @_;

  my $sign = $self->sign;

  return Data::Object::Args->new(named => $sign);
}

sub BUILD_DATA {
  my ($self) = @_;

  return Data::Object::Data->new(from => ref $self);
}

sub BUILD_OPTS {
  my ($self) = @_;

  my $spec = $self->spec;

  $self->{opts} = Data::Object::Opts->new(spec => $spec);
}

sub BUILD_VARS {
  my ($self) = @_;

  return Data::Object::Vars->new;
}

# METHODS

sub main {
  shift
}

sub help {
  my ($self) = @_;

  my $data = $self->data;
  my $help = $data->content('help');

  return $help;
}

sub okay {
  my ($self, $handler, @args) = @_;

  return $self->exit(0, $handler, @args);
}

sub fail {
  my ($self, $handler, @args) = @_;

  return $self->exit(1, $handler, @args);
}

sub exit {
  my ($self, $code, $handler, @args) = @_;

  $self->handle($handler, @args) if $handler;

  exit $code;
}

sub run {
  my ($class, @args) = @_;

  unless (caller(1)) {
    my $self = $class->new(@args);

    return $self->handle('main');
  }

  return time;
}

sub handle {
  my ($self, $method, %args) = @_;

  my %meta;

  $meta{args} = $self->args;
  $meta{data} = $self->data;
  $meta{opts} = $self->opts;
  $meta{vars} = $self->vars;

  return $self->$method(%meta, %args);
}

sub spec {
  my ($self) = @_;

  my $data = $self->data;
  my $spec = $data->content('spec');

  return [] if !$spec || !@$spec;

  return [split /,\s*/, join ', ', @$spec];
}

sub sign {
  my ($self) = @_;

  my $data = $self->data;
  my $sign = $data->content('sign');

  return {} if !$sign || !@$sign;

  my $indx = 0;
  my $regx = qr/\{(\w+)\}/;

  return {map +($_, $indx++), join('', @$sign) =~ m/$regx/g};
}

1;

=encoding utf8

=head1 NAME

Data::Object::Cli

=cut

=head1 ABSTRACT

Data-Object CLI Base Class

=cut

=head1 SYNOPSIS

  package Command;

  use Data::Object 'Class';

  extends 'Data::Object::Cli';

  method main() {
    say $self->help->list;
  }

  run Command;

  __DATA__

  =pod help

  Do something!

  =pod sign

  {command}

  =pod spec

  action=s, verbose|v

  =cut

=cut

=head1 DESCRIPTION

This package provides an abstract base class for defining command-line
interface classes, which can be run as scripts or passed as objects in a more
complex system.

=cut

=head1 ATTRIBUTES

This package has the following attributes.

=cut

=head2 args

  args(ArgsObject)

The attribute is read-only, accepts C<(ArgsObject)> values, and is optional.

=cut

=head2 data

  data(DataObject)

The attribute is read-only, accepts C<(DataObject)> values, and is optional.

=cut

=head2 opts

  opts(OptsObject)

The attribute is read-only, accepts C<(OptsObject)> values, and is optional.

=cut

=head2 vars

  vars(VarsObject)

The attribute is read-only, accepts C<(VarsObject)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 exit

  exit(Int $code, Maybe[Str] $name, Any %args) : ()

The exit method exits the program using the exit code provided. The exit code
defaults to C<0>. Optionally, you can call a handler before exiting by
providing a method name with arguments. The handler will be called using the
C<handle> method so the arguments should be key/value pairs.

=over 4

=item exit example

  $self->exit(0);
  $self->exit(1);

  $self->exit($code, $method_name, %args);
  $self->exit($code, $method_name);
  $self->exit($code);

=back

=cut

=head2 fail

  fail(Maybe[Str] $name, Any %args) : ()

The fail method exits the program with a C<1> exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the C<handle> method so the arguments should be
key/value pairs.

=over 4

=item fail example

  $self->fail;

  $self->fail($method_name, %args);
  $self->fail($method_name);

=back

=cut

=head2 handle

  handle(Str $name, Any %args) : Any

The handle method dispatches to the method whose name is provided as the first
argument. The forwarded method will receive arguments as key/value pairs. This
method injects the C<args>, C<data>, C<vars>, and C<opts> attributes as
arguments for convenience of use in the forwarded method. Any additional
arguments should be passed as key/value pairs.

=over 4

=item handle example

  $self->handle($method_name, %args);
  $self->handle($method_name);

=back

=cut

=head2 help

  help() : ArrayRef[Str]

The help method returns the help text documented in POD if available.

=over 4

=item help example

  =pod help

  ...

  =cut

  my $help = $self->help

=back

=cut

=head2 main

  main(Any %args) : Any

The main method is the "main method" and entrypoint into the program. It's
called automatically by the C<run> method if your package is configured as
recommended. This method accepts arguments as key/value pairs, and if called by
C<run> will receive the C<args>, C<data>, C<opts>, and C<vars> objects.

=over 4

=item main example

  # $args{args} = $self->args; # represents @ARGV
  # $args{data} = $self->data; # represents __DATA__
  # $args{opts} = $self->opts; # represents Getopt::Long
  # $args{vars} = $self->vars; # represents %ENV

  $self->main(%args)

=back

=cut

=head2 okay

  okay(Maybe[Str] $name, Any %args) : ()

The okay method exits the program with a C<0> exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the C<handle> method so the arguments should be
key/value pairs.

=over 4

=item okay example

  $self->okay;

  $self->okay($method_name, %args);
  $self->okay($method_name);

=back

=cut

=head2 run

  run() : Any

The run method is designed to bootstrap the program. It detects whether the
package is being invoked as a script or class and behaves accordingly. It will
be called automatically when the package is looaded if your package is
configured as recommended. This method will, if invoked as a script, call the
C<main> method passing the C<args>, C<data>, C<opts>, and C<vars> objects.

=over 4

=item run example

  run __PACKAGE__;

=back

=cut

=head2 sign

  sign() : HashRef[Int]

The sign method returns an hashref of named C<@ARGV> positional arguments.
These named arguments are accessible as methods on the L<Data::Object::Args>
object through the C<args> attribute.

=over 4

=item sign example

  =pod sign

  {command} {action}

  =cut

  $self->sign;

  # using the arguments

  $self->args->command; # $ARGV[0]
  $self->args->action; # $ARGV[1]

  $self->args->command($new_command);
  $self->args->action($new_action);

=back

=cut

=head2 spec

  spec() : ArrayRef[Str]

The spec method returns an arrayref of L<Getopt::Long> option specs. By
default, this package look for those specs as a comma-separated list in the POD
section named "spec", short for "options specifications". These options are
accessible as methods on the L<Data::Object::Opts> object through the C<opts>
attribute.

=over 4

=item spec example

  =pod spec

  resource|r=s, verbose|v, help|h

  =cut

  $self->spec;

  # using the options

  $self->opts->resource;
  $self->opts->verbose;

  $self->opts->resource($new_resource);
  $self->opts->verbose(0);

=back

=cut

=head1 CREDITS

Al Newkirk, C<+303>

Anthony Brummett, C<+10>

Adam Hopkins, C<+1>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/do/wiki>

L<Project|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Milestones|https://github.com/iamalnewkirk/do/milestones>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Issues|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Do>

L<Data::Object>

L<Data::Object::Class>

L<Data::Object::ClassHas>

L<Data::Object::Role>

L<Data::Object::RoleHas>

L<Data::Object::Library>

=cut