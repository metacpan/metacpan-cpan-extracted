package Earth;

use 5.018;

use strict;
use warnings;

use Venus qw(
  catch
  error
  raise
);

use Exporter 'import';

our @EXPORT = qw(
  call
  catch
  chain
  error
  false
  make
  raise
  true
  wrap
);

require Scalar::Util;

# VERSION

our $VERSION = '0.01';

# AUTHORITY

our $AUTHORITY = 'cpan:AWNCORP';

# FUNCTIONS

sub call {
  my ($invocant, $routine, @arguments) = @_;
  if (UNIVERSAL::isa($invocant, 'CODE')) {
    return $invocant->(@arguments);
  }
  return if !$routine;
  if (Scalar::Util::blessed($invocant)) {
    return $invocant->$routine(@arguments);
  }
  require Venus::Space;
  my $package = Venus::Space->new($invocant)->load;
  if (my $routine = $package->can($routine)) {
    return $routine->(@arguments);
  }
  if ($package->can('AUTOLOAD')) {
    no strict 'refs';
    return &{"${package}::${routine}"}(@arguments);
  }
  raise 'Earth';
}

sub chain {
  my ($invocant, @routines) = @_;
  return if !$invocant;
  for my $next (map +(ref($_) eq 'ARRAY' ? $_ : [$_]), @routines) {
    $invocant = call($invocant, @$next);
  }
  return $invocant;
}

sub make {
  return if !@_;
  return call($_[0], 'new', @_);
}

sub wrap {
  my ($package, $alias) = @_;
  return if !$package;
  my $moniker = $alias // $package =~ s/\W//gr;
  my $caller = caller(0);
  no strict 'refs';
  no warnings 'redefine';
  return *{"${caller}::${moniker}"} = sub { @_ ? make($package, @_) : $package };
}

1;


=head1 NAME

Earth - FP Library

=cut

=head1 ABSTRACT

FP Standard Library for Perl 5

=cut

=head1 VERSION

0.01

=cut

=head1 SYNOPSIS

  package main;

  use Earth;

  wrap 'Venus::String', 'String';

  # call(String, 'function', @args);

  true;

=cut

=head1 DESCRIPTION

Earth is a functional-programming framework with standard library for Perl 5,
built on top of L<Venus> which provides the underlying object-oriented standard
library. Perl is a multi-paradigm programming language that also supports
functional programming, but, Perl has an intentionally limited standard library
with an emphasis on providing library support via the CPAN which is
overwhelmingly object-oriented. This makes developing in a functional style
difficult as you'll eventually need to rely on a CPAN library that requires you
to switch over to object-oriented programming.Earth facilitates functional
programming for Perl 5 by providing keyword functions which enable indirect
routine dispatching, allowing the execution of both functional and
object-oriented code.

=cut

=head1 FUNCTIONS

This package provides the following functions:

=cut

=head2 call

  call(Str | Object | CodeRef $self, Any @args) (Any)

The call function dispatches function and method calls to a package and returns
the result.

I<Since C<0.01>>

=over 4

=item call example 1

  # given: synopsis

  my $string = call(String('hello'), 'titlecase');

  # "Hello"

=back

=over 4

=item call example 2

  # given: synopsis

  my $default = call(String('hello'), 'default');

  # ""

=back

=over 4

=item call example 3

  # given: synopsis

  my $space = call(String('hello'), 'space');

  # bless( {value => "Venus::String"}, 'Venus::Space' )

=back

=cut

=head2 catch

  catch(CodeRef $block) (Error, Any)

The catch function executes the code block trapping errors and returning the
caught exception in scalar context, and also returning the result as a second
argument in list context.

I<Since C<0.01>>

=over 4

=item catch example 1

  package main;

  use Earth;

  my $error = catch {die};

  $error; # 'Died at ...'

=back

=over 4

=item catch example 2

  package main;

  use Earth;

  my ($error, $result) = catch {error};

  $error; # Venus::Error

=back

=over 4

=item catch example 3

  package main;

  use Earth;

  my ($error, $result) = catch {true};

  $result; # 1

=back

=cut

=head2 chain

  chain(Str | Object | CodeRef $self, Str | ArrayRef[Str] @args) (Any)

The chain function chains function and method calls to a package (and return
values) and returns the result.

I<Since C<0.01>>

=over 4

