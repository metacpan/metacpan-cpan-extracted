package FFI::Platypus::Record::StringArray;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus::Memory qw( strdup calloc free );
use constant _ptr_size => FFI::Platypus->new->sizeof('opaque');

# ABSTRACT: Array of strings for your FFI record
our $VERSION = '0.01'; # VERSION


my $ffi;

sub new
{
  my $class = shift;

  $ffi ||= FFI::Platypus->new( lib => [undef] );

  my $size       = @_;
  my $array      = [map { defined $_ ? strdup($_) : undef } @_, undef];
  my $opaque     = calloc($size, _ptr_size);

  $ffi->function(
    memcpy => [ 'opaque', "opaque[$size]", 'size_t' ] => 'opaque',
  )->call($opaque, $array, $size * _ptr_size);

  my $self = bless {
    array => $array,
    opaque => $opaque,
  }, $class;
}


sub opaque
{
  my($self) = @_;
  $self->{opaque};
}


sub size
{
  my($self) = @_;
  scalar @{ $self->{array} } - 1;
}


sub element
{
  my($self, $index) = @_;
  $ffi->cast( 'opaque' => 'string', $self->{array}->[$index] );
}

sub DESTROY
{
  my($self) = @_;
  free($_) for grep { defined $_ } @{ $self->{array} };
  free($self->{opaque});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Record::StringArray - Array of strings for your FFI record

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 my $a = FFI::Platypus::Record::StringArray->new(qw( foo bar baz ));
 my $opaque = $a->opaque;

=head1 DESCRIPTION

Experimental interface for an array of C strings, useful for FFI record
classes.

The Platypus record class doesn't easily support an array of strings,
and trying to use an C<opaque> type to implement this is possible but more
than a little arcane.  This class provides an interface for creating
a C array of strings which can be used to provide an C<opaque> pointer
than can be used by an L<FFI::Platypus::Record> object.

Care needs to be taken!  Because Perl has no way of knowing if/when
the opaque pointer is no longer being used by C, you have to make
sure that the L<FFI::Platypus::Record::StringArray> instance remains
in scope for as long as the C<opaque> pointer is in use by C.

=head1 CONSTRUCTOR

=head2 new

 my $a = FFI::Platypus::Record::StringArray->new(@a);

Creates a new array of C strings.

=head1 METHODS

=head2 opaque

 my $opaque = $a->opaque;

Returns the opaque pointer to the array of C strings.

=head2 size

 my $size = $a->size;

Returns the number of elements in the array of C strings.

=head2 element

 my $element = $a->element($index);

Returns the string in the array of C strings at the given index.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
