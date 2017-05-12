package Finnigan::RawFileInfo;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'stringify');

sub decode {
  my ($class, $stream, $version) = @_;

  my $fields = [
                "preamble"          => ['object',  'Finnigan::RawFileInfoPreamble'],
                "label heading[1]"  => ['varstr', 'PascalStringWin32'],
                "label heading[2]"  => ['varstr', 'PascalStringWin32'],
                "label heading[3]"  => ['varstr', 'PascalStringWin32'],
                "label heading[4]"  => ['varstr', 'PascalStringWin32'],
                "label heading[5]"  => ['varstr', 'PascalStringWin32'],
                "unknown text"      => ['varstr', 'PascalStringWin32'],
               ];

  my $self = Finnigan::Decoder->read($stream, $fields, $version);

  return bless $self, $class;
}

sub preamble {
  shift->{data}->{preamble}->{value};
}

sub stringify {
  shift->preamble->stringify;
}

1;
__END__

=head1 NAME

Finnigan::RawFileInfo -- a decoder for RawFileInfo, the primary index structure

=head1 SYNOPSIS

  use Finnigan;
  my $file_info = Finnigan::RawFileInfo->decode(\*INPUT);
  say $file_info->preamble->run_header_addr;
  say $file_info->preamble->data_addr;
  $file_info->dump;

=head1 DESCRIPTION

This variable-size structure consists of RawFileInfoPreamble followed
by six text strings. The first five strings contain the headings for
the user-defined labels stored in SeqRow. The sixth string is probably
used to store the sample ID.

The older versions of RawFileInfoPreamble contained an unpacked
rpresentation of the file creation date in the UTC time zone.

The modern versions of the preamble also contain the pointer to the
ScanData stream and the pointer to RunHeader, which in turn stores
pointers to all other data streams in the file.

There are other data elements in the modern preamble, whose meaning is
unkonwn.


=head2 METHODS

=over 4

=item decode

The constructor method

=item preamble

Get the Finnigan::RawFileInfoPreamble object

=item stringify

Make a concise string representation of the structure

=back

=head1 SEE ALSO

Finnigan::RawFileInfoPreamble

Finnigan::SeqRow

Finnigan::Runheader

L<uf-rfi>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
