# Using Locale::XGettext From Various Programming Languages

In this subdirectory you will find implementations of a very simple
string extractor in a number of languages.  The extractor will split
its input into lines and make every non-empty line into a PO entry.

All examples --- except for the [Perl example](perl/README.md) --- use the `Inline` Perl 
module that allows embedding code written in other languages directly 
into Perl code.

In order to use the example scanners you usually have to do the following:

    sudo cpan install Inline::LANGUAGE
    perl -Ilib samples/LANGUAGE/xgettext-lines.pl --help
    perl -Ilib samples/LANGUAGE/xgettext-lines.pl README.md

Replace LANGUAGE with the language you want to test.  In the case of
Java you may have to run the command "sudo cpan install Inline::Java::Class"
(not just "Inline::Java").

If your package manager already has a prebuilt package for the
`Inline` module of your choice you should give it a try.  In general,
installing `Inline` modules is quite challenging.

Following is a list of possible candidate languages for that 
"Inline::*" bindings exists:

* [C](C/README.md)
* C++
* Guile
* [Java](Java/README.md)
* Lua
* [Python](Python/README.md)
* [Ruby](Ruby/README.md)
* Tcl

Some of the language names above link to a fully function example.

The list is not complete, but the languages Go and JavaScript
(via NodeJS) are still missing at the time of this writing.

# Walk-through example for Python

Let's look at a step-by-step instruction for writing an xgettext
program in Python.  The source code for the sample implementations for
other languages will give you enough information to modify the example
for your own needs.

## Installation of Inline::Python

We need the module that allows calling Python from Perl (and vice
versa):

    $ sudo cpan install Inline::Python

This will install "Inline::Python".

## Implementation with a separate module

The `Python` subdirectory contains a script `xgettext-lines.pl` and a
Python module `PythonGettext.py`.

