package Data::Object::Any::Base;

use strict;
use warnings;

use Scalar::Util ();

use parent 'Data::Object::Base';

our $VERSION = '1.07'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  if (Scalar::Util::blessed($data) && $data->can('detract')) {
    $data = $data->detract;
  }

  if (Scalar::Util::blessed($data) && $data->isa('Regexp') && $^V <= v5.12.0) {
    $data = do { \(my $q = qr/$data/) };
  }

  return bless ref($data) ? $data : \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Any::Base

=cut

=head1 ABSTRACT

Data-Object Abstract Any Class

=cut

=head1 SYNOPSIS

  package My::Any;

  use parent 'Data::Object::Any::Base';

  my $any = My::Any->new(\*main);

=cut

=head1 DESCRIPTION

Data::Object::Any::Base is an abstract base class for operating on any Perl 5 data type.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Any $arg1) : Object

Construct a new object.

=over 4

=item new example

  package My::Any;

  use parent 'Data::Object::Any::Base';

  my $any = My::Any->new(\*main);

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