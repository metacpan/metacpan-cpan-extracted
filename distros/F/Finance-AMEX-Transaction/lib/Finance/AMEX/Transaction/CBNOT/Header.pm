package Finance::AMEX::Transaction::CBNOT::Header;
$Finance::AMEX::Transaction::CBNOT::Header::VERSION = '0.004';
use strict;
use warnings;

# ABSTRACT: Parse AMEX Chargeback Notification Files (CBNOT) Header Rows

use base 'Finance::AMEX::Transaction::CBNOT::Base';

sub field_map {
  return {
    REC_TYPE                => [1, 1],
    AMEX_APPL_AREA          => [2, 100],

    APPLICATION_SYSTEM_CODE => [2, 2],
    FILE_TYPE_CODE          => [4, 3],
    FILE_CREATION_DATE      => [6, 8],

    SAID                    => [102, 6],
    DATATYPE                => [108, 5],
    CCYYDDD                 => [113, 7],
    HHMMSS                  => [120, 7],
  };
}

sub type {return 'HEADER'}

sub AMEX_APPL_AREA          {return $_[0]->_get_column('AMEX_APPL_AREA')}
sub APPLICATION_SYSTEM_CODE {return $_[0]->_get_column('APPLICATION_SYSTEM_CODE')}
sub FILE_TYPE_CODE          {return $_[0]->_get_column('FILE_TYPE_CODE')}
sub FILE_CREATION_DATE      {return $_[0]->_get_column('FILE_CREATION_DATE')}
sub SAID                    {return $_[0]->_get_column('SAID')}
sub DATATYPE                {return $_[0]->_get_column('DATATYPE')}
sub CCYYDDD                 {return $_[0]->_get_column('CCYYDDD')}

# perl does not allow 0 at the beginning of a sub name,
# so we strip of the filler character in both the subname
# and the return value
sub HHMMSS                  {return substr($_[0]->_get_column('HHMMSS'), 1, 6)}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::CBNOT::Header - Parse AMEX Chargeback Notification Files (CBNOT) Header Rows

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $cbnot = Finance::AMEX::Transaction->new(file_type => 'CBNOT');
 open my $fh, '<', '/path to CBNOT file' or die "cannot open CBNOT file: $!";

 while (my $record = $cbnot->getline($fh)) {

  if ($record->type eq 'HEADER') {
    print $record->FILE_CREATION_DATE . "\n";
  }
 }

 # to parse a single line

 my $record = $cbnot->parse_line('line from a CBNOT file');
 if ($record->type eq 'HEADER') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::CBNOT::Header> object.

 my $record = Finance::AMEX::Transaction::CBNOT::Header->new(line => $line);

=head2 type

This will always return the string HEADER.

 print $record->type; # HEADER

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 REC_TYPE

This field contains the constant literal "H", a Record Type code that indicates that this is a Chargeback Notifications (CBNOT) File Header Record.

 print $record->REC_TYPE; # H

=head2 AMEX_APPL_AREA

This field contains the internal American Express data.

=head2 APPLICATION_SYSTEM_CODE

Not defined in the documentation.

=head2 FILE_TYPE_CODE

Not defined in the documentation.

=head2 FILE_CREATION_DATE

Not defined in the documentation.

=head2 SAID

This field contains the American Express-assigned, six-character, Service Access ID (SAID).

=head2 DATATYPE

This field contains the constant literal "CBNOT", a Data Type code that indicates that these are chargebacks from upstream systems.

=head2 CCYYDDD

This field contains the STARS creation date, which is the date that American Express transmitted the file to the merchant.

=head1 NAME

Finance::AMEX::Transaction::CBNOT::Header - Object methods for AMEX chargeback notification file header records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
