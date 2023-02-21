use utf8;
use strict;
use warnings;
use Test::More;
use List::Util                qw/max/;
use List::MoreUtils           qw/all/;
use Scalar::Util              qw/looks_like_number/;
use Clone                     qw/clone/;
use Module::Load::Conditional qw/check_install/;

use Excel::ValueReader::XLSX;

note "testing Excel::ValueReader::XLSX version $Excel::ValueReader::XLSX::VERSION";


(my $tst_dir = $0) =~ s/valuereader\.t$//;
$tst_dir       ||= ".";
my $xl_file      = "$tst_dir/valuereader.xlsx";
my $xl_1904      = "$tst_dir/valuereader1904.xlsx";
my $xl_ulibuck   = "$tst_dir/ulibuck.xlsx";
my $xl_mappe     = "$tst_dir/Mappe1.xlsx";
my $xl_without_r = "$tst_dir/cells_without_r_attr.xlsx";


my @expected_sheet_names = qw/Test Empty Entities Tab_entities Dates Tables/;
my @expected_values      = (  ["Hello", undef, undef, 22, 33, 55],
                              [123, undef, '<>'],
                              ["This is bold text", undef, '&'],
                              ["This is a Unicode string €", undef, '&<>'],
                              [],
                              [undef, "after an empty row and col",
                               undef, undef, undef,
                               "Hello after an empty row and col"],
                              ["cell\r\nwith\r\nembedded newlines"],
                             );

my @expected_tab_entities  = (
  [],
  [],
  ['Nombre de Name', "\x{c9}tiquettes de colonnes" ],
  ["\x{c9}tiquettes de lignes", 'capital', 'small', '(vide)',
   "Total g\x{e9}n\x{e9}ral"],
  ['A',                        '6',      '6',    undef, '12'],
  ['acute accent',             '1',      '1',    undef,  '2'],
  ['circumflex accent',        '1',      '1',    undef,  '2'],
  ['grave accent',             '1',      '1',    undef,  '2'],
  ['ring',                     '1',      '1',    undef,  '2'],
  ['tilde',                    '1',      '1',    undef,  '2'],
  ['dieresis or umlaut mark',  '1',      '1',    undef,  '2'],
  ['AE diphthong (ligature)',  '1',      '1',    undef,  '2'],
  ['(vide)',                   '1',      '1',    undef,  '2'],
  ['C',                        '1',      '1',    undef,  '2'],
  ['cedilla',                  '1',      '1',    undef,  '2'],
  ['E',                        '4',      '4',    undef,  '8'],
  ['acute accent',             '1',      '1',    undef,  '2'],
  ['circumflex accent',        '1',      '1',    undef,  '2'],
  ['grave accent',             '1',      '1',    undef,  '2'],
  ['dieresis or umlaut mark',  '1',      '1',    undef,  '2'],
  ['Eth',                      '1',      '1',    undef,  '2'],
  ['Icelandic',                '1',      '1',    undef,  '2'],
  ['greater than',             undef,    undef,    '1',  '1'],
  ['(vide)',                   undef,    undef,    '1',  '1'],
  ['I',                        '4',      '4',    undef,  '8'],
  ['acute accent',             '1',      '1',    undef,  '2'],
  ['circumflex accent',        '1',      '1',    undef,  '2'],
  ['grave accent',             '1',      '1',    undef,  '2'],
  ['dieresis or umlaut mark',  '1',      '1',    undef,  '2'],
  ['less than',                undef,    undef,    '1',  '1'],
  ['(vide)',                   undef,    undef,    '1',  '1'],
  ['N',                        '1',      '1',    undef,  '2'],
  ['tilde',                    '1',      '1',    undef,  '2'],
  ['O',                        '6',      '6',    undef, '12'],
  ['acute accent',             '1',      '1',    undef,  '2'],
  ['circumflex accent',        '1',      '1',    undef,  '2'],
  ['grave accent',             '1',      '1',    undef,  '2'],
  ['tilde',                    '1',      '1',    undef,  '2'],
  ['dieresis or umlaut mark',  '1',      '1',    undef,  '2'],
  ['slash',                    '1',      '1',    undef,  '2'],
  ['sharp s',                  undef,    '1',    undef,  '1'],
  ['German (sz ligature)',     undef,    '1',    undef,  '1'],
  ['single quote',             undef,    undef,    '1',  '1'],
  ['(vide)',                   undef,    undef,    '1',  '1'],
  ['THORN',                    '1',      '1',    undef,  '2'],
  ['Icelandic',                '1',      '1',    undef,  '2'],
  ['U',                        '4',      '4',    undef,  '8'],
  ['acute accent',             '1',      '1',    undef,  '2'],
  ['circumflex accent',        '1',      '1',    undef,  '2'],
  ['grave accent',             '1',      '1',    undef,  '2'],
  ['dieresis or umlaut mark',  '1',      '1',    undef,  '2'],
  ['Y',                        '1',      '2',    undef,  '3'],
  ['acute accent',             '1',      '1',    undef,  '2'],
  ['dieresis or umlaut mark',  undef,    '1',    undef,  '1'],
  ['(vide)',                   undef,    undef,    '1',  '1'],
  ['(vide)',                   undef,    undef,    '1',  '1'],
  ['ampersand',                undef,    undef,    '1',  '1'],
  ['(vide)',                   undef,    undef,    '1',  '1'],
  ["Total g\x{e9}n\x{e9}ral",  '30',     '32',     '5', '67'],
 );

