package FFI::Platypus::Lang::Raw;

use strict;
use warnings;
use base qw( FFI::Platypus::Lang::C );

# ABSTRACT: Types for use with FFI::Platypus::Legacy::Raw
our $VERSION = '0.06'; # VERSION


my %types;
sub native_type_map
{
  my $class = shift;
  unless(%types)
  {
    %types = (
      %{ $class->SUPER::native_type_map },
      'v' => 'void',
      'x' => 'sint64',
      'X' => 'uint64',
      'i' => 'sint32',
      'I' => 'uint32',
      'z' => 'sint16',
      'Z' => 'uint16',
      'c' => 'sint8',
      'C' => 'uint8',
      'f' => 'float',
      'd' => 'double',
      's' => 'string',
    );
  }
  $types{l} = $types{'long'};
  $types{L} = $types{'unsigned long'};
  \%types;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Lang::Raw - Types for use with FFI::Platypus::Legacy::Raw

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use FFI::Platypus;

 my $ffi = FFI::Platypus->new;
 $ffi->lang('Raw');

=head1 DESCRIPTION

This is a "language" plugin for L<FFI::Platypus::Legacy::Raw> integration.
Included are the same types provided by L<FFI::Platypus::Lang::C>, plus
the types understood by Raw such as C<FFI::Platypus::Legacy::Raw::int()>.

=head1 METHODS

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::Raw->native_type_map;

Returns a hashref for the type map for L<FFI::Platypus::Legacy::Raw>.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus::Legacy::Raw>

=back

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
