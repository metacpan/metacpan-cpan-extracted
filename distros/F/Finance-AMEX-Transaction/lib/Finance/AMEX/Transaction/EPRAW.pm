package Finance::AMEX::Transaction::EPRAW;
$Finance::AMEX::Transaction::EPRAW::VERSION = '0.003';
use strict;
use warnings;

use Finance::AMEX::Transaction::EPRAW::Header;
use Finance::AMEX::Transaction::EPRAW::Summary;
use Finance::AMEX::Transaction::EPRAW::Detail::ChargeSummary;
use Finance::AMEX::Transaction::EPRAW::Detail::Chargeback;
use Finance::AMEX::Transaction::EPRAW::Detail::Adjustment;
use Finance::AMEX::Transaction::EPRAW::Detail::Other;
use Finance::AMEX::Transaction::EPRAW::Trailer;
use Finance::AMEX::Transaction::EPRAW::Unknown;

# ABSTRACT: Parse AMEX Reconciliation Files (EPRAW)

sub new {
  my ($class, %props) = @_;

  my $type_map = {
    HEADER            => 'Finance::AMEX::Transaction::EPRAW::Header',
    SUMMARY           => 'Finance::AMEX::Transaction::EPRAW::Summary',
    SOC_DETAIL        => 'Finance::AMEX::Transaction::EPRAW::Detail::ChargeSummary',
    CHARGEBACK_DETAIL => 'Finance::AMEX::Transaction::EPRAW::Detail::Chargeback',
    ADJUSTMENT_DETAIL => 'Finance::AMEX::Transaction::EPRAW::Detail::Adjustment',
    OTHER_DETAIL      => 'Finance::AMEX::Transaction::EPRAW::Detail::Other',
    TRAILER           => 'Finance::AMEX::Transaction::EPRAW::Trailer',
  };

  my $self = bless {
    _type_map => $type_map,
  }, $class;

  return $self;
}

sub parse_line {
  my ($self, $line) = @_;

  return if not defined $line;

  my $header_trailer_indicator = substr($line, 0, 5);

  # DFHDR = header
  # DFTRL = trailer
  # 1-00 = summary
  # 2-10 = SOC detail
  # 2-20 = Chargeback detail
  # 2-30 = Adjustment detail
  # 2-40, 2-41, 2-50 = Other Fees and Revenues detail

  my $indicator = 'UNKNOWN';

  if ($header_trailer_indicator eq 'DFHDR') {
    $indicator = 'HEADER';
  } elsif ($header_trailer_indicator eq 'DFTRL') {
    $indicator = 'TRAILER';
  } elsif ($indicator eq 'UNKNOWN') {
    my $summary_detail_indicator = join('-', substr($line, 42, 1), substr($line, 43, 2));
    if ($summary_detail_indicator eq '1-00') {
      $indicator = 'SUMMARY';
    } elsif ($summary_detail_indicator eq '2-10') {
      $indicator = 'SOC_DETAIL';
    } elsif ($summary_detail_indicator eq '2-20') {
      $indicator = 'CHARGEBACK_DETAIL';
    } elsif ($summary_detail_indicator eq '2-30') {
      $indicator = 'ADJUSTMENT_DETAIL';
    } elsif ($summary_detail_indicator eq '2-40' or $summary_detail_indicator eq '2-41' or $summary_detail_indicator eq '2-50') {
      $indicator = 'OTHER_DETAIL';
    }
  }
  if (exists $self->{_type_map}->{$indicator}) {
    return $self->{_type_map}->{$indicator}->new(line => $line);
  }
  return Finance::AMEX::Transaction::EPRAW::Unknown->new(line => $line);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPRAW - Parse AMEX Reconciliation Files (EPRAW)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Finance::AMEX::Transaction;

  my $epraw = Finance::AMEX::Transaction->new(file_type => 'EPRAW');
  open my $fh, '<', '/path to EPRAW file' or die "cannot open EPRAW file: $!";

  while (my $record = $epraw->getline($fh)) {

    if ($record->type eq 'TRAILER') {
      print $record->FILE_CREATION_DATE . "\n";
    }
  }

=head1 DESCRIPTION

This module parses AMEX Reconciliation Files (EPRAW) and returns an object which is appropriate for the line that it was asked to parse.

You would not normally be calling this module directly, it is merely a router to the correct object type that is returned to L<Finance::AMEX::Transaction>'s getline method.

Object returned are one of:

=over 4

=item L<Finance::AMEX::Transaction::EPRAW::Header>

Header Rows

 print $record->type; # HEADER

=item L<Finance::AMEX::Transaction::EPRAW::Summary>

Summary Rows

 print $record->type; # SUMMARY

=item L<Finance::AMEX::Transaction::EPRAW::Detail::ChargeSummary>

Summary of Charge (SOC) Detail Rows

 print $record->type; # SOC_DETAIL

=item L<Finance::AMEX::Transaction::EPRAW::Detail::Chargeback>

Chargeback Detail Rows

 print $record->type; # CHARGEBACK_DETAIL

=item L<Finance::AMEX::Transaction::EPRAW::Detail::Adjustment>

Adjustment Detail Rows

 print $record->type; # ADJUSTMENT_DETAIL

=item L<Finance::AMEX::Transaction::EPRAW::Detail::Other>

Other Detail Rows

 print $record->type; # OTHER_DETAIL

=item L<Finance::AMEX::Transaction::EPRAW::Trailer>

Trailer Rows

 print $record->type; # TRAILER

=item L<Finance::AMEX::Transaction::EPRAW::Unknown>

Unknown Rows

 print $record->type; # UNKNOWN

=back

=head1 METHODS

=head2 new

Returns a L<Finance::AMEX::Transaction::EPRAW> object.

 my $epraw = Finance::AMEX::Transaction::EPRAW->new;

=head2 parse_line

Returns one of the L<Finance::AMEX::Transaction::EPRAW::Header>, L<Finance::AMEX::Transaction::EPRAW::Summary>, L<Finance::AMEX::Transaction::EPRAW::Detail::ChargeSummary>, L<Finance::AMEX::Transaction::EPRAW::Detail::Chargeback>, L<Finance::AMEX::Transaction::EPRAW::Detail::Adjustment>, L<Finance::AMEX::Transaction::EPRAW::Detail::Other>, L<Finance::AMEX::Transaction::EPRAW::Trailer>, or L<Finance::AMEX::Transaction::EPRAW::Unknown> records depending on the contents of the line.

 my $record = $epraw->parse_line('line from a epraw file');

=head1 NAME

Finance::AMEX::Transaction::EPRAW - Parse AMEX Reconciliation Files (EPRAW)

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