my @expected_dates_and_times = (
  [ '10.07.2020',  '10.07.2020',  '01.02.1989', '10.07.2020 02:57:00', '02:57:59'],
  [ '10.07.2020',  '10.07.2020',  '31.12.1999', '10.07.2020 02:57:59', '01:23:00'],
  [ '10.07.2020',         undef,  '01.01.1900',                 undef, '01:26:18'],
  [ '10.07.2020',         undef,  '02.01.1900',                                  ],
  [ '10.07.2020',         undef,  '28.02.1900'                                   ],
  [ '10.07.2020',         undef,  '01.03.1900'                                   ],
  [ '10.07.2020',         undef,  '01.03.1900'                                   ],
  [ '10.07.2020',         undef,  '04.04.4444'                                   ],
  [ '10.07.2020'                                                                 ],
  [ '10.07.2020'                                                                 ],
  [ '10.07.2020'                                                                 ],
 );
# NOTE : cell C6 displays "29.02.1900" in Excel, but that date does not exist, so
# this module gets 01.03.1900 instead.

my @expected_dates_1904 = (
  ['11.07.2024', '11.07.2024', '01.02.1989',],
  ['11.07.2024', '11.07.2024', '31.12.1999',],
  ['11.07.2024',        undef, '02.01.1904',],
  ['11.07.2024',        undef, '03.01.1904',],
  ['11.07.2024',        undef, '29.02.1904',],
  ['11.07.2024',        undef, '01.03.1904',],
  ['11.07.2024',        undef, '02.03.1904',],
  ['11.07.2024',        undef, '05.04.4448',],
  ['11.07.2024',                            ],
  ['11.07.2024',                            ],
  ['11.07.2024',                            ],
);


