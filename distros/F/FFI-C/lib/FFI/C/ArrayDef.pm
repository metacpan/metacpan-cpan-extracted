package FFI::C::ArrayDef;

use strict;
use warnings;
use 5.008001;
use Ref::Util qw( is_blessed_ref is_ref is_plain_arrayref );
use FFI::C::Array;
use Sub::Install ();
use Sub::Util ();
use Scalar::Util qw( refaddr );
use base qw( FFI::C::Def );

our @CARP_NOT = qw( FFI::C );

# ABSTRACT: Array data definition for FFI
our $VERSION = '0.06'; # VERSION


sub new
{
  my $self = shift->SUPER::new(@_);

  my %args = %{ delete $self->{args} };

  my $member;
  my $count = 0;

  my @members = @{ delete $args{members} || [] };
  if(@members == 1)
  {
    ($member) = @members;
  }
  elsif(@members == 2)
  {
    ($member, $count) = @members;
  }
  else
  {
    Carp::croak("The members argument should be a struct/union type and an optional element count");
  }

  if(my $def = $self->ffi->def('FFI::C::Def', $member))
  {
    $member = $def;
  }

  Carp::croak("Canot nest an array def inside of itself") if refaddr($member) == refaddr($self);

  Carp::croak("Illegal member")
    unless defined $member && is_blessed_ref($member) && $member->isa("FFI::C::Def");

  Carp::croak("The element count must be a positive integer")
    if defined $count && $count !~ /^[1-9]*[0-9]$/;

  $self->{size}              = $member->size * $count;
  $self->{align}             = $member->align;
  $self->{members}->{member} = $member;
  $self->{members}->{count}  = $count;

  Carp::carp("Unknown argument: $_") for sort keys %args;

  if($self->class)
  {
    # not handled by the superclass:
    #  3. Any nested cdefs must have Perl classes.

    {
      my $member = $self->{members}->{member};
      my $accessor = $self->class . '::get';
      Carp::croak("Missing Perl class for $accessor")
        if $member->{nest} && !$member->{nest}->{class};
    }

    $self->_generate_class(qw( get ));

    {
      my $member_class = $self->{members}->{member}->class;
      my $member_size  = $self->{members}->{member}->size;
      my $code = sub {
        my($self, $index) = @_;
        Carp::croak("Negative array index") if $index < 0;
        Carp::croak("OOB array index") if $self->{count} && $index >= $self->{count};
        my $ptr = $self->{ptr} + $member_size * $index;
        $member_class->new($ptr,$self);
      };
      Sub::Util::set_subname(join('::', $self->class), $code);
      Sub::Install::install_sub({
        code => $code,
        into => $self->class,
        as   => 'get',
      });
    }

    {
      no strict 'refs';
      push @{ join '::', $self->class, 'ISA' }, 'FFI::C::Array';
    }

  }

  $self;
}


sub create
{
  my $self = shift;

  return $self->class->new(@_) if $self->class;

  local $self->{size} = $self->{size};
  my $count = $self->{members}->{count};
  if(@_ == 1)
  {
    if(! is_ref $_[0])
    {
      $count = shift;
    }
    elsif(is_plain_arrayref $_[0])
    {
      $count = scalar @{$_[0]};
    }
    if($count)
    {
      $self->{size} = $self->{members}->{member}->size * $count;
    }
  }

  if( (@_ == 2 && ! is_ref $_[0]) || ($self->size) )
  {
    my $array = $self->SUPER::create(@_);
    $array->{count} = $count;
    FFI::C::Util::perl_to_c($array, $_[0]) if @_ == 1 && is_plain_arrayref $_[0];
    return $array;
  }

  Carp::croak("Cannot create array without knowing the number of elements");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C::ArrayDef - Array data definition for FFI

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your C code:

 #include <stdio.h>
 
 typedef struct {
   double x, y;
 } point_t;
 
 void
 print_rectangle(point_t rec[2])
 {
   printf("[[%g %g] [%g %g]]\n",
     rec[0].x, rec[0].y,
     rec[1].x, rec[1].y
   );
 }

In your Perl code:

 use FFI::Platypus 1.00;
 use FFI::C::ArrayDef;
 use FFI::C::StructDef;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 # See FFI::Platypus::Bundle for how bundle works.
 $ffi->bundle;
 
 my $point_def = FFI::C::StructDef->new(
   $ffi,
   name  => 'point_t',
   class => 'Point',
   members => [
     x => 'double',
     y => 'double',
   ],
 );
 
 my $rect_def = FFI::C::ArrayDef->new(
   $ffi,
   name    => 'rectangle_t',
   class   => 'Rectangle',
   members => [
     $point_def, 2,
   ]
 );
 
 $ffi->attach( print_rectangle => ['rectangle_t'] );
 
 my $rect = Rectangle->new([
   { x => 1.5,  y => 2.0  },
   { x => 3.14, y => 11.0 },
 ]);
 
 print_rectangle($rect);  # [[1.5 2] [3.14 11]]
 
 # move rectangle on the y axis
 $rect->[$_]->y( $rect->[$_]->y + 1.0 ) for 0..1;
 
 print_rectangle($rect);  # [[1.5 3] [3.14 12]]

=head1 DESCRIPTION

This class creates a def for a C array of structured data.  Usually the def
contains a L<FFI::C::StructDef> or L<FFI::C::UnionDef> and optionally a number
of elements.

=head1 CONSTRUCTOR

=head2 new

 my $def = FFI::C::ArrayDef->new(%opts);
 my $def = FFI::C::ArrayDef->new($ffi, %opts);

For standard def options, see L<FFI::C::Def>.

=over 4

=item members

This should be an array reference the member type, and
optionally the number of elements.  Examples:

 my $struct = FFI::C::StructDef->new(...);
 
 my $fixed = FFI::C::ArrayDef->new(
   members => [ $struct, 10 ],
 );
 
 my $var = FFI::C::ArrayDef->new(
   members => [ $struct ],
 );

=back

=head1 METHODS

=head2 create

 my $instance = $def->create;
 my $instance = $def->class->new;          # if class was specified
 my $instance = $def->create($count);
 my $instance = $def->class->new($count);  # if class was specified
 my $instance = $def->create(\@init);
 my $instance = $def->class->new(\@init);  # if class was specified

This creates an instance of the array.  If C<$count> is given, this
is used for the element count, possibly overriding what was specified
when the def was created.  If the def doesn't have an element count
specified, then you MUST provide it here.  Returns a L<FFI::C::Array>.

You can optionally initialize member values using C<@init>.

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