=item chain example 1

  # given: synopsis

  my $string = chain(String('hello world'), ['replace', 'world', 'cosmos'], 'get');

  # "hello cosmos"

=back

=over 4

=item chain example 2

  # given: synopsis

  my $string = chain(String('hELLO  World'), 'box', 'lowercase', 'kebabcase', 'unbox');

  # "hello-world"

=back

=over 4

=item chain example 3

  # given: synopsis

  my $string = chain(String('hello'), 'space', 'inherits');

  # ["Venus::Kind::Value"]

=back

=cut

=head2 error

  error(Maybe[HashRef] $args) (Error)

The error function throws a L<Venus::Error> exception object using the
exception object arguments provided.

I<Since C<0.01>>

=over 4

=item error example 1

  package main;

  use Earth;

  my $error = error;

  # bless( {...}, 'Venus::Error' )

=back

=over 4

=item error example 2

  package main;

  use Earth;

  my $error = error {
    message => 'Something failed!',
  };

  # bless( {...}, 'Venus::Error' )

=back

=cut

=head2 false

  false() (Bool)

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value.

I<Since C<0.01>>

=over 4

=item false example 1

  package main;

  use Earth;

  my $false = false;

  # 0

=back

=over 4

=item false example 2

  package main;

  use Earth;

  my $true = !false;

  # 1

=back

=cut

=head2 make

  make(Str $package, Any @args) (Any)

The make function L<"calls"/call> the C<new> routine on the invocant and
returns the result which should be a package string or an object.

I<Since C<0.01>>

=over 4

=item make example 1

  # given: synopsis

  my $string = make('Venus::String');

  # bless( {value => ""}, 'Venus::String' )

=back

=over 4

=item make example 2

  # given: synopsis

  my $string = make('Venus::String', 'hello world');

  # bless( {value => "hello world"}, 'Venus::String' )

=back

=cut

=head2 raise

  raise(Str $class | Tuple[Str, Str] $class, Maybe[HashRef] $args) (Error)

The raise function generates and throws a named exception object derived from
L<Venus::Error>, or provided base class, using the exception object arguments
provided.

I<Since C<0.01>>

=over 4

=item raise example 1

  package main;

  use Earth;

  my $error = raise 'MyApp::Error';

  # bless( {...}, 'Venus::Error' )

=back

=over 4

=item raise example 2

  package main;

  use Earth;

  my $error = raise ['MyApp::Error', 'Venus::Error'];

  # bless( {...}, 'Venus::Error' )

=back

=over 4

=item raise example 3

  package main;

  use Earth;

  my $error = raise ['MyApp::Error', 'Venus::Error'], {
    message => 'Something failed!',
  };

  # bless( {...}, 'Venus::Error' )

=back

=cut

=head2 true

  true() (Bool)

The true function returns a truthy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<1> value.

I<Since C<0.01>>

=over 4

=item true example 1

  package main;

  use Earth;

  my $true = true;

  # 1

=back

=over 4

=item true example 2

  package main;

  use Earth;

  my $false = !true;

  # 0

=back

=cut

=head2 wrap

  wrap(Str $package, Str $alias) (CodeRef)

The wrap function installs a wrapper function in the calling package which when
called either returns the package string if no arguments are provided, or calls
L</make> on the package with whatever arguments are provided and returns the
result. Unless an alias is provided as a second argument, special characters
are stripped from the package to create the function name.

I<Since C<0.01>>

=over 4

=item wrap example 1

  # given: synopsis

  my $coderef = wrap('Venus::Space');

  # my $space = VenusSpace();

  # "Venus::Space"

=back

=over 4

=item wrap example 2

  # given: synopsis

  my $coderef = wrap('Venus::Space');

  # my $space = VenusSpace({});

  # bless( {value => "Venus"}, 'Venus::Space' )

=back

=over 4

=item wrap example 3

  # given: synopsis

  my $coderef = wrap('Venus::Space', 'Space');

  # my $space = Space();

  # "Venus::String"

=back

=over 4

=item wrap example 4

  # given: synopsis

  my $coderef = wrap('Venus::Space', 'Space');

  # my $space = Space({});

  # bless( {value => "Venus"}, 'Venus::Space' )

=back

=over 4

=item wrap example 5

  # given: synopsis

  my $coderef = wrap('Venus::Space', 'Space');

  # my $space = Space('Earth');

  # bless( {value => "Earth"}, 'Venus::Space' )

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut