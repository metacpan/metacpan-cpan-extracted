#
# This file is part of Exception-Stringy
#
# This software is Copyright (c) 2014 by Damien Krotkine.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
# ABSTRACT: a Perl Exceptions module where exceptions are not objects but simple strings.

package Exception::Stringy;
{
  $Exception::Stringy::VERSION = '0.20';
}
use strict;
use warnings;
use 5.8.9;

use Scalar::Util qw(blessed);
use Carp;


our ( $_symbol_throw, $_symbol_rethrow, $_symbol_raise, $_symbol_class,
      $_symbol_isa, $_symbol_fields, $_symbol_field, $_symbol_message,
      $_symbol_error);

my @symbols = qw( throw rethrow raise class isa fields field message error );

# regexp to extract header's type and flags
my $only_header_r = qr/(\[[^]|]+\|[^]]*\|\])/;
my $header_r = qr/\[([^]|]+)(\|([^]]*)\|)\]/;
my $klass_r  = qr/^([_a-zA-Z:][_a-zA-Z0-9:]*)$/;
my $field_name_r = qr/^([_a-zA-Z][_a-zA-Z0-9]*)$/;
my $field_value_r = qr/^([^\034:|]*)$/;
my $field_value_b64_r = qr|^\034([A-Za-z0-9+/=]+)$|;
my $is_b64 = qr|^(\034[A-Za-z0-9+/=]*)$|;

no strict 'refs';
no warnings qw(once);

my %registered;
my %throw_aliases;
my %name_aliases;

use MIME::Base64;

sub _encode {
    defined $_[0]
      or return '';
    $_[0] =~ $field_value_r
      and return $_[0];
    "\034" . encode_base64($_[0], '');
}

sub _decode {
    my ($t) = $_[0] =~ $field_value_b64_r
      or return $_[0];
    decode_base64($t);
}

sub dor ($$) { defined $_[0] ? $_[0] : $_[1] }

sub Fields { return (); }

sub _fields_hashref { +{ map { $_ => 1 } $_[0]->Fields() } }

sub import {
    my ($class, %options) = @_;
    my $caller = caller;

    my $method_prefix = dor($options{method_prefix}, 'x');

    foreach (@symbols) {
        defined ${"${caller}::${method_prefix}$_"}
          and next;
        defined ${"${class}::_symbol_$_"}
          or next;
        *{"${caller}::${method_prefix}$_"} = \${"${class}::_symbol_$_"}
    } 

    foreach my $k (keys %throw_aliases) {
        my $v = $throw_aliases{$k};
        $caller->can($k)
          or *{"${caller}::$k"} = sub { $v->throw(@_) };
    }

    foreach my $k (keys %name_aliases) {
        my $v = $name_aliases{$k};
        $caller->can($k)
          or *{"${caller}::$k"} = sub () { $v };
    }
}

sub declare_exceptions {
    my $class = shift;
    my $caller = caller;

    while ( scalar @_ ) {
        my $klass = shift;
        dor($klass, '') =~ $klass_r or _croak(class => $klass);
        my $isa = $class;
        my ($override, @fields);
        if (my $r = ref $_[0] ) {
            $r eq 'HASH' or _croak('exception definition structure' => $r,
                                   'It should be HASH');
            my %h = %{shift()};
            $override = $h{override};
            @fields =
              map { dor($_, '') =~ $field_name_r or _croak(field => $_); $_ }
              @{ dor($h{fields}, []) };
            $h{isa} and $isa = $h{isa};

            if (length(dor( my $throw_alias = $h{throw_alias}, ''))) {
                defined $throw_aliases{$throw_alias}
                  and _croak(throw_alias => $throw_alias, 'It has already been defined');
                $throw_aliases{$throw_alias} = $klass;
            }

            if (length(dor( my $name_alias = $h{name_alias}, ''))) {
                defined $name_aliases{$name_alias}
                  and _croak(name_alias => $name_alias, 'It has already been defined');
                $name_aliases{$name_alias} = $klass;
            }
        }

        ! $override && $registered{$klass}
          and _croak(class => $klass, 'It has already been registered');

        unshift @{"${klass}::ISA"}, $isa;
        @{"${klass}::_internal_fields"} = @fields;
        eval "package $klass; sub Fields { (\$_[0]->SUPER::Fields, \@${klass}::_internal_fields) }";
        $registered{$klass} = 1;
    }

    foreach my $k (keys %throw_aliases) {
        my $v = $throw_aliases{$k};
        $caller->can($k)
          or *{"${caller}::$k"} = sub { $v->throw(@_) };
    }

    foreach my $k (keys %name_aliases) {
        my $v = $name_aliases{$k};
        $caller->can($k)
          or *{"${caller}::$k"} = sub () { $v };
    }

}

