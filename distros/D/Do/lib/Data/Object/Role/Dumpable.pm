package Data::Object::Role::Dumpable;

use 5.014;

use strict;
use warnings;

use Moo::Role;

our $VERSION = '1.85'; # VERSION

# METHODS

sub dump {
  my ($data) = @_;

  require Data::Dumper;
  require Data::Object::Utility;

  no warnings 'once';

  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Useqq = 1;

  $data = Data::Object::Utility::DetractDeep($_[0]);
  $data = Data::Dumper::Dumper($data);
  $data =~ s/^"|"$//g;

  return $data;
}

sub print {
  my ($self, @args) = @_;

  return CORE::print(map &dump($_), @args, $self);
}

sub say {
  my ($self, @args) = @_;

  return CORE::print(map +(&dump($_), "\n"), @args, $self);
}

sub pretty_dump {
  my ($data) = @_;

  require Data::Dumper;
  require Data::Object::Utility;

  no warnings 'once';

  local $Data::Dumper::Indent = 2;
  local $Data::Dumper::Trailingcomma = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Pad = '';
  local $Data::Dumper::Varname = 'VAR';
  local $Data::Dumper::Useqq = 0;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Freezer = '';
  local $Data::Dumper::Toaster = '';
  local $Data::Dumper::Deepcopy = 1;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Bless = 'bless';
  local $Data::Dumper::Pair = ' => ';
  local $Data::Dumper::Maxdepth = 0;
  local $Data::Dumper::Maxrecurse = 1000;
  local $Data::Dumper::Useperl = 0;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Deparse = 1;
  local $Data::Dumper::Sparseseen = 0;

  $data = Data::Object::Utility::DetractDeep($_[0]);
  $data = Data::Dumper::Dumper($data);
  $data =~ s/^'|'$//g;

  chomp $data;

  return $data;
}

sub pretty_print {
  my ($self, @args) = @_;

  return CORE::print(map &pretty_dump($_), @args, $self);
}

sub pretty_say {
  my ($self, @args) = @_;

  return CORE::print(map +(&pretty_dump($_), "\n"), @args, $self);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Dumpable

=cut

=head1 ABSTRACT

Data-Object Dumpable Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Dumpable';

=cut

=head1 DESCRIPTION

This role provides functionality for dumping the object and underlying value.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 dump

  dump() : Str

The dump method returns a string representation of the underlying data.

=over 4

=item dump example

  my $dump = $self->dump();

=back

=cut

=head2 pretty_dump

  pretty_dump() : Str

The pretty_dump method returns a string representation of the underlying data
that is human-readable and useful for debugging.

=over 4

=item pretty_dump example

  my $pretty_dump = $self->pretty_dump();

=back

=cut

=head2 pretty_print

  pretty_print() : NumObject

The pretty_print method prints a stringified human-readable representation of
the underlying data.

=over 4

=item pretty_print example

  my $pretty_print = $self->pretty_print();

=back

=cut

=head2 pretty_say

  pretty_say() : NumObject

The pretty_say method prints a stringified human-readable representation of the
underlying data. This prints with a trailing newline.

=over 4

=item pretty_say example

  my $pretty_say = $self->pretty_say();

=back

=cut

=head2 print

  print() : NumObject

Output stringified object data.

=over 4

=item print example

  my $print = $self->print();

=back

=cut

=head2 say

  say() : NumObject

Output stringified object data with newline.

=over 4

=item say example

  my $say = $self->say();

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