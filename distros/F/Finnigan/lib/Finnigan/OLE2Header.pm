package Finnigan::OLE2Header;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'stringify');

sub decode {
  my ($class, $stream, $version) = @_;

  my @fields = (
                "guid"            => ['a16',   'RawBytes'], # used by some apps
                "minor version"   => ['v',     'UInt16'],
                "major version"   => ['v',     'UInt16'],
                "endian"          => ['a2',    'RawBytes'], # 0xFFFE for Intel
                "bb log"          => ['v',     'UInt16'],   # log2-size of big blocks
                "sb log"          => ['v',     'UInt16'],   # log2-size of small blocks (minisectors)
                "reserved"        => ['a6',    'RawBytes'],
                "csectdir"        => ['V',     'UInt32'],   # Number of sector pointers in directory chain (sector size 4 kb)
                "bb count"        => ['V',     'UInt32'],   # number of blocks in Big Block Depot (number of SECTs in the FAT chain)
                "bb start"        => ['V',     'UInt32'],   # the first block in Big Block Depot (first SECT in the Directory chain)
                "transaction"     => ['a4',    'RawBytes'], # transaction signature
                "ministream max"  => ['V',     'UInt32'],   # max. size of a ministream (4096)
                "sb start"        => ['V',     'UInt32'],   # the first block in Small Block Depot (first SECT in the mini-FAT chain)
                "sb count"        => ['V',     'UInt32'],   # number of blocks in Small Block Depot (number of SECTs in the mini-FAT chain)
                "dif start"       => ['V',     'UInt32'],   # the first SECT in the DIF chain (should be 0xfffffffe if the file is smaller than 7Mb)
                "dif count"       => ['V',     'UInt32'],   # number of SECTs in the DIF chain (should be 0 if the file is smaller than 7Mb)
               );

  my $self = Finnigan::Decoder->read($stream, \@fields, $version);
  return bless $self, $class;
}

sub stringify {
  my $self = shift;

  my $version = $self->{data}->{"major version"}->{value} . "." . $self->{data}->{"minor version"}->{value};
  my $fat_blocks = $self->bb_count;
  my $minifat_blocks = $self->sb_count;
  my $dif_blocks = $self->dif_count;
  return "Version $version; block(s) in FAT chain: $fat_blocks; in mini-FAT chain: $minifat_blocks; in DIF chain: $dif_blocks";
}

sub ministream_max {
  shift->{data}->{"ministream max"}->{value};
}

sub bb_log {
  shift->{data}->{"bb log"}->{value};
}

sub sb_log {
  shift->{data}->{"sb log"}->{value};
}

sub bb_start {
  shift->{data}->{"bb start"}->{value};
}

sub bb_count {
  shift->{data}->{"bb count"}->{value};
}

sub sb_start {
  shift->{data}->{"sb start"}->{value};
}

sub sb_count {
  shift->{data}->{"sb count"}->{value};
}

sub dif_start {
  shift->{data}->{"dif start"}->{value};
}

sub dif_count {
  shift->{data}->{"dif count"}->{value};
}

1;
__END__

=head1 NAME

Finnigan::OLE2Header -- a decoder for the Microsoft OLE2 header structure

=head1 SYNOPSIS

  use Finnigan;
  my $header = Finnigan::OLE2Header->decode(\*INPUT);
  say "$header";

=head1 DESCRIPTION

This is an auxiliary decoder used by Finnigan::OLE2File; it is of no use on its own.

The OLE2 header is the first the first object to be decoded on the way
to parsing the embedded filesystem. It contains the key parameters that
determine the shape of the filesystem.

=head2 METHODS

=over 4

=item  decode($stream)

The constructor method

=item  bb_count

Get the number of blocks in Big Block Depot (number of SECTs in the FAT chain)

=item  bb_log

Get the log2-size of big blocks

=item  bb_start

Get the first block in Big Block Depot (first SECT in the Directory chain)

=item  dif_count

Get the number of SECTs in the DIF chain (should be 0 if the file is smaller than 7Mb)

=item  dif_start

Get the first SECT in the DIF chain (should be 0xfffffffe if the file is smaller than 7Mb)

=item  ministream_max

Get the maximum size of a ministream (4096)

=item  sb_count

Get the number of blocks in Small Block Depot (number of SECTs in the mini-FAT chain

=item  sb_log

Get the log2-size of small blocks

=item  sb_start

Get the first block in Small Block Depot (first SECT in the mini-FAT chain)

=item stringify

Makes a short text summary consisting of container format version and block use

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
