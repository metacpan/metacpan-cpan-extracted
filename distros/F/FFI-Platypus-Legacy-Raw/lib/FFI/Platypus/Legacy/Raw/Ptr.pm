package FFI::Platypus::Legacy::Raw::Ptr;

use strict;
use warnings;

# ABSTRACT: Base FFI::Platypus::Legacy::Raw pointer type
our $VERSION = '0.05'; # VERSION


sub new {
  my($class, $ptr) = @_;
  bless \$ptr, $class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Legacy::Raw::Ptr - Base FFI::Platypus::Legacy::Raw pointer type

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 package Foo;
 
 use FFI::Platypus::Legacy::Raw;
 
 use base qw(FFI::Platypus::Legacy::Raw::Ptr);
 
 *_foo_new = FFI::Platypus::Legacy::Raw->new(
   $shared, 'foo_new',
   FFI::Platypus::Legacy::Raw::ptr
 )->coderef;
 
 sub new {
   bless shift->SUPER::new(_foo_new());
 }

 *get_bar = FFI::Platypus::Legacy::Raw->new(
   $shared, 'foo_get_bar',
   FFI::Platypus::Legacy::Raw::int,
   FFI::Platypus::Legacy::Raw::ptr
 )->coderef;
 
 *set_bar = FFI::Platypus::Legacy::Raw->new(
   $shared, 'foo_set_bar',
   FFI::Platypus::Legacy::Raw::void,
   FFI::Platypus::Legacy::Raw::ptr,
   FFI::Platypus::Legacy::Raw::int
 )->coderef;
 
 *DESTROY = FFI::Platypus::Legacy::Raw->new(
   $shared, 'foo_free',
   FFI::Platypus::Legacy::Raw::void,
   FFI::Platypus::Legacy::Raw::ptr
 )->coderef;
 
 1;
 
 package main;
 
 my $foo = Foo->new;
 
 $foo->set_bar(42);

=head1 DESCRIPTION

B<FFI::Platypus::Legacy::Raw> and friends are a fork of L<FFI::Raw> that uses L<FFI::Platypus>
instead of L<FFI::Raw>'s own libffi implementation.  It is intended for use when migrating from
L<FFI::Raw> to L<FFI::Platypus>.  The main reason one might have for switching from Raw to Platypus
is because Platypus is actively maintained, provides a more powerful interface, can be much faster
when functions are "attached", and works on more platforms than Raw.  This module should be a drop
in replacement for L<FFI::Raw>, simply replace all instances of C<FFI::Raw> to
C<FFI::Platypus::Legacy::Raw>.  See also L<Alt::FFI::Raw::Platypus> for a way to use this module
without making any source code changes.

A B<FFI::Platypus::Legacy::Raw::Ptr> represents a pointer to memory which can be passed to
functions taking a C<FFI::Platypus::Legacy::Raw::ptr> argument.

Note that differently from L<FFI::Platypus::Legacy::Raw::MemPtr>, C<FFI::Platypus::Legacy::Raw::Ptr> pointers are
not automatically deallocated once not in use anymore.

=head1 CONSTRUCTOR

=head2 new

 my $ptr = FFI::Platypus::Legacy::Raw::Ptr->new( $ptr );

Create a new C<FFI::Platypus::Legacy::Raw::Ptr> pointing to C<$ptr>, which can be either a
C<FFI::Platypus::Legacy::Raw::MemPtr> or a pointer returned by a C function.

=head1 AUTHOR

Original author: Alessandro Ghedini (ghedo, ALEXBIO)

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

Dylan Cali (CALID)

Brian Wightman (MidLifeXis, MLX)

David Steinbrunner (dsteinbrunner)

Olivier Mengué (DOLMEN)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alessandro Ghedini.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
