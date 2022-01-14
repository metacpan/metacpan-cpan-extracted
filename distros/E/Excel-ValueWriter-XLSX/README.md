Excel::ValueWriter::XLSX - generating data-only Excel workbooks in XLSX format, fast

  my $writer = Excel::ValueWriter::XLSX->new;
  $writer->add_sheet($sheet_name1, $table_name1, [[qw/a b/], [1, 2], [3, 4]]);
  $writer->add_sheet($sheet_name2, $table_name2, $row_generator);
  $writer->save_as($filename);


The common way for generating Microsoft Excel workbooks in C<XLSX>
format from Perl programs is the excellent L<Excel::Writer::XLSX>
module. That module is very rich in features, but quite costly in CPU
and memory usage. By contrast, the present module
L<Excel::ValueWriter::XLSX> is aimed at fast and cost-effective
production of data-only workbooks, containing nothing but plain
values. Such workbooks are useful in architectures where Excel is used
merely as a local database, for example in connection with a PowerBI
architecture.
