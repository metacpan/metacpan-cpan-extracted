package FFI::Platypus::Type::StringArray;

use strict;
use warnings;

# ABSTRACT: Platypus custom type for arrays of strings
our $VERSION = '0.01'; # VERSION


use constant _incantation =>
  $^O eq 'MSWin32' && $Config::Config{archname} =~ /MSWin32-x64/
  ? 'Q'
  : 'L!';

my @stack;

sub perl_to_native
{
  # this is the variable length version
  # and is actually simpler than the
  # fixed length version
  my $count = scalar @{ $_[0] };
  my $pointers = pack(('P' x $count)._incantation, @{ $_[0] }, 0);
  my $array_pointer = unpack _incantation, pack 'P', $pointers;
  push @stack, [ \$_[0], \$pointers ];
  $array_pointer;
}

sub perl_to_native_post
{
  pop @stack;
  ();
}

sub ffi_custom_type_api_1
{
  # arg0 = class
  # arg1 = FFI::Platypus instance
  # arg2 = array size
  # arg3 = default value
  my(undef, undef, $count, $default) = @_;
  
  my $config = {
    native_type => 'opaque',
    perl_to_native => \&perl_to_native,
    perl_to_native_post => \&perl_to_native_post,
  };

  if(defined $count)
  {
    $config->{perl_to_native} = sub {
      my @list;
      my $incantation = '';
      
      foreach my $i (0..($count-1))
      {
        my $item = $_[0]->[$i];
        if(defined $item)
        {
          push @list, $item;
          $incantation .= 'P';
        }
        elsif(defined $default)
        {
          push @list, $default;
          $incantation .= 'P';
        }
        else
        {
          push @list, 0;
          $incantation .= _incantation;
        }
      }
      
      push @list, 0;
      $incantation .= _incantation;
      my $pointers = pack $incantation, @list;
      my $array_pointer = unpack _incantation, pack 'P', $pointers;
      push @stack, [ \@list, $pointers ];
      $array_pointer;
    };
  }
  
  $config;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Type::StringArray - Platypus custom type for arrays of strings

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your C code:

 void
 takes_string_array(const char **array)
 {
   ...
 }
 
 void
 takes_fixed_string_array(const char *array[5])
 {
   ...
 }

In your L<Platypus::FFI> code:

 use FFI::Platypus::Declare
   'void',
   [ '::StringArray' => 'string_array' ],
   [ '::StringArray' => 'string_5' => 5 ];
 
 attach takes_string_array => [string_array] => void;
 attach takes_fixed_string_array => [string_5] => void;
 
 my @list = qw( foo bar baz );
 
 takes_string_array(\@list);
 takes_fixed_string_array([qw( s1 s2 s3 s4 s5 )]);

=head1 DESCRIPTION

This module provides a L<FFI::Platypus> custom type for arrays of 
strings. The array is always NULL terminated.  It is not (yet) supported 
as a return type.

This custom type takes two optional arguments.  The first is the size of 
arrays and the second is a default value to fill in any values that 
aren't provided when the function is called.  If not default is provided 
then C<NULL> will be passed in for those values.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<FFI::Platypus::Type::StringPointer>

=back

=cut

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
