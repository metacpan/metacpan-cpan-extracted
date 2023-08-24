package FFI::Platypus::Lang::Rust;

use strict;
use warnings;
use File::Glob qw( bsd_glob );
use File::Which qw( which );
use File::Spec;
use Env qw( @PATH );

# ABSTRACT: Documentation and tools for using Platypus with the Rust programming language
our $VERSION = '0.17'; # VERSION


sub native_type_map
{
  require FFI::Platypus;
  {
    u8       => 'uint8',
    u16      => 'uint16',
    u32      => 'uint32',
    u64      => 'uint64',
    i8       => 'sint8',
    i16      => 'sint16',
    i32      => 'sint32',
    i64      => 'sint64',
    binary32 => 'float',    # need to check this is right
    binary64 => 'double',   #  "    "  "     "    "  "
    f32      => 'float',
    f64      => 'double',
    bool     => 'sint8',    # in practice, but not guaranteed by spec
    usize    => FFI::Platypus->type_meta('size_t')->{ffi_type},
    isize    => FFI::Platypus->type_meta('ssize_t')->{ffi_type},
  },
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Lang::Rust - Documentation and tools for using Platypus with the Rust programming language

=head1 VERSION

version 0.17

=head1 SYNOPSIS

Rust:

 #![crate_type = "cdylib"]
 
 #[no_mangle]
 pub extern "C" fn add(a: i32, b: i32) -> i32 {
     a + b
 }

Perl:

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 $ffi->lib(
     find_lib_or_die(
         lib        => 'add',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 
 $ffi->attach( add => ['i32', 'i32'] => 'i32' );
 
 print add(1,2), "\n";  # prints 3

=head1 DESCRIPTION

This module provides native Rust types for L<FFI::Platypus> in order to
reduce cognitive load and concentrate on Rust and forget about C types.
This document also documents issues and caveats that I have discovered
in my attempts to work with Rust and FFI.

Note that in addition to using pre-compiled Rust libraries, you can
bundle Rust code with your Perl distribution using L<FFI::Build> and
L<FFI::Build::File::Cargo>.

=head1 EXAMPLES

The examples in this discussion are bundled with this distribution and
can be found in the C<examples> directory.

=head2 Passing and Returning Integers

=head3 Rust Source

 #![crate_type = "cdylib"]
 
 #[no_mangle]
 pub extern "C" fn add(a: i32, b: i32) -> i32 {
     a + b
 }

=head3 Perl Source

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 $ffi->lib(
     find_lib_or_die(
         lib        => 'add',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 
 $ffi->attach( add => ['i32', 'i32'] => 'i32' );
 
 print add(1,2), "\n";  # prints 3

=head3 Execute

 $ rustc add.rs
 $ perl add.pl
 3

=head3 Notes

Basic types like integers and floating points are the easiest to pass
across the FFI boundary.  The Platypus Rust language plugin (this module)
provides the basic types used by Rust (for example: C<bool>, C<i32>, C<u64>,
C<f64>, C<isize> and others) will all work as a Rust programmer would expect.
This is nice because you don't have to think about what the equivalent types
would be in C when you are writing your Perl extension in Rust.

Rust symbols are "mangled" by default, which means that you cannot use
the name of the function from the source code without knowing what the
mangled name is.  Rust provides a function attribute C<#[no_mangle]>
which will tell the compiler not to mangle the name, making lookup of
the symbol possible from other programming languages like Perl.

Rust functions do not use the same ABI as C by default, so if you want
to be able to call Rust functions from Perl they need to be declared
as C<extern "C"> as in this example.

We also set the "crate type" to C<cdylib> in the first line to tell the
Rust compiler to generate a dynamic library that will be consumed by
a non-Rust language like Perl.

=head2 String Arguments

=head3 Rust Source

 #![crate_type = "cdylib"]
 
 use std::ffi::CStr;
 use std::os::raw::c_char;
 
 #[no_mangle]
 pub extern "C" fn how_many_characters(s: *const c_char) -> isize {
     if s.is_null() {
         return -1;
     }
 
     let s = unsafe { CStr::from_ptr(s) };
 
     match s.to_str() {
         Ok(s) => s.chars().count() as isize,
         Err(_) => -2,
     }
 }

=head3 Perl Source

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 $ffi->lib(
     find_lib_or_die(
         lib        => 'argument',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 
 $ffi->attach( how_many_characters => ['string'] => 'isize' );
 
 print how_many_characters(undef), "\n";           # prints -1
 print how_many_characters("frooble bits"), "\n";  # prints 12

=head3 Execute

 $ rustc argument.rs
 $ perl argument.pl
 -1
 12

=head3 Notes

Strings are considerably more complicated for a number of reasons,
but for passing them into Rust code the main challenge is that the
representation is different from what C uses.  C Uses NULL terminated
strings and Rust uses a pointer and size combination that allows
NULLs inside strings.  Perls internal representation of strings is
actually closer to what Rust uses, but when Perl talks to other
languages it typically uses C Strings.

Getting a Rust string slice C<&str> requires a few stems

=over 4

=item We have to ensure the C pointer is not C<NULL>

We return C<-1> to indicate an error here.  As we can see from the
calling Perl code passing an C<undef> from Perl is equivalent to
passing in C<NULL> from C.

=item Wrap using C<Cstr>

We then wrap the pointer using an C<unsafe> block.  Even though
we know at this point that the pointer cannot be C<NULL> it could
technically be pointing to uninitialized or unaddressable memory.
This C<unsafe> block is unfortunately necessary, though it is
relatively isolated so it is easy to reason about and review.

=item Convert to UTF-8

If the string that we passed in is valid UTF-8 we can convert
it to a C<&str> using C<to_str> and compute the length of the
string.  Otherwise, we return -2 error.

=back

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/string_arguments/>)

=head2 Returning allocated strings

=head3 Rust Source

 #![crate_type = "cdylib"]
 
 use std::ffi::CString;
 use std::iter;
 use std::os::raw::c_char;
 
 #[no_mangle]
 pub extern "C" fn theme_song_generate(length: u8) -> *mut c_char {
     let mut song = String::from("💣 ");
     song.extend(iter::repeat("na ").take(length as usize));
     song.push_str("Batman! 💣");
 
     let c_str_song = CString::new(song).unwrap();
     c_str_song.into_raw()
 }
 
 #[no_mangle]
 pub extern "C" fn theme_song_free(s: *mut c_char) {
     if s.is_null() {
         return;
     }
     unsafe { CString::from_raw(s) };
 }

=head3 Perl Source

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 $ffi->lib(
     find_lib_or_die(
         lib        => 'return',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 
 $ffi->attach( theme_song_free     => ['opaque'] => 'void'   );
 
 $ffi->attach( theme_song_generate => ['u8']     => 'opaque' => sub {
     my($xsub, $length) = @_;
     my $ptr = $xsub->($length);
     my $str = $ffi->cast( 'opaque' => 'string', $ptr );
     theme_song_free($ptr);
     $str;
 });
 
 print theme_song_generate(42), "\n";

=head3 Execute

 $ rustc return.rs
 $ perl return.pl
 💣 na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na na Batman! 💣

=head3 Notes

The big challenge of returning strings from Rust into Perl is
handling the ownership.  In this example we have a C API implemented
in Rust that returns a C NULL terminated string, but we have to
pass it back into Rust in order to deallocate it when we are done.

Unfortunately Platypus' C<string> type assumes that the callee
retains ownership of the returned string, so we have to get the
pointer instead as an C<opaque> so that we can later free it.
Before freeing it though we cast it into a Perl string.

In order to hide the complexities from caller of our
C<theme_song_generate> function, we use a function wrapper to
do all of that for us.

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/string_return/>)

=head2 Returning allocated strings, but keeping ownership

=head3 Rust Source

 #![crate_type = "cdylib"]
 
 use std::cell::RefCell;
 use std::ffi::CString;
 use std::iter;
 use std::os::raw::c_char;
 
 #[no_mangle]
 pub extern "C" fn theme_song_generate(length: u8) -> *const c_char {
     thread_local! {
         static KEEP: RefCell<Option<CString>> = RefCell::new(None);
     }
 
     let mut song = String::from("💣 ");
     song.extend(iter::repeat("na ").take(length as usize));
     song.push_str("Batman! 💣");
 
     let c_str_song = CString::new(song).unwrap();
 
     let ptr = c_str_song.as_ptr();
 
     KEEP.with(|k| {
         *k.borrow_mut() = Some(c_str_song);
     });
 
     ptr
 }

=head3 Perl Source

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 $ffi->lib(
     find_lib_or_die(
         lib        => 'keep',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 
 $ffi->attach( theme_song_generate => ['u8'] => 'string' );
 
 print theme_song_generate($_), "\n" for 1..10;

=head3 Execute

 $ rustc keep.rs
 $ perl keep.pl
 💣 na Batman! 💣
 💣 na na Batman! 💣
 💣 na na na Batman! 💣
 💣 na na na na Batman! 💣
 💣 na na na na na Batman! 💣
 💣 na na na na na na Batman! 💣
 💣 na na na na na na na Batman! 💣
 💣 na na na na na na na na Batman! 💣
 💣 na na na na na na na na na Batman! 💣
 💣 na na na na na na na na na na Batman! 💣

=head3 Notes

For frequently called functions with smaller strings it may make more
sense to keep ownership of the string and just return a pointer.  Perl
makes its own copy on return anyway when you use the C<string> type.

In this example we use thread local storage to keep the C<CString>
until the next call when it will be freed.  Since we are using thread
local storage, it should even be safe to use this interface from a
threaded Perl program (although you should probably not be using
threaded Perl).

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/string_arguments/>)

=head2 Return static strings

=head3 Rust Source

 #![crate_type = "cdylib"]
 
 #[no_mangle]
 pub extern "C" fn hello_rust() -> *const u8 {
     "Hello, world!\0".as_ptr()
 }

=head3 Perl Source

 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 use FFI::Platypus 1.00;
 
 my $ffi = FFI::Platypus->new( api => 1, lang => 'Rust');
 $ffi->lang('Rust');
 $ffi->lib(
     find_lib_or_die(
         lib        => 'static',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 $ffi->lib('./libstring.so');
 $ffi->attach(hello_rust => [] => 'string');
 
 print hello_rust(), "\n";

=head3 Execute

 $ rustc static.rs
 $ perl static.pl
 Hello, world!

=head3 Notes

Sometimes you just want to return a static NULL terminated string
from Rust to Perl.  This can sometimes be useful for returning
error messages.

=head2 Callbacks

=head3 Rust Source

 #![crate_type = "cdylib"]
 
 use std::ffi::CString;
 use std::os::raw::c_char;
 
 type PerlLog = extern "C" fn(line: *const c_char);
 
 #[no_mangle]
 pub extern "C" fn rust_log(logf: PerlLog) {
     let lines: [&str; 3] = ["Hello from rust!", "Something else.", "The last log line"];
 
     for line in lines.iter() {
         // convert string slice to a C style NULL terminated string
         let line = CString::new(*line).unwrap();
         logf(line.as_ptr());
     }
 }

=head3 Perl Source

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 $ffi->lib(
     find_lib_or_die(
         lib        => 'callback',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 
 $ffi->type( '(string)->void' => 'PerlLog' );
 $ffi->attach( rust_log => ['PerlLog'] );
 
 my $perl_log = $ffi->closure(sub {
     my $message = shift;
     print "log> $message\n";
 });
 
 rust_log($perl_log);

=head3 Execute

 $ rustc callback.rs
 $ perl callback.pl
 log> Hello from rust!
 log> Something else.
 log> The last log line

=head3 Notes

Calling back into Perl from Rust is easy, so long as you have the correct
types defined.  The above Rust function takes a C function pointer.  We
can crate a Platypus closure object from Perl from a plain Perl sub and
pass the closure into Rust.

=head2 Slice arguments

=head3 Rust Source

 #![crate_type = "cdylib"]
 
 use std::slice;
 
 #[no_mangle]
 pub extern "C" fn sum_of_even(numbers: *const u32, len: usize) -> i64 {
     if numbers.is_null() {
         return -1;
     }
 
     let numbers = unsafe { slice::from_raw_parts(numbers, len) };
 
     let sum: u32 = numbers.iter().filter(|&v| v % 2 == 0).sum();
     sum as i64
 }

=head3 Perl Source

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 $ffi->lib(
     find_lib_or_die(
         lib        => 'slice',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 
 $ffi->attach( sum_of_even => ['u32*', 'usize'] => 'i64' );
 
 print sum_of_even(undef, 0), "\n";          # print -1
 print sum_of_even([1,2,3,4,5,6], 6), "\n";  # print 12

=head3 Execute

 $ rustc slice.rs
 $ perl slice.pl
 -1
 12

=head3 Notes

A Rust slice is a pointer to a chunk of homogeneous data, and the
number of elements in the slice.  We can pass these two pieces in
from Perl and combine them into a slice in Rust.

This example sums the even numbers from a slice and returns the
result.

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/slice_arguments/>)

=head2 Tuples

=head3 Rust Source

 #![crate_type = "cdylib"]
 
 use std::convert::From;
 
 // A Rust function that accepts a tuple
 fn flip_things_around_rust(tup: (u32, u32)) -> (u32, u32) {
     let (a, b) = tup;
     (b + 1, a - 1)
 }
 
 // A struct that can be passed between C and Rust
 #[repr(C)]
 pub struct Tuple {
     x: u32,
     y: u32,
 }
 
 // Conversion functions
 impl From<(u32, u32)> for Tuple {
     fn from(tup: (u32, u32)) -> Tuple {
         Tuple { x: tup.0, y: tup.1 }
     }
 }
 
 impl From<Tuple> for (u32, u32) {
     fn from(tup: Tuple) -> (u32, u32) {
         (tup.x, tup.y)
     }
 }
 
 // The exported C method
 #[no_mangle]
 pub extern "C" fn flip_things_around(tup: Tuple) -> Tuple {
     flip_things_around_rust(tup.into()).into()
 }

=head3 Perl Source

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 $ffi->lib(
     find_lib_or_die(
         lib        => 'tuple',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 
 package Tuple;
 
 use FFI::Platypus::Record;
 
 use overload
   '""' => sub { shift->as_string },
   bool => sub { 1 }, fallback => 1;
 
 record_layout_1($ffi, qw(
   u32 x
   u32 y
 ));
 
 sub as_string {
   my $self = shift;
   sprintf "[%d,%d]", $self->x, $self->y;
 }
 
 package main;
 
 $ffi->type('record(Tuple)' => 'tuple_t');
 $ffi->attach( flip_things_around => ['tuple_t'] => 'tuple_t' );
 
 print flip_things_around(Tuple->new(x => 10, y => 20)), "\n";

=head3 Execute

 $ rustc tuple.rs
 $ perl tuple.pl
 [21,9]

=head3 Notes

Rust's tuples do not have a standard representation that can be used
directly from Perl, but if your tuple contains only simple types you
can use the L<Platypus Record class|FFI::Platypus::Record> and translate
in Rust between the tuple and the C<struct>.

Because we are passing in and out the entire C<struct>, not pointers
to a C<struct> we don't have to worry about freeing them from Perl.
They just get allocated and freed on the stack.

(This example is based on one provided in the
L<Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/tuples/>)

=head2 Objects

=head3 Rust Source

 use std::cell::RefCell;
 use std::ffi::c_void;
 use std::ffi::CStr;
 use std::ffi::CString;
 use std::os::raw::c_char;
 
 struct Person {
     name: String,
     lucky_number: i32,
 }
 
 impl Person {
     fn new(name: &str, lucky_number: i32) -> Person {
         Person {
             name: String::from(name),
             lucky_number: lucky_number,
         }
     }
 
     fn get_name(&self) -> String {
         String::from(&self.name)
     }
 
     fn set_name(&mut self, new: &str) {
         self.name = new.to_string();
     }
 
     fn get_lucky_number(&self) -> i32 {
         self.lucky_number
     }
 }
 
 type CPerson = c_void;
 
 #[no_mangle]
 pub extern "C" fn person_new(
     _class: *const c_char,
     name: *const c_char,
     lucky_number: i32,
 ) -> *mut CPerson {
     let name = unsafe { CStr::from_ptr(name) };
     let name = name.to_string_lossy().into_owned();
     Box::into_raw(Box::new(Person::new(&name, lucky_number))) as *mut CPerson
 }
 
 #[no_mangle]
 pub extern "C" fn person_name(p: *mut CPerson) -> *const c_char {
     thread_local!(
         static KEEP: RefCell<Option<CString>> = RefCell::new(None);
     );
 
     let p = unsafe { &*(p as *mut Person) };
     let name = CString::new(p.get_name()).unwrap();
     let ptr = name.as_ptr();
     KEEP.with(|k| {
         *k.borrow_mut() = Some(name);
     });
     ptr
 }
 
 #[no_mangle]
 pub extern "C" fn person_rename(p: *mut CPerson, new: *const c_char) {
     let new = unsafe { CStr::from_ptr(new) };
     let p = unsafe { &mut *(p as *mut Person) };
     if let Ok(new) = new.to_str() {
         p.set_name(new);
     }
 }
 
 #[no_mangle]
 pub extern "C" fn person_lucky_number(p: *mut CPerson) -> i32 {
     let p = unsafe { &*(p as *mut Person) };
     p.get_lucky_number()
 }
 
 #[allow(non_snake_case)]
 #[no_mangle]
 pub extern "C" fn person_DESTROY(p: *mut CPerson) {
     unsafe { Box::from_raw(p as *mut Person) };
 }
 
 #[cfg(test)]
 mod test;

=head3 Perl Source

Main class:

 package Person;
 
 use strict;
 use warnings;
 use FFI::Platypus 2.00;
 
 our $VERSION = '2.00';
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 
 # use the bundled code as a library
 $ffi->bundle;
 
 # use the person_ prefix
 $ffi->mangler(sub {
     my $symbol = shift;
     return "person_$symbol";
 });
 
 # Create a custom type mapping for the person_t (C) and Person (perl)
 # classes.
 $ffi->type( 'object(Person)' => 'person_t' );
 
 $ffi->attach( new          => [ 'string', 'string', 'i32' ] => 'person_t' );
 $ffi->attach( name         => [ 'person_t' ] => 'string' );
 $ffi->attach( rename       => [ 'person_t', 'string' ] );
 $ffi->attach( lucky_number => [ 'person_t' ] => 'i32' );
 $ffi->attach( DESTROY      => [ 'person_t' ] );
 
 1;

Test:

 use Test2::V0;
 use Person;
 
 my $plicease = Person->new("Graham Ollis", 42);
 
 is $plicease->name, "Graham Ollis";
 is $plicease->lucky_number, 42;
 
 $plicease->rename("Graham THE Ollis");
 
 is $plicease->name, "Graham THE Ollis";
 
 done_testing;

=head3 Execute

 $ prove -lvm t/basic.t
 t/basic.t ..
 # Seeded srand with seed '20221023' from local date.
 ok 1
 ok 2
 ok 3
 1..3
 ok
 All tests successful.
 Files=1, Tests=3,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.19 cusr  0.05 csys =  0.26 CPU)
 Result: PASS

=head3 Notes

This example includes excerpts from a full C<Person> dist which you can
find in the C<examples/Person> directory of this distribution.  You can
install it like a normal Perl distribution using L<ExtUtils::MakeMaker>,
or you can simply run the test file by using L<App::Prove>.  That is
because we are using L<FFI::Build> and L<FFI::Build::File::Cargo> to
build the Rust parts for us, which know how to work in either mode.
There are some stuff that we don't show you here for brevity: the
C<Makefile.PL> for example, and also the rust tests in C<ffi/src/test.rs>
which test the Rust crate by calling both its Rust and C interface.

What we have done here is created a Rust C<struct> and then written
C wrappers to create, query and modify the object.  We've also created
a destructor to free the object when we are done with it.

In terms of naming conventions, we use C<person_> prefix to denote that
these are methods for the Person class that we are creating.  This is
a common convention in C, where the only namespaces are adding prefixes
like this.  We also break the convention of using snake case for the
destructor C<person_DESTROY> because that will make it easier to bind
to from Perl.

When we creat the object we use C<Box::new> and C<Box::into_raw> to
create the object on the heap, and to return the opaque pointer back
to Perl.

For methods we can convert the raw pointers back into a Person C<struct>
using C<&*(p as *mut Person)> inside an C<unsafe> block.  In the case
of C<person_rename> we need a mutable version so we use C<&mut *(p as *mut Person)>
instead.

Finally when we are done with the object we can free it by simply
calling C<Box::from_raw>.  When it falls out of scope it will be freed.

On the Perl side, we use the C<mangler> method to prepend all symbols
with the C<person_> prefix, so that we can attach with just the method
name.

We also create a Platypus type for C<object(Person)> and give it the
alias C<person_t>.  Now we can use it as an argument and return type.
This is really a pointer to an opaque (to perl) C<struct>.

If you look at just the test, then you can't even tell that the implementation
for our Person class is in Rust, which is good because your users shouldn't
have to care!

=head2 Panic!

=head3 Rust Source

 #![crate_type = "cdylib"]
 
 use std::panic::catch_unwind;
 
 fn might_panic(i: u32) -> u32 {
     if i % 2 == 1 {
         panic!("oops!");
     }
     i / 2
 }
 
 #[no_mangle]
 pub extern "C" fn oopsie(i: u32) -> i64 {
     let result = catch_unwind(|| might_panic(i));
     match result {
         Ok(i) => i as i64,
         Err(_) => -1,
     }
 }

=head3 Perl Source

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
 $ffi->lib(
     find_lib_or_die(
         lib        => 'panic',
         libpath    => [dirname __FILE__],
         systempath => [],
     )
 );
 
 $ffi->attach( oopsie => ['u32'] => 'i64' );
 
 print oopsie(5), "\n";   # -1
 print oopsie(10), "\n";  # 5

=head3 Execute

 $ perl panic.pl
 thread '<unnamed>' panicked at 'oops!', panic.rs:7:9
 note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
 -1
 5

=head3 Notes

Be cautious about code that might C<panic!>.  A C<panic!> across the FFI
boundary is undefined behavior and usually results in a crash.  You will
want to catch the panic with a C<catch_unwind> and map to an appropriate
error result.  In this example, we have a function that returns the
integer passed in divided by 2.  It does not like odd numbers though and
will panic.  So we catch the panic and return -1 to indicate an error.
As you can see from the run we also get a rather ugly diagnostic, but
at least our program didn't crash!

=head1 METHODS

Generally you will not use this class directly, instead interacting with
the L<FFI::Platypus> instance.  However, the public methods used by
Platypus are documented here.

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::Rust->native_type_map;

This returns a hash reference containing the native aliases for the Rust
programming languages.  That is the keys are native Rust types and the
values are libffi native types.

=head1 CAVEATS

=over 4

=item The C<bool> type

As of this writing, the C<bool> type is in practice always a signed
8 bit integer, but this has not been guaranteed by the Rust specification.
This module assumes that it is a C<sint8> type, but if that ever
changes this module will need to be updated.

=back

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<FFI::Build::File::Cargo>

Bundle Rust code with your FFI / Perl extension.

=item L<The Rust FFI Omnibus|http://jakegoulding.com/rust-ffi-omnibus/>

Includes a number of examples of calling Rust from other languages.

=item L<The Rustonomicon - Foreign Function Interface|https://doc.rust-lang.org/nomicon/ffi.html>

Detailed Rust documentation on crossing the FFI barrier.

=item L<The Rust Programming Language - Unsafe Rust|https://doc.rust-lang.org/book/ch19-01-unsafe-rust.html>

Unsafe Rust in the Rust Programming Language book.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Andrew Grangaard (SPAZM)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
