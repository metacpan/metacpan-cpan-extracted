package Finnigan::CASInfoPreamble;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';


sub decode {
  my ($class, $stream) = @_;

  my $fields = [
                "unknown long[1]" => ['V',    'UInt32'],
                "unknown long[2]" => ['V',    'UInt32'],
                "number of wells" => ['V',    'UInt32'],
                "unknown long[3]" => ['V',    'UInt32'],
                "unknown long[4]" => ['V',    'UInt32'],
                "unknown long[5]" => ['V',    'UInt32'],
               ];

  my $self = Finnigan::Decoder->read($stream, $fields);
 
  return bless $self, $class;
}

1;
__END__

=head1 NAME

Finnigan::CASInfoPreamble -- a decoder for CASInfoPreamble, a numeric autosampler descriptor

=head1 SYNOPSIS

  use Finnigan;
  my $object = Finnigan::CASInfoPreamble->decode(\*INPUT);
  $object->dump;

=head1 DESCRIPTION

CASInfoPreamble is a fixed-length structure with some unknown data about the autosampler. It is a component of [CASInfo], which consists of this numeric descriptor and a text string following it.

=head2 METHODS

=over 4

=item decode

The constructor method

=back

=head1 SEE ALSO

Finnigan::CASInfo

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
