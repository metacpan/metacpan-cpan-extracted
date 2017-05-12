# NAME

Excel::CloneXLSX::Format - Convert Spreadsheet::ParseXLSX formats to Excel::Writer::XLSX

# SYNOPSIS

    use Excel::CloneXLSX::Format qw(translate_xlsx_format);
    use Excel::Writer::XLSX;
    use Safe::Isa;
    use Spreadsheet::ParseXLSX;

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

# DESCRIPTION

CPAN has great modules for reading XLS/XLSX files
([Spreadsheet::ParseExcel](https://metacpan.org/pod/Spreadsheet::ParseExcel) / [Spreadsheet::ParseXLSX](https://metacpan.org/pod/Spreadsheet::ParseXLSX)), and a great
module for writing XLSX files ([Excel::Writer::XLSX](https://metacpan.org/pod/Excel::Writer::XLSX)), but no module
for editing XLSX files.  _This_ module... won't do that either.  It
**will** convert [Spreadsheet::ParseExcel](https://metacpan.org/pod/Spreadsheet::ParseExcel)-style cell formats to a
structure that [Excel::Writer::XLSX](https://metacpan.org/pod/Excel::Writer::XLSX) will understand.

My hope is to eventually release an Excel::CloneXLSX module that will
create a copy of a `::Parse*` object, with hooks to modify the
content.

# USAGE

## translate\_xlsx\_format( $cell->get\_format() )

Takes the hashref returned from [Spreadsheet::ParseExcel::Cell](https://metacpan.org/pod/Spreadsheet::ParseExcel::Cell)'s
`get_format()` method and returns a hashref that can be fed to
[Excel::Writer::XLSX](https://metacpan.org/pod/Excel::Writer::XLSX)'s `new_format()` method.

### What's Supported

- Font (Family, Style, Size, {Super,Sub}script)
- Background Color
- Alignment
- Border Style and Color

### What isn't

- Foreground Color

    Trying to set the foreground color produces weird results.  I think it
    might be a bug in `Excel::Writer::XLSX`, but I haven't yet
    investigated.

- Everything else

# LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Fitz Elliott <felliott@fiskur.org>
