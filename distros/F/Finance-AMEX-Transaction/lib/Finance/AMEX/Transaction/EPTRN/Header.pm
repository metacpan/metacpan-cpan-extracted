package Finance::AMEX::Transaction::EPTRN::Header 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (EPTRN) Header Rows

use base 'Finance::AMEX::Transaction::EPTRN::Base';

sub field_map {
  return {
    DF_HDR_RECORD_TYPE => [1,  5],
    DF_HDR_DATE        => [6,  8],
    DF_HDR_TIME        => [14, 4],
    DF_HDR_FILE_ID     => [18, 6],
    DF_HDR_FILE_NAME   => [24, 20],
  };
}

sub type {return 'HEADER'}

sub DF_HDR_RECORD_TYPE {return $_[0]->_get_column('DF_HDR_RECORD_TYPE')}
sub DF_HDR_DATE        {return $_[0]->_get_column('DF_HDR_DATE')}
sub DF_HDR_TIME        {return $_[0]->_get_column('DF_HDR_TIME')}
sub DF_HDR_FILE_ID     {return $_[0]->_get_column('DF_HDR_FILE_ID')}
sub DF_HDR_FILE_NAME   {return $_[0]->_get_column('DF_HDR_FILE_NAME')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPTRN::Header - Parse AMEX Transaction/Invoice Level Reconciliation (EPTRN) Header Rows

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'EPTRN');
 open my $fh, '<', '/path to EPTRN file' or die "cannot open EPTRN file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'HEADER') {
    print $record->DF_HDR_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an EPTRN  file');
 if ($record->type eq 'HEADER') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::EPTRN::Header> object.

 my $record = Finance::AMEX::Transaction::EPTRN::Header->new(line => $line);

=head2 type

This will always return the string HEADER.

 print $record->type; # HEADER

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 field_map

Returns a hashref where the name is the record name and 
the value is an arrayref of the start position and length of that field.

 # print the start position of the DF_HDR_DATE field
 print $record->field_map->{DF_HDR_DATE}->[0]; # 6

=head2 DF_HDR_RECORD_TYPE

This field contains the constant literal “DFHDR”, a Record Type code that indicates that this is a Data File Header Record.

=head2 DF_HDR_DATE

This field contains the File Creation Date. The format is: MMDDYYYY

=over 4

=item MM = Month

=item DD = Day

=item YYYY = Year

=back

=head2 DF_HDR_TIME

This field contains the File Creation Time (24-hour format), when the file was created.

The format is: HHMM

=over 4

=item HH = Hours

=item MM = Minutes

=back

=head2 DF_HDR_FILE_ID

This field may contain an American Express, system-generated, File ID number that uniquely identifies this data file.

If unused, this field is zero filled.

=head2 DF_HDR_FILE_NAME

This field may contain a File Name (as entered in the American Express data distribution database) that corresponds to DF_HDR_FILE_ID. Alternately, it may be populated with the first line of settlement name/address data.

=head1 NAME

Finance::AMEX::Transaction::EPTRN::Header - Object methods for AMEX Transaction/Invoice Level Reconciliation (EPTRN) file header records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
