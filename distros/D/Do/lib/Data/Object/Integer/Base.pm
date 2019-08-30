package Data::Object::Integer::Base;

use 5.014;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

use parent 'Data::Object::Base';

our $VERSION = '1.09'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  if (Scalar::Util::blessed($data) && $data->can('detract')) {
    $data = $data->detract;
  }

  $data = "$data" if $data;

  if (defined $data) {
    $data =~ s/^\+//; # not keen on this but ...
  }

  if (!defined($data) || ref($data)) {
    Carp::confess('Instantiation Error: Not an Integer');
  }

  if (!Scalar::Util::looks_like_number($data)) {
    Carp::confess('Instantiation Error: Not an Integer');
  }

  $data += 0 unless $data =~ /[a-zA-Z]/;

  return bless \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Integer::Base

=cut

=head1 ABSTRACT

Data-Object Abstract Integer Class

=cut

=head1 SYNOPSIS

  package My::Integer;

  use parent 'Data::Object::Integer::Base';

  my $integer = My::Integer->new(9);

=cut

=head1 DESCRIPTION

Data::Object::Integer::Base provides routines for operating on Perl 5 integer
data. This package inherits all behavior from L<Data::Object::Base>.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Int $arg1) : Object

The new method expects a number and returns a new class instance.

=over 4

=item new example

  # given 9

  package My::Integer;

  use parent 'Data::Object::Integer::Base';

  my $integer = My::Integer->new(9);

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