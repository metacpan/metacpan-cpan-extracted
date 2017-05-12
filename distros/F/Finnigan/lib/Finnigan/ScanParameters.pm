package Finnigan::ScanParameters;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
our @ISA = ('Finnigan::GenericRecord');

sub charge_state {
  shift->{data}->{'Charge State:'}->{value}
}

sub injection_time {
  shift->{data}->{'Ion Injection Time (ms):'}->{value}
}

sub monoisotopic_mz {
  shift->{data}->{'Monoisotopic M/Z:'}->{value}
}

sub scan_segment {
  shift->{data}->{'Scan Segment:'}->{value}
}

sub scan_event {
  shift->{data}->{'Scan Event:'}->{value}
}

1;
__END__

=head1 NAME

Finnigan::ScanParameters -- a decoder for ScanParameters, a GenericRecord containing various scan meta-data.

=head1 SYNOPSIS

  use Finnigan;
  my $p = Finnigan::ScanParameters->decode(\*INPUT, $generic_header_ref);
  say $p->charge_state;

=head1 DESCRIPTION

This decoder augments the GenericRecord decoder with the
B<charge_state> method. Copies of all other elements in this structure
can be found in other streams, so there is no need in making accessors
for them. The purpose of this stream is to provide pre-formatted
human-readable messages describing the scan data; The B<charge_state>
element seems to be unique in that it either does not exist anywhere
else, or has not been discovered so far.

The entire set can be printed in the following manner:

  foreach my $key (@{$header->labels}) {
    say $key  . "\t" . $p->{data}->{$key}->{value};
  }


=head2 METHODS

=over 4

=item decode($stream, $header->field_templates)

The constructor method. It needs a previously decoded header to work.

=item charge_state

Get the charge state of the base ion

=item injection_time

Get ion injection time in milliseconds

=item monoisotopic_mz

Get the monoisotopic mass of precursor ion

=item scan_segment

Get the current ScanSegment number (1 .. )

=item scan_event

Get the cunnent ScanEvent number (1 .. )

=back

=head1 SEE ALSO

Finnigan::GenericRecord

Finnigan::GenericDataHeader

L<uf-params>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
