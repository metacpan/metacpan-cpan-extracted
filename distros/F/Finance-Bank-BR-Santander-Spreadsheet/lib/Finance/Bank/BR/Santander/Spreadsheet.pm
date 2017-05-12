package Finance::Bank::BR::Santander::Spreadsheet;

use strict;
use warnings;

use Spreadsheet::ParseExcel::Simple;

use DateTime::Format::Strptime qw(strptime);

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_init;
    if ($self->load(@_)) {
        return undef;
    }
    return $self;
}

sub _init {
    my $self = shift;
    $self->{balance} = 0;
    $self->{statement} = [];
}

sub _parse {
    my $self = shift;
    my $xls = shift;
    my @sheets = $xls->sheets;
    my $sheet = $sheets[0];
    if ($sheet->has_data) {
        my @header = $sheet->next_row;
    }
    while ($sheet->has_data) {
        my @line = $sheet->next_row;
        my $obj = {
            'date' => strptime("%d/%m/%Y", $line[0]),
            'name' => $line[2],
            'extra' => $line[3],
            'value' => $line[4],
            'balance' => $line[5],
        };
        push @{$self->{statement}}, $obj;
        $self->{balance} = $line[5];
    }
}

sub load {
    my $self = shift;
    my $filename = shift;
    if (defined($filename)) {
        my $xls = Spreadsheet::ParseExcel::Simple->read($filename);
        if (!defined($xls)) {
            return 1;
        }
        $self->_parse($xls);
    }
    return 0;
}

sub balance {
    my $self = shift;
    return $self->{balance};
}

sub statement {
    my $self = shift;
    return @{$self->{statement}};
}

1;

__END__

=head1 NAME

Finance::Bank::BR::Santander::Spreadsheet - Parse statement exported from Brazilian branch of Santander Internet Banking

=head1 SYNOPSIS

    use Finance::Bank::BR::Santander::Spreadsheet;

    my $spreadsheet = Finance::Bank::BR::Santander::Spreadsheet->new($filename);
    my $balance = $spreadsheet->balance;
    my @data = $spreadsheet->statement;
    foreach my $transaction (@data) {
        say "$transaction->{date}, $transaction->{name}, $transaction->{extra}, $transaction->{value}, $transaction->{balance}";
    }

=head1 Description

This module is an object-oriented interface that parses statements exported as XLS from the Internet Banking for the Brazilian branch of Santander.

=head1 Spreadsheet

=head2 new($filename)

The C<new()> method creates a new Spreadsheet object containing the data parsed from C<$filename>.

If an error occurs while loading the file, C<new()> returns C<undef>.

=head2 balance()

The C<balance()> method returns the last balance found in the sheet.

=head2 statement()

The C<statement()> method returns an array of transactions, described as below.

=head1 Transaction

The transaction is a hash containing the following keys:

=head2 name

A string with a name describing the transaction.

=head2 value

A floating number containing the credit (positive) or debit (negative) of the transaction.

=head2 date

A DateTime object representing the date when the transaction occurred.

=head2 balance

A floating number containing the balance resulting from the transaction.

=head2 extra

Data provided by the bank identifying the transaction. In this case, a number specific to the type of transaction. It can be used to help uniquely identify the transaction.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2015 Thadeu Lima de Souza Cascardo <cascardo@cascardo.eti.br>

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut
