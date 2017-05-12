package Finnigan::SampleInfo;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Carp;
use Finnigan;
use base 'Finnigan::Decoder';


sub decode {
  my ($class, $stream) = @_;

  my $fields = [
                "unknown long[1]"    => ['V',      'UInt32'],  #  0
                "unknown long[2]"    => ['V',      'UInt32'],  #  2
                "first scan number"  => ['V',      'UInt32'],  #  4
                "last scan number"   => ['V',      'UInt32'],  #  6
                "inst log length"    => ['V',      'UInt32'],  #  8
                "unknown long[3]"    => ['V',      'UInt32'],  # 10
                "unknown long[4]"    => ['V',      'UInt32'],  # 12
                "scan index addr"    => ['V',      'UInt32'],  # 14 * unused in 64-bit versions
                "data addr"          => ['V',      'UInt32'],  # 16 *
                "inst log addr"      => ['V',      'UInt32'],  # 18 *
                "error log addr"     => ['V',      'UInt32'],  # 20 *
                "unknown long[5]"    => ['V',      'UInt32'],
                "max ion current"    => ['d<',     'Float64'],
                "low mz"             => ['d<',     'Float64'],
                "high mz"            => ['d<',     'Float64'],
                "start time"         => ['d<',     'Float64'],
                "end time"           => ['d<',     'Float64'],
                "unknown area"       => ['C56',    'RawBytes'],
                "tag[1]"             => ['U0C88',  'UTF16LE'],
                "tag[2]"             => ['U0C40',  'UTF16LE'],
                "tag[3]"             => ['U0C320', 'UTF16LE'],
               ];

  my $self = Finnigan::Decoder->read($stream, $fields);

  return bless $self, $class;
}

sub first_scan {
  shift->{data}->{"first scan number"}->{value};
}

sub last_scan {
  shift->{data}->{"last scan number"}->{value};
}

sub inst_log_length {
  shift->{data}->{"inst log length"}->{value};
}

sub max_ion_current {
  shift->{data}->{"max ion current"}->{value};
}

sub low_mz {
  shift->{data}->{"low mz"}->{value};
}

sub high_mz {
  shift->{data}->{"high mz"}->{value};
}

sub start_time {
  shift->{data}->{"start time"}->{value};
}

sub end_time {
  shift->{data}->{"end time"}->{value};
}

sub scan_index_addr {
  croak "direct access to SampleInfo->scan_index_addr breaks version compatbility. Use RunHeader->scan_index_addr instead."
}

sub data_addr {
  croak "direct access to SampleInfo->data_addr breaks version compatbility. Use RunHeader->data_addr instead."
}

sub inst_log_addr {
  croak "direct access to SampleInfo->inst_log_addr breaks version compatbility. Use RunHeader->inst_log_addr instead."
}

sub error_log_addr {
  croak "direct access to SampleInfo->error_log_addr breaks version compatbility. Use RunHeader->error_log_addr instead."
}

1;
__END__

=head1 NAME

Finnigan::SampleInfo -- a decoder for SampleInfo, the primary file index structure

=head1 SYNOPSIS

  use Finnigan;
  my $rh = Finnigan::RunHeader->decode(\*INPUT, $version);
  my $si = $rh->sample_info; # calls Finnigan::SampleInfo->decode
  say $si->first_scan;
  say $si->last_scan;
  say $si->tot_ion_current;
  my $scan_index_addr = $si->scan_index_addr;
  . . .

=head1 DESCRIPTION

SampleInfo is a static (fixed-size) binary preamble to RunHeader
containing data stream lengths and addresses, as well as some
unidentified data. All data streams in the file, except for the list
of ScanHeader records and TrailerScanEvent stream have their addresses
stored in SampleInfo.

The addresses of the ScanHeader and TrailerScanEvent streams are
stored in the parent structure, RunHeader.

It appears as though RunHeader is a recently introduced wrapper around
the older SampleInfo structure.

=head2 METHODS

=over

=item decode($stream)

The constructor method

=item first_scan

Get the first scan number

=item last_scan

Get the last scan number

=item inst_log_length

Get the number of instrument log records

=item max_ion_current

Get the pointer to the stream of ScanPrarameters? structures

=item low_mz

Get the low end of the M/z range

=item high_mz

Get the high end of the M/z range

=item start_time

Get the start time (retention time in seconds)

=item end_time

Get the end time (retention time in seconds)

=item scan_index_addr

Deprecated. See RunHeader->scan_index_addr

=item data_addr

Deprecated. See RunHeader->data_addr

=item inst_log_addr

Deprecated. See RunHeader->inst_log_addr

=item error_log_addr

Deprecated. See RunHeader->error_log_addr


=back

=head1 SEE ALSO

Finnigan::RunHeader

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
