package Data::Object::Func::String::Titlecase;

use Data::Object 'Class';

extends 'Data::Object::Func::String';

our $VERSION = '1.02'; # VERSION

# BUILD

has arg1 => (
  is => 'ro',
  isa => 'Object',
  req => 1
);

# METHODS

sub execute {
  my ($self) = @_;

  my ($data) = $self->unpack;

  my $result = "$data";

  $result =~ s/\b(\w)/\U$1/g;

  return $result;
}

sub mapping {
  return ('arg1');
}

1;
=encoding utf8

=head1 NAME

Data::Object::Func::String::Titlecase

=cut

=head1 ABSTRACT

Data-Object String Function (Titlecase) Class

=cut

=head1 SYNOPSIS

  use Data::Object::Func::String::Titlecase;

  my $func = Data::Object::Func::String::Titlecase->new(@args);

  $func->execute;

=cut

=head1 DESCRIPTION

Data::Object::Func::String::Titlecase is a function object for Data::Object::String.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 execute

  execute() : Object

Executes the function logic and returns the result.

=over 4

=item execute example

  my $data = Data::Object::String->new("hello world");

  my $func = Data::Object::Func::String::Titlecase->new(
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