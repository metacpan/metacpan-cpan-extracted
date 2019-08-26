package Data::Object::Autobox::Undef;

use 5.014;

use strict;
use warnings;

use Data::Object ();

our $VERSION = '1.02'; # VERSION

# BUILD

sub new {
  Data::Object->undef(pop);
}

1;
=encoding utf8

=head1 NAME

Data::Object::Autobox::Undef

=cut

=head1 ABSTRACT

Data-Object Autoboxing for Undef Objects

=cut

=head1 SYNOPSIS

  use Data::Object::Autobox::Undef;

=cut

=head1 DESCRIPTION

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Undef> objects.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 new

  new(Maybe[Undef] $arg1) : UndefObject

Construct a new object.

=over 4

=item new example

  my $undef = Data::Object::Autobox::Undef->new;

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