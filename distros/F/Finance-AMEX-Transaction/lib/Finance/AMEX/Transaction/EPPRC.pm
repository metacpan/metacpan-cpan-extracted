package Finance::AMEX::Transaction::EPPRC 0.005;

use strict;
use warnings;

use Finance::AMEX::Transaction::EPPRC::Header;
use Finance::AMEX::Transaction::EPPRC::Summary;
use Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummary;
use Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing;
use Finance::AMEX::Transaction::EPPRC::Detail::RecordSummary;
use Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing;
use Finance::AMEX::Transaction::EPPRC::Detail::Chargeback;
use Finance::AMEX::Transaction::EPPRC::Detail::Adjustment;
use Finance::AMEX::Transaction::EPPRC::Detail::Other;
use Finance::AMEX::Transaction::EPPRC::Trailer;
use Finance::AMEX::Transaction::EPPRC::Unknown;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC)

sub new {
  my ($class, %props) = @_;

  my $type_map = {
    HEADER            => 'Finance::AMEX::Transaction::EPPRC::Header',
    SUMMARY           => 'Finance::AMEX::Transaction::EPPRC::Summary',
    SOC_DETAIL        => 'Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummary',
    SOC_PRICING       => 'Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing',
    ROC_DETAIL        => 'Finance::AMEX::Transaction::EPPRC::Detail::RecordSummary',
    ROC_PRICING       => 'Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing',
    CHARGEBACK_DETAIL => 'Finance::AMEX::Transaction::EPPRC::Detail::Chargeback',
    ADJUSTMENT_DETAIL => 'Finance::AMEX::Transaction::EPPRC::Detail::Adjustment',
    OTHER_DETAIL      => 'Finance::AMEX::Transaction::EPPRC::Detail::Other',
    TRAILER           => 'Finance::AMEX::Transaction::EPPRC::Trailer',
  };

  my $self = bless {_type_map => $type_map}, $class;

  return $self;
}

sub file_format  {return 'N/A'}
sub file_version {return 'N/A'}

sub line_indicator {
  my ($self, $line) = @_;

  return if not defined $line;

  my $header_trailer_indicator = substr($line, 0, 5);

  my $indicator_map = {
    DFHDR => 'HEADER',
    DFTRL => 'TRAILER',
  };

  if (exists $indicator_map->{$header_trailer_indicator}) {
    return $indicator_map->{$header_trailer_indicator};
  }

  # if it is not a header or trailer, we need to look deeper
  my $summary_detail_indicator = join('-', substr($line, 42, 1), substr($line, 43, 2));

  my $summary_map = {
    '1-00' => 'SUMMARY',
    '2-10' => 'SOC_DETAIL',
    '2-12' => 'SOC_PRICING',
    '3-11' => 'ROC_DETAIL',
    '3-13' => 'ROC_PRICING',
    '2-20' => 'CHARGEBACK_DETAIL',
    '2-30' => 'ADJUSTMENT_DETAIL',
    '2-40' => 'OTHER_DETAIL',
    '2-41' => 'OTHER_DETAIL',
    '2-50' => 'OTHER_DETAIL',
  };

  if (exists $summary_map->{$summary_detail_indicator}) {
    return $summary_map->{$summary_detail_indicator};
  }

  # we don't know what it is!
  return;
}

sub parse_line {
  my ($self, $line) = @_;

  return if not defined $line;

  my $indicator = $self->line_indicator($line);

  if ($indicator and exists $self->{_type_map}->{$indicator}) {
    return $self->{_type_map}->{$indicator}->new(line => $line);
  }

  return Finance::AMEX::Transaction::EPPRC::Unknown->new(line => $line);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPPRC - Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC)

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Finance::AMEX::Transaction;

  my $epprc = Finance::AMEX::Transaction->new(file_type => 'EPPRC');
  open my $fh, '<', '/path to EPPRC file' or die "cannot open EPPRC file: $!";

  while (my $record = $epprc->getline($fh)) {

    if ($record->type eq 'TRAILER') {
      print $record->FILE_CREATION_DATE . "\n";
    }
  }

=head1 DESCRIPTION

This module parses AMEX Transaction/Invoice Level Reconciliation (EPPRC) files and  returns an object
which is appropriate for the line that it was asked to parse.

You would not normally be calling this module directly, it is merely a router to the correct object type
that is returned to L<Finance::AMEX::Transaction>'s getline method.

Object returned are one of:

=over 4

=item L<Finance::AMEX::Transaction::EPPRC::Header>

Header Rows

 print $record->type; # HEADER

=item L<Finance::AMEX::Transaction::EPPRC::Summary>

Summary Rows

 print $record->type; # SUMMARY

=item L<Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummary>

Summary of Charge (SOC) Detail Rows

 print $record->type; # SOC_DETAIL

=item L<Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing>

Summary of Charge (SOC) Level Pricing Rows

 print $record->type; # SOC_PRICING

=item L<Finance::AMEX::Transaction::EPPRC::Detail::RecordSummary>

Record of Charge (ROC) Detail Rows

 print $record->type; # ROC_DETAIL

=item L<Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing>

Record of Charge (ROC) Level Pricing Record Rows

 print $record->type; # ROC_PRICING

=item L<Finance::AMEX::Transaction::EPPRC::Detail::Chargeback>

Chargeback Detail Rows

 print $record->type; # CHARGEBACK_DETAIL

=item L<Finance::AMEX::Transaction::EPPRC::Detail::Adjustment>

Adjustment Detail Rows

 print $record->type; # ADJUSTMENT_DETAIL

=item L<Finance::AMEX::Transaction::EPPRC::Detail::Other>

Other Fees and Revenues Detail Rows

 print $record->type; # OTHER_DETAIL

=item L<Finance::AMEX::Transaction::EPPRC::Trailer>

Trailer Rows

 print $record->type; # TRAILER

=item L<Finance::AMEX::Transaction::EPPRC::Unknown>

Unknown Rows

 print $record->type; # UNKNOWN

=back

=head1 METHODS

=head2 new

Returns a L<Finance::AMEX::Transaction::EPPRC> object.

 my $epprc = Finance::AMEX::Transaction::EPPRC->new;

=head2 parse_line

Returns one of the L<Finance::AMEX::Transaction::EPPRC::Header>, L<Finance::AMEX::Transaction::EPPRC::Summary>, L<Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummary>, L<Finance::AMEX::Transaction::EPPRC::Detail::ChargeSummaryPricing>, L<Finance::AMEX::Transaction::EPPRC::Detail::RecordSummary>, L<Finance::AMEX::Transaction::EPPRC::Detail::RecordSummaryPricing>, L<Finance::AMEX::Transaction::EPPRC::Detail::Chargeback>, L<Finance::AMEX::Transaction::EPPRC::Detail::Adjustment>, L<Finance::AMEX::Transaction::EPPRC::Detail::Other>, L<Finance::AMEX::Transaction::EPPRC::Trailer>, or L<Finance::AMEX::Transaction::EPPRC::Unknown> records depending on the contents of the row.

 my $record = $epprc->parse_line('line from a epprc file');

=head2 file_format

This is included for compatibility, it will always return the string 'N/A'.

=head2 file_version

This is included for compatibility, it will always return the string 'N/A'.

=head2 line_indicator

Returns one of the line types for the EPPRC format.
You wouldn't normally need to call this.

 my $line_type = $epprc->line_indicator('line from a epprc file');

=head1 NAME

Finance::AMEX::Transaction::EPPRC - Parse AMEX Transaction/Invoice Level Reconciliation (EPPRC)

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
