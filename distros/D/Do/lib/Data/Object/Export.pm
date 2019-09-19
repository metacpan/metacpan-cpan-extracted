package Data::Object::Export;

use 5.014;

use strict;
use warnings;

use Memoize;

use parent 'Exporter';

our $VERSION = '1.80'; # VERSION

# BUILD

our @EXPORT = (
  'cast',
  'const',
  'do',
  'true',
  'false',
  'is_true',
  'is_false',
  'raise'
);

our %EXPORT_TAGS = (
  all => [@EXPORT]
);

# FUNCTIONS

sub do {
  unless (grep length, grep defined, @_) {
    keyraise("Null filename used");
  }

  return CORE::do($_[0]) if @_ < 2;

  my $point;

  my $routine = shift;
  my $package = __PACKAGE__;

  # it's fun to do bad things {0_0}
  unless ($package && $routine) {
    keyraise("Can't make call without a package and function");
  }

  unless ($point = $package->can($routine)) {
    keyraise("Function ($routine) not callable on package ($package)");
  }

  goto $point;
}

sub cast {
  require Data::Object::Utility;

  if ($_[1]) {
    my ($arg, $type) = @_;

    my $class = 'Data::Object';
    my $point = load($class)->can($type) or return;

    return $class->$type($arg);
  }

  goto &Data::Object::Utility::DeduceDeep;
}

sub dump {
  require Data::Dumper;

  no warnings 'once';

 local $Data::Dumper::Indent = 1;
 local $Data::Dumper::Purity = 1;
 local $Data::Dumper::Quotekeys = 0;
 local $Data::Dumper::Deepcopy = 1;
 local $Data::Dumper::Deparse = 1;
 local $Data::Dumper::Sortkeys = 1;
 local $Data::Dumper::Terse = 0;
 local $Data::Dumper::Useqq = 1;

  return Data::Dumper::Dumper(@_);
}

sub true {
  require Data::Object::Boolean;

  return Data::Object::Boolean::True();
}

sub is_true {
  require Data::Object::Boolean;

  return Data::Object::Boolean::True() unless scalar @_;

  return Data::Object::Boolean::IsTrue(@_);
}

sub false {
  require Data::Object::Boolean;

  return Data::Object::Boolean::False();
}

sub is_false {
  require Data::Object::Boolean;

  return Data::Object::Boolean::False() unless scalar @_;

  return Data::Object::Boolean::IsFalse(@_);
}

sub load {
  my ($class) = @_;

  my $failed = !$class || $class !~ /^[\D](?:[\w:']*\w)?$/;
  my $loaded;

  keyraise("Invalid package name ($class)") if $failed;

  my $error = do {
    local $@;
    $loaded = $class->can('new') || eval "require $class; 1";
    $@;
  };

  keyraise("Error attempting to load $class: $error")
    if $error
    or $failed
    or not $loaded;

  return $class;
}

sub raise {
  require Data::Object::Exception;

  my $class = 'Data::Object::Exception';
  my $point = Data::Object::Exception->can('throw');

  unshift @_, $class and goto $point;
}

sub keyraise {
  raise(shift, undef, 3);
}

memoize 'load';

1;

=encoding utf8

=head1 NAME

Data::Object::Export

=cut

=head1 ABSTRACT

Data-Object Keyword Functions

=cut

=head1 SYNOPSIS

  use Data::Object::Export;

  my $num = cast 123; # Data::Object::Number
  my $str = cast 123, 'string'; # Data::Object::String

=cut

=head1 DESCRIPTION

This package is an exporter that provides a few simple keyword functions to
every calling package.

=head1 EXPORTS

This package can export the following functions.

=head2 all

  use Data::Object::Export ':all';

The all export tag will export the exportable functions, i.e. C<cast>,
C<const>, C<do>, C<is_false>, C<is_true>, C<false>, C<true>, and C<raise>.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Exporter>

=cut

=head1 FUNCTIONS

This package implements the following functions.

=cut

=head2 cast

  cast(Any $arg1, Str $type) : Any

The cast function returns a data object for the argument provided. If the data
passed is blessed then that same object will be returned.

=over 4

=item cast example

  # given 123

  my $num = cast(123); # Data::Object::Number
  my $str = cast(123, 'string'); # Data::Object::String

=back

=cut

=head2 do

  do(Str $arg1, Any @args) : Any

The do function is a special constructor function that is automatically
exported into the consuming package. It overloads and extends the core
L<perlfunc/do> function, supporting the core functionality and adding a new
feature, and exists to dispatch to exportable Data-Object functions and other
dispatchers.

=over 4

=item do example

  # given file syntax

  do 'file.pl'

  # given block syntax

  do { @{"${class}::ISA"} }

  # given func-args syntax

  do('array', [1..4]); # Data::Object::Array

=back

=cut

=head2 dump

  dump(Any $value) : Str

The dump function uses L<Data::Dumper> to return a string representation of the
argument provided. This function is not exported but can be access via the
L<super-do|/do> function.

=over 4

=item dump example

  # given $value

  my $str = do('dump', $value);

=back

=cut

=head2 false

  false() : BooleanObject

The false function returns a falsy boolean object.

=over 4

=item false example

  my $false = false;

=back

=cut

=head2 is_false

  is_false(Any $arg) : BooleanObject

The is_false function with no argument returns a falsy boolean object,
otherwise, returns a boolean object based on the value of the argument
provided.

=over 4

=item is_false example

  my $bool;

  $bool = is_false; # false
  $bool = is_false 1; # false
  $bool = is_false {}; # false
  $bool = is_false bless {}; # false
  $bool = is_false 0; # true
  $bool = is_false ''; # true
  $bool = is_false undef; # true

=back

=cut

=head2 is_true

  is_true(Any $arg) : BooleanObject

The is_true function with no argument returns a truthy boolean object,
otherwise, returns a boolean object based on the value of the argument
provided.

=over 4

=item is_true example

  my $bool;

  $bool = is_true; # true
  $bool = is_true 1; # true
  $bool = is_true {}; # true
  $bool = is_true bless {}; # true
  $bool = is_true 0; # false
  $bool = is_true ''; # false
  $bool = is_true undef; # false

=back

=cut

=head2 keyraise

  keyraise(Str $message, Any $context, Num $offset) : ()

The keyraise function is used internally by function keywords to L</raise>
exceptions from the persepective of the caller and not the keyword itself.

=over 4

=item keyraise example

  keyraise($message, $context, $offset);

=back

=cut

=head2 load

  load(Str $arg1) : ClassName

The load function attempts to dynamically load a module and either raises an
exception or returns the package name of the loaded module. This function is
not exported but can be access via the L<super-do|/do> function.

=over 4

=item load example

  # given 'List::Util';

  $package = do('load', 'List::Util'); # List::Util

=back

=cut

=head2 raise

  raise(Any @args) : Object

The raise function will dynamically load and raise an exception object. This
function takes all arguments accepted by the L<Data::Object::Exception> class.

=over 4

=item raise example

  # given $message;

  raise $message; # Exception! thrown in -e at line 1

=back

=cut

=head2 true

  true() : BooleanObject

The true function returns a truthy boolean object.

=over 4

=item true example

  my $true = true;

=back

=cut

=head1 CREDITS

Al Newkirk, C<+303>

Anthony Brummett, C<+10>

Adam Hopkins, C<+1>

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