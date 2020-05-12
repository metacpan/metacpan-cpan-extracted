package FFI::C::Util;

use strict;
use warnings;
use 5.008001;
use Ref::Util qw( is_blessed_ref is_plain_arrayref is_plain_hashref is_ref is_blessed_hashref );
use Sub::Identify ();
use Carp ();
use Class::Inspector;
use base qw( Exporter );

our @EXPORT_OK = qw( perl_to_c c_to_perl take owned set_array_count );

# ABSTRACT: Utility functions for dealing with structured C data
our $VERSION = '0.07'; # VERSION


sub perl_to_c ($$)
{
  my($inst, $values) = @_;
  if(is_blessed_ref $inst && $inst->isa('FFI::C::Array'))
  {
    Carp::croak("Tried to initalize a @{[ ref $inst ]} with something other than an array reference")
      unless is_plain_arrayref $values;
    &perl_to_c($inst->get($_), $values->[$_]) for 0..$#$values;
  }
  elsif(is_blessed_ref $inst)
  {
    Carp::croak("Tried to initalize a @{[ ref $inst ]} with something other than an hash reference")
      unless is_plain_hashref $values;
    foreach my $name (keys %$values)
    {
      my $value = $values->{$name};
      $inst->$name($value);
    }
  }
  else
  {
    Carp::croak("Not an object");
  }
}


sub c_to_perl ($)
{
  my $inst = shift;
  Carp::croak("Not an object") unless is_blessed_ref($inst);
  if($inst->isa("FFI::C::Array"))
  {
    return [map { &c_to_perl($_) } @$inst]
  }
  elsif($inst->isa("FFI::C::Struct"))
  {
    my $def = $inst->{def};

    my %h;
    foreach my $key (keys %{ $def->{members} })
    {
      next if $key =~ /^:/;
      my $value = $inst->$key;
      $value = &c_to_perl($value) if is_blessed_ref $value;
      $value = [@$value] if is_plain_arrayref $value;
      $h{$key} = $value;
    }

    return \%h;
  }
  else
  {
    my %h;
    my $df = $INC{'FFI/C/StructDef.pm'};
    foreach my $key (@{ Class::Inspector->methods(ref $inst) })
    {
      next if $key =~ /^(new|DESTROY)$/;

      # we only want to recurse on generated methods.
      my ($file) = Sub::Identify::get_code_location( $inst->can($key) );
      next unless $file eq $df;

      # get the value;
      my $value = $inst->$key;
      $value = &c_to_perl($value) if is_blessed_hashref $value;
      $value = [@$value] if is_plain_arrayref $value;
      $h{$key} = $value;
    }

    return \%h;
  }
}


sub owned ($)
{
  my $inst = shift;
  !!($inst->{ptr} && !$inst->{owner});
}


sub take ($)
{
  my $inst = shift;
  Carp::croak("Not an object") unless is_blessed_ref $inst;
  Carp::croak("Object is owned by someone else") if $inst->{owner};
  my $ptr = delete $inst->{ptr};
  Carp::croak("Object pointer went away") unless $ptr;
  $ptr;
}


sub set_array_count ($$)
{
  my($inst, $count) = @_;
  Carp::croak("Not a FFI::C::Array")
    unless is_blessed_ref $inst && $inst->isa('FFI::C::Array');
  Carp::croak("This array already has a size")
    if $inst->{count};
  $inst->{count} = $count;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C::Util - Utility functions for dealing with structured C data

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 use FFI::C::Util qw( perl_to_c take );
 use FFI::C::StructDef;
 use FFI::Platypus::Memory qw( free );
 
 my $def = FFI::C::StructDef->new(
   members => [
     x => 'uint8',
     y => 'sint64',
   ],
 );
 my $inst = $def->create;
 
 # initalize members
 perl_to_c($inst, { x => 1, y => 2 });
 
 # take ownership
 my $ptr = take $inst;
 
 # since we took ownership, we are responsible for freeing the memory:
 free $ptr;

=head1 DESCRIPTION

This module provides some useful utility functions for dealing with
the various def instances provided by L<FFI::C>

=head1 FUNCTIONS

=head2 perl_to_c

 perl_to_c $instance, \%values;  # for Struct/Union
 perl_to_c $instance, \@values;  # for Array

This function initializes the members of an instance.

=head2 c_to_perl

 my $perl = c_to_perl $instance;

This function takes an instance and returns the nested members as Perl data structures.

=head2 owned

 my $bool = owned $instance;

Returns true of the C<$instance> owns its allocated memory.  That is,
it will free up the allocated memory when it falls out of scope.
Reasons an instance might not be owned are:

=over 4

=item the instance is nested inside another object that owns the memory

=item the instance was returned from a C function that owns the memory

=item ownership was taken away by the C<take> function below.

=back

=head2 take

 my $ptr = take $instance;

This function takes ownership of the instance pointer, and returns
the opaque pointer.  This means a couple of things:

=over 4

=item C<$instance> will not free its data automatically

You should call C<free> on it manually to free the memory it is using.

=item C<$instance> cannot be used anymore

So don't try to get/set any of its members, or pass it into a function.

=back

The returned pointer can be cast into something else or passed into
a function that takes an C<opaque> argument.

=head2 set_array_count

 set_array_count $inst, $count;

This function sets the element count on a variable array returned from
C (where normally there is no way to know from just the return value).
If you try to set a count on a non-array or a fixed sized array an
exception will be thrown.

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
