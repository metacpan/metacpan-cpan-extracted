#!/usr/bin/env perl

=head1 SUMMARY

B<caixa.pl FILE.xls>

B<caixa.pl> parses F<FILE.txt> and outputs statements and balance.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2015-2016 Thadeu Lima de Souza Cascardo <cascardo@cascardo.eti.br>

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

use Finance::Bank::BR::Caixa::CSV;

if (@ARGV != 1) {
    print STDERR "caixa.pl FILE.xls\n";
    exit 1;
}

my $csv = Finance::Bank::BR::Caixa::CSV->new($ARGV[0]);

if (!defined($csv)) {
    print STDERR "Failed to parse $ARGV[0].\n";
    exit 2;
}

my $balance = $csv->balance;

my @data = $csv->statement;

foreach my $transaction (@data) {
    say "$transaction->{date}, $transaction->{name}, $transaction->{extra}, $transaction->{value}, $transaction->{balance}";
}

say $balance;
