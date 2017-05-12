package Finnigan::OLE2FAT;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';
use Carp qw/confess/;

sub decode {
  my ($class, $stream, $param) = @_;
  my ($start, $count) = @$param;

  # do a null read to initialize internal variables
  my $self = Finnigan::Decoder->read($stream, [], $param);
  bless $self, $class;

  $self->{start} = $start; # this is used in Hachoir to generate continuous index in descriptions
  $self->{count} = $count;

  $self->iterate_scalar($stream, $count, sect => ['V', 'UInt32']);

  return $self;
}

sub sect {
  shift->{data}->{sect}->{value};
}


1;
__END__

=head1 NAME

Finnigan::OLE2FAT -- a decoder for FAT Sector, a block allocation structure in OLE2

=head1 SYNOPSIS

  use Finnigan;
  my $fat = Finnigan::OLE2FAT->decode(\*INPUT, [$start, $count]);
  say join(' ', @{$fat->sect});

=head1 DESCRIPTION

This is an auxiliary decoder used by Finnigan::OLE2File; it is of no use on its own. It reads a specified number of 4-byte intergers into an array that is to be interpreted as a sector allocation table by the caller of the B<sect> method.

=head2 METHODS

=over 4

=item decode($stream, [$start, $count])

The constructor method. The start and count parameters are reserved for possible future use. Although they are not used at the moment (because Finnigan files do not use non-trivial FAT arrangements), these parameters must still be provided by the caller to avoid the unidentified value errors.

=item sect

Return the array containing the sector allocation table

=back


=head1 SEE ALSO

Finnigan::OLE2File

L<Windows Compound Binary File Format Specification|http://download.microsoft.com/download/0/B/E/0BE8BDD7-E5E8-422A-ABFD-4342ED7AD886/WindowsCompoundBinaryFileFormatSpecification.pdf>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
