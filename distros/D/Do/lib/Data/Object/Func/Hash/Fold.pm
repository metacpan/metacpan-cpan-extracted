package Data::Object::Func::Hash::Fold;

use Data::Object 'Class';

extends 'Data::Object::Func::Hash';

our $VERSION = '1.02'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

has arg2 => (
  is => 'ro',
  isa => 'Str',
  opt => 1
);

has arg3 => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1
);

has arg4 => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data, $path, $store, $cache) = $self->unpack;

  my $folded = _folding($data, $path, $store, $cache);

  return $folded;
}

sub mapping {
  return ('arg1', 'arg2', 'arg3', 'arg4');
}

# PRIVATE

sub _folding {
  my ($data, $path, $store, $cache) = @_;

  $store ||= {};
  $cache ||= {};

  my $ref = ref($data);
  my $obj = Scalar::Util::blessed($data);
  my $adr = Scalar::Util::refaddr($data);
  my $tmp = {%$cache};

  if ($adr && $tmp->{$adr}) {
    $store->{$path} = $data;
  } elsif ($ref eq 'HASH' || ($obj and $obj->isa('Data::Object::Hash'))) {
    $tmp->{$adr} = 1;
    if (%$data) {
      for my $key (sort(keys %$data)) {
        my $place = $path ? join('.', $path, $key) : $key;
        my $value = $data->{$key};
        _folding($value, $place, $store, $tmp);
      }
    } else {
      $store->{$path} = {};
    }
  } elsif ($ref eq 'ARRAY' || ($obj and $obj->isa('Data::Object::Array'))) {
    $tmp->{$adr} = 1;
    if (@$data) {
      for my $idx (0 .. $#$data) {
        my $place = $path ? join(':', $path, $idx) : $idx;
        my $value = $data->[$idx];
        _folding($value, $place, $store, $tmp);
      }
    } else {
      $store->{$path} = [];
    }
  } else {
    $store->{$path} = $data if $path;
  }

  return $store;
}

1;
=encoding utf8

=head1 NAME

Data::Object::Func::Hash::Fold

=cut

=head1 ABSTRACT

Data-Object Hash Function (Fold) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::Hash::Fold;

  my $func = Data::Object::Func::Hash::Fold->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::Hash::Fold is a function object for Data::Object::Hash.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::Hash->new({3,[4,5,6],7,{8,8,9,9}});

  my $func = Data::Object::Func::Hash::Fold->new(
    arg1 => $data
  );

  my $result = $func->execute;

=back

=cut

=head2 mapping

  mapping() : (Str)

Returns the ordered list of named function object arguments.

=over 4

=item mapping example

  my @data = $self->mapping;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 STATUS

=begin html

<a href="https://travis-ci.org/iamalnewkirk/data-object" target="_blank">
<img src="https://travis-ci.org/iamalnewkirk/data-object.svg?branch=master"/>
</a>

=end html

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

L<Contributing|https://github.com/iamalnewkirk/data-object/CONTRIBUTING.mkdn>

L<GitHub|https://github.com/iamalnewkirk/data-object>

=cut