The Perl script can be used without modification for any extractor that
you want to write in Python.  It will turn every method it finds in
`PythonGettext.py` into a Perl method.  See
[Locale::XGettext(3pm)](http://search.cpan.org/~guido/Locale-XGettext/lib/Locale/XGettext.pm)
for details about the methods you can implement.

## Minimal Implementation

The minimal implementation in `PythonGettext.py` will look like this:

    class PythonXGettext:
        def __init__(self, xgettext):
            self.xgettext = xgettext

The constructor is called with the instance of the Perl in the variable
`xgettext`.  Note that the Perl object is not initialzed at this point and
you should not call any methods of it.

Your extractor is already almost functional:

    $ ./xgettext-lines.pl --help
    Usage: xgettext-lines.pl [OPTION] [INPUTFILE]...
    ...

It already prints out usage information.  If you see an error message "Can't
locate Locale/XGettext.pm in @INC ..." instead, you haven't installed the
Perl module.  Either install it or tell the sample script to use the
source instead:


    $ perl -I../../lib xgettext-lines.pl --help
    Usage: xgettext-lines.pl [OPTION] [INPUTFILE]...

Not much happens but a directory `_Inline` that contains cached information
from `Inline::Python` was executed.
You can safely delete this directory at any point in time.

Now let's try our extractor with a real input file, for example the one that
you are currently reading:

    $ ./xgettext-lines.pl ../README.md
    Can't locate object method "readFile" via package "Locale::XGettext::Python" at ../../lib/Locale/XGettext.pm line 184.

The method `readFile` gets called for every input file and has to be 
implemented.  Let's add it to `PythonGettext.py`:

    def readFile(self, filename):
        with open(filename) as f:
            lineno = 0
            for line in f:
                lineno = lineno + 1
                reference = "%s:%u" % (str(filename)[2:-1], ++lineno)
                self.xgettext.addEntry({'msgid': line, 'reference': reference})

Now try it again:

    $ ./xgettext-lines.pl ../README.md

This time nothing should happen.  Don't worry, no news is good news.  A file
`messages.po` was created with one PO entry per line.

The other good news is: You're done! At least in many cases, this is already
sufficient and you can now focus on writing a real parser for your source
files.

## Implementation in one single file

Note that this is only implemented in the Python example.  if you want to
do the same for another language, please refer to the Python source
code!

The Perl wrapper script `xgettext-lines.pl` reads the python code from a 
separate file, the Python module `PythonXGettext.py`, so that the two 
languages are separated cleanly.  The script `xgettext-lines.py` shows 
another approach.  It still contains Perl code at the top but the Python
code is added to the bottom.  The overall layout of the script looks like
this:

    #! /usr/bin/env perl
    
    # Boilerplate Perl code.
    # ...
    
    use Inline Python => 'DATA'
    
    # More boilerplate Perl code.
    # ...
    
    __DATA__
    __Python__

    class PythonXGettext:
        def __init__(self, xgettext):
            self.xgettext = xgettext
    
        def readFile(self, filename):
            with open(filename) as f:
                for line in f:
                    self.xgettext.addEntry({'msgid': line});

The line `use Inline Python => 'DATA'` has the effect that Perl, resp.
the Inline module will look for the Python code to compile at the end of
the file, after two lines containing the special markers `__DATA__` and
`__Python__` (or `__Ruby__`, or `__Java__` for other programming
languages).

Instead of `__DATA__` you can also use `__END__`.  It has the same effect
in this particular case.

The script works standalone, without a separate Python module:

    $ ./xgettext-lines.py
    ./xgettext-lines.py: no input file given
    Try './xgettext-lines.py --help' for more information!

If `Locale::XGettext` is not yet installed, you have to specify the path
to the Perl library:

    $ perl -I../../lib xgettext-lines.py
    ./xgettext-lines.py: no input file given
    Try './xgettext-lines.py --help' for more information!

Whether you want to mix Perl and Python in one file, or keep them 
separate - as described above - is a matter of taste and your
individual requirements.

## `addEntry()` Revisited

In the example, the PO entries only contain the message id and
the source reference.  You can set a lot more properties though,
in particular the following:

<dl>
  <dt>msgid_plural</dt>
  <dd>A possible plural form for the entry.</dd>

  <dt>keyword</dt>
  <dd>
    The name of the keyword used, such as "gettext" or "ngettext".
    Users can specify automatic comments for certain keywords
    with the option "--keyword".  You have to tell B<Locale::XGettext>
    which keyword triggered the entry.
  </dd>

  <dt>flags</dt>
  <dd>A comma-separated list of flags to add to the entry,
      for example "perl-brace-format, no-wrap".</dd>
</dl>

See
[http://search.cpan.org/~guido/Locale-XGettext/lib/Locale/XGettext.pm#METHODS](http://search.cpan.org/~guido/Locale-XGettext/lib/Locale/XGettext.pm#METHODS)
or try the command `perldoc Locale::XGettext` for more information.

## Reading Strings From Other Data Sources

Sometimes you want to read strings from another data source that is not
a file.  One option is to simply interpret the command-line arguments not
as filenames but as identifiers for your data sources, for example
URLs, and then change the method `readFile()` to read from that data
source.

Another option is to override the method `extractFromNonFiles`.  This
method is invoked after all input files have been read but before the output
is created:

    def extractFromNonFiles(self):
        # Read, for example from a database.
        for string in database_records:
            self.xgettext.addEntry({'msgid': line})

## Calling Perl Methods

Your Python code can invoke all methods of the Perl object (that is
the property `xgettext` of the Python object):

    self.xgettext.addEntry({'msgid': line})

Adding a new message ID is just one example.  See the documentation in
[http://search.cpan.org/~guido/Locale-XGettext/lib/Locale/XGettext.pm](http://search.cpan.org/~guido/Locale-XGettext/lib/Locale/XGettext.pm).
for the complete interface.

## Extending the CLI

When you run your extractor script with the option `--help` you see a lot
of usage information from `Locale::XGettext`.  The API allows you to modify 
the command line interface of your extractor to a certain degree.

### Describing the Expected Input

If you implement the method `fileInformation()` you can describe the type
of input files you expect.

    def fileInformation(self):
        return "Input files are plain text files and are converted into one PO entry\nfor every non-empty line."

Look at the usage information:

    $ ./xgettext-lines.pl --help
    Usage: ./xgettext-lines.pl [OPTION] [INPUTFILE]...
    
    Extract translatable strings from given input files.  
    
    Input files are plain text files and are converted into one PO entry
    for every non-empty line.

    ...

Your description is now printed after the generic usage information.

### Language-specific Options

In order to add your own command-line options you have to override the method
`languageSpecificOptions`.  See this example:

    def languageSpecificOptions(self):
        return [
                   [
                       'test-binding',
                       'test_binding',
                       '    --test-binding',
                       'print additional information for testing the language binding'
                   ]
        ];

Print the usage description to see the effect:

    $ ./xgettext-lines.pl --help
    ...
    Language specific options:
      -a, --extract-all           extract all strings
      -kWORD, --keyword=WORD      look for WORD as an additional keyword
      -k, --keyword               do not to use default keywords"));
          --flag=WORD:ARG:FLAG    additional flag for strings inside the argument
                                  number ARG of keyword WORD
          --test-binding          print additional information for testing the
                                    language binding
    ...

Your new option `--test-binding` is printed after generic options.

Custom ptions are defined as an array of arrays.  Each
definition has four elements:

The first element (`'test-binding'`) contains the option specification.
The default are binary options that do not take arguments.  For a string
argument you would use `'test-binding=s'`, for an integer argument
`'test-binding=i'`.  For a complete description please see
[http://search.cpan.org/~jv/Getopt-Long/lib/Getopt/Long.pm](http://search.cpan.org/~jv/Getopt-Long/lib/Getopt/Long.pm).

The next element (`'test_binding'`) is the name of the option.  It is the
identifier that you have to use in order to access the value of the option.
See below for details.

The third element (`'    --test-binding'`) contains the left part of the
usage description.  You can use leading spaces for aligning the string with
the rest of the usage description.

The last element contains the description of the option in the usage
description.

### Accessing Command-Line Options

You access command line options with the method `option()`:

    self.xgettext.option('test_binding')

The argument to the method is the name (the second element) from the
option definition.

You can access the values of all other options as well.  The option name
is always the bare option description with hyphens converted to
underscores:

    self.xgettext.option('extract_all')

The above would extract the value of the option `'--extract-all'`.

### Accessing Keywords And Flags

Keywords and Flags are always a mixture between default settings
and those specified on the command-line with `--keyword` or
`--flag`.  There are two flavors of retrieving the merged
definitions:

    keywords = self.xgettext.keywords()

This will a list of objects resp. hashes/associative arrays,
each one having the following keys:

* function: the function name (the keyword)
* singular: the argument number of the singular form
* plural: the argument number of the plural form or 0
* context: the argument number of the message context or 0
* comment: an automatic comment or None, undefined, nil, NULL, ...

See the example source code for details how to retrieve that.

Alternatively, you can also just get an array of corresponding
object strings and parse them yourself:

    keywords = self.xgettext.keywordOptionStrings()

This would produce something like:

    [
        "gettext:1",
        "ngettext:1,2",
        "ncgettext:1c,2,3",
        "greet:1,\"Hello, world!\""
    ]

Accessing flags is almost the same.  The objects returned by
the method "flags()" have the properties "function", "arg"
(for the argument number), "flag" for the flag ("c-format",
"perl-format", ...), "no" (true for "no-c-format", "no-perl-format"),
and "pass" (for "pass-c-format", "pass-perl-format"). 
Alternatively, you have the method "flagOptionStrings()" if you
want to parse the values yourself.

Under normal circumstances, you don't have to access flags.
Just pass the "keyword" property with "addEntry()" and
`Locale::XGettext` will process the flags automatically.

### More Modifications To the CLI

By overriding certain methods you can enable or disable more options in
your extractor:

    def canExtractAll(self):
        return 1

If `canExtractAll()` returns a truthy value, the option `--extract-all`
is offered to the user.  The default is `false`.

    def canKeywords(self):
        return 1

If `canKeywords` returns a truthy value, options for keyword specification
(see below) are added to the interface.  The default is `true`.

    def canFlags(self):
        return 1

If `canFlags` returns a truthy value, options for flag specification
are added to the interface.  The default is `true`.

Note: `Locale::XGettext` does not yet support flags.

## Keyword Specification

If your extractor does not honor keyword specifications, you should override
the method `canKeywords()` and return `false`.  If it does, you can
define the default keywords for your language like this:

    def defaultKeywords(self):
        return [
                   'gettext:1', 
                   'ngettext:1,2',
                   'pgettext:1c,2',
                   'npgettext:1c,2,3' 
        ]

The return value of `defaultKeywords()` should be an array
of strings suitable as arguments for the command-line option
"--keyword". In the above example, the extractor
should extract the first argument to the function `npgettext()` and
interpret it as the message context (hence the `c` after the position),
arguments 2 and 3 should be interpreted as the singular and plural form
of the message.