sub _croak { croak $_[0] . " '" . dor($_[1], '<undef>') . "' is invalid" . ($_[2] ? ". $_[2]" : '') }

# Class methods

sub new {
    my ($class, $message, %fields) = @_;
    $registered{$class} or croak "exception class '$class' has not been registered yet";
    '[' . $class . '|' . join('|',
      map  { $_ . ':' . _encode($fields{$_}) }
      grep { $class->_fields_hashref()->{$_}
             or croak "invalid field '$_', exception class '$class' didn't declare it"
           }
      keys %fields
    ) . '|]' . dor($message, '');
}

sub raise { croak shift->new(@_)}
sub throw { croak shift->new(@_)}

sub registered_fields {
    my ($class) = @_;
    $class->Fields();
}

sub registered_exception_classes { keys %registered }

# fake methods (class methods with exception as first argument)

$_symbol_throw   = sub { croak $_[0] };
$_symbol_rethrow = sub { die $_[0] };
$_symbol_raise   = sub { croak $_[0] };

$_symbol_class = sub {
    my ($class) = $_[0] =~ $header_r
      or _croak(exception => $_[0]);
    $class;
};

$_symbol_isa = sub {
    my $class = blessed($_[0]);
    if ( ! defined $class ) {
        ($class) = $_[0] =~ $header_r
          or return;
    }
    $class->isa($_[1]);
};

$_symbol_fields = sub {
    my ($class, $fields) = $_[0] =~ $header_r
      or _croak(exception => $_[0]);
    map { (split(/:/, $_))[0] } split(/\|/, $fields);
};

$_symbol_field = sub {
    my $f = $_[1];
    my ($class, $fields) = $_[0] =~ $header_r
      or _croak(exception => $_[0]);
    my $regexp = qr/\|$f:(.*?)\|/;
    $class->_fields_hashref()->{$f}
      or _croak(field => $f, "It is unknown for this exception class ('$class')");
    if (@_ < 3) {
        defined (my $value = ($fields =~ $regexp)[0])
          or return;
        return _decode( $value );
    }

    $fields =~ s/$regexp/|/;
    $fields =~ s/^\|\|$/|/;
    my $v = _encode($_[2]);
    my $was_ro = Internals::SvREADONLY($_[0]);
    Internals::SvREADONLY($_[0] => 0);
    $_[0] =~ s/$header_r/[$class$fields$f:$v|]/;
    Internals::SvREADONLY($_[0] => $was_ro);
    return;
};

$_symbol_message = sub {
    if (@_ < 2) {
        my $message = $_[0];
        $message =~ s/$only_header_r//
          or _croak(exception => $_[0]);
        return $message;
    }

    my ($header) = $_[0] =~ $only_header_r
      or _croak(exception => $_[0]);
    my $was_ro = Internals::SvREADONLY($_[0]);
    Internals::SvREADONLY($_[0] => 0);
    $_[0] = "$header$_[1]";
    Internals::SvREADONLY($_[0] => $was_ro);
    return $_[0];
};

$_symbol_error = $_symbol_message;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Stringy - a Perl Exceptions module where exceptions are not objects but simple strings.

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  use Exception::Stringy;
  Exception::Stringy->declare_exceptions(
      'MyException',
   
      'YetAnotherException' => {
          isa         => 'AnotherException',
      },
   
      'ExceptionWithFields' => {
          isa    => 'YetAnotherException',
          fields => [ 'grandiosity', 'quixotic' ],
          throw_alias  => 'throw_fields',
      },
  );
  
  ### with Try::Tiny
  
  use Try::Tiny;
   
  try {
      # throw an exception
      MyException->throw('I feel funny.');
  
      # or use an alias
      throw_fields 'Error message', grandiosity => 1;

      # or with fields
      ExceptionWithFields->throw('I feel funny.',
                                 quixotic => 1,
                                 grandiosity => 2);

      # you can build exception step by step
      my $e = ExceptionWithFields->new("The error message");
      $e->$xfield(quixotic => "some_value");
      $e->$xthrow();
  
  }
  catch {
      if ( $_->$xisa('Exception::Stringy') ) {
          warn $_->$xerror, "\n";
      }
  
      if ( $_->$xisa('ExceptionWithFields') ) {
          if ( $_->$xfield('quixotic') ) {
              handle_quixotic_exception();
          }
          else {
              handle_non_quixotic_exception();
          }
      }
      else {
          $_->$xrethrow;
      }
  };
   
  ### without Try::Tiny
   
  eval {
      # ...
      MyException->throw('I feel funny.');
      1;
  } or do {
      my $e = $@;
      # .. same as above with $e instead of $_
  }

=head1 DESCRIPTION

