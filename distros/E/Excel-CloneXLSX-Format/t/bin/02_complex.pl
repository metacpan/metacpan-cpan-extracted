#!/usr/bin/env perl

# this is not yet a test, but a good way to eyeball differences

use strict;
use warnings;

use Test::More;

use Excel::CloneXLSX::Format qw(translate_xlsx_format);
use Excel::Writer::XLSX;
use Safe::Isa;
use Spreadsheet::ParseXLSX;


{
    my $old_workbook  = Spreadsheet::ParseXLSX->new->parse('t/data/sample.xlsx');
    my $old_worksheet = $old_workbook->worksheet('Sheet1');

    open my $fh, '>', 't/data/converted.xlsx'
        or die "Can't open output: $!";
    my $new_workbook  = Excel::Writer::XLSX->new( $fh );
    my $new_worksheet = $new_workbook->add_worksheet();

    my ($row_min, $row_max) = $old_worksheet->row_range();
    my ($col_min, $col_max) = $old_worksheet->col_range();
    for my $row ($row_min..$row_max) {
        for my $col ($col_min..$col_max) {

            my $old_cell   = $old_worksheet->get_cell($row, $col);
            my $old_format = $old_cell->$_call_if_object('get_format');
            my $fmt_props  = translate_xlsx_format( $old_format );
            my $new_format = $new_workbook->add_format(%$fmt_props);
            $new_worksheet->write(
                $row, $col, ($old_cell->$_call_if_object('unformatted') || ''),
                $new_format
            );
        }
    }

    $new_workbook->close;

    ok('done!');
}


done_testing();
