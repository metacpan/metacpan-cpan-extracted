package Finnigan::ScanIndexEntry;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

my $fields = [
              "offset"           => ['V',  'UInt32'],
              "index"            => ['V',  'UInt32'],
              "scan event"       => ['v',  'UInt16'],
              "scan segment"     => ['v',  'UInt16'],
              "next"             => ['V',  'UInt32'],
              "unknown long"     => ['V',  'UInt32'],
              "data size"        => ['V',  'UInt32'],
              "start time"       => ['d<', 'Float64'],
              "total current"    => ['d<', 'Float64'],
              "base intensity"   => ['d<', 'Float64'],
              "base mz"          => ['d<', 'Float64'],
              "low mz"           => ['d<', 'Float64'],
              "high mz"          => ['d<', 'Float64'],
             ];

my $fields64 = [
              "32-bit offset (defunct)" => ['V',  'UInt32'],
              "index"                   => ['V',  'UInt32'],
              "scan event"              => ['v',  'UInt16'],
              "scan segment"            => ['v',  'UInt16'],
              "next"                    => ['V',  'UInt32'],
              "unknown long"            => ['V',  'UInt32'],
              "data size"               => ['V',  'UInt32'],
              "start time"              => ['d<', 'Float64'],
              "total current"           => ['d<', 'Float64'],
              "base intensity"          => ['d<', 'Float64'],
              "base mz"                 => ['d<', 'Float64'],
              "low mz"                  => ['d<', 'Float64'],
              "high mz"                 => ['d<', 'Float64'],
              "offset"                  => ['Q<', 'Uint64'],
             ];

sub decode {
  if ($_[2] == 64) {
    return bless Finnigan::Decoder->read($_[1], $fields64), $_[0];
  }
  else {
    return bless Finnigan::Decoder->read($_[1], $fields), $_[0];
  }
}

sub offset {
  shift->{data}->{"offset"}->{value};
}

sub index {
  shift->{data}->{"index"}->{value};
}

sub scan_event {
  shift->{data}->{"scan event"}->{value};
}

sub scan_segment {
  shift->{data}->{"scan segment"}->{value};
}

sub next {
  shift->{data}->{"next"}->{value};
}

sub unknown {
  shift->{data}->{"unknown long"}->{value};
}

sub data_size {
  shift->{data}->{"data size"}->{value};
}

sub start_time {
  shift->{data}->{"start time"}->{value};
}

sub total_current {
  shift->{data}->{"total current"}->{value};
}

sub base_intensity {
  shift->{data}->{"base intensity"}->{value};
}

sub base_mz {
  shift->{data}->{"base mz"}->{value};
}

sub low_mz {
  shift->{data}->{"low mz"}->{value};
}

sub high_mz {
  shift->{data}->{"high mz"}->{value};
}


1;
__END__

=head1 NAME

Finnigan::ScanIndexEntry -- a decoder for ScanIndexEntry, a linked list element pointing to scan data

=head1 SYNOPSIS

  use Finnigan;
  my $entry = Finnigan::ScanIndexEntry->decode(\*INPUT, $VERSION);
  say $entry->offset; # returns an offset from the start of scan data stream 
  say $entry->data_size;
  $entry->dump;

=head1 DESCRIPTION

ScanIndexEntry is a static (fixed-size) structure containing the
pointer to a scan, the scan's data size and some auxiliary information
about the scan.

Scan Index elements seem to form a linked list. Each ScanIndexEntry
contains the index of the next entry.

Although in all observed instances the scans were sequential and their
indices could be ignored, it may not always be the case.

It is not clear whether scan index numbers start at 0 or at 1. If they
start at 0, the list link index must point to the next item. If they
start at 1, then "index" will become "previous" and "next" becomes
"index" -- the list will be linked from tail to head. Although
observations are lacking, I am inclined to interpret it as a
forward-linked list, simply from common sense.

Note: The "current/next" theory of the two ordinal numbers in this
structure may be totally wrong. It may just be that one of these
numbers is the 0-base index (0 .. n -1), and the other is 1-based: (1
.. n). It is suspicious that in the last entry in every stream, the
"next" value is not null, it simply n.

=head2 METHODS

=over 4

=item decode($stream, $version)

The constructor method

=item offset

Get the address of the corresponding ScanDataPacket relative to the
start of the data stream

=item index

Get this element's index (a valid assumption if the scan data indices
start at 0, otherwise this is the previous element's index)

=item next

Get the next element's index(a valid assumption if the scan data
indices start at 0, otherwise this is the current element's index)

=item scan_event

Get the index of this element's ScanEventTemplate in the current scan
segment

=item scan_segment

Get the index of this element's scan segment in Scan Event Hierarchy

=item data_size

Get the size of the ScanDataPacket this index element is pointing to

=item start_time

Get the current scan's start time

=item total_current

Get the scan's total current (a rough indicator of how many ions were
scanned)

=item base_intensity

Get the intensity of the most abundant ion

=item base_mz

Get the M/z value of the most abundant ion

=item low_mz

Get the low end of the scan range

=item high_mz

Get the high end of the scan range

=item unknown

Get the only unknown UInt32 stored in the index entry. Its value (or
some bits in it) seem to correspond to the type of scan, but its
interpretation is uncertain.

=back

=head1 SEE ALSO

Finnigan::Profile

Finingan::Peaks

Finnigan::Scan

L<uf-index>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
