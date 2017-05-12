#!/usr/bin/env perl

=head1 SUMMARY

B<santander.pl FILE.xls>

B<santander.pl> parses F<FILE.xls> and outputs statements and balance.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2015 Thadeu Lima de Souza Cascardo <cascardo@cascardo.eti.br>

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

use strict;
use warnings;
use feature qw(say);

use Finance::Bank::BR::Santander::Spreadsheet;

if (@ARGV != 1) {
    print STDERR "santander.pl FILE.xls\n";
    exit 1;
}

my $spreadsheet = Finance::Bank::BR::Santander::Spreadsheet->new($ARGV[0]);

if (!defined($spreadsheet)) {
    print STDERR "Failed to parse $ARGV[0].\n";
    exit 2;
}

my $balance = $spreadsheet->balance;

my @data = $spreadsheet->statement;

foreach my $transaction (@data) {
    say "$transaction->{date}, $transaction->{name}, $transaction->{extra}, $transaction->{value}, $transaction->{balance}";
}

say $balance;
