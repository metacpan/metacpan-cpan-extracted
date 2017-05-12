#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use FindBin qw($Bin);
use Getopt::Long;
use Pod::Usage;
use Safe::Isa;
use Spreadsheet::ParseExcel;

main: {
    my ($help);
    GetOptions('help|h' => \$help) or pod2usage(2);
    pod2usage(1) if ($help);

    my $old_workbook  = Spreadsheet::ParseExcel->new->parse("$Bin/../data/sample.xls");
    my $old_worksheet = $old_workbook->worksheet('Sheet1');

    my ($row_min, $row_max) = $old_worksheet->row_range();
    my ($col_min, $col_max) = $old_worksheet->col_range();
    for my $row ($row_min..$row_max) {
        for my $col ($col_min..$col_max) {
            my $old_cell   = $old_worksheet->get_cell($row, $col);
            my $old_format = $old_cell->$_call_if_object('get_format');
            p($old_format) if ($old_format->{Fill}[0] == 1);
        }
    }

}

__END__

=head1 NAME

extract-xls.pl

=head1 SYNOPSIS

=head1 OPTIONS

=over

=item B<-h, --help>

Prints this message and exits.

=back
