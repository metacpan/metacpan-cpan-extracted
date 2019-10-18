package Data::Object::ClassHas;

use 5.014;

use strict;
use warnings;

use Data::Object::Utility;

our $VERSION = '1.88'; # VERSION

# BUILD

sub import {
  my ($class, @args) = @_;

  my $target = caller;

  my $has = $target->can('has') or return;

  no strict 'refs';
  no warnings 'redefine';

  *{"${target}::has"} = _generate_has([$class, $target], $has);

  return;
}

sub _generate_has {
  my ($info, $orig) = @_;

  return sub { @_ = _formulate_opts($info, @_); goto $orig; };
}

sub _formulate_opts {
  my ($info, $name, %opts) = @_;

  # name-only support
  %opts = (is => 'ro', isa => 'Any') unless %opts;

  %opts = (%opts, _formulate_new($info, $name, %opts)) if $opts{new};
  %opts = (%opts, _formulate_bld($info, $name, %opts)) if $opts{bld};
  %opts = (%opts, _formulate_clr($info, $name, %opts)) if $opts{clr};
  %opts = (%opts, _formulate_crc($info, $name, %opts)) if $opts{crc};
  %opts = (%opts, _formulate_def($info, $name, %opts)) if $opts{def};
  %opts = (%opts, _formulate_hnd($info, $name, %opts)) if $opts{hnd};
  %opts = (%opts, _formulate_isa($info, $name, %opts)) if $opts{isa};
  %opts = (%opts, _formulate_lzy($info, $name, %opts)) if $opts{lzy};
  %opts = (%opts, _formulate_opt($info, $name, %opts)) if $opts{opt};
  %opts = (%opts, _formulate_pre($info, $name, %opts)) if $opts{pre};
  %opts = (%opts, _formulate_rdr($info, $name, %opts)) if $opts{rdr};
  %opts = (%opts, _formulate_req($info, $name, %opts)) if $opts{req};
  %opts = (%opts, _formulate_tgr($info, $name, %opts)) if $opts{tgr};
  %opts = (%opts, _formulate_use($info, $name, %opts)) if $opts{use};
  %opts = (%opts, _formulate_wkr($info, $name, %opts)) if $opts{wkr};
  %opts = (%opts, _formulate_wrt($info, $name, %opts)) if $opts{wrt};

  $name = "+$name" if $opts{mod} || $opts{modify};

  return ($name, %opts);
}

sub _formulate_new {
  my ($info, $name, %opts) = @_;

  if (delete $opts{new}) {
    $opts{builder} = "new_${name}";
    $opts{lazy} = 1;
  }

  return (%opts);
}

sub _formulate_bld {
  my ($info, $name, %opts) = @_;

  $opts{builder} = delete $opts{bld};

  return (%opts);
}

sub _formulate_clr {
  my ($info, $name, %opts) = @_;

  $opts{clearer} = delete $opts{clr};

  return (%opts);
}

sub _formulate_crc {
  my ($info, $name, %opts) = @_;

  $opts{coerce} = delete $opts{crc};

  return (%opts);
}

sub _formulate_def {
  my ($info, $name, %opts) = @_;

  $opts{default} = delete $opts{def};

  return (%opts);
}

sub _formulate_hnd {
  my ($info, $name, %opts) = @_;

  $opts{handles} = delete $opts{hnd};

  return (%opts);
}

sub _formulate_isa {
  my ($info, $name, %opts) = @_;

  return (%opts) if ref($opts{isa});

  $opts{isa} = Data::Object::Utility::Reify($info->[1], $opts{isa});

  return (%opts);
}

sub _formulate_lzy {
  my ($info, $name, %opts) = @_;

  $opts{lazy} = delete $opts{lzy};

  return (%opts);
}

sub _formulate_opt {
  my ($info, $name, %opts) = @_;

  delete $opts{opt};

  $opts{required} = 0;

  return (%opts);
}

sub _formulate_pre {
  my ($info, $name, %opts) = @_;

  $opts{predicate} = delete $opts{pre};

  return (%opts);
}

sub _formulate_rdr {
  my ($info, $name, %opts) = @_;

  $opts{reader} = delete $opts{rdr};

  return (%opts);
}

sub _formulate_req {
  my ($info, $name, %opts) = @_;

  delete $opts{req};

  $opts{required} = 1;

  return (%opts);
}

sub _formulate_tgr {
  my ($info, $name, %opts) = @_;

  $opts{trigger} = delete $opts{tgr};

  return (%opts);
}

sub _formulate_use {
  my ($info, $name, %opts) = @_;

  if (my $use = delete $opts{use}) {
    $opts{builder} = _formulate_use_builder($info, $name, @$use);
    $opts{lazy} = 1;
  }

  return (%opts);
}

sub _formulate_use_builder {
  my ($info, $name, $sub, @args) = @_;

  return sub {
    my ($self) = @_;

    @_ = ($self, @args);

    my $point = $self->can($sub) or do {
      require Carp;
      my $class = $info->[1];
      Carp::croak("has '$name' cannot 'use' method '$sub' via package '$class'");
    };

    goto $point;
  }
}

sub _formulate_wkr {
  my ($info, $name, %opts) = @_;

  $opts{weak_ref} = delete $opts{wkr};

  return (%opts);
}

