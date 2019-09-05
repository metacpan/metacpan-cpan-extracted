package Data::Object::Exception;

use 5.014;

use strict;
use warnings;

use overload (
  '""'     => 'data',
  '~~'     => 'data',
  fallback => 1
);

our $VERSION = '1.50'; # VERSION

# BUILD

sub new {
  my ($class, @args) = @_;

  my %args;
  my $data = {};
  my $self = bless $data, $class;

  %args = @args == 1
    ? !ref($args[0])
      # single non-ref argument
      ? (message => $args[0])
      : %{$args[0]}
    : @args;

  for my $attr (qw(message context)) {
    $self->{$attr} = $args{$attr} if exists $args{$attr};
  }

  return $self;
}

# METHODS

sub data {
  my ($self) = @_;

  $self->trace(1, 1) if !$self->{frames};

  my $frames = $self->{frames};

  my $file = $frames->[0][1];
  my $line = $frames->[0][2];
  my $pack = $frames->[0][0];
  my $subr = $frames->[0][3];

  my $message = $self->{message} || 'Exception!';

  my @stacktrace = ("$message in $file at line $line");

  for (my $i = 1; $i < @$frames; $i++) {
    my $pack = $frames->[$i][0];
    my $file = $frames->[$i][1];
    my $line = $frames->[$i][2];
    my $subr = $frames->[$i][3];

    push @stacktrace, "\t$subr in $file at line $line";
  }

  return join "\n", @stacktrace, "";
}

sub throw {
  my ($self, $message, $context) = @_;

  if (ref $self) {
    $message ||= $self->{message};
    $context ||= $self->{context};

    $self = ref $self;
  }

  my $exception = $self->new(message => $message, context => $context);

  die $exception->trace;
}

sub trace {
  my ($self, $offset, $limit) = @_;

  $self->{frames} = my $frames = [];

  for (my $i = $offset // 1; my @caller = caller($i); $i++) {
    push @$frames, [@caller];

    last if defined $limit && $i + 1 == $offset + $limit;
  }

  return $self;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Exception

=cut

=head1 ABSTRACT

Data-Object Exception Class

=cut

=head1 SYNOPSIS

  use Data::Object::Exception;

  my $exception = Data::Object::Exception->new;

  die $exception;

  $exception->throw('Oops');

  die $exception->new('Oops')->trace(0);

  "$exception" # renders exception message

=cut

=head1 DESCRIPTION

This package provides functionality for creating, throwing, and introspecting
exception objects.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 data

  data() : Any

Render the exception message with optional context and stack trace.

=over 4

=item data example

  my $data = $exception->data();

=back

=cut

=head2 new

  new(HashRef $arg1) : ExceptionObject

The new method expects a message, or named arguments, and returns a new class
instance.

=over 4

=item new example

  # Oops

  my $exception = Data::Object::Exception->new(
    message => 'Oops'
  });

=back

=cut

=head2 throw

  throw(Str $arg1) : Object

Throw error with message and context.

=over 4

=item throw example

  $exception->throw();

=back

=cut

=head2 trace

  trace(Int $offset, $Int $limit) : ExceptionObject

The trace method compiles a stack trace and returns the object. By default it
skips the first frame.

=over 4

=item trace example

  # $exception

  my $trace = $exception->trace;
  my $trace = $exception->trace(0); # all frames
  my $trace = $exception->trace(0, 5); # five frames, no skip

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<On GitHub|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut