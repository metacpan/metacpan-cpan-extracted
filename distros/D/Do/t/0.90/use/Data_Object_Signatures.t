use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Signatures

=abstract

Data-Object Method Signatures

=synopsis

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

=description

This package provides method and function signatures supporting all the type
constraints provided by L<Data::Object::Library>.

+=head1 FOREWARNING

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

use_ok "Data::Object::Signatures";

ok 1 and done_testing;
