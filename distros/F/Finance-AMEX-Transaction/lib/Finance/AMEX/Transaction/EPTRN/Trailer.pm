package Finance::AMEX::Transaction::EPTRN::Trailer;
$Finance::AMEX::Transaction::EPTRN::Trailer::VERSION = '0.002';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (EPTRN) Trailer Rows

use base 'Finance::AMEX::Transaction::EPTRN::Base';

sub field_map {
  return {
    DF_TRL_RECORD_TYPE   => [1, 5],
    DF_TRL_DATE          => [6, 8],
    DF_TRL_TIME          => [14, 4],
    DF_TRL_FILE_ID       => [18, 6],
    DF_TRL_FILE_NAME     => [24, 20],
    DF_TRL_RECIPIENT_KEY => [44, 40],
    DF_TRL_RECORD_COUNT  => [84, 7],
  };
}

sub type {return 'TRAILER'}

sub DF_TRL_RECORD_TYPE   {return $_[0]->_get_column('DF_TRL_RECORD_TYPE')}
sub DF_TRL_DATE          {return $_[0]->_get_column('DF_TRL_DATE')}
sub DF_TRL_TIME          {return $_[0]->_get_column('DF_TRL_TIME')}
sub DF_TRL_FILE_ID       {return $_[0]->_get_column('DF_TRL_FILE_ID')}
sub DF_TRL_FILE_NAME     {return $_[0]->_get_column('DF_TRL_FILE_NAME')}
sub DF_TRL_RECIPIENT_KEY {return $_[0]->_get_column('DF_TRL_RECIPIENT_KEY')}
sub DF_TRL_RECORD_COUNT  {return $_[0]->_get_column('DF_TRL_RECORD_COUNT')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::EPTRN::Trailer - Parse AMEX Transaction/Invoice Level Reconciliation (EPTRN) Trailer Rows

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'EPTRN');
 open my $fh, '<', '/path to EPTRN file' or die "cannot open EPTRN file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'FOOTER') {
    print $record->DF_TRL_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an EPTRN  file');
 if ($record->type eq 'TRAILER') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::EPTRN::Trailer> object.

 my $record = Finance::AMEX::Transaction::EPTRN::Trailer->new(line => $line);

=head2 type

This will always return the string TRAILER.

 print $record->type; # TRAILER

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 DF_TRL_RECORD_TYPE

This field contains the constant literal "DFTRL", a Record Type code that indicates that this is a Data File Trailer Record.

=head2 DF_TRL_DATE

This field contains the File Creation Date.

The format is: MMDDYYYY

=over 4

=item MM = Month

=item DD = Day

=item YYYY = Year

=back

=head2 DF_TRL_TIME

This field contains the File Creation Time (24-hour format), when the file was created.

The format is: HHMM

=over 4

=item HH = Hours

=item MM = Minutes

=back

=head2 DF_TRL_FILE_ID

This field contains an American Express, system-generated, File ID number that uniquely identifies this data file.

=head2 DF_TRL_FILE_NAME

This field contains the File Name (as entered in the American Express data distribution database) that corresponds to DF_TRL_FILE_ID.

=head2 DF_TRL_RECIPIENT_KEY

This field contains the Recipient Key, a unique, American Express, system-generated number that identifies this data file.

Note: This number is unique to each individual file.

=head2 DF_TRL_RECORD_COUNT

This field contains the Record Count for all items in this data file, including the header and trailer records.

=head1 NAME

Finance::AMEX::Transaction::EPTRN::Footer - Object methods for AMEX Transaction/Invoice Level Reconciliation (EPTRN) Trailer Rows

=head1 AUTHOR

Tom Heady <theady@ziprecruiter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
