package Finnigan::OLE2File;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';
use Carp qw/confess/;

use overload ('""' => 'stringify');

my $NDIF = 109;
my $FAT_POINTER_SIZE = 4; # 32 bits
my $PROPERTY_SIZE    = 128;
my $UNUSED       = 0xFFFFFFFF;   # -1
my $END_OF_CHAIN = 0xFFFFFFFE;   # -2
my $FAT_SECTOR  = 0xFFFFFFFD;   # -3
my $DIF_SECTOR = 0xFFFFFFFC;   # -4

my %SPECIAL = ($END_OF_CHAIN => 1, $UNUSED => 1, $FAT_SECTOR => 1, $DIF_SECTOR => 1);

sub decode {
  my ($class, $stream, $version) = @_;

  my @fields = (
                "magic"       => ['a8',     'RawBytes'],
                "header"      => ['object', 'Finnigan::OLE2Header'],
               );

  my $self = Finnigan::Decoder->read($stream, \@fields, $version);
  bless $self, $class;

  die "incorect OLE2 id" unless $self->magic eq "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1";

  # configure values
  $self->{stream} = $stream;
  $self->{"sector size"} = (1 << $self->header->bb_log);
  $self->{"fat count"} = $self->header->bb_count;
  $self->{"items per fat"} = $self->{"sector size"} / 4; # (size of sector pointer)
  $self->{"ss size"} = (1 << $self->header->sb_log);
  $self->{"items per minifat"} = $self->{"items per fat"};

  # read the DIF (Double-Indirect FAT)
  $self->SUPER::decode(
                       $stream,
                       ["dif" => ['object', 'Finnigan::OLE2DIF']],
                       [$self->header->dif_start, $self->header->dif_count],
                      );

  $self->{"block ref addr"} =
    $self->{addr}
      + $self->{data}->{magic}->{size}
        + $self->{data}->{header}->{size}
          + $NDIF * $FAT_POINTER_SIZE;

  # read the big FAT
  $self->{fat} = [];
  my $start = 0;
  my $count = $self->{"items per fat"};
  for my $index ( 0 .. scalar @{$self->dif->sect} - 1 ) {
    my $block = $self->dif->sect->[$index];
    last if $block == $UNUSED;
    $self->seek_block($block);
    $self->SUPER::decode(
                         $stream,
                         ["fat[$block]" => ['object', 'Finnigan::OLE2FAT']],
                         [$start, $count],
                        );
    push @{$self->{fat}}, $self->{data}->{"fat[$block]"}->{value};
  }

  # Read the mini-FAT
  $self->{minifat} = [];
  my @chain = $self->get_chain($self->header->sb_start, 'big');
  $start = 0;
  $count = $self->{"items per minifat"};
  for my $index ( 0 .. $#chain ) {
    my $block = $chain[$index];
    $self->seek_block($block);
    $self->SUPER::decode(
                         $stream,
                         ["minifat[$block]" => ['object', 'Finnigan::OLE2FAT']],
                         [$start, $count],
                        );
    push @{$self->{minifat}}, $self->{data}->{"minifat[$block]"}->{value};
    $start += $count;
  }
  
  # Read properties
  @chain = $self->get_chain($self->header->bb_start, 'big');
  my $prop_per_sector = int( $self->{"sector size"} / $PROPERTY_SIZE );
  $self->{properties} = [];
  foreach my $block ( @chain ) {
    $self->seek_block($block);
    foreach my $index ( 1 .. $prop_per_sector ) {
      # read the property name and return to start
      my $addr = tell $stream;
      my $bytes_to_read = 64;
      my $rec;
      my $nbytes = CORE::read $stream, $rec, $bytes_to_read;
      $nbytes == $bytes_to_read
        or die "could not read the $bytes_to_read bytes of property name at $addr";
      seek $stream, $addr, 0;

      my $charset;
      if ( $rec =~ /^\w\0\w\0/ ) {
        $charset = "UTF-16-LE";
      }
      elsif ( $rec =~ /^\0\w\0\w/ ) {
        $charset = "UTF-16-BE";
      }
      elsif ( $rec =~ /^\0{64}/ ) {
        last; # a null entry indicates the end of directory
      }
      else {
        my @hex = map { if (/[A-z]/) {$_} else { sprintf "%2.2x", ord($_) } } split("", $rec);
        confess "unknown encoding or not a string at $addr (@hex)";
      }

      $self->SUPER::decode(
                           $stream,
                           ["property[$block][$index]" => ['object', 'Finnigan::OLE2Property']],
                           [$self->header->bb_log, $charset]
                          );
      push @{$self->{properties}}, $self->{data}->{"property[$block][$index]"}->{value};
    }
  }

  # read the small block depot (which resides in the root entry's data stream)
  my $dir = new Finnigan::OLE2DirectoryEntry($self, 0);
  $self->{rootdir} = $dir;
  $self->{sbd} = $dir->data;

  return $self;
}

sub list {
  shift->{rootdir}->list();
}

sub stream {
  shift->{stream};
}

sub magic {
  shift->{data}->{magic}->{value};
}

sub header {
  shift->{data}->{header}->{value};
}

