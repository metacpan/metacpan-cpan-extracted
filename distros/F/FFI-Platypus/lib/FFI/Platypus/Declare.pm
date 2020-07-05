package FFI::Platypus::Declare;

use strict;
use warnings;
use Carp ();
use FFI::Platypus;

# ABSTRACT: Declarative interface to FFI::Platypus
our $VERSION = '1.31'; # VERSION


our $ffi    = {};
our $types  = {};

sub _ffi_object
{
  my($package, $filename) = caller(1);
  $ffi->{$package} ||= FFI::Platypus->new->package($package,$filename);
}


sub lib (@)
{
  _ffi_object->lib(@_);
}


sub type ($;$)
{
  _ffi_object->type(@_);
}


sub custom_type ($$)
{
  _ffi_object->custom_type(@_);
}


sub load_custom_type ($$;@)
{
  _ffi_object->load_custom_type(@_);
}


sub type_meta($)
{
  _ffi_object->type_meta(@_);
}


my $inner_counter = 0;

sub attach ($$$;$$)
{
  my $wrapper;
  $wrapper = pop if ref($_[-1]) eq 'CODE';
  my($name, $args, $ret, $proto) = @_;

  my($symbol_name, $perl_name) = ref $name ? (@$name) : ($name, $name);
  my $function = _ffi_object->function($symbol_name, $args, $ret, $wrapper);
  $function->attach($perl_name, $proto);
  ();
}


sub closure (&)
{
  my($coderef) = @_;
  require FFI::Platypus::Closure;
  FFI::Platypus::Closure->new($coderef);
}


sub sticky ($)
{
  my($closure) = @_;
  Carp::croak("usage: sticky \$closure")
    unless defined $closure && ref($closure) eq 'FFI::Platypus::Closure';
  $closure->sticky;
  $closure;
}


sub cast ($$$)
{
  _ffi_object->cast(@_);
}


sub attach_cast ($$$)
{
  my($name, $type1, $type2) = @_;
  my $caller = caller;
  $name = join '::', $caller, $name;
  _ffi_object->attach_cast($name, $type1, $type2);
}


sub sizeof ($)
{
  _ffi_object->sizeof($_[0]);
}


sub lang ($)
{
  _ffi_object->lang($_[0]);
}


sub abi ($)
{
  _ffi_object->abi($_[0]);
}

