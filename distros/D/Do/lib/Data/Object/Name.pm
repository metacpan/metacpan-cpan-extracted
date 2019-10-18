package Data::Object::Name;

use 5.014;

use strict;
use warnings;

our $VERSION = '1.88'; # VERSION

# METHODS

my $sep = qr/'|__|::/;

sub new {
  my ($class, @args) = @_;

  my $name = join(' ', @args) || $class;

  return bless \$name, $class;
}

sub file {
  my ($self) = @_;

  return $$self if $self->lookslike_a_file;

  my $string = $self->package;

  return join '__', map {
    join '_', map {lc} map {split /_/} grep {length}
    split /([A-Z]{1}[^A-Z]*)/
  } split /$sep/, $string;
}

sub label {
  my ($self) = @_;

  return $$self if $self->lookslike_a_label;

  return join '_', split /$sep/, $self->package;
}

sub package {
  my ($self) = @_;

  return $$self if $self->lookslike_a_package;

  my $string = $$self;

  if ($string !~ $sep) {
    return join '', map {ucfirst} split /[^a-zA-Z0-9]/, $string;
  } else {
    return join '::', map {
      join '', map {ucfirst} split /[^a-zA-Z0-9]/
    } split /$sep/, $string;
  }
}

sub path {
  my ($self) = @_;

  return $$self if $self->lookslike_a_path;

  return join '/', split /$sep/, $self->package;
}

sub format {
  my ($self, $method, $format) = @_;

  my $string = $self->$method;

  return sprintf($format || '%s', $string);
}

sub lookslike_a_file {
  my ($self) = @_;

  my $string = $$self;

  return $string =~ /^[a-z](?:\w*[a-z])?$/;
}

sub lookslike_a_label {
  my ($self) = @_;

  my $string = $$self;

  return $string =~ /^[A-Z](?:\w*[a-zA-Z0-9])?$/;
}

sub lookslike_a_package {
  my ($self) = @_;

  my $string = $$self;

  return $string =~ /^[A-Z](?:(?:\w|::)*[a-zA-Z0-9])?$/;
}

sub lookslike_a_path {
  my ($self) = @_;

  my $string = $$self;

  return $string =~ /^[A-Z](?:(?:\w|\\|\/|[\:\.]{1}[a-zA-Z0-9])*[a-zA-Z0-9])?$/;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Name

=cut

=head1 ABSTRACT

Data-Object Name Class

=cut

=head1 SYNOPSIS

  use Data::Object::Name;

  my $name;

  $name = Data::Object::Name->new('Foo/Bar');
  $name = Data::Object::Name->new('Foo::Bar');
  $name = Data::Object::Name->new('Foo__Bar');
  $name = Data::Object::Name->new('foo__bar');

  my $file = $name->file; # foo__bar
  my $package = $name->package; # Foo::Bar
  my $path = $name->path; # Foo/Bar
  my $label = $name->label; # Foo__Bar

=cut

=head1 DESCRIPTION

This package provides methods for converting name strings, e.g. package names,
file names, path names, and label names, to and from each other.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 file

  file() : Str

The file method returns a file representation of the name.

=over 4

=item file example

  # given FooBar::Baz

  my $file = $name->file; # foo_bar__baz

=back

=cut

=head2 format

  format(Str $method, Str $format) : Str

The format method called the specified method and passes the result to the core
L<perlfunc/sprintf> function with the string representation of itself as the
argument

=over 4

=item format example

  # given Foo::Bar

  $name->format('file', '%s.t'); # foo__bar.t

  # given Foo::Bar

  $name->format('path', '%s.pm'); # Foo/Bar.pm

=back

=cut

=head2 label

  label() : Str

The label method returns a label (or constant) representation of the name

=over 4

=item label example

  # given Foo::Bar

  my $label = $name->label; # Foo_Bar

=back

=cut

=head2 lookslike_a_file

  lookslike_a_file() : Bool

The lookslike_a_file method returns truthy if its state resembles a filename.

=over 4

=item lookslike_a_file example

  # given foo_bar

  $name->lookslike_a_file; # truthy

  # given Foo/Bar

  $name->lookslike_a_file; # falsy

=back

=cut

=head2 lookslike_a_label

  lookslike_a_label() : Bool

The lookslike_a_label method returns truthy if its state resembles a label (or constant).

=over 4

=item lookslike_a_label example

  # given Foo_Bar

  $name->lookslike_a_label; # truthy

  # given Foo/Bar

  $name->lookslike_a_label; # falsy

=back

=cut

=head2 lookslike_a_package

  lookslike_a_package() : Bool

The lookslike_a_package method returns truthy if its state resembles a package
name.

=over 4

=item lookslike_a_package example

  # given Foo::Bar

  $name->lookslike_a_package; # truthy

  # given Foo/Bar

  $name->lookslike_a_package; # falsy

=back

=cut

=head2 lookslike_a_path

  lookslike_a_path() : Bool

The lookslike_a_path method returns truthy if its state resembles a file path.

=over 4

=item lookslike_a_path example

  # given Foo::Bar

  $name->lookslike_a_path; # falsy

  # given Foo/Bar

  $name->lookslike_a_path; # truthy

=back

=cut

=head2 new

  new(Str $arg) : Object

The new method returns instantiates the class and returns an object.

=over 4

=item new example

  # given $string

  my $name = Data::Object::Name->new($string);

=back

=cut

=head2 package

  package() : Str

The package method returns a package name representation of the name given.

=over 4

=item package example

  # given foo-bar__bar

  my $package = $name->package; # FooBar::Baz

=back

=cut

=head2 path

  path() : Str

The path method returns a path representation of the name.

=over 4

=item path example

  # given Foo::Bar

  my $path = $name->path; # Foo/Bar

=back

=cut

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