my @expected_mappe = (
  [qw/a	b	c	d	e	a                                           /],
  [qw/a	b	c	d	e	b                                           /],
  [qw/a	b	c	d	e	c                                           /],
  [qw/a	b	c	d	e	d                                           /],
  [qw/a	b	c	d	e	e                                           /],
  [qw/a	b	bla-bla-bla	bla-bla-bla	bla-bla-bla	f                   /],
  [qw/a	b	bla-bla-bla	bla-bla-bla	bla-bla-bla	1                   /],
  [qw/a	b	bla-bla-bla	bla-bla-bla	bla-bla-bla	2                   /],
  [qw/a	b	bla-bla-bla	d	e	3                                   /],
  [qw/a	b	bla-bla-bla	d	e	5                                   /],
  [qw/a	b	c	d	e	6                                           /],
  [qw/1	11	bla-bla-bla	bla-bla-bla	bla-bla-bla	z                   /],
  [qw/2	12	bla-bla-bla	bla-bla-bla	bla-bla-bla	v                   /],
  [qw/3	13	bla-bla-bla	bla-bla-bla	bla-bla-bla	bla-bla-bla         /],
  [qw/4	14	c	d	e	bla-bla-bla                                 /],
  [qw/5	15	c	d	e	bla-bla-bla                                 /],
  [qw/6	16	c	d	e	bla-bla-bla                                 /],
  [qw/7	17	bla-bla-bla	bla-bla-bla	bla-bla-bla	bla-bla-bla         /],
  [qw/8	18	bla-bla-bla	bla-bla-bla	bla-bla-bla	bla-bla-bla         /],
  [qw/9	19	bla-bla-bla	bla-bla-bla	bla-bla-bla	bla-bla-bla         /],
  [qw/10	20	bla-bla-bla	bla-bla-bla	bla-bla-bla	bla-bla-bla /],
  [qw/11	21	bla-bla-bla	bla-bla-bla	bla-bla-bla	bla-bla-bla /],
  [qw/12	22	bla-bla-bla	bla-bla-bla	bla-bla-bla	bla-bla-bla /],
);


my @expected_tab_names = qw(Entities tab_foobar tab_in_middle_of_sheet tab_without_headers Cols_with_entities);


my @expected_tab_foobar = (
  {foo => 11, bar => 22},
  {foo => 33, bar => 44},
 );

my @expected_tab_badambum = (
  {badam => 99, bum => 88},
  {badam => 77, bum => 66},
 );

my @expected_tab_no_headers = (
  {col1 => 'aa', col2 => 'bb',  col3 => 'cc'},
  {col1 => 'dd', col2 => undef, col3 => undef},
  {col1 => 'ee', col2 => 'ff',  col3 => 'gg'},
 );

my @expected_tab_cols_with_entities = (
  {'col<' => 'foo', 'col&' => 'bar', 'col>' => 'bim'},
);


my @expected_without_r = (
  [qw/One      two      three/],
  [qw/four     five     six  /],
  [qw/seven    eight    nine /],
  [11, 22],
  [],
  [33, 44],
 );


my @backends = ('Regex');
push @backends, 'LibXML' if check_install(module => 'XML::LibXML::Reader');

