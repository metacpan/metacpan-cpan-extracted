package Data::Object::Role::Detract;

use 5.014;

use strict;
use warnings;

use Moo::Role;

our $VERSION = '1.60'; # VERSION

# BUILD
# METHODS

sub data {
  goto \&detract;
}

sub detract {
  my ($data) = @_;

  require Data::Object::Export;

  return Data::Object::Export::detract_deep($data);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Role::Detract

=cut

=head1 ABSTRACT

Data-Object Detract Role

=cut

=head1 SYNOPSIS

  use Data::Object::Class;

  with 'Data::Object::Role::Detract';

=cut

=head1 DESCRIPTION

This role provides functionality for accessing the underlying data type and
value.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 data

  data() : Any

The data method returns the underlying data structure.

=over 4

=item data example

  my $data = $self->data();

=back

=cut

=head2 detract

  detract() : Any

The detract method returns the underlying data structure.

=over 4

=item detract example

  my $detract = $self->detract();

=back

=cut

=head1 CREDITS

Al Newkirk, C<awncorp@cpan.org>, C<+284>

Anthony Brummett, C<abrummet@genome.wustl.edu>, C<+10>

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