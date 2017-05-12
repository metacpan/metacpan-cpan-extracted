package Finance::Bank::BR::Caixa::CSV;

use strict;
use warnings;

use DateTime::Format::Strptime qw(strptime);
use Text::CSV::Encoded;

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
    my $file = shift;
    my $csv = Text::CSV::Encoded->new({
        encoding => "utf-8",
        encoding_in => "utf-8",
        sep_char => ";"
    });
    my $lines = $csv->getline_all($file, 1);
    my $balance = $self->{balance};
    for my $line (@{$lines}) {
        my $val = $line->[4];
        $val = -$val if ($line->[5] eq "D");
        $balance += $val;
        my $obj = {
            'date' => strptime("%Y%m%d", $line->[1]),
            'name' => $line->[3],
            'extra' => $line->[2],
            'value' => $val,
            'balance' => $balance,
        };
        push @{$self->{statement}}, $obj;
    }
    $self->{balance} = $balance;
}

sub load {
    my $self = shift;
    my $filename = shift;
    if (defined($filename)) {
        open my $file, "<", $filename or return 1;
        $self->_parse($file);
        close $file;
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

Finance::Bank::BR::Caixa::CSV - Parse statement exported from Brazilian bank Caixa Econômica Federal

=head1 SYNOPSIS

    use Finance::Bank::BR::Caixa::CSV;

    my $csv = Finance::Bank::BR::Caixa::CSV->new($filename);
    my $balance = $csv->balance;
    my @data = $csv->statement;
    foreach my $transaction (@data) {
        say "$transaction->{date}, $transaction->{name}, $transaction->{extra}, $transaction->{value}, $transaction->{balance}";
    }

=head1 Description

This module is an object-oriented interface that parses statements
exported as CSV from the Internet Banking for the Brazilian bank
Caixa Econômica Federal.

=head1 CSV

=head2 new($filename)

The C<new()> method creates a new CSV object containing the data parsed from C<$filename>.

If an error occurs while loading the file, C<new()> returns C<undef>.

=head2 balance()

The C<balance()> method returns the balance calculated from the file
assuming initial balance of 0.

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

  Copyright (C) 2015-2016 Thadeu Lima de Souza Cascardo <cascardo@cascardo.eti.br>

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut
