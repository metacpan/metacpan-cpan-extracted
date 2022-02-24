package FFI::Platypus::Lang::CPP;

use strict;
use warnings;
use FFI::ExtractSymbols qw( extract_symbols );
use FFI::Platypus 1.00;

our $VERSION = '0.06';

=head1 NAME

FFI::Platypus::Lang::CPP - Documentation and tools for using Platypus with
the C++ programming language

=head1 SYNOPSIS

B<NOTE>: The original author of this module considered the techniques used by and
documented by this module to be somewhate experimental even back in 2015 when he
wrote it.  The original author now thinks that it is probably safer to write a C API
layer between your C++ library and Perl rather than try to call C++ directly as
advocated by this module.  While the original author has not yet deprecated this
module, users of this module should consider its limitations before using it.

C++:

 // on Linux compile with: g++ --shared -o basic.so basic.cpp
 // elsewhere, consult your C++ compiler documentation
 
 class Foo {
 
 public:
 
   // note you should avoid inlining functions
   // for classes you intend to use with FFI
   // as the compiler may not emit code/symbols
   // for those functions.
   Foo();
   ~Foo();
 
   int get_bar();
   void set_bar(int);
 
   int _size();
 
 private:
 
   int bar;
 
 };
 
 Foo::Foo()
 {
   bar = 0;
 }
 
 Foo::~Foo()
 {
 }
 
 int
 Foo::get_bar()
 {
   return bar;
 }
 
 void
 Foo::set_bar(int value)
 {
   bar = value;
 }
 
 int
 Foo::_size()
 {
   return sizeof(Foo);
 }

Perl:

 package Foo;
 
 use FFI::Platypus 1.00;
 use FFI::Platypus::Memory qw( malloc free );
 
 my $ffi = FFI::Platypus->new( api => 1 )
 $ffi->lang('CPP');
 $ffi->lib('./basic.so');
 
 $ffi->custom_type( Foo => {
   native_type => 'opaque',
   perl_to_native => sub { ${ $_[0] } },
   native_to_perl => sub { bless \$_[0], 'Foo' },
 });
 
 $ffi->attach( [ 'Foo::Foo()'     => '_new'     ] => ['Foo']  => 'void' );
 $ffi->attach( [ 'Foo::~Foo()'    => '_DESTROY' ] => ['Foo']  => 'void' );
 $ffi->attach( [ 'Foo::get_bar()' => 'get_bar'  ] => ['Foo']  => 'int'  );
 $ffi->attach( [ 'Foo::set_bar(int)'
                                  => 'set_bar'  ] => ['Foo','int']
                                                              => 'void' );
 
 my $size = $ffi->function('Foo::_size()' => [] => 'int')->call;
 
 sub new
 {
   my($class) = @_;
   my $ptr = malloc $size;
   my $self = bless \$ptr, $class;
   _new($self);
   $self;
 }
 
 sub DESTROY
 {
   my($self) = @_;
   _DESTROY($self);
   free($$self);
 }
 
 package main;
 
 my $foo = Foo->new;
 
 print $foo->get_bar, "\n";  # 0
 $foo->set_bar(22);
 print $foo->get_bar. "\n";  # 22

=head1 DESCRIPTION

This module provides some hooks for Platypus so that C++ names can be
mangled for you.  It uses the same primitive types as C.  This document
also documents issues and caveats that I have discovered in my attempts
to work with C++ and FFI.

This module is somewhat experimental.  It is also available for adoption
for anyone either sufficiently knowledgable about C++ or eager enough to
learn enough about C++.  If you are interested, please send me a pull
request or two on the project's GitHub.

There are numerous difficulties and caveats involved in using C++
libraries from Perl via FFI.  This document is intended to enlighten on
that subject.

Note that in addition to using pre-compiled C++ libraries you can bundle
C++ code with your Perl distribution using L<FFI::Build>.  For a
complete example, which attempts to address the caveats listed below you
can take a look at this sample distro on GitHub:

L<https://github.com/plicease/Color-FFI>

=head1 CAVEATS

In general I have done my research of FFI and C++ using the Gnu C++
compiler.  I have done some testing with C<clang> as well.

=head2 name mangling

C++ names are "mangled" to handle features such as function overloading
and the fact that some characters in the C++ names are illegal machine
code symbol names.  What this means is that the C++ member function
C<Foo::get_bar> looks like C<_ZN3Foo7get_barEv> to L<FFI::Platypus>.
What makes this even trickier is that different C++ compilers provide
different mangling formats.  When you use the L<FFI::Platypus#lang>
method to tell Platypus that you are intending to use it with C++, like
this:

 $ffi->lang('CPP');

it will mangle the names that you give it.  That saves you having to
figure out the "real" name for C<Foo::get_bar>.

The current implementation uses the C<c++filt> command or
L<FFI::Platypus::Lang::CPP::Demangle::XS> if it is installed.  If
C<c++filt> cannot be found at install time, then
L<FFI::Platypus::Lang::CPP::Demangle::XS> will be made a prerequsite, so
you can have some confidence that this feature will work even if your
platform does not provide C<c++filt>.  The XS module is not a
prerequsite when C<c++filt> IS found because using C<c++filt> does not
require invoking the compiler and may be more reliable.

You can turn off the use of L<FFI::Platypus::Lang::CPP::Demangle::XS>
completely by setting the environment varaible C<FFI_PLATYPUS_LANG_CPP_NO_XS>
to a Perl true value.  If set at install time it will also not add it
as a prereq.

If the approach to mangling C++ names described above does not work for
you, or if it makes you feel slightly queasy, then you can also write C
wrapper functions around each C++ method that you want to call from
Perl.  You can write these wrapper functions right in your C++ code
using the C<extern "C"> trick:

 class Foo {
   public:
     int bar() { return 1; }
 }
 
 extern "C" int
 my_bar(Class *foo)
 {
   return foo->bar();
 }

Then instead of attaching C<Foo::bar()> attach C<my_bar>.

 $ffi->attach( my_bar => [ 'Foo' ] => 'int' );

=head2 constructors, destructors and methods

Constructors and destructors are essentially just functions that do not
return a value that need to be called when the object is created and
when it is no longer needed (respectively).  They take a pointer to the
object (C<this>) as their first argument.  Constructors can take
additional arguments, as you might expect they just come after the
object itself.  Destructors take no arguments other than the object
itself (C<this>).

You need to alloate the memory needed for the object before you call the
constructor and free it after calling the destructor.  The tricky bit is
figuring out how much memory to allocate.  If you have access to the
header file that describes the class and a compiler you can compute the
size from within C++ and hand it off to Perl using a static method as I
did in the L</SYNOPSIS> above.

Regular methods also take the object pointer as their first argument.
Additional arguments follow, and they may or may not return a value.

=head2 inline functions

C++ compilers typically do not emit symbols for inlined functions.  If
you get a message like this:

 unable to find Foo::get_bar() at basic line 21

even though you are sure that class has that method, this is probably
the problem that you are having.  The Gnu C++ compiler, C<g++> has an
option to force it to emit the symbols, even for inlined functions:

 -fkeep-inline-functions     # use this

Clang has an option to do the opposite of this:

 -fvisibility-inlines-hidden # do not use this

but unhelpfully not a way to keep inlined functions.  This appears to be
a deliberate design decision made by the clang developers and it makes
sense for C++, since inline functions are typically defined in C++
header files (.h) so it is difficult to determine in which object file
the uninlined inlined functions should go.

If you have the source of the C++ and you can recompile it you can also
optionally change it to not use inlined functions.  In addition to
removing any C<inline> keywords from the source, you need to move the
implementations of any methods outside of the class body.  That is, do
not do this:

 class Foo {
   public:
     int bar() { return 1; } # WRONG
 }

Do this:

 class Foo {
   public:
     int bar();              # RIGHT
 }
 
 int
 Foo::bar()                  # RIGHT
 {
   return 1;
 }

=head2 the standard C++ library

If you are getting errors like this:

 unable to find Foo::Foo()

that can't be explained by the issues described above, set the
environment variable FFI_PLATYPUS_DLERROR to a true value and try again.
If you see a warning like this:

 error loading Foo.so: Foo.so: undefined symbol: __gxx_personality_v0

then you probably need to explicitly link with the standard C++ library.
The most portable way to deal with this is by using
L<ExtUtils::CppGuess>.

=head1 METHODS

Generally you will not use this class directly, instead interacting with
the L<FFI::Platypus> instance.  However, the public methods used by
Platypus are documented here.

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::CPP->native_type_map;

This returns a hash reference containing the native aliases for the
C++ programming languages.  That is the keys are native C++ types and the
values are libffi native types.

=cut

sub native_type_map
{
  require FFI::Platypus::Lang::C;
  return FFI::Platypus::Lang::C->native_type_map;
}

=head2 mangler

 my $mangler = FFI::Platypus::Lang::CPP->mangler($ffi->libs);
 # prints _ZN9MyInteger7int_sumEii
 print $mangler->("MyInteger::int_sum(int, int)");

Returns a subroutine reference that will "mangle" C++ names.

=cut

if((!$ENV{FFI_PLATYPUS_LANG_CPP_NO_XS}) && eval { require FFI::Platypus::Lang::CPP::Demangle::XS })
{
  *_demangle = \&FFI::Platypus::Lang::CPP::Demangle::XS::demangle;
}
else
{
  *_demangle = sub { `c++filt $_[0]` };
}

sub mangler
{
  my($class, @libs) = @_;

  my %mangle;

  foreach my $libpath (@libs)
  {
    extract_symbols($libpath,
      export => sub {
        my($symbol1, $symbol2) = @_;
        my $cpp_symbol = _demangle($symbol2);
        return unless defined $cpp_symbol;
        chomp $cpp_symbol;
        return if $cpp_symbol eq $symbol2;
        $mangle{$cpp_symbol} = $symbol1;
      },
    );
  }

  sub {
    defined $mangle{$_[0]} ? $mangle{$_[0]} : $_[0];
  };
}

1;

=head1 EXAMPLES

=head2 Using a C++ class without writing bundling any C/C++ code

The example in the L</SYNOPSIS> shows how you I<can> use a C++ class
without writing any wrapper code, though you will have to guess or
determine the instance size of the class.

=head2 Using a C++ class with a wrapper

(For the full source for this example, see examples/wrapper.{pl,cpp}
that came with this distribution)

Sometimes it is easier to write wrapper functions around your new and
delete operations.  Consider if you add these functions to the C++
source to the example in the L</SYNOPSIS>.

 // These could also be class methods
 extern "C" Foo*
 Foo_new()
 {
   return new Foo();
 }
 
 extern "C" void
 Foo_delete(Foo *foo)
 {
   delete foo;
 }

Now we can use this class without having to know I<in the perl code>
what the size of the class is.  We declare the constructor and
destructor in Perl space like this:

 $ffi->attach( [ 'Foo_new'        => 'new'      ] => []       => 'Foo' );
 $ffi->attach( [ 'Foo_delete'     => 'DESTROY'  ] => ['Foo']  => 'void' );

We've also removed the Perl C<new> and C<DESTROY> wrappers as they are
unnecessary now, and so the the C++ functions are attached directly to
their intended names.

=head2 Exceptions

(For the full source of this example, see examples/exception.{pl,cpp}
that came with this distribution)

If your library throws an exception and you do not catch it in C++ it
is going to kill your program.  As an example, suppose C<set_bar> in
the example above throws an exception:

 void
 Foo::set_bar(int value)
 {
   if(value > 512)
     throw new FooException("too hot");
   if(value < 0)
     throw new FooException("too cold");
    bar = value;
 }

Now if you try to use C<set_bar> with a bad value like this from Perl:

 $foo->set_bar(-2);

it will crash your Perl program.

 terminate called after throwing an instance of 'FooException'
 Abort

To handle this, you need to write a wrapper around the C<set_bar>
method.

 static FooException *last_exception = NULL;
 
 extern "C" FooException *
 Foo_get_exception()
 {
   return last_exception;
 }
 
 extern "C" void
 Foo_reset_exception()
 {
   if(last_exception != NULL)
     delete last_exception;
   last_exception = NULL;
 }
 
 extern "C" void
 Foo_set_bar(Foo *foo, int value)
 {
   try
   {
     Foo_reset_exception();
     foo->set_bar(value);
   }
   catch(FooException *e)
   {
     last_exception = e;
   }
 }

Next we will write an interface to the FooException class in Perl:

 package FooException;
 
 use overload '""' => sub { "exception: " . $_[0]->message . "\n" };
 
 $ffi->custom_type( FooException => {
   native_type => 'opaque',
   perl_to_native => sub { ${ $_[0] } },
   native_to_perl => sub {
     defined $_[0]
     ? (bless \$_[0], 'FooException')
     : ();
   },
 });
 
 $ffi->attach(
   [ 'Foo_get_exception' => 'get_exception' ] => [] => 'FooException'
 );
 
 $ffi->attach(
   [ 'FooException::message()' => 'message' ] => ['FooException'] => 'string'
 );

And finally we write a wrapper for the Perl C<set_bar> method.

 $ffi->attach( [ 'Foo_set_bar'    => '_set_bar' ] => ['Foo','int']
                                                              => 'void' );
 sub set_bar
 {
   my($self, $value) = @_;
   $self->_set_bar($value);
   my $error = FooException->get_exception;
   die $error if $error;
 }

And now when we give C<set_bar> a bogus value we get a Perl exception
instead of an application crash:

 exception: too cold

So we can easily wrap the call to C<set_bar> in a Perl eval if we want
to catch the exception and handle it.

=head1 SUPPORT

If something does not work as advertised, or the way that you think it
should, or if you have a feature request, please open an issue on this
project's GitHub issue tracker:

L<https://github.com/PerlFFI/FFI-Platypus-Lang-CPP/issues>

=head1 CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a
pull reequest on this project's GitHub repository:

L<https://github.com/PerlFFI/FFI-Platypus-Lang-CPP/issues>

Caution: if you do this too frequently I may nominate you as the new
maintainer.  Extreme caution: if you like that sort of thing.

This project's GitHub issue tracker listed above is not Write-Only.  If
you want to contribute then feel free to browse through the existing
issues and see if there is something you feel you might be good at and
take a whack at the problem.  I frequently open issues myself that I
hope will be accomplished by someone in the future but do not have time
to immediately implement myself.

Another good area to help out in is documentation.  I try to make sure
that there is good document coverage, that is there should be
documentation describing all the public features and warnings about
common pitfalls, but an outsider's or alternate view point on such
things would be welcome; if you see something confusing or lacks
sufficient detail I encourage documentation only pull requests to
improve things.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<FFI::Build> + L<FFI::Build::File::CXX>

Bundle C or C++ with your FFI / Perl extension.

=item L<ExtUtils::CppGuess>

Guess the appropriate C++ compiler / linker flags for your C compiler
platform combination.

=back

=head1 AUTHOR

Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

