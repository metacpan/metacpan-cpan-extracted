This script automates the conversion of the POD-documentation into HTML
documents.

It searches for all source files in the given source directory and its
subdirectories and writes the HTML output to the specified target.

pod2html.pl -help will tell you:

  Usage: ./pod2html.pl [options]
  
  -help   - This help screen.
  -source - The source directory of the perl modules that should be converted.
            Defaults to .
  -target - The target directory where the HTML files will be stored.
            Defaults to ../doc
  -css    - The CSS file which should be used.
            Defaults to cpan.css
  -index  - Create an index.html or not.
            Defaults to 0