sub dif {
  shift->{data}->{dif}->{value};
}

sub fat {
  my ( $self, $block ) = @_;
  shift->{data}->{"fat[$block]"}->{value};
}

sub stringify {
  my $self = shift;

  my $n = scalar @{$self->{properties}};
  return "Windows Compound Binary File: $n nodes";
}

sub sector_size {
  my ( $self, $stream_size ) = @_;
  return $self->{"sector size"} unless $stream_size; # big by default
  return $self->{"sector size"} if $stream_size and $stream_size eq 'big';
  return $self->{"ss size"} if $stream_size and $stream_size eq 'mini';
}

sub seek_block {
  my ($self, $block) = @_;
  seek $self->{stream}, $self->{"block ref addr"} + $block * $self->sector_size('big'), 0;
}

sub read {
  my ($self, $stream_size, $start, $blocks_to_read) = @_;
  my $sector_size = $self->sector_size($stream_size);
  if ( $stream_size eq 'big' ) {
    my $rec;
    my $addr = tell $self->stream;
    my $bytes_to_read = $blocks_to_read * $sector_size;
    $self->seek_block($start);
    my $nbytes = CORE::read $self->stream, $rec, $bytes_to_read;
    $nbytes == $bytes_to_read
      or die "could not read $bytes_to_read bytes of property name at $addr";
    return $rec;
  }
  else {
    return substr $self->{sbd}, $start*$sector_size, $blocks_to_read*$sector_size;
  }
}

sub get_chain {
  my ($self, $start, $stream_size) = @_;

  my ($fat, $items_per_fat, $err_prefix);
  my @result;
  if ( $stream_size eq 'mini' ) {
    $fat = $self->{minifat};
    $items_per_fat = $self->{"items per minifat"};
    $err_prefix = "SFAT chain";
  }
  else {
    $fat = $self->{fat};
    $items_per_fat = $self->{"items per fat"};
    $err_prefix = "FAT chain";
  }

  my $block = $start;
  my %block_set;
  my $previous = $block;
  while ( $block != $END_OF_CHAIN ) {
    die (
         sprintf "%s: Invalid block index (0x%08x), previous=%s", $err_prefix, $block, $previous
        ) if $SPECIAL{$block};
    die ( sprintf "%s: Found a loop (%s=>%s)", $err_prefix, $previous, $block )
      if $block_set{$block};
    $block_set{$block}++;
    push @result, $block;
    $previous = $block;
    my $index = int($block / $items_per_fat);
    $block = $fat->[$index]->sect->[$block];
    last unless defined $block;
  }

  return @result;
}

sub find {
  my ($self, $path) = @_;
  $self->{rootdir}->find($path);
}

1;
__END__

=head1 NAME

Finnigan::OLE2File -- a decoder for Microsoft structured data files (OLE2 a.k.a. CDF)

=head1 SYNOPSIS

  use Finnigan;
  my $container = Finnigan::OLE2File->decode(\*INPUT);
  my $analyzer_method_text = $container->find("LTQ/Text")->data;

=head1 DESCRIPTION

Thermo uses the Microsoft OLE2 container to store the instrument
method files. This container has a hirerachical structure based on a
FAT filesystem. It seems like there are always two levels of hierarchy
used in the method container: one directory node for each istrument,
each directory containing one to three leaf nodes (files) named Data,
Text, or Header. The Header file exists only in the first directory
corresponding to the mass analyser. Other directories contain either
Text and Data, or just Data. It seems like Text is simply a
human-readable representation of Data, but this conjectures has not
been verified because the structure of the Data files remains unknown.

Finnigan::OLE2File decodes the container structure and allows the
extraction of the leaf nodes -- Header, Data, and Text.

=head2 METHODS

=over 4

=item decode($stream)

The constructor methad

=item list

Prints the directory listing of the entire OLE2 container to
STDOUT. A typical output may look like this:

  LTQ 
    Data (7512 bytes)
    Text (9946 bytes)
    Header (1396 bytes)

  EksigentNanoLcCom_DLL 
    Data (2898 bytes)
    Text (1924 bytes)

  NanoLC-AS1 Autosampler 
    Data (154 bytes)

  EksigentNanoLc_Channel2 
    Data (3028 bytes)
    Text (2398 bytes)

This method is not useful as part of the API (directory listings are
better understood by humans). But once the path to a node is known, it
can be retrieved with the B<find> method.

=item find($path)

Get the directory entry (Finnigan::OLE2DirectoryEntry) matching the
path supplied in the only argument. The directory entry's B<data>
method needs to be called in order to extract the node data.

=item stringify

Make a short string representation of the object, naming the file type and the number of nodes it contains

=back

=head2 PRIVATE METHODS

=over 4

=item dif

=item fat

=item get_chain

=item header

=item magic

=item read

=item sector_size

=item seek_block

=item stream

=back

=head1 SEE AlSO

L<Windows Compound Binary File Format Specification|http://download.microsoft.com/download/0/B/E/0BE8BDD7-E5E8-422A-ABFD-4342ED7AD886/WindowsCompoundBinaryFileFormatSpecification.pdf>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
