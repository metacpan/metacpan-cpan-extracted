package Data::Object::Try;

use 5.014;

use strict;
use warnings;

use Moo;
use Try::Tiny ();

our $VERSION = '1.85'; # VERSION

has invocant => (
  is => 'ro',
);

has arguments => (
  is => 'ro',
);

has on_try => (
  is => 'rw',
);

has on_catch => (
  is => 'rw',
);

has on_default => (
  is => 'rw',
);

has on_finally => (
  is => 'rw',
);

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  $self->{'on_catch'} = [] if !$args->{'on_catch'};

  return $args;
}

# METHODS

sub call {
  my ($self, $callback) = @_;

  $self->on_try($self->callback($callback));

  return $self;
}

sub catch {
  my ($self, $class, $callback) = @_;

  push @{$self->on_catch}, [$class, $self->callback($callback)];

  return $self;
}

sub default {
  my ($self, $callback) = @_;

  $self->on_default($self->callback($callback));

  return $self;
}

sub finally {
  my ($self, $callback) = @_;

  $self->on_finally($self->callback($callback));

  return $self;
}

sub maybe {
  my ($self) = @_;

  $self->on_default(sub{''});

  return $self;
}

sub result {
  my ($self, @args) = @_;

  my $returned;

  Try::Tiny::try(sub {
    my $tryer = $self->on_try;

    $returned = $self->execute($tryer, @args);
  }, Try::Tiny::catch(sub {
    my $caught = $_;
    my $catchers = $self->on_catch;
    my $default = $self->on_default;

    for my $catcher (@$catchers) {
      if (UNIVERSAL::isa($caught, $catcher->[0])) {
        $returned = $catcher->[1]->($caught);
        last;
      }
    }

    if(!$returned) {
      $returned = $default->($caught) if $default;
      die $caught if not defined $returned;
    }
  }, Try::Tiny::finally(sub {
    my $finally = $self->on_finally;

    $self->execute($finally, @args) if $finally;
  })));

  return $returned;
}

sub execute {
  my ($self, $callback, @args) = @_;

  if ($self->invocant) {
    unshift @args, $self->invocant;
  }

  if ($self->arguments && @{$self->arguments}) {
    unshift @args, @{$self->arguments};
  }

  return $callback->(@args);
}

sub callback {
  my ($self, $callback) = @_;

  unless (UNIVERSAL::isa($callback, 'CODE')) {
    my $method = $self->invocant
      ? $self->invocant->can($callback) : $self->can($callback);
    die sprintf(qq(Can't locate object method "%s" on package "%s"), (
        $callback, ref $self
    )) if !$method;
    $callback = sub { goto $method };
  }

  return $callback;
}

sub no_try {
  my ($self) = @_;

  $self->on_try(undef);

  return $self;
}

sub no_catch {
  my ($self) = @_;

  $self->on_catch([]);

  return $self;
}

sub no_default {
  my ($self) = @_;

  $self->on_default(undef);

  return $self;
}

