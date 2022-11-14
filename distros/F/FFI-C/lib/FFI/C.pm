package FFI::C;

use strict;
use warnings;
use 5.008001;
use Carp ();
use Ref::Util qw( is_ref is_plain_arrayref is_plain_hashref );

# ABSTRACT: C data types for FFI
our $VERSION = '0.14'; # VERSION


our %ffi;

sub _ffi_get
{
  my($filename) = @_;
  $ffi{$filename} ||= do {
    require FFI::Platypus;
    FFI::Platypus->new( api => 1 );
  };
}

sub ffi
{
  my($class, $new) = @_;
  my(undef, $filename) = caller;

  if($new)
  {
    Carp::croak("Already have an FFI::Platypus instance for $filename")
      if defined $ffi{$filename};
    return $ffi{$filename} = $new;
  }

  _ffi_get($filename);
}


our $def_class;
sub _gen
{
  shift;
  my($class, $filename) = caller;

  my($name, $members);

  my %extra = is_plain_hashref $_[-1] ? %{ pop() } : ();

  if(@_ == 2 && !is_ref $_[0] && is_plain_arrayref $_[1])
  {
    ($name, $members) = @_;
  }
  elsif(@_ == 1 && is_plain_arrayref $_[0])
  {
    $name = lcfirst [split /::/, $class]->[-1];
    $name =~ s/([A-Z]+)/'_' . lc($1)/ge;
    $name .= "_t";
    ($members) = @_;
  }
  else
  {
    my($method) = map { lc $_ } $def_class =~ /::([A-Za-z]+)Def$/;
    Carp::croak("usage: FFI::C->$method([\$name], \\\@members)");
  }

  $def_class->new(
    _ffi_get($filename),
    %extra,
    name    => $name,
    class   => $class,
    members => $members,
  );
}

sub struct
{
  require FFI::C::StructDef;
  $def_class = 'FFI::C::StructDef';
  goto &_gen;
}


sub union
{
  require FFI::C::UnionDef;
  $def_class = 'FFI::C::UnionDef';
  goto &_gen;
}


sub array
{
  require FFI::C::ArrayDef;
  $def_class = 'FFI::C::ArrayDef';
  goto &_gen;
}