foreach my $backend (@backends) {

  # dirty hack when testing with LibXML, because \r\n are silently transformed into \n
  local $expected_values[-1][0] = "cell\nwith\nembedded newlines"
    if $backend eq 'LibXML';

  # instantiate the reader
  my $reader = Excel::ValueReader::XLSX->new(xlsx => $xl_file, using => $backend);

  # check sheet names
  my @sheet_names = $reader->sheet_names;
  is_deeply(\@sheet_names, \@expected_sheet_names, "sheet names using $backend");

  # check a regular sheet
  my $values = $reader->values('Test');
  is_deeply($values, \@expected_values, "values using $backend");
  my $nb_cols = max map {scalar @$_} @$values;
  is ($nb_cols, 6, "nb_cols using $backend");

  # check an empty sheet
  my $empty  = $reader->values('Empty');
  is_deeply($empty, [], "empty values using $backend");

  # tables
  my ($entity_columns, $entities) = $reader->table('Entities');
  is_deeply($entity_columns, [qw(Num Name Char Cap/small Letter Variant)],
                                           "column names, using $backend");
  is $entities->[0]{Name},   'amp'       , "1st table row, name, using $backend";
  is $entities->[0]{Letter}, 'ampersand' , "1st table row, letter, using $backend";
  is $entities->[-1]{Name},  'yuml' ,      "last table row, name, using $backend";

  is_deeply([$reader->table_names], \@expected_tab_names, "table names, using $backend");

  my $tab_foobar = $reader->table('tab_foobar');
  is_deeply($tab_foobar, \@expected_tab_foobar, "tab_foobar, using $backend");

  my $tab_badambum = $reader->table('tab_in_middle_of_sheet');
  is_deeply($tab_badambum, \@expected_tab_badambum, "tab_badambum, using $backend");

  my ($col_headers, $tab_no_headers) = $reader->table('tab_without_headers');
  is_deeply($tab_no_headers, \@expected_tab_no_headers, "tab_no_headers, using $backend");

  my $tab_cols_with_entities = $reader->table('Cols_with_entities');
  is_deeply($tab_cols_with_entities, \@expected_tab_cols_with_entities, "tab_cols_with_entities, using $backend");

  # check a pivot table
  my $tab_entities = $reader->values('Tab_entities');
  is_deeply($tab_entities, \@expected_tab_entities, "tab_entities using $backend");

  # check date conversions
  my $dates = $reader->values('Dates');
  is_deeply($dates, \@expected_dates_and_times, "dates using $backend");

  # check time conversions with rounding hack
  my $t1 = $reader->formatted_date("44022.123599537037", "[h]:mm:ss");
  is($t1, '02:57:59', 'time conversion 1');
  my $t2 = $reader->formatted_date("0.123599537037", "[h]:mm:ss");
  is($t2, '02:57:59', 'time conversion 2');

  # other date format
  my $expected_other_format = clone \@expected_dates_and_times;
  foreach my $row (@$expected_other_format) {
    $_ and s/^(\d\d)\.(\d\d)\.\d\d(\d\d)/$2-$1-$3/ foreach @$row;
  }
  my $other_reader = Excel::ValueReader::XLSX->new(xlsx => $xl_file, using => $backend,
                                                   date_format => "%m-%d-%y");
  my $other_dates = $other_reader->values('Dates');
  is_deeply($other_dates, $expected_other_format, "dates with other format, using $backend");


  # no date format
  my $reader_no_date = Excel::ValueReader::XLSX->new(xlsx => $xl_file, using => $backend,
                                                     date_formatter => undef);
  my $dates_raw_nums  = $reader_no_date->values('Dates');
  my @all_vals_flat   = grep {$_} map {@$_} @$dates_raw_nums;
  my $are_all_numbers = all {looks_like_number($_)} @all_vals_flat;
  ok($are_all_numbers, "dates with no format, using $backend");


  # Excel file in 1904 date format
  my $reader_1904 = Excel::ValueReader::XLSX->new(xlsx => $xl_1904, using => $backend);
  my $dates_1904  = $reader_1904->values('Dates');
  is_deeply($dates_1904, \@expected_dates_1904, "dates in 1904 format, using $backend");

  # some edge cases provided by https://github.com/ulibuck
  my $reader_ulibuck = Excel::ValueReader::XLSX->new(xlsx => $xl_ulibuck, using => $backend);
  my $example1       = $reader_ulibuck->values('Example');
  is($example1->[3][2], '30.12.2021', "date1904=\"false\", using $backend");
  my $example2       = $reader_ulibuck->values('Example two');
  is($example2->[12][2], '# Dummy', "# Dummy, using $backend");

  # https://github.com/damil/Excel-ValueReader-XLSX/issues/2 : empty string (ulibuck++)
  my $reader_mappe = Excel::ValueReader::XLSX->new(xlsx => $xl_mappe, using => $backend);
  my $strings      = $reader_mappe->values('Tabelle2');
  is_deeply $strings, \@expected_mappe, "empty string nodes, using $backend";

  # cells do not always have a 'r' attribute
  my $reader_without_r = Excel::ValueReader::XLSX->new(xlsx => $xl_without_r, using => $backend);
  my $vals = $reader_without_r->values(1);
  is_deeply $vals, \@expected_without_r, "cells without 'r' attribute";
}



done_testing();