sub _formulate_wrt {
  my ($info, $name, %opts) = @_;

  $opts{writer} = delete $opts{wrt};

  return (%opts);
}

# METHODS

1;

=encoding utf8

=head1 NAME

Data::Object::ClassHas

=cut

=head1 ABSTRACT

Data-Object Class Attribute Builder

=cut

=head1 SYNOPSIS

  package Point;

  use Data::Object::Class;
  use Data::Object::ClassHas;

  has 'x';
  has 'y';

  1;

=cut

=head1 DESCRIPTION

This package modifies the consuming package with behaviors useful in defining
classes. Specifically, this package wraps the C<has> attribute keyword
functions and adds shortcuts and enhancements.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 EXPORTS

This package automatically exports the following keywords.

=head2 has

  package Person;

  use Data::Object::Class;
  use Data::Object::ClassHas;

  has 'id';

  has fname => (
    is => 'ro',
    isa => 'StrObj',
    crc => 1,
    req => 1
  );

  has lname => (
    is => 'ro',
    isa => 'StrObj',
    crc => 1,
    req => 1
  );

  1;

The C<has> keyword is used to declare class attributes, which can be accessed
and assigned to using the built-in getter/setter or by the object constructor.
See L<Moo> for more information.

=over 4

=item is

  is => 'ro' # read-only
  is => 'rw' # read-write

The C<is> directive is used to denote whether the attribute is read-only or
read-write. See the L<Moo> documentation for more details.

=item isa

  # declare type constraint

  isa => 'StrObject'
  isa => 'ArrayObject'
  isa => 'CodeObject'

The C<isa> directive is used to define the type constraint to validate the
attribute against. See the L<Moo> documentation for more details.

=item req|required

  # required attribute

  req => 1
  required => 1

The C<required> directive is used to denote if an attribute is required or
optional. See the L<Moo> documentation for more details.

=item opt|optional

  # optional attribute

  opt => 1
  optional => 1

The C<optional> directive is used to denote if an attribute is optional or
required. See the L<Moo> documentation for more details.

=item bld|builder

  # build value

  bld => $builder
  builder => $builder

The C<builder> directive expects a coderef and builds the attribute value if it
wasn't provided to the constructor. See the L<Moo> documentation for more
details.

=item clr|clearer

  # create clear_${attribute}

  clr => $clearer
  clearer => $clearer

The C<clearer> directive expects a coderef and generates a clearer method. See
the L<Moo> documentation for more details.

=item crc|coerce

  # coerce value

  crc => 1
  coerce => 1

The C<coerce> directive denotes whether an attribute's value should be
automatically coerced. See the L<Moo> documentation for more details.

=item def|default

  # default value

  def => $default
  default => $default

The C<default> directive expects a coderef and is used to build a default value
if one is not provided to the constructor. See the L<Moo> documentation for
more details.

=item mod|modify

  # modify definition

  mod => 1
  modify => 1

The C<modify> directive denotes whether a pre-existing attribute's definition
is being modified. This ability is not supported by the L<Moo> object
superclass.

=item hnd|handles

  # dispatch to value

  hnd => $handles
  handles => $handles

The C<handles> directive denotes the methods created on the object which
dispatch to methods available on the attribute's object. See the L<Moo>
documentation for more details.

=item lzy|lazy

  # lazy attribute

  lzy => 1
  lazy => 1

The C<lazy> directive denotes whether the attribute will be constructed
on-demand, or on-construction. See the L<Moo> documentation for more details.

=item new

  # lazy attribute
  # create new_${attribute}

  new => 1

The C<new> directive, if truthy, denotes that the attribute will be constructed
on-demand, i.e. is lazy, with a builder named C<new_{attribute}>. This ability
is not supported by the L<Moo> object superclass.

=item pre|predicate

  # create has_${attribute}

  pre => 1
  predicate => 1

The C<predicate> directive expects a coderef and generates a method for
checking the existance of the attribute. See the L<Moo> documentation for more
details.

=item rdr|reader

  # attribute reader

  rdr => $reader
  reader => $reader

The C<reader> directive denotes the name of the method to be used to "read" and
return the attribute's value. See the L<Moo> documentation for more details.

=item tgr|trigger

  # attribute trigger

  tgr => $trigger
  trigger => $trigger

The C<trigger> directive expects a coderef and is executed whenever the
attribute's value is changed. See the L<Moo> documentation for more details.

=item use

  # lazy dependency injection

  use => ['service', 'datetime']

The C<use> directive denotes that the attribute will be constructed
on-demand, i.e. is lazy, using a custom builder meant to perform service
construction. This directive exists to provide a simple dependency injection
mechanism for class attributes. This ability is not supported by the L<Moo>
object superclass.

=item wkr|weak_ref

  # weaken ref

  wkr => 1
  weak_ref => 1

The C<weak_ref> directive is used to denote if the attribute's value should be
weakened. See the L<Moo> documentation for more details.

=item wrt|writer

  # attribute writer

  wrt => $writer
  writer => $writer

The C<writer> directive denotes the name of the method to be used to "write"
and return the attribute's value. See the L<Moo> documentation for more
details.

=back

=head1 CREDITS

Al Newkirk, C<+319>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated here,
https://github.com/iamalnewkirk/do/blob/master/LICENSE.

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