package FFI::Platypus::Legacy::Raw::Callback;

use strict;
use warnings;
use FFI::Platypus::Memory qw( strdup free );
use FFI::Platypus::Legacy::Raw::Platypus;

# ABSTRACT: FFI::Platypus::Legacy::Raw function pointer type
our $VERSION = '0.06'; # VERSION


sub new
{
  my($class, $coderef, $ret_type, @arg_types) = @_;

  my $self;

  if($ret_type eq 's')
  {
    $ret_type = 'opaque';
    my $original = $coderef;
    $coderef = sub {
      free $self->{strptr} if $self->{strptr};
      delete $self->{strptr};
      my $string = $original->(@_);
      return undef unless defined $string;
      $self->{strptr} = strdup($string);
    };
  }

  if($ret_type eq 'p')
  {
    $ret_type = 'opaque';
    my $original = $coderef;
    $coderef = sub {
      my $ptr = $original->(@_);
      return undef unless defined $ptr;
      if(ref $ptr)
      {
        if(eval { $ptr->isa('FFI::Platypus::Legacy::Raw::Ptr') })
        { $ptr = $$ptr }
        elsif(eval { $ptr->isa('FFI::Platypus::Legacy::Raw::Callback') })
        { $ptr = $ptr->{ptr} }
      }
      $ptr;
    };
  }

  my $closure = _ffi_package->closure($coderef);
  my $closure_type = '(' . join(',', @arg_types) . ")->$ret_type";

  $self = bless {
    coderef => $coderef,
    closure => $closure,
    ptr     => _ffi_package->cast($closure_type => 'opaque', $closure),
  }, $class;
}

sub DESTROY
{
  my($self) = @_;
  free $self->{strptr} if $self->{strptr};
  delete $self->{strptr};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Legacy::Raw::Callback - FFI::Platypus::Legacy::Raw function pointer type

=head1 VERSION

version 0.06

=head1 DESCRIPTION

B<FFI::Platypus::Legacy::Raw> and friends are a fork of L<FFI::Raw> that uses L<FFI::Platypus>
instead of L<FFI::Raw>'s own libffi implementation.  It is intended for use when migrating from
L<FFI::Raw> to L<FFI::Platypus>.  The main reason one might have for switching from Raw to Platypus
is because Platypus is actively maintained, provides a more powerful interface, can be much faster
when functions are "attached", and works on more platforms than Raw.  This module should be a drop
in replacement for L<FFI::Raw>, simply replace all instances of C<FFI::Raw> to
C<FFI::Platypus::Legacy::Raw>.  See also L<Alt::FFI::Raw::Platypus> for a way to use this module
without making any source code changes.

A B<FFI::Platypus::Legacy::Raw::Callback> represents a function pointer to a Perl routine. It can
be passed to functions taking a C<FFI::Platypus::Legacy::Raw::ptr> type.

=head1 CONSTRUCTOR

=head2 new

 my $callback = FFI::Platypus::Legacy::Raw::Callback->new( $coderef, $ret_type, @arg_types );

Create a C<FFI::Platypus::Legacy::Raw::Callback> using the code reference C<$coderef> as body. The
signature (return and arguments types) must also be passed.

=head1 CAVEATS

For callbacks with a C<FFI::Platypus::Legacy::Raw::str> return type, the string value will be copied
to a private field on the callback object.  The memory for this value will be
freed the next time the callback is called, or when the callback itself is freed.
For more exact control over when the return value is freed, you can instead
use C<FFI::Platypus::Legacy::Raw::ptr> type and return a L<FFI::Platypus::Legacy::Raw::MemPtr> object.

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
