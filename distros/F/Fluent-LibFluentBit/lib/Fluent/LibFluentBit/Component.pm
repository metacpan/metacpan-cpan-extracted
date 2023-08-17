package Fluent::LibFluentBit::Component;
our $VERSION = '0.03'; # VERSION
use strict;
use warnings;
use Carp;
use Scalar::Util;

# ABSTRACT: Base class for handle-based objects


sub context { $_[0]{context} }
sub id      { $_[0]{id} }
sub name    { $_[0]{name} }

sub new {
   my $class= shift;
   my %attrs= @_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_;
   my $context= delete $attrs{context};
   ref $context or croak "Attribute 'context' is required and must be a LibFluentBit instance";
   my $name= delete $attrs{name};
   defined $name && length $name or croak "Attribute 'name' is required";
   my $self= bless { context => $context, name => $name }, $class;
   Scalar::Util::weaken($self->{context});
   $self->{id}= defined $attrs{id}? delete $attrs{id} : $self->_build_id($name);
   $self->configure(%attrs);
}

sub configure {
   my $self= shift;
   my %conf= @_ == 1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_;

   for (keys %conf) {
      if ($self->_set_attr($_, $conf{$_}) >= 0) {
         $self->{lc $_}= $conf{$_};
      } else {
         carp "Invalid fluent-bit attribute '$_' = '$conf{$_}'";
      }
   }
   return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Fluent::LibFluentBit::Component - Base class for handle-based objects

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This is a base class for the sub-objects of the FluentBit library, such as input, output,
and filters.  Each one is referenced by an integer rather than a pointer, and needs
paired with a fluent-bit context.

=head1 ATTRIBUTES

=head2 context

Weak-reference to Fluent::LibFluentBit instance

=head2 id

An integer referring to this object within the fluent-bit context.

=head2 name

The plugin name, which is more like a "type" of the object.

=head1 METHODS

=head2 new

The constructor requires 'id' and 'context' and 'name', and creates the related library object,
then passes any other attributes to the L</configure> method.

=head2 configure

  $obj->configure(key1 => $value1, key2 => $value2, ...)

The fluent-bit API assigns attributes by name and value (all strings, as if they came from
the config file)  The attributes are written to the library, and also written to the hashref
of this object for later inspection (because the library doesn't have getter functions).
The fluent-bit attribute names are case-insensitive, so this method flattens them to lowercase
before storing them in the Perl object.  Invalid attributes generate warnings, not errors.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