This module allows you to declare exceptions, and provides a simple interface
to declare, throw, and interact with them. It can be seen as a light version of
C<Exception::Class>, except that there is a catch: exceptions are
B<not objects>, they are B<normal strings>, with a pattern that contains properties.

This modules has one external dependancy: C<Scalar::Util>. It requires Perl 5.8.9 or above.

=head1 WHY WOULD YOU WANT SUCH THING ?

Having exceptions be objects is sometimes very annoying. What if some code is
calling you, and isn't expecting objects exceptions ? Sometimes string
overloading doesn't work. Sometimes, external code tamper with your exception.
Consider:

  use Exception::Class ('MyException');
  use Scalar::Util qw( blessed );
  use Try::Tiny;

  $SIG{__DIE__} = sub { die "FATAL: $_[0]" };

  try {
    MyException->throw("foo");
  } catch {
    die "this is not a Exception::Class" unless blessed $_ && $_->isa('Exception::Class');
    if ($_->isa('MyException')) { ... }
  };

In this example, the exception thrown is a C<Exception::Class> instance, but it
gets forced to a string by the signal handler. When in the catch block, it's
not an object anymore, it's a regular string, and the code fails to see that
it's was once 'MyException'.

Using C<Exception::Stringy>, exceptions are regular strings, that embed in
themselves a small pattern to contain their properties. They can be
stringified, concatenated, and tampered with in any way, as long as the pattern
isn't removed (it can be moved inside the string though).

As a result, exceptions are more robust, while still retaining all features
you'd expect from similar modules like L<Exception::Class>

  use Exception::Stringy;
  Exception::Stringy->declare_exceptions('MyException');
  use Try::Tiny;

  $SIG{__DIE__} = sub { die "FATAL: $_[0]" };

  try {
    MyException->throw("foo");
  } catch {
    die "this is not a Exception::Stringy" unless $_->$xisa('Exception::Stringy');
    if ($_->$xisa('MyException')) { ... }
  };

=head1 BASIC USAGE

=head2 Registering exception classes

Defining exception classes is done by calling C<declare_exceptions>:

  use Exception::Stringy;
  Exception::Stringy->declare_exceptions(
    'MyException',
    'ExceptionWithFields' => {
          isa    => 'MyException',
          fields => [ qw(field1 field2) ],
          throw_alias  => 'throw_fields',
    },
  );

In the previous code, C<MyException> is a simple exception, with no field, and
it simply inherits from C<Exception::Stringy> (all exceptions inherits from
it). C<ExceptionWithFields> inherits from C<MyException>, has two fields
defined, and C<throw_fields> can be used as a shortcut to throw it.

Here are the details about what can be in the exception definitions:

=head3 class name

The keys of the definition's hash are reggular class name string, with an
exception: they cannot start with a underscore ( C<_> ), keys starting with an
underscore are reserved for options specification (see L<ADVANCED OPTIONS>);

=head3 isa

Expects a name (Str). If set, the exception will inherit from the given name.
Using this mechanism, an exception class can inherits fields from an other
exception class, and add its own fields. Only simple inlheritance is supported.

=head3 fields

Expects a list of field names (ArrayRef). If set, the exceptions will be able
to set/get these fields. Fields values should be short scalars (no references).

=head3 throw_alias

Expects a function name (Str). If set, the user will be able to use this
function as a shortcut to throw the exception. From the example above,
C<throw_fields(...)> will be equivalent to C<<ExceptionWithFields->throw(...)>>

=head3 name_alias

Expects a function name (Str). If set, the user will be able to use this name
as an alias for the class name. Warning, if you use it, make sure to enclose
the C<declare_exceptions> call in a C<BEGIN> block, otherwise the alias won't
be available in the rest of the file (it will however be available in other
modules loading it)

=head3 override

Expects a boolean (defaults to false). If set to true, then an already
registered exception can be updated.

=head2 throwing exceptions

  ExceptionWithFields->throw("error message", grandiosity => 42);

=head2 catching and checking exceptions

The pseudo methods (see below) are loaded when C<use>-ing the C<Exception::Stringy> module:

  use Exception::Stringy;
  eval { ... 1; } or do {
    my $e = $@;
    if ($e->$xisa('Exception::Stringy')) {
      if ($e->$xisa('ExceptionWithFields')) {
        ...
      } elsif ($e->$xisa('YetAnotherException')) {
        ...
      }
    } else {
      # this works on anything, even objects or bare strings
      e->$xrethrow;
    }
  };

=head1 CLASS METHODS

=head2 declare_exceptions

See L<BASIC USAGE> above.

=head2 raise, throw

  # both are exactly the same
  ExceptionWithFields->throw("error message", grandiosity => 42);
  ExceptionWithFields->raise("error message", grandiosity => 42);

