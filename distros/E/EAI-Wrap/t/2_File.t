use strict; use warnings;
use EAI::File; use Test::File; use Test::More; use Data::Dumper; use File::Spec;
use Test::More tests => 16; 

require './t/setup.pl';
chdir "./t";
my ($expected_filecontent,$expected_datastruct,$File,$data);

# 1 write data to tab separated file
$expected_filecontent = "col1\tcol2\tcol3\nval11\tval21\tval31\nval12\tval22\tval32\n";
$File = {format_sep => "\t",filename => "Testout.txt",columns => {1=>"col1",2=>"col2",3=>"col3"},};
$data = [{col1 => "val11",col2 => "val21",col3 => "val31"},{col1 => "val12",col2 => "val22",col3 => "val32"}];
writeText($File,$data);
file_contains_like("Testout.txt",qr/$expected_filecontent/,"Testout.txt is written content");

# 2 write data to csv file including quotes in header and values
$expected_filecontent = "\"col 1\",col2,col3\n\"val 11\",val21,val31\n\"val 12\",val22,val32\n";
$File = {format_sep => ",", format_quotedcsv => 1,filename => "Testout.csv",columns => {1=>"col 1",2=>"col2",3=>"col3"},};
$data =[{"col 1" => "val 11",col2 => "val21",col3 => "val31"},{"col 1" => "val 12",col2 => "val22",col3 => "val32"}];
writeText($File,$data);
file_contains_like("Testout.csv",qr/$expected_filecontent/,"Testout.csv is written content");

# 3 write data to excel xlsx file
$expected_filecontent = "";
$File = {format_xlformat => "xlsx",filename => "Testout.xlsx",columns => {1=>"col1",2=>"col2",3=>"col3"},};
$data =[{col1 => "val11",col2 => "val21",col3 => "val31"},{col1 => "val12",col2 => "val22",col3 => "val32"}];
writeExcel($File,$data);
file_exists_ok("Testout.xlsx","Testout.xlsx was written");

# 4 write data to excel xls file, data begins one line below header
$expected_filecontent = "";
$File = {format_xlformat => "xls", filename => "Testout.xls",columns => {1=>"col1",2=>"col2",3=>"col3"},};
$data =[{col1 => "",col2 => "",col3 => ""},{col1 => "val11",col2 => "val21",col3 => "val31"},{col1 => "val12",col2 => "val22",col3 => "val32"}];
writeExcel($File,$data);
file_exists_ok("Testout.xls","Testout.xls was written");

# 5 read data from tab separated file
$File = {format_skip => 1, format_sep => "\t",format_header => "col1\tcol2\tcol3",format_targetheader => "col1\tcol2\tcol3",filename => "Testout.txt",};
$data =[];
$expected_datastruct = [{col1 => "val11",col2 => "val21",col3 => "val31"},{col1 => "val12",col2 => "val22",col3 => "val32"}];
readText($File,$data,["Testout.txt"]);
is_deeply($data,$expected_datastruct,"read in tab sep data is expected content");

# 6 read csv data from file including quotes in header and values
$File = {format_skip => 1, format_sep => ",", format_quotedcsv => 1, format_header => "col 1,col2,col3", format_targetheader => "col 1,col2,col3",filename => "Testout.csv",};
$data =[];
$expected_datastruct = [{"col 1" => "val 11",col2 => "val21",col3 => "val31"},{"col 1" => "val 12",col2 => "val22",col3 => "val32"}];
readText($File,$data,["Testout.csv"]);
is_deeply($data,$expected_datastruct,"read in csv data is expected content");

# 7 read data from excel xlsx file
$File = {format_xlformat => "xlsx", format_worksheetID=>1, format_header => "col1\tcol2\tcol3",format_targetheader => "col1\tcol2\tcol3",filename => "Testout.xlsx",};
$data =[];
$expected_datastruct = [{col1 => "val11",col2 => "val21",col3 => "val31"},{col1 => "val12",col2 => "val22",col3 => "val32"}];
readExcel($File,$data,["Testout.xlsx"]);
is_deeply($data,$expected_datastruct,"read in excel xlsx data is expected content");

# 8 read data from excel xls file, data begins one line below header (format_skip starts from first row, existence of header is not regarded here)
$File =  {format_xlformat => "xls", format_worksheetID=>1, format_skip=>2, format_header => "col1\tcol2\tcol3",format_targetheader => "col1\tcol2\tcol3",filename => "Testout.xls",};
$data =[];
$expected_datastruct = [{col1 => "val11",col2 => "val21",col3 => "val31"},{col1 => "val12",col2 => "val22",col3 => "val32"}];
readExcel($File,$data,["Testout.xls"]);
is_deeply($data,$expected_datastruct,"read in excel xls data is expected content");

# 9 read data from excel xls file using format_headerColumns
$File = {format_xlformat => "xls", format_worksheetID=>1, format_skip=>2, format_headerColumns => [1,3], format_header => "col1\tcol3",format_targetheader => "col1\tcol3",filename => "Testout.xls",};
$data =[];
$expected_datastruct = [{col1 => "val11",col3 => "val31"},{col1 => "val12",col3 => "val32"}];
readExcel($File,$data,["Testout.xls"]);
is_deeply($data,$expected_datastruct,"read in excel xls data is expected content");