sub enum
{
  (undef)    = shift;
  my $name   = defined $_[0] && !is_ref $_[0] ? shift : undef;
  my @values = defined $_[0] && is_plain_arrayref $_[0] ? @{shift()} : ();
  my %config = defined $_[0] && is_plain_hashref $_[0]  ? %{shift()} : ();

  my($class, $filename) = caller;

  unless(defined $name)
  {
    $name = lcfirst [split /::/, $class]->[-1];
    $name =~ s/([A-Z]+)/'_' . lc($1)/ge;
    $name .= "_t";
  }

  my $ffi = _ffi_get($filename),

  $config{package} ||= $class;
  my @maps;
  $config{maps} = \@maps;
  my $rev = $config{rev}  ||= 'str';

  $ffi->load_custom_type('::Enum', $name, \%config, @values);

  my($str_lookup, $int_lookup, $type) = @maps;

  require FFI::C::Def;
  $ffi->def('FFI::C::EnumDef', $name,
    FFI::C::EnumDef->new(
      str_lookup => $str_lookup,
      int_lookup => $int_lookup,
      type       => $type,
      rev        => $rev,
    )
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C - C data types for FFI

=head1 VERSION

version 0.14

=head1 SYNOPSIS

In C:

 #include <stdint.h>
 
 typedef struct {
   uint8_t red;
   uint8_t green;
   uint8_t blue;
 } color_value_t;
 
 typedef struct {
   char name[22];
   color_value_t value;
 } named_color_t;
 
 typedef named_color_t array_named_color_t[4];
 
 typedef union {
   uint8_t  u8;
   uint16_t u16;
   uint32_t u32;
   uint64_t u64;
 } anyint_t;

In Perl:

 use FFI::C;
 
 package ColorValue {
   FFI::C->struct([
     red   => 'uint8',
     green => 'uint8',
     blue  => 'uint8',
   ]);
 }
 
 package NamedColor {
   FFI::C->struct([
     name  => 'string(22)',
     value => 'color_value_t',
   ]);
 }
 
 package ArrayNamedColor {
   FFI::C->array(['named_color_t' => 4]);
 };
 
 my $array = ArrayNamedColor->new([
   { name => "red",    value => { red   => 255 } },
   { name => "green",  value => { green => 255 } },
   { name => "blue",   value => { blue  => 255 } },
   { name => "purple", value => { red   => 255,
                                  blue  => 255 } },
 ]);
 
 # dim each color by 1/2
 foreach my $color (@$array)
 {
   $color->value->red  ( $color->value->red   / 2 );
   $color->value->green( $color->value->green / 2 );
   $color->value->blue ( $color->value->blue  / 2 );
 }
 
 # print out the colors
 foreach my $color (@$array)
 {
   printf "%s [%02x %02x %02x]\n",
     $color->name,
     $color->value->red,
     $color->value->green,
     $color->value->blue;
 }
 
 package AnyInt {
   FFI::C->union([
     u8  => 'uint8',
     u16 => 'uint16',
     u32 => 'uint32',
     u64 => 'uint64',
   ]);
 }
 
 my $int = AnyInt->new({ u8 => 42 });
 print $int->u32;

=head1 DESCRIPTION

This distribution provides tools for building classes to interface for common C
data types.  Arrays, C<struct>, C<union> and nested types based on those are
supported.

Core L<FFI::Platypus> also provides L<FFI::Platypus::Record> for manipulating and
passing structured data.  Typically you want to use L<FFI::C> instead, the main
exception is when you need to pass structured data by value instead of by
reference.

To work with C APIs that work with C file pointers you can use
L<FFI::C::File> and L<FFI::C::PosixFile>.  For C APIs that expose the POSIX
C<stat> structure use L<FFI::C::Stat>.

=head1 METHODS

=head2 ffi

 FFI::C->ffi($ffi);
 my $ffi = FFI::C->ffi;

Get or set the L<FFI::Platypus> instance used for the current Perl file
(C<.pl> or C<.pm>).

By default a new Platypus instance is created the on the first call to
C<ffi>, or when a new type is created with C<struct>, C<union> or C<array>
below, so if you want to use your own Platypus instance make sure that
you set it as soon as possible.

The Platypus instance is file scoped because scoping on just one package
doesn't make sense if you are defining multiple types in one file since
each type must be in its own package.  It also doesn't make sense to make
the Platypus instance global, because different distributions would
conflict.

=head2 struct

 FFI::C->struct($name, \@members);
 FFI::C->struct(\@members);

Generate a new L<FFI::C::Struct> class with the given C<@members> into
the calling package.  (C<@members> should be a list of name/type pairs).
You may optionally give a C<$name> which will be used for the
L<FFI::Platypus> type name for the generated class.  If you do not
specify a C<$name>, a C style name will be generated from the last segment
in the calling package name by converting to snake case and appending a
C<_t> to the end.

As an example, given:

 package MyLibrary::FooBar {
   FFI::C->struct([
     a => 'uint8',
     b => 'float',
   ]);
 };

You can use C<MyLibrary::FooBar> via the file scoped L<FFI::Platypus> instance
using the type C<foo_bar_t>.

 my $foobar = MyLibrary::FooBar->new({ a => 1, b => 3.14 });
 $ffi->function( my_library_func => [ 'foo_bar_t' ] => 'void' )->call($foobar);

=head2 union

 FFI::C->union($name, \@members);
 FFI::C->union(\@members);

This works exactly like the C<struct> method above, except a
L<FFI::C::Union> class is generated instead.

=head2 array

 FFI::C->array($name, [$type, $count]);
 FFI::C->array($name, [$type]);
 FFI::C->array([$type, $count]);
 FFI::C->array([$type]);

This is similar to C<struct> and C<union> above, except L<FFI::C::Array> is
generated.  For an array you give it the member type and the element count.
The element count is optional for variable length arrays, but keep in mind
that when you create such an array you do need to provide a size.

=head2 enum

 FFI::C->enum($name, \@values, \%config);
 FFI::C->enum(\@values, \%config);
 FFI::C->enum(\@values, \%config);
 FFI::C->enum(\@values);

Defines an enum.  The C<@values> and C<%config> are passed to
L<FFI::Platypus::Type::Enum>, except the constants are exported
to the calling package by default.

=head1 EXAMPLES

=head2 unix time struct

 use FFI::Platypus 1.00;
 use FFI::C;
 
 my $ffi = FFI::Platypus->new(
   api => 1,
   lib => [undef],
 );
 FFI::C->ffi($ffi);
 
 package Unix::TimeStruct {
 
   FFI::C->struct(tm => [
     tm_sec    => 'int',
     tm_min    => 'int',
     tm_hour   => 'int',
     tm_mday   => 'int',
     tm_mon    => 'int',
     tm_year   => 'int',
     tm_wday   => 'int',
     tm_yday   => 'int',
     tm_isdst  => 'int',
     tm_gmtoff => 'long',
     _tm_zone  => 'opaque',
   ]);
 
   # For now 'string' is unsupported by FFI::C, but we
   # can cast the time zone from an opaque pointer to
   # string.
   sub tm_zone {
     my $self = shift;
     $ffi->cast('opaque', 'string', $self->_tm_zone);
   }
 
   # attach the C localtime function
   $ffi->attach( localtime => ['time_t*'] => 'tm', sub {
     my($inner, $class, $time) = @_;
     $time = time unless defined $time;
     $inner->(\$time);
   });
 }
 
 # now we can actually use our My::UnixTime class
 my $time = Unix::TimeStruct->localtime;
 printf "time is %d:%d:%d %s\n",
   $time->tm_hour,
   $time->tm_min,
   $time->tm_sec,
   $time->tm_zone;

=head1 CAVEATS

L<FFI::C> objects must be passed into C via L<FFI::Platypus> by pointers.
So-called "pass-by-value" is not and will not be supported.  For
"pass-by-value" record types, you should instead use L<FFI::Platypus::Record>.

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::Def>

=item L<FFI::C::File>

=item L<FFI::C::PosixFile>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
