# NAME

HTML::HTMLDoc - Perl interface to the htmldoc program for producing PDF Files from HTML content.

# SYNOPSIS

    use HTML::HTMLDoc;

    my $htmldoc = new HTML::HTMLDoc();

    # generate from a string of HTML:
    $htmldoc->set_html_content(qq~<html><body>A PDF file</body></html>~);
    
    # or generate from an HTML file:
    $htmldoc->set_input_file($filename); 

    # create the PDF
    my $pdf = $htmldoc->generate_pdf();

    # print the content of the PDF
    print $pdf->to_string();
    
    # save to a file
    $pdf->to_file('foo.pdf');

    # see the htmldoc command used to generate a PDF -- after using set_input_file() 
    # and all other desired configuration methods
    print $htmldoc->get_htmldoc_command();

# DESCRIPTION

This module provides an OO interface to the HTMLDOC program.  HTMLDOC is a command
line utility which creates PDF and PostScript files from HTML 3.2.  It is actively
maintained and available via the package manager (apt, yum) of the major Linux distros.

HTML 3.2 is very limited for web interfaces, but it can do a lot when preparing a 
document for printing.  The complete list of supported HTML tags is listed here:
[https://www.msweet.org/htmldoc/htmldoc.html#HTMLREF](https://www.msweet.org/htmldoc/htmldoc.html#HTMLREF)  There are also several 
HTMLDOC-specific comment options detailed here: [https://www.msweet.org/htmldoc/htmldoc.html#COMMENTS](https://www.msweet.org/htmldoc/htmldoc.html#COMMENTS)

The HTMLDOC home page at [https://www.msweet.org/htmldoc](https://www.msweet.org/htmldoc) and includes complete
documentation for the program and a link to the GitHub repo.

You will need to install HTMLDOC prior to installing this module, and it is
recommended to experiment with the 'htmldoc' command prior to utilizing this module.

All the config-setting modules return true for success or false for failure. You can 
test if errors occurred by calling the error-method.

Please use the get\_htmldoc\_command() method to retrieve an HTMLDOC command with your 
options for easy troubleshooting.  **If your HTML does not work with the HTMLDOC
command, it will also not work with this module.**

Normally this module uses IPC::Open3 for communication with the HTMLDOC process.
This works in PSGI and CGI environments, but if you are working in a Mod\_Perl environment,
you may need to set the file mode in new():

        my $htmldoc = new HTMLDoc('mode'=>'file', 'tmpdir'=>'/tmp');

# METHODS

## new()

Creates a new Instance of HTML::HTMLDoc.

Optional parameters are:

- mode=>\['file'|'ipc'\] defaults to ipc
- tmpdir=>$dir defaults to /tmp
- bindir=>$dir directory containing your preferred htmldoc executable, such as /usr/local/bin.  Useful when you have installed from source.

The tmpdir is used for temporary html-files in filemode. Remember to set the file-permissions
to write for the executing process.

## set\_page\_size($size)

Sets the desired size of the pages in the resulting PDF-document. $size is one of:

- universal (default) == 8.27x11in (210x279mm)
- a4 == 8.27x11.69in (210x297mm)
- letter == 8.5x11in (216x279mm)
- WxH{in,cm,mm} eg '10x10cm'

## set\_owner\_password($password)

Sets the owner-password for this document. $password can be any string. This only has effect if encryption is enabled.
see enable\_encryption().

## set\_user\_password($password)

Sets the user-password for this document. $password can be any string. If set, User will be asked for this
password when opening the file. This only has effect if encryption is enabled, see enable\_encryption().

## set\_permissions($perm)

Sets the permissions the user has to this document. $perm can be:

- all
- annotate
- copy
- modify
- print
- no-annotate
- no-copy
- no-modify
- no-print
- none

    Setting one of this flags automatically enables the document-encryption ($htmldoc->enable\_encryption())
    for you, because setting permissions will have no effect without it.

    Setting 'all' and 'none' will delete all other previously set options. You can set multiple options if
    you need, eg.:

    $htmldoc->set\_permissions('no-copy');
    $htmldoc->set\_permissions('no-modify');

    This one will do the same:
    $htmldoc->set\_permissions('no-copy', 'no-modify');

## links()

Turns link processing on.

## no\_links()

Turns the links off.

## path()

Specifies the search path for files in a document. Use this method if your images are not shown.

Example:

$htmldoc->path("/home/foo/www/myimages/");

## landscape()

Sets the format of the resulting pages to landscape.

## portrait()

Sets the format of the resulting pages to portrait.

## title()

Turns the title on.

## no\_title()

Turns the title off.

## set\_right\_margin($margin, $messure)

Set the right margin. $margin is a INT, $messure one of 'in', 'cm' or 'mm'.

## set\_left\_margin($margin, $messure)

Set the left margin. $margin is a INT, $messure one of 'in', 'cm' or 'mm'.

## set\_bottom\_margin($margin, $messure)

Set the bottom margin. $margin is a INT, $messure one of 'in', 'cm' or 'mm'.

## set\_top\_margin($margin, $messure)

Set the top margin. $margin is a INT, $messure one of 'in', 'cm' or 'mm'.

## set\_bodycolor($color)

Sets the background of all pages to this background color. $color is a hex-coded color-value (eg. #FFFFFF),
a rgb-value (eg set\_bodycolor(0,0,0) for black) or a color name (eg. black)

## set\_bodyfont($font)

Sets the default font of the content. Currently the following fonts are supported:

Arial Courier Helvetica Monospace Sans Serif Symbol Times

## set\_fontsize($fsize)

Sets the default font size for the body text to the number of points, e.g. 12 for 12-point font.  1 point = 1/72 of an inch.

## set\_textfont($font)

Sets the default font of the document. Currently the following fonts are supported:

Arial Courier Helvetica Monospace Sans Serif Symbol Times

## set\_bodyimage($image)

Sets the background image for the document. $image is the path to the image in your filesystem.

## set\_logoimage($image)

Sets the logo-image for the document. $image is the path to the image in your filesystem. The supported formats are BMP, GIF, JPEG, and PNG.
Remember to specify the 'l'-option somewhere in header or footer using set\_header() or/and set\_footer().

$htmldoc->set\_logoimage('mylogo.gif');
$htmldoc->set\_header('.', 'l', '.');

## get\_logoimage()

Reads out a previous set logo-image. You will get the filename to the image.

## set\_letterhead($image)

Sets the image to use as a letter for the document. $image is the path to the image in your filesystem. 
The image should be 72DPI, and for portrait mode, 620-650 pixels wide and 72-90 pixels tall.
The supported formats are BMP, GIF, JPEG, and PNG.

This only works when the header is set to '.L.', and this method will automatically set\_header()
to create that settings.

NOTE: This option is compatible with HTMLDOC 1.9.8 and higher. As of Feb. 14, 2020, that version is
available from cloning (and manual compile) from the HTMLDOC Git rep: [https://github.com/michaelrsweet/htmldoc](https://github.com/michaelrsweet/htmldoc)

$htmldoc->set\_letterhead('myletterhead.png');

## get\_letterhead()

Reads out a previous set letterhead image. You will get the filename to the image.

## set\_browserwidth($width)

Specifies the browser width in pixels. The browser width is used to scale images and pixel measurements when generating PostScript and PDF files. It does not affect the font size of text.

The default browser width is 680 pixels which corresponds roughly to a 96 DPI display. Please note that your images and table sizes are equal to or smaller than the browser width, or your output will overlap or truncate in places.

## set\_compression($level)

Specifies that Flate compression should be performed on the output file. The optional level parameter is a number from 1 (fastest and least amount of compression) to 9 (slowest and most amount of compression).

This option is only available when generating Level 3 PostScript or PDF files.

## set\_jpeg\_compression($quality)

$quality is a value between 1 and 100. Defaults to 75.

Sets the quality of the images in the PDF. Low values result in poor image quality but also in low file sizes for the PDF. High values result in good image quality but also in high file sizes.
You can also use methods best\_image\_quality() or low\_image\_quality(). For normal usage, including photos or similar a value of
75 should be ok. For high quality results use 100. If you want to reduce file size you have to play with the value to find a
compromise between quality and size that fits your needs.

## best\_image\_quality()

Set the jpg-image quality to the maximum value. Call this method if you want to produce high quality PDF-Files. Note that this could produce huge file sizes
depending on how many images you include and how big they are. See set\_jpeg\_compression(100).

## low\_image\_quality()

Set the jpg-image quality to a low value (25%). Call this method if you have many or huge images like photos in your PDF and you do not want exploding file sizes for your
resulting document. Note that calling this method could result in poor image quality. If you want some more control see method set\_jpeg\_compression() which allows you to
set the value of the compression to other values than 25%.

## set\_pagelayout($layout)

Specifies the initial page layout in the PDF viewer. The layout parameter can be one of the following:

- single - A single page is displayed.
- one - A single column is displayed.
- twoleft - Two columns are displayed with the first page on the left.
- tworight - Two columns are displayed with the first page on the right.

This option is only available when generating PDF files. 

## set\_pagemode($mode)

specifies the initial viewing mode of the document. $mode is one of:

- document - The document pages are displayed in a normal window.
- outline - The document outline and pages are displayed.
- fullscreen - The document pages are displayed on the entire screen.

## set\_charset($charset)

Defines the charset for the output document. The following charsets are currenty supported:

cp-874 cp-1250 cp-1251 cp-1252 cp-1253 cp-1254 cp-1255
cp-1256 cp-1257 cp-1258 iso-8859-1 iso-8859-2 iso-8859-3
iso-8859-4 iso-8859-5 iso-8859-6 iso-8859-7 iso-8859-8
iso-8859-9 iso-8859-14 iso-8859-15 koi8-r utf-8

## color\_on()

Defines that color output is desired.

## color\_off()

Defines that b&w output is desired.

## duplex\_on()

Enables output for two-sided printing.

## duplex\_off()

Sets output for one-sided printing.

## enable\_encryption()

Snables encryption and security features for the document.

## disable\_encryption()

Enables encryption and security features for the document.

## set\_output\_format($format)

Sets the format of the output-document. $format can be one of:

- html
- epub
- pdf (default)
- pdf11
- pdf12
- pdf13
- pdf14
- ps
- ps1
- ps2
- ps3

## set\_html\_content($html)

This is the function to set the html-content as a scalar. See set\_input\_file($filename)
to use a present file from your filesystem for input

## get\_html\_content()

Returns the previous set html-content.

## set\_input\_file($input\_filename)

This is the function to set the input file name.  It will also switch the
operational mode to 'file'.

## get\_input\_file()

Returns the previous set input file name.

## set\_header($left, $center, $right)

Defines the data that should be displayed in header. One can choose from the following chars for each left,
center and right:

- **.** A period indicates that the field should be blank.
- **:** A colon indicates that the field should contain the current and total number of pages in the chapter (n/N).
- **/** A slash indicates that the field should contain the current and total number of pages (n/N).
- **1** The number 1 indicates that the field should contain the current page number in decimal format (1, 2, 3, ...)
- **a** A lowercase "a" indicates that the field should contain the current page number using lowercase letters.
- **A** An uppercase "A" indicates that the field should contain the current page number using UPPERCASE letters.
- **c** A lowercase "c" indicates that the field should contain the current chapter title.
- **C** An uppercase "C" indicates that the field should contain the current chapter page number.
- **d** A lowercase "d" indicates that the field should contain the current date.
- **D** An uppercase "D" indicates that the field should contain the current date and time.
- **h** An "h" indicates that the field should contain the current heading.
- **i** A lowercase "i" indicates that the field should contain the current page number in lowercase roman numerals (i, ii, iii, ...)
- **I** An uppercase "I" indicates that the field should contain the current page number in uppercase roman numerals (I, II, III, ...)
- **l** A lowercase "l" indicates that the field should contain the logo image.
- **T** An uppercase "L" indicates that the logo image should stretch across the entire header.  Use only in the center.  (Works with htmldoc source as of Feb. 10, 2020.)
- **t** A lowercase "t" indicates that the field should contain the document title.
- **T** An uppercase "T" indicates that the field should contain the current time.
- **T** An lowercase "u" indicates that the field should contain the current filename or URL.

Example:

Setting the header to contain the title left, nothing in center and actual pagenumber right do the follwing

$htmldoc->set\_header('t', '.', '1');

## set\_footer($left, $center, $right)

Defines the data that should be displayed in footer. See set\_header() for details setting the left, center and right
value.

## embed\_fonts()

Specifies that fonts should be embedded in PostScript and PDF output. This is especially useful when generating documents in character sets other than ISO-8859-1.

## no\_embed\_fonts()

Turn the font-embedding previously enabled by embed\_fonts() off.

## generate\_pdf()

Generates the output-document. Returns a instance of HTML::HTMLDoc::PDF. See the perldoc of this class
for details

## get\_htmldoc\_command()

Returns the 'htmldoc' command with arguments to generate the PDF based on the configuration you've set
via the other methods.  Only works if you have specified an input HTML files via set\_input\_file().
Very useful for troubleshooting your output very quickly.

## error()

In scalar content returns the last error that occurred, in list context returns all errors that occurred.

## EXPORT

None by default.

# AUTHORS

Eric Chernoff - ericschernoff at	gmail.com - is the primary maintainer starting from the 0.12 release.

The module was created and developed by Michael Frankl - mfrankl at    seibert-media.de

# LICENSE

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# CREDITS

Many portions of this documentation pertaining to the options / configuration were copied and pasted from the HTMLDOC User Manual by Michael R Sweet at [https://www.msweet.org/htmldoc/htmldoc.html](https://www.msweet.org/htmldoc/htmldoc.html).

Thanks very much to:

Rajat Bhatia

Keith W. Sheffield

Christoffer Landtman

Aleksey Serba

Helen Hamster

Najib

for suggestions and bug fixes for versions 0.10 and earlier.

# FAQ

- Q: Where are the images that I specified in my HTML-Code?

    A: The images that you want to include have to be found by the process that is generating your PDF (that is
    using this Module). If you call the images relatively in your html-code like:
    &lt;img src="test.gif"> or &lt;img src="./myimages/test.gif">
    make sure that your perl program can find them. Note that a perl program can change the working
    directory internal (See perl -f chdir). You can find out the working directory using:

    use Cwd;
    print Cwd::abs\_path(Cwd::cwd);

    The module provides a method path($p). Use this if you want to specify where the images you want to use
    can be found. Example:

    $htmldoc->path("/home/foo/www/myimages/");

- Q: How can I do a page break?

    A: You can include a HTML-Comment that will do a page break for you at the point it is located:
    &lt;!-- PAGE BREAK -->

- Q: The Module works in shell but not with mod\_perl

    A: Use htmldoc in file-Mode:

    my $htmldoc = new HTMLDoc('mode'=>'file', 'tmpdir'=>'/tmp');

# BUGS

Please use the GitHub Issue Tracker to report any bugs or missing functions.

[https://github.com/ericschernoff/HTMLDoc/issues](https://github.com/ericschernoff/HTMLDoc/issues)

If you have difficulty with any of the features of this module, please test them
via the native 'htmldoc' command prior to reporting an issue.

# SEE ALSO

[https://www.msweet.org/htmldoc/htmldoc.html](https://www.msweet.org/htmldoc/htmldoc.html).

[https://github.com/michaelrsweet/htmldoc](https://github.com/michaelrsweet/htmldoc).

[PDF::API2](https://metacpan.org/pod/PDF::API2)

[PDF::Create](https://metacpan.org/pod/PDF::Create)

[CAM::PDF](https://metacpan.org/pod/CAM::PDF)
