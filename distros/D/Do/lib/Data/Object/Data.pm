package Data::Object::Data;

use 5.014;

use strict;
use warnings;

use Moo;

use parent 'Data::Object::Base';

our $VERSION = '1.76'; # VERSION

# BUILD

sub BUILD {
  my ($self, $data) = @_;

  my @attrs = qw(data file from);

  for my $attr (grep { defined $data->{$_} } @attrs) {
    $self->{$attr} = $data->{$attr};
  }

  unless (%$data) {
    $data->{from} = 'main';
  }

  if ($data->{file} && !$data->{data}) {
    $self->from_file($data->{file});
  }

  if ($data->{from} && !$data->{data}) {
    $self->from_data($data->{from});
  }

  return $self;
}

sub from_file {
  my ($self, $file) = @_;

  my $data = $self->file($file);

  $self->{file} = $file;
  $self->{data} = $self->parser(join("\n", @$data)) if @$data;

  return $self;
}

sub from_data {
  my ($self, $class) = @_;

  my $data = $self->data($class) or return;

  $self->{from} = $class;
  $self->{data} = $self->parser(join("\n", @$data)) if @$data;

  return $self;
}

# METHODS

sub file {
  my ($self, $file) = @_;

  open(my $handle, "<:encoding(UTF-8)", $file) or die "Error with $file: $!";

  my $data = [(<$handle>)];

  return $data;
}

sub data {
  my ($self, $class) = @_;

  my $handle = do { no strict 'refs'; \*{"${class}::DATA"} };

  fileno $handle or return [];

  # (no longer errors if DATA is missing)
  # fileno $handle or die "Error with $class: DATA not accessible";

  seek $handle, 0, 0;

  my $data = [(<$handle>)];

  return $data;
}

sub item {
  my ($self, $name) = @_;

  for my $item (@{$self->{data}}) {
    return $item if $item->{name} eq $name;
  }

  return;
}

sub list {
  my ($self, $name) = @_;

  return if !$name;

  my @list;

  for my $item (@{$self->{data}}) {
    push @list, $item if $item->{list} && $item->{list} eq $name;
  }

  return [sort { $a->{index} <=> $b->{index} } @list];
}

sub pluck {
  my ($self, $type, $name) = @_;

  return if !$name;
  return if !$type || ($type ne 'item' && $type ne 'list');

  my (@list, @copy);

  for my $item (@{$self->{data}}) {
    my $matched = 0;

    $matched = 1 if $type eq 'list' && $item->{list} && $item->{list} eq $name;
    $matched = 1 if $type eq 'item' && $item->{name} && $item->{name} eq $name;

    push @list, $item if $matched;
    push @copy, $item if !$matched;
  }

  $self->{data} = [sort { $a->{index} <=> $b->{index} } @copy];

  return $type eq 'name' ? $list[0] : [@list];
}

sub content {
  my ($self, $name) = @_;

  my $item = $self->item($name) or return;
  my $data = $item->{data};

  return $data;
}

sub contents {
  my ($self, $name) = @_;

  my $items = $self->list($name) or return;
  my $data = [map { $_->{data} } @$items];

  return $data;
}

