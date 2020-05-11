package FFI::C::Array;

use strict;
use warnings;
use FFI::C::FFI ();
use overload
  '@{}' => \&tie,
  bool => sub { 1 },
  fallback => 1;

# ABSTRACT: Array instance for FFI
our $VERSION = '0.06'; # VERSION


sub get
{
  my($self, $index) = @_;
  Carp::croak("Negative array index") if $index < 0;
  Carp::croak("OOB array index") if $self->{count} && $index >= $self->{count};
  my $member = $self->{def}->{members}->{member};
  my $ptr = $self->{ptr} + $member->size * $index;
  $member->create($ptr,$self->{owner} || $self);
}

sub count { shift->{count} }

sub tie
{
  my @a;
  CORE::tie @a, 'FFI::C::Array', shift;
  \@a;
}

sub DESTROY
{
  my($self) = @_;
  if($self->{ptr} && !$self->{owner})
  {
    FFI::C::FFI::free(delete $self->{ptr});
  }
}

sub TIEARRAY
{
  my($class, $array) = @_;
  $array;
}

sub FETCH
{
  my($self, $index) = @_;
  $self->get($index);
}

sub STORE
{
  Carp::croak("Cannot set");
}

sub FETCHSIZE
{
  my($self) = @_;
  $self->count;
}

sub STORESIZE
{
  my($self) = @_;
  $self->count;
}

sub CLEAR
{
  Carp::croak("Cannot clear");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C::Array - Array instance for FFI

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use FFI::C::ArrayDef;
 use FFI::C::StructDef;
 
 my $point_def = FFI::C::StructDef->new(
   name  => 'point_t',
   class => 'Point',
   members => [
     x => 'double',
     y => 'double',
   ],
 );
 
 my $rect_def = FFI::C::ArrayDef->new(
   name    => 'rectangle_t',
   class   => 'Rectangle',
   members => [
     $point_def, 2,
   ]
 );
 
 # create a rectangle using the def's create method
 my $square = $rect_def->create([
   { x => 1.0, y => 1.0 },
   { x => 2.0, y => 2.0 },
 ]);
 
 printf "[[%d %d][%d %d]]\n",
   $square->[0]->x, $square->[0]->y,
   $square->[1]->x, $square->[1]->y;   # [[1 1][2 2]]
 
 # move square by 1 on the x axis
 $square->[$_]->x( $square->[$_]->x + 1 ) for 0..1;
 
 printf "[[%d %d][%d %d]]\n",
   $square->[0]->x, $square->[0]->y,
   $square->[1]->x, $square->[1]->y;   # [[2 1][3 2]]
 
 # Create a rectange usingn the generated class
 my $rect = Rectangle->new;
 $rect->[0]->x(1.0);
 $rect->[0]->y(1.0);
 $rect->[1]->x(2.0);
 $rect->[1]->y(3.0);

=head2 DESCRIPTION

This class represents an instance of a C an array.  This class can be created using
C<new> on the generated class, if that was specified for the L<FFI::C::ArrayDef>,
or by using the C<create> method on L<FFI::C::ArrayDef>.

Each element of the array can be accessed using the C<get> method below, or by using
the object as an array reference, thanks to magical Perl ties.

=head1 CONSTRUCTOR

=head2 new

 FFI::C::ArrayDef->new( class => 'User::Array::Class', ... );
 my $instance = User::Array::Class->new;
 my $instance = User::Array::Class->new($count);

Creates a new instance of the array.  If C<$count> is specified, that will be used
as the element count, overriding the count defined by the def.  If the def did not
specify a count then you MUST provide a count.

=head1 METHODS

=head2 get

 my $element = $instance->get($index);
 my $element = $instance->[$index];

Gets the element at the given C<$index>.

=head2 count

 my $count = $instance->count;

Returns the number of elements in the array, if known.

=head2 tie

 my $arrayref = $instance->tie;

Returns a Perl array reference tied to the C array.

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::Def>

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

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
