package Finance::AMEX::Transaction::CBNOT::Trailer 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX Chargeback Notification Files (CBNOT) Trailer Rows

use base 'Finance::AMEX::Transaction::CBNOT::Base';

sub field_map {
  return {
    REC_TYPE                => [1,   1],
    AMEX_APPL_AREA          => [2,   100],
    APPLICATION_SYSTEM_CODE => [2,   2],
    FILE_TYPE_CODE          => [4,   2],
    FILE_CREATION_DATE      => [6,   8],
    FILE_SEQUENCE_NUMBER    => [20,  6],
    JULIAN_DATE             => [22,  2],
    AMEX_TOTAL_RECORDS      => [27,  5],
    CONFIRM_RECORD_COUNT    => [36,  9],
    AMEX_JOB_NUMBER         => [45,  9],
    SAID                    => [102, 6],
    DATATYPE                => [108, 5],
    CCYYDDD                 => [113, 7],
    HHMMSS                  => [120, 7],
    STARS_FILESEQ_NB        => [127, 3],
  };
}

sub type {return 'TRAILER'}

sub AMEX_APPL_AREA          {return $_[0]->_get_column('AMEX_APPL_AREA')}
sub APPLICATION_SYSTEM_CODE {return $_[0]->_get_column('APPLICATION_SYSTEM_CODE')}
sub FILE_TYPE_CODE          {return $_[0]->_get_column('FILE_TYPE_CODE')}
sub FILE_CREATION_DATE      {return $_[0]->_get_column('FILE_CREATION_DATE')}
sub FILE_SEQUENCE_NUMBER    {return $_[0]->_get_column('FILE_SEQUENCE_NUMBER')}
sub JULIAN_DATE             {return $_[0]->_get_column('JULIAN_DATE')}
sub AMEX_TOTAL_RECORDS      {return $_[0]->_get_column('AMEX_TOTAL_RECORDS')}
sub CONFIRM_RECORD_COUNT    {return $_[0]->_get_column('CONFIRM_RECORD_COUNT')}
sub AMEX_JOB_NUMBER         {return $_[0]->_get_column('AMEX_JOB_NUMBER')}
sub SAID                    {return $_[0]->_get_column('SAID')}
sub DATATYPE                {return $_[0]->_get_column('DATATYPE')}
sub CCYYDDD                 {return $_[0]->_get_column('CCYYDDD')}

# perl does not allow 0 at the beginning of a sub name,
# so we strip off the filler character in both the subname
# and the return value
sub HHMMSS           {return substr($_[0]->_get_column('HHMMSS'), 1, 6)}
sub STARS_FILESEQ_NB {return $_[0]->_get_column('STARS_FILESEQ_NB')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::CBNOT::Trailer - Parse AMEX Chargeback Notification Files (CBNOT) Trailer Rows

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Finance::AMEX::Transaction;

  my $cbnot = Finance::AMEX::Transaction->new(file_type => 'CBNOT');
  open my $fh, '<', '/path to CBNOT file' or die "cannot open CBNOT file: $!";

  while (my $record = $cbnot->getline($fh)) {

    if ($record->type eq 'TRAILER') {
      print $record->FILE_CREATION_DATE . "\n";
    }
  }

  # to parse a single line

  my $record = $cbnot->parse_line('line from a CBNOT file');
  if ($record->type eq 'TRAILER') {
    ...
  }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new Finance::AMEX::Transaction::CBNOT::Trailer object.

 my $record = Finance::AMEX::Transaction::CBNOT::Trailer->new(line => $line);

=head2 type

This will always return the string TRAILER.

 print $record->type; # TRAILER

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 field_map

Returns a hashref where the name is the record name and 
the value is an arrayref of the start position and length of that field.

 # print the start position of the FILE_CREATION_DATE field
 print $record->field_map->{FILE_CREATION_DATE}->[0]; # 6

=head2 REC_TYPE

This field contains a code that identifies the record type. The constant literal "H" indicates that this is a CBNOT File Trailer Record.

 print $record->REC_TYPE; # T

=head2 AMEX_APPL_AREA

This field contains the internal American Express data.

=head2 APPLICATION_SYSTEM_CODE

Part of the internal American Express data. Constant '01'.

=head2 FILE_TYPE_CODE

Part of the internal American Express data. Constant '01'.

=head2 FILE_CREATION_DATE

Part of the internal American Express data. Format: YYYYMMDD.

=head2 FILE_SEQUENCE_NUMBER

Part of the internal American Express data. American Express assigned processing control number, currently unused.

=head2 JULIAN_DATE

Part of the internal American Express data. Currently unused.

=head2 AMEX_TOTAL_RECORDS

Part of the internal American Express data. Total record count.

=head2 CONFIRM_RECORD_COUNT

Part of the internal American Express data. Total record count.

=head2 AMEX_JOB_NUMBER

Part of the internal American Express data. American Express assigned job number, currently unused.

=head2 SAID

This field contains the American Express-assigned, six-character, Service Access ID (SAID).

=head2 DATATYPE

This field contains a code that corresponds to the data type. The constant literal "CBNOT" indicates that these are "chargeback notifications" from upstream systems.

=head2 CCYYDDD

This field contains the file creation date. The format is: CCYYDDD

 CC = Century
 YY = Year
 DDD = Day (Julian date)

For example, October 21st, 2010 would appear as: 2010294

=head2 HHMMSS

This field contains the file creation time. The format is: HHMMSS

 HH = Hour (24 hour clock)
 MM = Minute
 SS = Second

For example, 2:37:00 P . M . would appear as: 143700

Note the this differs slightly from the official AMEX documentation, this module automatically removes a leading zero that is present in the original source data.

=head2 STARS_FILESEQ_NB

This field contains the STARS * file sequence number. This constant number is set to "001".

=head1 NAME

Finance::AMEX::Transaction::CBNOT::Trailer - Object methods for AMEX chargeback notification file trailer records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
