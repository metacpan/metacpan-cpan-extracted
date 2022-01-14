use strict;
use warnings;
use Test::More;
use Excel::ValueWriter::XLSX;
use Archive::Zip;


# build an XLSX file with 3 sheets
my $filename = 'foo.xlsx';
my $writer = Excel::ValueWriter::XLSX->new;
$writer->add_sheet(s1 =>      tabt1 => [[qw/foo bar barbar gig/],
                                        [1, 2],
                                        [3, undef, 0, 4],
                                        [qw(01.01.2022 19.12.1999 2022-3-4 12/30/1998)],
                                        [qw(01.01.1900 28.02.1900 01.03.1900)],
                                        [qw/bar foo/]]);
$writer->add_sheet('FEUILLE', undef,  [[qw/aa bb cc dd/], [45, 56], [qw/il était une bergère/], [99, 33, 33]]);
my $random_rows = do {my $count = 500; sub {$count-- == 500 ? [map {"h$_"} 1 .. 300] :
                                            $count          ? [map {rand()} 1 .. 300] : undef}};
$writer->add_sheet(RAND => rand => $random_rows);

$writer->save_as($filename);


# some stupid regex checks in various parts of the ZIP archive
my $zip = Archive::Zip->new($filename);

my $content_types = $zip->contents('[Content_Types].xml');
like $content_types, qr[<Override PartName="/xl/worksheets/sheet1.xml"], 'content-types';

my $workbook = $zip->contents('xl/workbook.xml');
like $workbook, qr[<sheets><sheet name="s1" sheetId="1" r:id="rId1"/>.+</sheets>], 'workbook';

my $sheet1 = $zip->contents('xl/worksheets/sheet1.xml');
like $sheet1, qr[<sheetData><row r="1" spans="1:4"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v>],  'sheet1';

my $table1 = $zip->contents('xl/tables/table1.xml');
like $table1, qr[<tableColumn id="1"], 'table1';

my $strings = $zip->contents('xl/sharedStrings.xml');
like $strings, qr[<si><t>foo</t></si><si><t>bar</t></si>], 'shared strings';


# end of tests
done_testing;



