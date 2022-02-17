package Finance::AMEX::Transaction::GRRCN::Trailer 0.005;

use strict;
use warnings;

# ABSTRACT: Parse AMEX Transaction/Invoice Level Reconciliation (GRRCN) Trailer Rows

use base 'Finance::AMEX::Transaction::GRRCN::Base';

sub field_map {
  return [
    {RECORD_TYPE        => [1,  10]},
    {SEQUENTIAL_NUMBER  => [11, 10]},
    {TOTAL_RECORD_COUNT => [21, 10]},
    {FILLER1            => [31, 770]},
  ];
}

sub type {return 'TRAILER'}

sub RECORD_TYPE        {return $_[0]->_get_column('RECORD_TYPE')}
sub SEQUENTIAL_NUMBER  {return $_[0]->_get_column('SEQUENTIAL_NUMBER')}
sub TOTAL_RECORD_COUNT {return $_[0]->_get_column('TOTAL_RECORD_COUNT')}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Finance::AMEX::Transaction::GRRCN::Trailer - Parse AMEX Transaction/Invoice Level Reconciliation (GRRCN) Trailer Rows

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Finance::AMEX::Transaction;

 my $epraw = Finance::AMEX::Transaction->new(file_type => 'GRRCN');
 open my $fh, '<', '/path to GRRCN file' or die "cannot open GRRCN file: $!";

 while (my $record = $epraw->getline($fh)) {

  if ($record->type eq 'FOOTER') {
    print $record->RECORD_TYPE . "\n";
  }
 }

 # to parse a single line

 my $record = $epraw->parse_line('line from an GRRCN  file');
 if ($record->type eq 'TRAILER') {
   ...
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Finance::AMEX::Transaction>'s getline method.

=head1 METHODS

=head2 new

Returns a new L<Finance::AMEX::Transaction::GRRCN::Trailer> object.

 my $record = Finance::AMEX::Transaction::GRRCN::Trailer->new(line => $line);

=head2 type

This will always return the string TRAILER.

 print $record->type; # TRAILER

=head2 line

Returns the full line that is represented by this object.

 print $record->line;

=head2 field_map

Returns an arrayref of hashrefs where the name is the record name and 
the value is an arrayref of the start position and length of that field.

 # print the start position of the SEQUENTIAL_NUMBER field
 print $record->field_map->[1]->{SEQUENTIAL_NUMBER}->[0]; # 11

=head2 RECORD_TYPE

This field contains the Record identifier, which will always be “TRAILER” for the Trailer Record.

=head2 SEQUENTIAL_NUMBER

This field contains the Sequential Number which is the same as the sequential number in the Header Record.

A sequential number with a prefix of “A” indicates an Ad-hoc file.

=head2 TOTAL_RECORD_COUNT

This field contains the Record Count for all items in this data file, including the Header and Trailer Records. This field is intended to support value verification.

=head1 NAME

Finance::AMEX::Transaction::GRRCN::Trailer - Object methods for AMEX Reconciliation file footer records.

=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by ZipRecruiter/Tom Heady.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
