package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Earth

=cut

$test->for('name');

=version

0.01

=cut

$test->for('version');

=tagline

FP Library

=cut

$test->for('tagline');

=abstract

FP Standard Library for Perl 5

=cut

$test->for('abstract');

=includes

function: call
function: catch
function: chain
function: error
function: false
function: make
function: raise
function: true
function: wrap

=cut

$test->for('includes');

=synopsis

  package main;

  use Earth;

  wrap 'Venus::String', 'String';

  # call(String, 'function', @args);

  true;

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=description

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

$test->for('description');

=function call

The call function dispatches function and method calls to a package and returns
the result.

=signature call

  call(Str | Object | CodeRef $self, Any @args) (Any)

=metadata call

{
  since => '0.01',
}

=example-1 call

  # given: synopsis

  my $string = call(String('hello'), 'titlecase');

  # "Hello"

=cut

$test->for('example', 1, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Hello';

  $result
});

=example-2 call

  # given: synopsis

  my $default = call(String('hello'), 'default');

  # ""

=cut

$test->for('example', 2, 'call', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result eq '';


  !$result
});

=example-3 call

  # given: synopsis

  my $space = call(String('hello'), 'space');

  # bless( {value => "Venus::String"}, 'Venus::Space' )

=cut

$test->for('example', 3, 'call', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Space');
  ok $result->value eq 'Venus::String';

  $result
});

=function catch

The catch function executes the code block trapping errors and returning the
caught exception in scalar context, and also returning the result as a second
argument in list context.

=signature catch

  catch(CodeRef $block) (Error, Any)

=metadata catch

{
  since => '0.01',
}

=example-1 catch

  package main;

  use Earth;

  my $error = catch {die};

  $error; # 'Died at ...'

=cut

$test->for('example', 1, 'catch', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok !ref($result);

  $result
});

=example-2 catch

  package main;

  use Earth;

  my ($error, $result) = catch {error};

  $error; # Venus::Error

=cut

$test->for('example', 2, 'catch', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');

  $result
});

=example-3 catch

  package main;

  use Earth;

  my ($error, $result) = catch {true};

  $result; # 1

=cut

$test->for('example', 3, 'catch', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=function chain

The chain function chains function and method calls to a package (and return
values) and returns the result.

=signature chain

  chain(Str | Object | CodeRef $self, Str | ArrayRef[Str] @args) (Any)

=metadata chain

{
  since => '0.01',
}

=example-1 chain

  # given: synopsis

  my $string = chain(String('hello world'), ['replace', 'world', 'cosmos'], 'get');

  # "hello cosmos"

=cut

$test->for('example', 1, 'chain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'hello cosmos';

  $result
});

=example-2 chain

  # given: synopsis

  my $string = chain(String('hELLO  World'), 'box', 'lowercase', 'kebabcase', 'unbox');

  # "hello-world"

=cut

$test->for('example', 2, 'chain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'hello-world';

  $result
});

=example-3 chain

  # given: synopsis

  my $string = chain(String('hello'), 'space', 'inherits');

  # ["Venus::Kind::Value"]

=cut

$test->for('example', 3, 'chain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply $result, ["Venus::Kind::Value"];

  $result
});

=function error

The error function throws a L<Venus::Error> exception object using the
exception object arguments provided.

=signature error

  error(Maybe[HashRef] $args) (Error)

=metadata error

{
  since => '0.01',
}

=example-1 error

  package main;

  use Earth;

  my $error = error;

  # bless( {...}, 'Venus::Error' )

=cut

$test->for('example', 1, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Exception!';

  $result
});

=example-2 error

  package main;

  use Earth;

  my $error = error {
    message => 'Something failed!',
  };

  # bless( {...}, 'Venus::Error' )

=cut

$test->for('example', 2, 'error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Something failed!';

  $result
});

=function false

The false function returns a falsy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<0> value.

=signature false

  false() (Bool)

=metadata false

{
  since => '0.01',
}

=example-1 false

  package main;

  use Earth;

  my $false = false;

  # 0

=cut

$test->for('example', 1, 'false', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result == 0;

  !$result
});

=example-2 false

  package main;

  use Earth;

  my $true = !false;

  # 1

=cut

$test->for('example', 2, 'false', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=function make

The make function L<"calls"/call> the C<new> routine on the invocant and
returns the result which should be a package string or an object.

=signature make

  make(Str $package, Any @args) (Any)

=metadata make

{
  since => '0.01',
}

=example-1 make

  # given: synopsis

  my $string = make('Venus::String');

  # bless( {value => ""}, 'Venus::String' )

=cut

$test->for('example', 1, 'make', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result->isa('Venus::String');
  ok $result eq '';

  !$result
});

