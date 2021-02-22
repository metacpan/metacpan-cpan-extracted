# NAME

Excel::Grinder - Import/export plain Excel (XLSX) files as simply as possible.

# DESCRIPTION / PURPOSE

This module should help you read/write XLSX spreadsheets to/from Perl arrays 
as simply as possible. The use cases are (1) when you need to export data from 
your database/application for non-programmers to enjoy in their beloved Excel 
and (2) when you need to allow for batch import/update operations via 
user-provided Excel.

There are so many awesome things you can do with Excel (formatting, formulas, 
pivot tables, etc.) but this module does none of that.  This is for the basic 
read-it-in and write-it-out -- which might just fit the bill.

This module will read an Excel (XLSX) file into a three-level arrayref.  The first
level is the worksheets, second level is the rows, and third level is the cells, such that:

        $$my_data[4][2][10] --> Worksheet 5, Row 3, Column 11 (aka as Column K)
        

Form a three-level arrayref to represent worksheets/rows/cells in this way, and you can create
a plain Excel XLSX file.  No formatting or formulas.  Ready for Tableau or just to confuse
your favorite front-line manager.

I put this together because I was offended at how difficult it is just to create an Excel
file in certain non-Perl environments, and since Excel is just a part of life for so many of us,
it really should be dead-simple.

To pursue additional Excel features, please see the excellent [Excel::Writer::XLSX](https://metacpan.org/pod/Excel%3A%3AWriter%3A%3AXLSX) and 
[Spreadsheet::XLSX](https://metacpan.org/pod/Spreadsheet%3A%3AXLSX) modules, of which this module is just a simple abstraction.

# SYNOPSIS

        # create the object to read/write excel files
        my $xlsx = Excel::Grinder->new('/opt/data/excel_files'); 
        # the directory can be anywhere that is writable; leave blank for /tmp/excel_grinder

        # to create a two-worksheet Excel workbook at /opt/data/excel_files/our_family.xlsx
        my $full_file_path = $xlsx->write_excel(
                'filename' => 'our_family.xlsx',
                'headings_in_data' => 1,
                'worksheet_names' => ['Dogs','People'],
                'the_data' => [
                        [
                                ['Name','Main Trait','Age Type'],
                                ['Ginger','Wonderful','Old'],
                                ['Pepper','Loving','Passed'],
                                ['Polly','Fun','Young'],
                                ['Daisy','Crazy','Puppy']
                        ],
                        [
                                ['Name','Main Trait','Age Type'],
                                ['Melanie','Smart','Oldish'],
                                ['Lorelei','Fun','Young'],
                                ['Eric','Fat','Old']
                        ]
                ],
        );      
        
        # if you prebuilt had that three-level array in $our_family_data:
        $full_file_path = $xlsx->write_excel(
                'filename' => 'our_family.xlsx',
                'headings_in_data' => 1,
                'worksheet_names' => ['Dogs','People'], 
                'the_data' => $our_family_data
        );
        
        # to read that spreadsheet back into an three-level arrayref that is just like
        # what we fed in to write_excel() above:        
        my $family_data = $xlsx->read_excel('our_family.xlsx');

        # Now you can modify or add to $family_data, and overwrite our_family.xlsx 
        # or create another XLSX file.

# METHODS

## new()

Creates a new object to use this module.  Accepts a 'default directory' path for where
to save / load the Excel files:

        $xlsx = Excel::Grinder->new('/home/ginger/excel_files');
        

If you leave out that directory argument, the default is /tmp/excel\_grinder .

## write\_excel()

Take a properly-formed three-level array and create an XLSX file.  The simplest
way to invoke.

        $full_file_path = $xlsx->write_excel(
                'filename' => 'some_filename.xlsx',
                'the_data' => $some_data
        );
        

The return value is the full location (file path) of the new file.

'Properly-formed' means the data itself is really at the third level,
while the first two just organize it into worksheets and rows:

        $websites = [
                [
                        [ 'Facebook','https://www.facebook.com', ],
                        [ 'LinkedIn','https://www.linkedin.com', ],
                        [ 'Google','https://www.google.com', ],
                ],
                [
                        [ 'CPAN','https://metacpan.org/', ],
                        [ 'Perl.Org','https://www.perl.org/', ]
                ],
        ];
        

This represents an Excel workbook with two worksheets.  The first one has three two-column rows,
and the second one has two two-column rows.  Often, a structure like this would be defined 
during a loop of some kind, or perhaps feed from the results of DBI's fetchall\_arrayref().
Yes, you might just have one worksheet, but you would still prepare a three-level arrayref,
with just one element at the top.  Sorry.

The 'headings\_in\_data' arg tells use to make each worksheet's first row all caps to 
indicate those are the headings.  The 'worksheet\_names' argument is the arrayref to 
the names to put on the nice tabs for the worksheets.  Both 'worksheet\_names' and 
'headings\_in\_data' are optional.

## read\_excel()

This does the exact opposite of write\_excel() in that it reads in an XLSX
file and returns the arrayref in the exact same format as what write\_excel()
receives.  All it needs is the absolute filepath for an XLSX file:

        $the_data = $xlsx->read_excel('/opt/data/excel_files/DATABASE_NAME/ginger.xlsx');
        # or you can just provide the filename, so long as it is in the default
        # directory path provided in new()

@$the\_data will look like the structure in the examples above.  Try it out ;)

# SEE ALSO

[Excel::Writer::XLSX](https://metacpan.org/pod/Excel%3A%3AWriter%3A%3AXLSX) 

[Spreadsheet::XLSX](https://metacpan.org/pod/Spreadsheet%3A%3AXLSX)

# AUTHOR

Eric Chernoff <eric@weaverstreet.net>

Please send me a note with any bugs or suggestions.

# LICENSE

MIT License

Copyright (c) 2021 Eric Chernoff

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