sub parser {
  my ($self, $data) = @_;

  my @chunks = split /^=\s*(.+?)\s*\r?\n/m, $data;

  shift @chunks;

  my $items = [];

  while (my ($meta, $data) = splice @chunks, 0, 2) {
    next unless $meta && $data;
    next unless $meta ne 'cut';

    my @info = split /\s/, $meta, 2;

    my ($list, $name) = @info == 2 ? @info : (undef, @info);

    $data = [split /\n\n/, $data];

    my $item = { name => $name, data => $data, index => @$items + 1, list => $list };

    push @$items, $item;
  }

  return $items;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Data

=cut

=head1 ABSTRACT

Data-Object Data Extraction Class

=cut

=head1 SYNOPSIS

  use Data::Object::Data;

  my $data = Data::Object::Data->new;

This example is extracting from the main package.

  use Data::Object::Data;

  my $data = Data::Object::Data->new(from => 'Example::Package');

This example is extracting from a class.

  use Data::Object::Data;

  my $data = Data::Object::Data->new(file => 'lib/Example/Package.pm');

This example is extracting from a file.

  use Data::Object::Data;

  my $data = Data::Object::Data->new(data => [,"..."]);

This example is extracting from existing data.

  package Command;

  use Data::Object::Data;

  =pod help

  fetches results from the api

  =cut

  my $data = Data::Object::Data->new(
    from => 'Command'
  );

  my $help = $data->content('help');
  # fetches results ...

  my $token = $data->content('token');
  # token: the access token ...

  my $secret = $data->content('secret');
  # secret: the secret for ...

  my $flags = $data->contents('flag');
  # [,...]

  __DATA__

  =flag secret

  secret: the secret for the account

  =flag token

  token: the access token for the account

  =cut

=cut

=head1 DESCRIPTION

This package provides methods for parsing and extracting pod-like data sections
from any file or package. The pod-like syntax allows for using these sections
anywhere in the source code and Perl properly ignoring them.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Base>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 content

  content(Str $arg1) : Str

The content method returns the pod-like section where the name matches the
given string.

=over 4

=item content example

  =pod help

  Example content

  =cut

  # given $data

  $data->content('help');

  # Example content

=back

=cut

=head2 contents

  contents(Str $arg1) : ArrayRef

The contents method returns all pod-like sections that start with the given
string, e.g. C<pod> matches C<=pod foo>. This method returns an arrayref of
data for the matched sections.

=over 4

=item contents example

  =pod help

  Example content

  =cut

  # given $data

  $data->contents('pod');

  # [,...]

=back

=cut

=head2 data

  data(Str $arg1) : ArrayRef

The data method returns the contents from the C<DATA> and C<END> sections of a
package.

=over 4

=item data example

  # given $data

  $data->data($class);

  # ...

=back

=cut

=head2 file

  file(Str $arg1) : ArrayRef

The file method returns the contents of a file which contains pod-like sections
for a given filename.

=over 4

=item file example

  # given $data

  $data->file($args);

  # ...

=back

=cut

=head2 from_data

  from_data(Str $arg1) : Str

The from_data method returns content for the given class to be passed to the
constructor. This method isn't meant to be called directly.

=over 4

=item from_data example

  # given $data

  $data->from_data($class);

  # ...

=back

=cut

=head2 from_file

  from_file(Str $arg1) : Str

The from_data method returns content for the given file to be passed to the
constructor. This method isn't meant to be called directly.

=over 4

=item from_file example

  # given $data

  $data->from_file($file);

  # ...

=back

=cut

=head2 item

  item(Str $arg1) : HashRef

The item method returns metadata for the pod-like section that matches the
given string.

=over 4

=item item example

  =pod help

  Example content

  =cut

  # given $data

  $data->item('help');

  # {,...}

=back

=cut

=head2 list

  list(Str $arg1) : ArrayRef

The list method returns metadata for each pod-like section that matches the
given string.

=over 4

=item list example

  =pod help

  Example content

  =cut

  # given $data

  $data->list('pod');

  # [,...]

=back

=cut

=head2 parser

  parser(Str $arg1) : ArrayRef

The parser method extracts pod-like sections from a given string and returns an
arrayref of metadata.

=over 4

=item parser example

  # given $data

  $data->parser($string);

  # [,...]

=back

=cut

=head2 pluck

  pluck(Str $arg1, Str $arg2) : HashRef

The pluck method splices and returns metadata for the pod-like section that
matches the given list or item by name.

=over 4

=item pluck example

  =pod help

  Example content

  =cut

  # given $data

  $data->pluck('item', 'help');

  # {,...}

=back

=cut

=head1 CREDITS

Al Newkirk, C<+296>

Anthony Brummett, C<+10>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<GitHub|https://github.com/iamalnewkirk/do>

L<Projects|https://github.com/iamalnewkirk/do/projects>

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