=example-2 make

  # given: synopsis

  my $string = make('Venus::String', 'hello world');

  # bless( {value => "hello world"}, 'Venus::String' )

=cut

$test->for('example', 2, 'make', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::String');
  ok $result eq 'hello world';

  $result
});

=function raise

The raise function generates and throws a named exception object derived from
L<Venus::Error>, or provided base class, using the exception object arguments
provided.

=signature raise

  raise(Str $class | Tuple[Str, Str] $class, Maybe[HashRef] $args) (Error)

=metadata raise

{
  since => '0.01',
}

=example-1 raise

  package main;

  use Earth;

  my $error = raise 'MyApp::Error';

  # bless( {...}, 'Venus::Error' )

=cut

$test->for('example', 1, 'raise', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('MyApp::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Exception!';

  $result
});

=example-2 raise

  package main;

  use Earth;

  my $error = raise ['MyApp::Error', 'Venus::Error'];

  # bless( {...}, 'Venus::Error' )

=cut

$test->for('example', 2, 'raise', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('MyApp::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Exception!';

  $result
});

=example-3 raise

  package main;

  use Earth;

  my $error = raise ['MyApp::Error', 'Venus::Error'], {
    message => 'Something failed!',
  };

  # bless( {...}, 'Venus::Error' )

=cut

$test->for('example', 3, 'raise', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->error(\(my $error))->result;
  ok $error;
  ok $error->isa('MyApp::Error');
  ok $error->isa('Venus::Error');
  ok $error->message eq 'Something failed!';

  $result
});

=function true

The true function returns a truthy boolean value which is designed to be
practically indistinguishable from the conventional numerical C<1> value.

=signature true

  true() (Bool)

=metadata true

{
  since => '0.01',
}

=example-1 true

  package main;

  use Earth;

  my $true = true;

  # 1

=cut

$test->for('example', 1, 'true', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result == 1;

  $result
});

=example-2 true

  package main;

  use Earth;

  my $false = !true;

  # 0

=cut

$test->for('example', 2, 'true', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);

  !$result
});

=function wrap

The wrap function installs a wrapper function in the calling package which when
called either returns the package string if no arguments are provided, or calls
L</make> on the package with whatever arguments are provided and returns the
result. Unless an alias is provided as a second argument, special characters
are stripped from the package to create the function name.

=signature wrap

  wrap(Str $package, Str $alias) (CodeRef)

=metadata wrap

{
  since => '0.01',
}

=example-1 wrap

  # given: synopsis

  my $coderef = wrap('Venus::Space');

  # my $space = VenusSpace();

  # "Venus::Space"

=cut

$test->for('example', 1, 'wrap', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->() eq 'Venus::Space';

  $result
});

=example-2 wrap

  # given: synopsis

  my $coderef = wrap('Venus::Space');

  # my $space = VenusSpace({});

  # bless( {value => "Venus"}, 'Venus::Space' )

=cut

$test->for('example', 2, 'wrap', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->({})->isa('Venus::Space');
  ok $result->({}) eq 'Venus';

  $result
});

=example-3 wrap

  # given: synopsis

  my $coderef = wrap('Venus::Space', 'Space');

  # my $space = Space();

  # "Venus::String"

=cut

$test->for('example', 3, 'wrap', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->() eq 'Venus::Space';

  $result
});

=example-4 wrap

  # given: synopsis

  my $coderef = wrap('Venus::Space', 'Space');

  # my $space = Space({});

  # bless( {value => "Venus"}, 'Venus::Space' )

=cut

$test->for('example', 4, 'wrap', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->({})->isa('Venus::Space');
  ok $result->({}) eq 'Venus';

  $result
});

=example-5 wrap

  # given: synopsis

  my $coderef = wrap('Venus::Space', 'Space');

  # my $space = Space('Earth');

  # bless( {value => "Earth"}, 'Venus::Space' )

=cut

$test->for('example', 5, 'wrap', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->('Earth')->isa('Venus::Space');
  ok $result->('Earth') eq 'Earth';

  $result
});

=authors

Awncorp, C<awncorp@cpan.org>

=cut

# END

$test->render('lib/Earth.pod') if $ENV{RENDER};

ok 1 and done_testing;