sub import
{
  my $caller = caller;
  shift; # class

  foreach my $arg (@_)
  {
    if(ref $arg)
    {
      if($arg->[0] =~ /::/)
      {
        _ffi_object->load_custom_type(@$arg);
        no strict 'refs';
        *{join '::', $caller, $arg->[1]} = sub () { $arg->[1] };
      }
      else
      {
        _ffi_object->type(@$arg);
        no strict 'refs';
        *{join '::', $caller, $arg->[1]} = sub () { $arg->[0] };
      }
    }
    else
    {
      _ffi_object->type($arg);
      no strict 'refs';
      *{join '::', $caller, $arg} = sub () { $arg };
    }
  }

  no strict 'refs';
  *{join '::', $caller, 'lib'} = \&lib;
  *{join '::', $caller, 'type'} = \&type;
  *{join '::', $caller, 'type_meta'} = \&type_meta;
  *{join '::', $caller, 'custom_type'} = \&custom_type;
  *{join '::', $caller, 'load_custom_type'} = \&load_custom_type;
  *{join '::', $caller, 'attach'} = \&attach;
  *{join '::', $caller, 'closure'} = \&closure;
  *{join '::', $caller, 'sticky'} = \&sticky;
  *{join '::', $caller, 'cast'} = \&cast;
  *{join '::', $caller, 'attach_cast'} = \&attach_cast;
  *{join '::', $caller, 'sizeof'} = \&sizeof;
  *{join '::', $caller, 'lang'} = \&lang;
  *{join '::', $caller, 'abi'} = \&abi;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Declare - Declarative interface to FFI::Platypus

=head1 VERSION

version 1.31

=head1 SYNOPSIS

 use FFI::Platypus::Declare 'string', 'int';
 
 lib undef; # use libc
 attach puts => [string] => int;
 
 puts("hello world");

=head1 DESCRIPTION

This module is officially B<discouraged>.  The idea was to provide a
simpler declarative interface without the need of (directly) creating
an L<FFI::Platypus> instance.  In practice it is almost as complicated
and makes it difficult to upgrade to the proper OO interface if the
need arises.  I have stopped using it mainly for this reason.  It will
remain as part of the Platypus core distribution to keep old code working,
but you are encouraged to write new code using the OO interface.
Alternatively, you can try the Perl 6 inspired L<NativeCall>, which
provides most of the goals this module was intended for (that is
a simple interface at the cost of some power), without much of the
complexity.  The remainder of this document describes the interface.

This module provides a declarative interface to L<FFI::Platypus>. It
provides a more concise interface at the cost of a little less power,
and a little more namespace pollution.

Any strings passed into the C<use> line will be declared as types and
exported as constants into your namespace, so that you can use them
without quotation marks.

Aliases can be declared using a list reference:

 use FFI::Platypus [ 'int[48]' => 'my_integer_array' ];

Custom types can also be declared as a list reference (the type name
must include a ::):

 use FFI::Platypus [ '::StringPointer' => 'my_string_pointer' ];
 # short for FFI::Platypus::Type::StringPointer

=head1 FUNCTIONS

All functions are exported into your namespace.  If you do not want that,
then use the OO interface (see L<FFI::Platypus>).

=head2 lib

 lib $libpath;

Specify one or more dynamic libraries to search for symbols. If you are
unsure of the location / version of the library then you can use
L<FFI::CheckLib#find_lib>.

=head2 type

 type $type;
 type $type = $alias;

Declare the given type.

Examples:

 type 'uint8'; # only really checks that uint8 is a valid type
 type 'uint8' => 'my_unsigned_int_8';

=head2 custom_type

 custom_type $alias => \%args;

Declare the given custom type.  See L<FFI::Platypus::Type#Custom-Types>
for details.

=head2 load_custom_type

 load_custom_type $name => $alias, @type_args;

Load the custom type defined in the module I<$name>, and make an alias
with the name I<$alias>. If the custom type requires any arguments, they
may be passed in as I<@type_args>. See L<FFI::Platypus::Type#Custom-Types>
for details.

If I<$name> contains C<::> then it will be assumed to be a fully
qualified package name. If not, then C<FFI::Platypus::Type::> will be
prepended to it.

=head2 type_meta

 my $meta = type_meta $type;

Get the type meta data for the given type.

Example:

 my $meta = type_meta 'int';

=head2 attach

 attach $name => \@argument_types => $return_type;
 attach [$c_name => $perl_name] => \@argument_types => $return_type;
 attach [$address => $perl_name] => \@argument_types => $return_type;

Find and attach a C function as a Perl function as a real live xsub.

If just one I<$name> is given, then the function will be attached in
Perl with the same name as it has in C.  The second form allows you to
give the Perl function a different name.  You can also provide a memory
address (the third form) of a function to attach.

Examples:

 attach 'my_function', ['uint8'] => 'string';
 attach ['my_c_function_name' => 'my_perl_function_name'], ['uint8'] => 'string';
 my $string1 = my_function($int);
 my $string2 = my_perl_function_name($int);

=head2 closure

 my $closure = closure $codeblock;

Create a closure that can be passed into a C function.  For details on closures, see L<FFI::Platypus::Type#Closures>.

Example:

 my $closure1 = closure { return $_[0] * 2 };
 my $closure2 = closure sub { return $_[0] * 4 };

=head2 sticky

 my $closure = sticky closure $codeblock;

Keyword to indicate the closure should not be deallocated for the life
of the current process.

If you pass a closure into a C function without saving a reference to it
like this:

 foo(closure { ... });         # BAD

Perl will not see any references to it and try to free it immediately.
(this has to do with the way Perl and C handle responsibilities for
memory allocation differently).  One fix for this is to make sure the
closure remains in scope using either C<my> or C<our>.  If you know the
closure will need to remain in existence for the life of the process (or
if you do not care about leaking memory), then you can add the sticky
keyword to tell L<FFI::Platypus> to keep the thing in memory.

 foo(sticky closure { ... });  # OKAY

=head2 cast

 my $converted_value = cast $original_type, $converted_type, $original_value;

The C<cast> function converts an existing I<$original_value> of type
I<$original_type> into one of type I<$converted_type>.  Not all types
are supported, so care must be taken.  For example, to get the address
of a string, you can do this:

 my $address = cast 'string' => 'opaque', $string_value;

=head2 attach_cast

 attach_cast "cast_name", $original_type, $converted_type;
 my $converted_value = cast_name($original_value);

This function creates a subroutine which can be used to convert
variables just like the L<cast|FFI::Platypus::Declare#cast> function
above.  The above synopsis is roughly equivalent to this:

 sub cast_name { cast($original_type, $converted_type, $_[0]) }
 my $converted_value = cast_name($original_value);

Except that the L<attach_cast|FFI::Platypus::Declare#attach_cast>
variant will be much faster if called multiple times since the cast does
not need to be dynamically allocated on each instance.

=head2 sizeof

 my $size = sizeof $type;

Returns the total size of the given type.  For example to get the size
of an integer:

 my $intsize = sizeof 'int'; # usually 4 or 8 depending on platform

You can also get the size of arrays

 my $intarraysize = sizeof 'int[64]';

Keep in mind that "pointer" types will always be the pointer / word size
for the platform that you are using.  This includes strings, opaque and
pointers to other types.

This function is not very fast, so you might want to save this value as
a constant, particularly if you need the size in a loop with many
iterations.

=head2 lang

 lang $language;

Specifies the foreign language that you will be interfacing with. The
default is C.  The foreign language specified with this attribute
changes the default native types (for example, if you specify
L<Rust|FFI::Platypus::Lang::Rust>, you will get C<i32> as an alias for
C<sint32> instead of C<int> as you do with L<C|FFI::Platypus::Lang::C>).

In the future this may attribute may offer hints when doing demangling
of languages that require it like L<C++|FFI::Platypus::Lang::CPP>.

=head2 abi

 abi $abi;

Set the ABI or calling convention for use in subsequent calls
to L</attach>.  May be either a string name or integer value
from L<FFI::Platypus#abis>.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Object oriented interface to Platypus.

=item L<FFI::Platypus::Type>

Type definitions for Platypus.

=item L<FFI::Platypus::API>

Custom types API for Platypus.

=item L<FFI::Platypus::Memory>

memory functions for FFI.

=item L<FFI::CheckLib>

Find dynamic libraries in a portable way.

=item L<FFI::TinyCC>

JIT compiler for FFI.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

Dylan Cali (calid)

pipcet

Zaki Mughal (zmughal)

Fitz Elliott (felliott)

Vickenty Fesunov (vyf)

Gregor Herrmann (gregoa)

Shlomi Fish (shlomif)

Damyan Ivanov

Ilya Pavlov (Ilya33)

Petr Pisar (ppisar)

Mohammad S Anwar (MANWAR)

Håkon Hægland (hakonhagland, HAKONH)

Meredith (merrilymeredith, MHOWARD)

Diab Jerius (DJERIUS)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015,2016,2017,2018,2019,2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
