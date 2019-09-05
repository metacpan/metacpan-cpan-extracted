package Data::Object::Signatures;

use 5.014;

use strict;
use warnings;

use Function::Parameters;

use Data::Object::Export 'namespace', 'reify';

our $VERSION = '1.50'; # VERSION

# BUILD

sub import {
  return Function::Parameters->import(settings(@_));
}

sub settings {
  my ($class, @args) = @_;

  # reifier config
  my $caller = caller(1);
  my @config = ($class, sub { unshift @_, $caller; goto \&reify });

  # for backwards compat
  @args = grep !/^:/, @args;
  namespace($caller, pop(@args)) if @args;

  # keyword config
  my %settings;

  %settings = (func_settings(@config), %settings);
  %settings = (meth_settings(@config), %settings);
  %settings = (befr_settings(@config), %settings);
  %settings = (aftr_settings(@config), %settings);
  %settings = (arnd_settings(@config), %settings);

  return {%settings};
}

sub func_settings {
  my ($class, $reifier) = @_;

  return (fun => {
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'function',
    invocant             => 1,
    name                 => 'optional',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    types                => 1,
  });
}

sub meth_settings {
  my ($class, $reifier) = @_;

  return (method => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    invocant             => 1,
    name                 => 'optional',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    shift                => '$self',
    types                => 1,
  });
}

sub aftr_settings {
  my ($class, $reifier) = @_;

  return (after => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'after',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    shift                => '$self',
    types                => 1,
  });
}

sub befr_settings {
  my ($class, $reifier) = @_;

  return (before => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'before',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    shift                => '$self',
    types                => 1,
  });
}

sub arnd_settings {
  my ($class, $reifier) = @_;

  return (around => {
    attributes           => ':method',
    check_argument_count => 0, # for backwards compat :(
    check_argument_types => 1,
    default_arguments    => 1,
    defaults             => 'method',
    install_sub          => 'around',
    invocant             => 1,
    name                 => 'required',
    named_parameters     => 1,
    reify_type           => $reifier,
    runtime              => 1,
    shift                => ['$orig', '$self'],
    types                => 1,
  });
}

1;

=encoding utf8

=head1 NAME

Data::Object::Signatures

=cut

=head1 ABSTRACT

Data-Object Method Signatures

=cut

=head1 SYNOPSIS

  use Data::Object::Signatures;

  fun hello (Str $name) {
    return "Hello $name, how are you?";
  }

  before created() {
    # do something ...
    return $self;
  }

  after created() {
    # do something ...
    return $self;
  }

  around updated() {
    # do something ...
    $self->$orig;
    # do something ...
    return $self;
  }

=cut

=head1 DESCRIPTION

This package provides method and function signatures supporting all the type
constraints provided by L<Data::Object::Library>.

=head1 FOREWARNING

Please note that function and method signatures do support parameterized types
but with certain caveats. For example, consider the following:

  package App::Store;

  use Do 'Class', 'App';

  method checkout(InstanceOf[Cart] $cart) {
    # perform store checkout
  }

  1;

This method signature is valid so long as the C<Cart> type is registered in the
user-defined C<App> type library. However, in the case where that type is not
in the type library, you might be tempted to use the fully-qualified class
name, for example:

  package App::Store;

  use Do 'Class', 'App';

  method checkout(InstanceOf[App::Cart] $cart) {
    # perform store checkout
  }

  1;

Because the type portion of the method signature is evaluated as a Perl string
that type declaration is not valid and will result in a syntax error due to the
signature parser not expecting the bareword. You might then be tempted to
simply quote the fully-qualified class name, for example:

  package App::Store;

  use Do 'Class', 'App';

  method checkout(InstanceOf["App::Cart"] $cart) {
    # perform store checkout
  }

  1;

TLDR; The signature parser doesn't like that either. To resolve this issue you
have two potential solutions, the first being to declare the C<Cart> type in
the user-defined library, for example:


  package App;

  use Do 'Library';

  our $Cart = declare 'Cart',
    as InstanceOf["App::Cart"];

  package App::Store;

  use Do 'Class', 'App';

  method checkout(Cart $cart) {
    # perform store checkout
  }

  1;

Or, alternatively, you could express the type declaration as a string which the
parser will except and evaluate properly, for example:

  package App::Store;

  use Do 'Class';

  method checkout(('InstanceOf["App::Cart"]') $cart) {
    # perform store checkout
  }

  1;

=cut

=head1 FUNCTIONS

This package implements the following functions.

=cut

=head2 aftr_settings

  aftr_settings(Str $arg1, Object $arg2) : (Str, HashRef)

The aftr_settings function returns the after-keyword configuration.

=over 4

=item aftr_settings example

  my $aftr_settings = aftr_settings();

=back

=cut

=head2 arnd_settings

  arnd_settings(Str $arg1, Object $arg2) : (Str, HashRef)

The arnd_settings function returns the around-keyword configuration.

=over 4

=item arnd_settings example

  my $arnd_settings = arnd_settings();

=back

=cut

=head2 befr_settings

  befr_settings(Str $arg1, Object $arg2) : (Str, HashRef)

The befr_settings function returns the before-keyword configuration.

=over 4

=item befr_settings example

  my $befr_settings = befr_settings();

=back

=cut

=head2 func_settings

  func_settings(Str $arg1, Object $arg2) : (Str, HashRef)

The func_settings function returns the fun-keyword configuration.

=over 4

=item func_settings example

  my $func_settings = func_settings();

=back

=cut

=head2 meth_settings

  meth_settings(Str $arg1, Object $arg2) : (Str, HashRef)

The meth_settings function returns the method-keyword configuration.

=over 4

=item meth_settings example

  my $meth_settings = meth_settings();

=back

=cut

=head2 settings

  settings(Str $arg1, Any @args) : HashRef

The settings function returns the settings for Function::Parameters
configuration.

=over 4

=item settings example

  my $settings = settings();

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