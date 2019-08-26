package Data::Object::Regexp;

use Try::Tiny;
use Role::Tiny::With;

use Data::Object::Export qw(
  cast
  croak
  load
);

map with($_), my @roles = qw(
  Data::Object::Role::Detract
  Data::Object::Role::Dumper
  Data::Object::Role::Output
  Data::Object::Role::Throwable
);

map with($_), my @rules = qw(
  Data::Object::Rule::Defined
);

use overload (
  '""'     => 'data',
  '~~'     => 'data',
  fallback => 1
);

use parent 'Data::Object::Base::Regexp';

our $VERSION = '1.02'; # VERSION

# BUILD
# METHODS

sub roles {
  return cast([@roles]);
}

sub rules {
  return cast([@rules]);
}

# DISPATCHERS

sub defined {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Regexp::Defined';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

# METHODS

sub search {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Regexp::Search';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub replace {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Regexp::Replace';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

1;
=encoding utf8

=head1 NAME

Data::Object::Regexp

=cut

=head1 ABSTRACT

Data-Object Regexp Class

=cut

=head1 SYNOPSIS

  use Data::Object::Regexp;

  my $re = Data::Object::Regexp->new(qr(\w+));

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 regular expressions.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item defined example

  # given $regexp

  $re->defined; # 1

=back

=cut

=head2 replace

  replace(Str $arg1, Str $arg2) : StrObject

The replace method performs a regular expression substitution on the given
string. The first argument is the string to match against. The second argument
is the replacement string. The optional third argument might be a string
representing flags to append to the s///x operator, such as 'g' or 'e'.  This
method will always return a L<Data::Object::Replace> object which can be
used to introspect the result of the operation.

=over 4

=item replace example

  # given qr(test)

  $re->replace('this is a test', 'drill');
  $re->replace('test 1 test 2 test 3', 'drill', 'gi');

=back

=cut

=head2 roles

  roles() : ArrayRef

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=over 4

=item roles example

  # given $regexp

  $re->roles;

=back

=cut

=head2 rules

  rules() : ArrayRef

The rules method returns consumed rules.

=over 4

=item rules example

  my $rules = $re->rules;

=back

=cut

=head2 search

  search(Str $arg1) : SearchObject

The search method performs a regular expression match against the given string
This method will always return a L<Data::Object::Search> object which
can be used to introspect the result of the operation.

=over 4

=item search example

  # given qr((test))

  $re->search('this is a test');
  $re->search('this does not match', 'gi');

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