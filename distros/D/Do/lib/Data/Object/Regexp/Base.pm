package Data::Object::Regexp::Base;

use 5.014;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

use parent 'Data::Object::Base';

our $VERSION = '1.07'; # VERSION

# BUILD

sub new {
  my ($class, $data) = @_;

  if (Scalar::Util::blessed($data) && $data->can('detract')) {
    $data = $data->detract;
  }

  if (!defined($data) || !re::is_regexp($data)) {
    Carp::confess('Instantiation Error: Not a RegexpRef');
  }

  return bless \$data, $class;
}

1;

=encoding utf8

=head1 NAME

Data::Object::Regexp::Base

=cut

=head1 ABSTRACT

Data-Object Abstract Regexp Class

=cut

=head1 SYNOPSIS

  package My::Regexp;

  use parent 'Data::Object::Regexp::Base';

  my $re = My::Regexp->new(qr(\w+));

=cut

=head1 DESCRIPTION

Data::Object::Regexp::Base provides routines for operating on Perl 5 regular
expressions.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(RegexpRef $arg1) : Object

The new method expects a regular-expression object and returns a new class
instance.

=over 4

=item new example

  # given qr(something to match against)

  package My::Regexp;

  use parent 'Data::Object::Regexp::Base';

  my $re = My::Regexp->new(qr(something to match against));

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