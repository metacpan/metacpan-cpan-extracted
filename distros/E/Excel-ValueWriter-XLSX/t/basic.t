use utf8;
use strict;
use warnings;
use Test::More;
use Excel::ValueWriter::XLSX;
use Archive::Zip;


# build an XLSX file
my $filename = 'foo.xlsx';
my $writer = Excel::ValueWriter::XLSX->new(compression_level => 7);

# 1st sheet, plain values and dates
$writer->add_sheet(s1 => à_table => [[qw/foo bar barbar gig/],
                                     [1, 2, "=[foo]+[bar]&[bar]", "'=[foo]+[bar]&[bar]"],
                                     [3, undef, 0, 4],
                                     [qw(01.01.2022 19.12.1999 2022-3-4 12/30/1998)],
                                     [qw(01.01.1900 28.02.1900 01.03.1900)],
                                     [qw/bar foo/]]);

# sheet without table
$writer->add_sheet(table_oubliée => (undef) => [[qw/aa bb cc dd/],
                                                [45, 56],
                                                [qw/il était une bergère/],
                                                [99, 33, 33]]);

# sheet with a large number of random values
my @headers_for_rand = map {"h$_"} 1 .. 300;
my $random_rows = do {my $count = 500; sub {$count-- > 0 ? [map {rand()} 1 .. 300] : undef}};
$writer->add_sheet(RAND => rand => \@headers_for_rand, $random_rows);

# other call syntax: headers as 3rd arg
$writer->add_sheet(With_header => t_header => [qw/col1 col2/], [[33, 44], [11, 22]]);

# empty sheets, with and without table
$writer->add_sheet(Empty1 => t_empty => []);
$writer->add_sheet(Empty2 => (undef) => []);

# defined names
$writer->add_defined_name(my_formula  => q{'s1'!$A$1&'s1'!$A$2}, "no comment");
$writer->add_defined_name(my_constant => q{"constant_value"});

# save the worksheet
$writer->save_as($filename);


# some stupid regex checks in various parts of the ZIP archive
my $zip = Archive::Zip->new($filename);

my $content_types = $zip->contents('[Content_Types].xml');
like $content_types, qr[<Override PartName="/xl/worksheets/sheet1.xml"], 'content-types';

my $workbook = $zip->contents('xl/workbook.xml');
like $workbook, qr[<sheets><sheet name="s1" sheetId="1" r:id="rId1"/>.+</sheets>], 'workbook';
like $workbook, qr[<definedName name="my_formula" comment="no comment">'s1'!\$A\$1&amp;'s1'!\$A\$2</], 'defined name';

my $sheet1 = $zip->contents('xl/worksheets/sheet1.xml');
like $sheet1, qr[<sheetData><row r="1" spans="1:4"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v>],  'sheet1';
like $sheet1, qr[<f>\Q[foo]+[bar]&amp;[bar]\E</f>], 'formula';


my $table1 = $zip->contents('xl/tables/table1.xml');
like $table1, qr[<tableColumn id="1"], 'table1';

my $strings = $zip->contents('xl/sharedStrings.xml');
like $strings, qr[<si><t>foo</t></si><si><t>bar</t></si>],     'shared strings';
like $strings, qr[<si><t>\Q=[foo]+[bar]&amp;[bar]\E</t></si>], 'escaped formula';

# end of tests
done_testing;



