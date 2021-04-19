package FFI::Platypus::Type::PtrObject;

use strict;
use warnings;
use FFI::Platypus 1.11;
use Ref::Util qw( is_blessed_hashref );
use Carp ();
use 5.008001;

# ABSTRACT: Platypus custom type for an object wrapped around an opaque pointer
our $VERSION = '0.03'; # VERSION


push @FFI::Platypus::CARP_NOT, __PACKAGE__;

sub ffi_custom_type_api_1
{
  my(undef, undef, $wrapper_class, $constructor) = @_;

  Carp::croak("no class specified") unless defined $wrapper_class;
  Carp::croak("illegal class name: $wrapper_class") unless $wrapper_class =~ /^[A-Z_][0-9A-Z_]*(::[A-Z_][0-9A-Z_]*)*$/i;

  $constructor ||= sub {
    defined $_[0] ? bless { ptr => $_[0] }, $wrapper_class : undef;
  };

  return {
    native_type    => 'opaque',
    perl_to_native => sub {
      Carp::croak("argument is not a $wrapper_class") unless is_blessed_hashref($_[0]) && $_[0]->isa($wrapper_class);
      my $ptr = $_[0]->{ptr};
      Carp::croak("pointer for $wrapper_class went away") unless defined $ptr;
      $ptr;
    },
    native_to_perl => $constructor,
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Type::PtrObject - Platypus custom type for an object wrapped around an opaque pointer

=head1 VERSION

version 0.03

=head1 SYNOPSIS

C:

 #include <string.h>
 
 typedef struct { char buffer[100] } foo_t;
 
 void
 set(foo_t *self, const char *value)
 {
   strncpy(self->buffer, value, 100);
 }
 
 const char *
 get(foo_t *self)
 {
   return self->buffer;
 }
 
 foo_t *
 clone(foo_t *self)
 {
   foo_t *clone;
   clone = malloc(100);
   memcpy(clone->buffer, self->buffer, 100);
   return clone;
 }

Perl:

 my $ffi = FFI::Platypus->new( api => 1 );
 $ffi->bundle;  # See FFI::Platypus::Bundle
 $ffi->load_custom_type('::PtrObject', 'foo_t', 'Foo');
 
 package Foo {
   use FFI::Platypus::Memory qw( malloc free );
 
   sub new
   {
     my $class = shift;
     bless {
       ptr => malloc(100),
     }, $class;
   }
 
   $ffi->attach( set   => ['foo_t','string']    );
   $ffi->attach( get   => ['foo_t'] => 'string' );
   $ffi->attach( clone => ['foo_t'] => 'foo_t'  );
 
   sub take_ownership
   {
     my($self) = @_;
     return delete $self->{ptr};
   }
 
   sub DESTROY
   {
     my($self) = @_;
     if(defined $self->{ptr})
     {
       free($self->{ptr});
     }
   }
 }
 
 my $foo = Foo->new;
 $foo->set("hello there");
 print $foo->get, "\n";    # hello there
 my $bar = $foo->clone;
 print $bar->get, "\n";    # hello there
 
 Foo::get(undef);    # undef is not a Foo, throws exception
 
 my $baz = bless { ptr => 0xdeadbeaf }, 'Baz';
 Foo::get($baz);     # $baz is not a Foo, throws exception
 
 # by calling take ownership, the pointer will be
 # removed from $foo, so we now own the pointer.
 my $ptr = $foo->take_ownership;
 
 $foo->get;  # $foo no longer owns its pointer, throws an exception
 
 # since $foo no longer is tracking the memory, we should free it
 # manually ourselves.
 use FFI::Platypus::Memory qw( free );
 free $ptr;
 
 # $bar will free its memory when it falls out of scope automatically
 # since it still owns its pointer.

=head1 DESCRIPTION

This is a helper type for L<FFI::Platypus> that handles type checking for the common
pattern where a Perl class is a simple wrapper around an opaque pointer.  The class
should be implemented as a hash reference, and the pointer itself is expected to be
stored on the C<ptr> key.  If the caller of the interface (Perl) is responsible for
cleaning up the memory, then it normally should be done in the C<DESTROY> method
(as above).

If you do not pass in the correct type, it will be detected before the C code is
called and an exception will be thrown.  (otherwise you would probably get a segment
violation SEGV).

=head1 CAVEATS

Care needs to be taken that only the responsible party frees its pointers.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