sub no_finally {
  my ($self) = @_;

  $self->on_finally(undef);

  return $self;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Try

=cut

=head1 ABSTRACT

Data-Object Try/Catch Class

=cut

=head1 SYNOPSIS

  use Data::Object::Try;

  my $try = Data::Object::Try->new;

  $try->call(fun (@args) {
    # try something

    return something
  });

  $try->catch($type, fun ($caught) {
    # caught an exception

    return $something;
  });

  $try->default(fun ($caught) {
    # catch the uncaught

    return $something;
  });

  $try->finally(fun (@args) {
    # always run after try/catch
  });

  my $result = $try->result(@args);

=cut

=head1 DESCRIPTION

This package provides an object-oriented interface for performing complex
try/catch operations.

=cut

=head1 ATTRIBUTES

This package has the following attributes.

=cut

=head2 invocant

  invocant(Object)

The attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head2 arguments

  arguments(ArrayRef)

The attribute is read-only, accepts C<(ArrayRef)> values, and is optional.

=cut

=head2 on_try

  on_try(CodeRef)

The attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_catch

  on_catch(ArrayRef[CodeRef])

The attribute is read-only, accepts C<(ArrayRef[CodeRef])> values, and is optional.

=cut

=head2 on_default

  on_default(CodeRef)

The attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 on_finally

  on_finally(CodeRef)

The attribute is read-only, accepts C<(CodeRef)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 call

  call(Str | CodeRef $method) : Object

The call method takes a method name or coderef, registers it as the tryable
routine, and returns the object. When invoked, the callback will received an
C<invocant> if one was provided to the constructor, the default C<arguments> if
any were provided to the constructor, and whatever arguments were provided by
the invocant.

=over 4

=item call example

  $try = $try->call($method);
  $try = $try->call(fun (@args) {
    # do something
  });

=back

=cut

=head2 callback

  callback(Str | CodeRef) : CodeRef

The callback method takes a method name or coderef, and returns a coderef for
registration. If a coderef is provided this method is mostly a passthrough.

=over 4

=item callback example

  my $callback;

  $callback = $try->callback($method);
  $callback = $try->callback(fun (@args) {
    # do something
  });

=back

=cut

=head2 catch

  catch(Str $isa, Str | CodeRef $callback) : Any

The catch method takes a package or ref name, and when triggered checks whether
the captured exception is of the type specified and if so executes the given
callback.

=over 4

=item catch example

  $try = $try->catch('Error::HTTP400', fun ($caught) {
    # do something
  });

  $try = $try->catch('Error::HTTP401', fun ($caught) {
    # do something
  });

=back

=cut

=head2 default

  default(Str | CodeRef $callback) : Object

The default method takes a method name or coderef and is triggered if no
C<catch> conditions match the exception thrown.

=over 4

=item default example

  $try = $try->default(fun ($caught) {
    # do something
  });

=back

=cut

=head2 execute

  execute(CodeRef $callback, Any @args) : Any

The execute method takes a coderef and executes it with any given arguments.
When invoked, the callback will received an C<invocant> if one was provided to
the constructor, the default C<arguments> if any were provided to the
constructor, and whatever arguments were passed directly to this method.

=over 4

=item execute example

  my $result = $try->execute($callback, @args);

=back

=cut

=head2 finally

  finally(Str | CodeRef $callback) : Object

The finally method takes a package or ref name and always executes the callback
after a try/catch operation. The return value is ignored. When invoked, the
callback will received an C<invocant> if one was provided to the constructor,
the default C<arguments> if any were provided to the constructor, and whatever
arguments were provided by the invocant.

=over 4

=item finally example

  $try = $try->finally(fun (@args) {
    # always do something
  });

=back

=cut

=head2 maybe

  maybe() : Object

The maybe method registers a default C<catch> condition that returns an falsy,
i.e. an empty string, if an exception is encountered.

=over 4

=item maybe example

  $try = $try->maybe;

=back

=cut

=head2 no_catch

  no_catch() : Object

The no_catch method removes any configured catch conditions and returns the
object.

=over 4

=item no_catch example

  $try = $try->no_catch;

=back

=cut

=head2 no_default

  no_default() : Object

The no_default method removes any configured default condition and returns the
object.

=over 4

=item no_default example

  $try = $try->no_default;

=back

=cut

=head2 no_finally

  no_finally() : Object

The no_finally method removes any configured finally condition and returns the
object.

=over 4

=item no_finally example

  $try = $try->no_finally;

=back

=cut

=head2 no_try

  no_try() : Object

The no_try method removes any configured "try" operation and returns the
object.

=over 4

=item no_try example

  $try = $try->no_try;

=back

=cut

=head2 result

  result(Any @args) : Any

The result method executes the try/catch/default/finally logic and returns
either 1) the return value from the successfully tried operation 2) the return
value from the successfully matched catch condition if an exception was thrown
3) the return value from the default catch condition if an exception was thrown
and no catch condition matched. When invoked, the C<try> and C<finally>
callbacks will received an C<invocant> if one was provided to the constructor,
the default C<arguments> if any were provided to the constructor, and whatever
arguments were passed directly to this method.

=over 4

=item result example

  my $result = $try->result(@args);

=back

=cut

=head1 CREDITS

Al Newkirk, C<+309>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

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