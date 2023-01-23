use utf8;
use strict;
use warnings;
use Test::More;
use Excel::ValueWriter::XLSX;
use Archive::Zip;

my $filename  = 'booleans.xlsx';
my @bool_data = ([qw/COL1 COL2/] => [ [qw/true false/],
                                      [qw/TRUE FALSE/],
                                      [qw/VRAI FAUX /]]);


# 1) build XLSX with default options
note "default options";
my $writer = Excel::ValueWriter::XLSX->new;
$writer->add_sheet(s1 => bools => @bool_data);
$writer->save_as($filename);

# checks
my $zip     = Archive::Zip->new($filename);
my $sheet1  = $zip->contents('xl/worksheets/sheet1.xml');
my $strings = $zip->contents('xl/sharedStrings.xml');
like $sheet1,  qr[t="b"><v>1</v></c>],                        'uppercase TRUE as bool';
like $sheet1,  qr[t="b"><v>0</v></c>],                        'uppercase FALSE as bool';
like $strings, qr[<si><t>true</t></si><si><t>false</t></si>], 'lowercase true/false as strings';


# 2) build XLSX without support for booleans
note "no booleans";
$writer = Excel::ValueWriter::XLSX->new(bool_regex => undef);
$writer->add_sheet(s1 => bools => @bool_data);
$writer->save_as($filename);

# checks
$zip     = Archive::Zip->new($filename);
$sheet1  = $zip->contents('xl/worksheets/sheet1.xml');
$strings = $zip->contents('xl/sharedStrings.xml');
unlike $sheet1,  qr[t="b"><v>1</v></c>],                      'no uppercase TRUE as bool';
unlike $sheet1,  qr[t="b"><v>0</v></c>],                      'no uppercase FALSE as bool';
like $strings, qr[<si><t>true</t></si><si><t>false</t></si>], 'lowercase true/false as strings';
like $strings, qr[<si><t>TRUE</t></si><si><t>FALSE</t></si>], 'uppercase true/false as strings';

# 3) french booleans
note "french booleans";
$writer = Excel::ValueWriter::XLSX->new(bool_regex => qr[^(?:(VRAI)|FAUX)$]);
$writer->add_sheet(s1 => bools => @bool_data);
$writer->save_as($filename);

# checks 
$zip     = Archive::Zip->new($filename);
$sheet1  = $zip->contents('xl/worksheets/sheet1.xml');
$strings = $zip->contents('xl/sharedStrings.xml');
like $sheet1,  qr[t="b"><v>1</v></c>],                        'uppercase VRAI as bool';
like $sheet1,  qr[t="b"><v>0</v></c>],                        'uppercase FAUX as bool';

# end of tests
done_testing;