# 10 read data from excel xls file using format_headerColumns
$File =  {format_xlformat => "xls", format_skip => 1, format_worksheetID=>1, format_headerColumns => [1,3], format_header => "col1\tcol2\tcol3",format_targetheader => "col1\tcol2\tcol3",filename => "Testout.xls",};
$data =[];
$expected_datastruct = []; # expect empty array returned due to error.
readExcel($File,$data,["Testout.xls"]);
is_deeply($data,$expected_datastruct,"read in excel xls data not available due to error");

# 11 read data from XML file
open (FH, ">Testout.xml");
# write test xml
print FH "<topleveldata><coldata>topleveldataVal</coldata><sublevel><datalevel><record><col2>val21</col2><sub><col3>val31</col3></sub></record><record><col2>val22</col2><sub><col3>val32</col3></sub></record></datalevel></sublevel></topleveldata>";
close FH;
$File = {format_XML => 1, format_sep => ',', format_xpathRecordLevel => '//sublevel/datalevel/*', format_fieldXpath => {col1 => '//topleveldata/coldata', col2 => 'col2', col3 => 'sub/col3'}, format_header => "col1,col2,col3", filename => "Testout.xml",};
$data =[];
$expected_datastruct = [{col1 => "topleveldataVal",col2 => "val21",col3 => "val31"},{col1 => "topleveldataVal",col2 => "val22",col3 => "val32"}];
readXML($File,$data,["Testout.xml"]);
is_deeply($data,$expected_datastruct,"read in XML data is expected content");
unlink "Testout.xml";

# 12 read data from XML file with namespace
open (FH, ">Testout.xml");
# write test xml
print FH '<topleveldata xmlns="https://some.funny.namespace"><coldata>topleveldataVal</coldata><sublevel><datalevel><record><col2>val21</col2><sub><col3>val31</col3></sub></record><record><col2>val22</col2><sub><col3>val32</col3></sub></record></datalevel></sublevel></topleveldata>';
close FH;
$File = {format_XML => 1, format_sep => ',', format_namespaces => {e => 'https://some.funny.namespace'}, format_xpathRecordLevel => '//e:sublevel/e:datalevel/*', format_fieldXpath => {col1 => '//e:topleveldata/e:coldata', col2 => 'e:col2', col3 => 'e:sub/e:col3'}, format_header => "col1,col2,col3", filename => "Testout.xml",};
$data =[];
$expected_datastruct = [{col1 => "topleveldataVal",col2 => "val21",col3 => "val31"},{col1 => "topleveldataVal",col2 => "val22",col3 => "val32"}];
readXML($File,$data,["Testout.xml"]);
is_deeply($data,$expected_datastruct,"read in XML data is expected content");

# 13 evalCustomCode anon sub
$File = {format_skip => 1, format_sep => "\t",format_header => "col1\tcol2\tcol3",format_targetheader => "col1\tcol2\tcol3",filename => "Testout.txt", lineCode=>sub {$EAI::File::line{col1}=1;$EAI::File::line{col2}="test";}};
$data =[];
$expected_datastruct = [{col1 => 1,col2 => "test",col3 => "val31"},{col1 => 1,col2 => "test",col3 => "val32"}];
readText($File,$data,["Testout.txt"]);
is_deeply($data,$expected_datastruct,"evalCustomCode set \$line correctly with anon sub");

# 14 evalCustomCode string eval
$File = {format_skip => 1, format_sep => "\t",format_header => "col1\tcol2\tcol3",format_targetheader => "col1\tcol2\tcol3",filename => "Testout.txt", lineCode=>'$line{col1}=$line[0]."added";$line{col2}="test123";'};
$data =[];
$expected_datastruct = [{col1 => "val11added",col2 => "test123",col3 => "val31"},{col1 => "val12added",col2 => "test123",col3 => "val32"}];
readText($File,$data,["Testout.txt"]);
is_deeply($data,$expected_datastruct,"evalCustomCode set \$line correctly with string eval");

# 15 evalCustomCode string eval getting previous line with access to $data. $data needs to be accessed by dereferencing and checking if already filled (otherwise first data row will be autovivified)
$File = {format_skip => 1, format_sep => "\t",format_header => "col1\tcol2\tcol3",format_targetheader => "col1\tcol2\tcol3",filename => "Testout.txt", lineCode=>'$line{col2}=$data->[0]{col2} if @$data>0;'};
$data =[];
$expected_datastruct = [{col1 => "val11",col2 => "val21",col3 => "val31"},{col1 => "val12",col2 => "val21",col3 => "val32"}];
readText($File,$data,["Testout.txt"]);
is_deeply($data,$expected_datastruct,"evalCustomCode set \$line correctly with string eval getting previous line with access to \$data");

# 16 evalCustomCode anon sub getting previous line with access to $data. $data needs to be accessed by dereferencing and checking if already filled (otherwise first data row will be autovivified)
$File = {format_skip => 1, format_sep => "\t",format_header => "col1\tcol2\tcol3",format_targetheader => "col1\tcol2\tcol3",filename => "Testout.txt", lineCode=>sub {$EAI::File::line{col1}=$data->[0]{col2} if @$data>0;}};
$data =[];
$expected_datastruct = [{col1 => "val11",col2 => "val21",col3 => "val31"},{col1 => "val21",col2 => "val22",col3 => "val32"}];
readText($File,$data,["Testout.txt"]);
is_deeply($data,$expected_datastruct,"evalCustomCode set \$line correctly with anon sub getting previous line with access to \$data");

unlink "Testout.txt";
unlink "Testout.csv";
unlink "Testout.xlsx";
unlink "Testout.xls";
unlink "Testout.xml";
unlink "config/site.config";
unlink "config/log.config";
rmdir "config";
done_testing();