Creates a string exception from the given class, with the error message and
fields, then throws the exception. The exception is thrown using C<croak()>
from the C<Carp> module.

The error message is always the first argument. If ommited, it'll default to
empty string. Optional fields are provided as flat key / value pairs.

=head2 new

  my $e = ExceptionWithFields->new("error message", grandiosity => 42);

Takes the same arguments as C<throw()> but doesn't throw the exception.
Instead, the exception is returned.

=head2 registered_fields 

  my @fields = ExceptionWithFields->registered_fields;

Returns the possible fields that an exception of the given class can have.

=head2 registered_exception_classes

  my @class_names = Exception::Stringy->registered_exception_classes;

Returns the exceptions classes that have been registered.

=head1 (pseudo) METHODS

The syntax is a bit strange, but that's because exceptions are bare strings,
and not blessed references, so we have to use a trick to have the arrow syntax
working.

By default, the methods are prefixed by C<x> (mnemonic: eXception) but you
can change that by specifying a other C<method_prefix> option at import time
(see L<IMPORT OPTIONS> below)

=head2 $xthrow(), $xrethrow(), $xraise()

  $exception->$xthrow();
  $exception->$xrethrow();
  $exception->$xraise();

Throws the exception.

=head2 $xclass()

  my $class = $exception->$xclass();

Returns the exception class name.

=head2 $xisa()

  if ($exception->$xisa('ExceptionClass')) {... }

Returns true if the class of the given exception C<->isa()> the class given in
parameter. Otherwise, return false.

C<$xisa> is more useful than it seems:

=over

=item *

When applied on an C<Exception::Stringy> exception, it'll properly etract the
exception class and perform the C<isa> call on it.

=item *

When applied on a blessed reference, it'll do the right thing, and work like standard C<isa()>.

=item *

When applied on something else, it won't die, but return false.

=back

So it means that you can safely use C<$exception->$xisa('SomeClass')> whatever
C<$exception> is, no need to do additional testing on it.

=head2 $xfields()

  my @fields = $exception->$xfields();

Returns the list of field names that are in the exception.

=head2 $xfield()

  my $value = $exception->$xfield('field_name');

  $exception->$xfield(field_name => $value);

Set or get the given field. If the value contains one of the following
caracters, then it is transparently base64 encoded and decoded.

The list of forbidden caracters are:

=over

=item C<:>

the semicolon

=item C<|>

the pipe

=item C<\034>

C<\034>, the 0x28 seperator ASCII caracter.

=back

=head2 $xmessage(), $xerror()

  my $text = $exception->$xmessage();
  my $text = $exception->$xerror();

  $exception->$xmessage("Error message");
  $exception->$xerror("Error message");

Set or get the error message of the exception

=head1 GOOD PRACTISES

=head2 exceptions declaration

It's often useful to gather exceptions declarations in a common module. You can
easily do that, because declaring new exceptions is decoupled from C<use>-ing
the module. All you need is to implement a module that uses
C<<Exception::Stringy->declare_exceptions(...)>> one or more times. Other
modules can then use this module. Note however that they also will have to
C<use> C<Exception::Stringy> to have pseudo-methods imported in their
namespaces.

=head2 exceptions naming

It's recommended to use normal class names, with a common prefix, like
C<MyException::Network::Connection>, and to reflect the inheritance
relationship within the name. So C<MyException::Networking::Connection> would
inherit from C<MyException::Networking>. Multiple inheritance or roles aren't
provided by this package.

=head2 mixing with exception objects

Sometimes, you'll have to work with some of the exceptions being
C<Exception::Stringy> exceptions, and some other exceptions being objects
(blessedd references), for example coming from C<Exception::Class>.

In this case, I recommend using C<$xisa> method to handle them appropriately,
as C<$exception->$xisa('SomeClass')> will work on any type of C<$exception>,
and will not die. Instead, it'll always return a true or false value.

=head1 IMPORT OPTIONS

  use Exception::Stringy (
      method_prefix => 'exception_',
  );
  Exception::Stringy->declare_exceptions('MyException');


  my $e = MyException->new("error message");
  say $e->$exception_message();

When C<use>-ing this module, you can specify parameters as a Hash. Here is as
list of supported options:

=head3 method_prefix

If set, pseudo methods imported in the calling methods use the specified
prefix. By default, it is C<x>, so methods will look like:

  $e->$xthrow();
  $e->$xfields();
  ...

But if for instance you specify method_prefix to be instead C<exception_>, then
imported pseudo methods will be like this:

  $e->$exception_throw();
  $e->$exception_fields();
  ...

=for Pod::Coverage Fields dor

=head1 AUTHOR

Damien Krotkine <dams@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Damien Krotkine.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
