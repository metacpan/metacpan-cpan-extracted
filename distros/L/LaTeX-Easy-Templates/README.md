# NAME

LaTeX::Easy::Templates - Easily format content into PDF/PS/DVI with LaTeX templates.

# VERSION

Version 0.02

# SYNOPSIS

This module provides functionality to format
text content, living in a Perl data structure,
into printer-ready documents (PDF/Postscript/DVI).
It utilises the idea of Templates and employs the
powerful LaTeX (via [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver)) in order
to format and render the final documents into
printer feed.

Its use requires
that LaTeX is already installed in your system.
Don't be alarmed! LaTeX is simple to install in any OS.
Download the installer from here: [https://www.tug.org/texlive/](https://www.tug.org/texlive/)
or, if you have Linux, add it via your package manager.
Using LaTeX will not only empower you like
Guttenberg's press did and does, but it
will also satisfy even the highest aesthetic
standards with its 20/20 perfect typography.
LaTeX is one of the rare
cases where Software can be termed as Hardware.
Install it and use it. Now.

Here is a basic scenario borrowed from Dilbert's adventures.
You have a number of emails with fields like `sender`,
`recipient`, `subject` and `content`. This data
can be represented in Perl as an array of hashes like:

    [
      {
        sender => 'jack',
        recipient => 'the clown',
        subject => 'hello',
        content => 'blah blah',
      },
      {
        sender => 'dede',
        recipient => 'kinski',
        subject => 'Paris rooftops',
        content => 'blah2 blah2',
      },
      ...
    ]

You want to render this data to PDF.

A more interesting scenario:

You are scraping a, say, News website. You want each article
rendered as PDF. Your scraper provides the following data
for each News article, and you have lots of those:

    [
      {
        author => 'jack',
        title => '123',
        date => '12/12/2012',
        content => [
           'paragraph1',
           'paragraph2',
           ...
        ],
        comments => [
          {
            'author' => 'sappho',
            'content' => 'yearning ...',
         },
         ... # more comments
      }
      ... # more News articles
    ]

Once you collect your data and save it
into a Perl data structure as above (note:
the stress is on **structure**) you need to
create a templated LaTeX document which
will be complete except that where
the `author`, `sender`, `recipient`, `content`,
etc. would be, you will place some tags like:

    <: $author :>
    <: $sender :>

etc.

The [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates) module
will then take your data and your LaTeX template
and produce the final rendered documents.

In section ["STARTING WITH LaTeX"](#starting-with-latex) you will see how to easily build a LaTeX template
from open source, publicly available, superbly styled "_themes_".

    use LaTeX::Easy::Templates;

    # templated LaTeX document in-memory
    # (with variables to be substituted)
    my $latex_template =<<'EOLA';
    % basic LaTeX document
    \documentclass[a4,12pt]{article}
    \begin{document}
    \title{ <: $data.title :> }
    \author{ <: $data.author.name :> <: $data.author.surname :> }
    \date{ <: $data.date :> }
    \maketitle
    <: $data.content :>
    \end{document}
    EOLA

    # my template variable substitutions
    my $template_data = {
      'title' => 'a test title',
      'author' => {
        'name' => 'myname',
        'surname' => 'surname',
      },
      'date' => '2024/12/12',
      'content' => 'blah blah',
    };

    my $latte = LaTeX::Easy::Templates->new({
      debug => {verbosity=>2, cleanup=>1},
      'processors' => {
        'mytemplate' => {
          'template' => {
            'content' => $latex_template_string,
          },
          'output' => {
            'filepath' => 'output.pdf'
          }
        }
      }
    });
    die unless $latte;

    my $ret = $latter->format({
      'template-data' => $template_data,
      'outfile' => 'xyz.pdf',
      # this is the in-memory LaTeX template
      'processor' => 'mytemplate'
    });
    die unless $ret;

In this way you can nicely and easily typesed your data
into a PDF.

# METHODS

## `new()`

The constructor.

The full list of arguments, provided as a hashref, is as follows:

- **processors** : required parameter as a hash(ref) specifying one or more
_processors_ which are responsible for rendering the final typeset document
from either a template or a LaTeX source file. The processor name is a key to the
specified hash and should contain these items:
    - **template** : a hash(ref) containing information about the input LaTeX template.
    This information must be specified if no LaTeX source file is specified (see **latex** section below).
    Basically you need to specify the location of the LaTeX template file or
    a string with the contents of this template (as an in-memory template).

        Note that **basedir** and **filename** are explictly specified (instead of **filepath**)
        then **\*\*ALL CONTENTS\*\*** of **basedir**
        will be **copied recursively** to the output dir assuming that there are other files there
        (for example images, LaTeX style files etc.) which are needed during
        processing the template or running latex. If you do not want this file copying then
        just specify **filepath**.

        If there are other files or directories you will need during processing the
        template or running latex then you can specify them as an array(ref)
        in **auxfiles**. These will be **copied recursively** to the output dir.

        - **filepath** : specify the full path to the template file, or,
        - **filename** and **basedir** : specify a filename (not a file path) and the
        directory it resides. Note that if you specify these two,
        then **\*\*ALL CONTENTS\*\*** of **basedir**
        will be **copied recursively** to the output dir assuming that there are other files there
        (for example images, LaTeX style files etc.) which are needed during
        processing the template or running latex.
        - **content** : specify a string with the template contents. If this
        template calls other templates (from disk) then you should specify **basedir**
        to point to the path which holds these extra files. In this
        case **basedir** can be an array(ref) with more than one paths or just
        a scalar with a single path.
        - **auxfiles** : specify a set of files or directories, as an array(ref), to
        be **copied recursively** to the output dir. These files may be needed for processing the template
        or for running latex (for example, style files, images, other template files, etc.).
        However, copying directories recursively can be pretty heavy. So, there is an
        upper limit on the total file size of each of the paths specified. This can be
        set during runtime with

                $self->max_size_for_filecopy(1024*1024);
                # or set it to negative for skipping all file size checks
                $self->max_size_for_filecopy(-1);

    - **output** : specifies the file path to the output typesed document:
        - **filepath** : specify the full path to the output file, or,
        - **filename** and **basedir** : specify a filename (not a file path) and the
        directory it should reside.

            Note that the path will be created if it does not exist.
    - **latex** : a hash(ref) containing information about the LaTeX source
    which will either be created from a LaTeX template (see **template** above)
    and some data for the template variables (more on this later) or be provided
    (the LaTeX source file) by the caller without any template.
        - **filepath** : specify the full path to the LaTeX source file which
        will be created from the template if the **template** parameter was specified,
        or be used directly if no template was specified. In the former case, the
        file may or may not exist on disk and will be created. In the latter case,
        it must exist on disk.
        - **filename** and **basedir** : specify a filename (not a file path)
        and the directory it resides. Again, the LaTeX source file needs to exist
        if no **template** parameter was specified.
        - **latex-driver-parameters** : parameters in a hash(ref) to be passed on
        to the LaTeX driver ([LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver))
        which does the actual rendering of the LaTeX source file into the typeset
        printer-ready document. Refer to the [documentation](https://metacpan.org/pod/LaTeX%3A%3ADriver%23new%28%25params%29)
        of [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver)'s constructor for the description of each of the parameters.

            Note that **only the following** parameters will be passed on:

            - **format** : specify the output format (e.g. **pdf**, **ps**, etc.)
            of the rendered document and, optionally, the LaTeX "flavour" to be used,
            e.g. `xelatex`, `pdflatex`, `latex`, etc. The default value is `pdf(pdflatex)`.
            - **paths** : specifies a mapping of program names to full pathname as a hash reference.
            These paths override the paths determined at installation time (of [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver)).
            - **maxruns** : The maximum number of runs of the formatter program (defaults to 10 in [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver))
            - **extraruns** : The number of additional runs of the formatter program after the document has stabilized.
            - **timeout** : Specifies a timeout in seconds within which any commands spawned should finish. Even for very long
            documents LaTeX is extremely fast, so this can be well under a minute.
            - **indexstyle** : The name of a makeindex index style file that should be passed to makeindex.
            - **indexoptions** : Specifies additional options that should be passed to makeindex. Useful options are: -c to compress intermediate blanks in index keys, -l to specify letter ordering rather than word ordering, -r to disable implicit range formation. Refer to LaTeX's makeindex(1) for full details.
            - **DEBUG** : Enables debug statements if set to a non-zero value. The value will be the same as our verbosity level.
            - **DEBUGPREFIX** : Sets the debug prefix, which is prepended to debug output if debug statements. By default there is no prefix.

            Note that the descriptions of the parameters (above) to be passed on to [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver) are taken more-or-less verbatim from
            its documentation page, refer to the original document in case there are changes.
    - **latex** : specify default parameters for **processors**' **latex** data
    in case it is absent:
        - **filename** : default LaTeX source filename (not a filepath).
        - **latex-driver-parameters** : default parameters to be passed on to
        [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver)'s constructor. See above for what it includes.
    - **debug** :
        - **verbosity** : script's verbosity. A value of zero mutes the script.
        A higher integer increases the verbosity.
        - **cleanup** : a non-zero value will clean up all temporary files and directories
        including those created by [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver). This is the default. For debugging purpose,
        set this to zero so that you can inspect all intermediate files created.
    - **tempdir** : specify where the temporary files will be placed. This location
    will be created if it does not exist. Default is to use a temporary location as
    given by the OS.
    - **logfile** : specify a file to redirect the logger's output to. Default
    is to log messages to the console (STDOUT, STDERR).
    - **logger\_object** : supply a [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog) object to use as the logger.
    In fact any object implementing `error()`, `warn()` and `info()` like
    [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog) does will be accepted.

The constructor returns `undef` on failure.

Here is example code for calling the constructor:

     use LaTeX::Easy::Template;
     my $latter = LaTeX::Easy::Template->new({
      'processors' => {
        'in-memory' => {
           'latex' => {
                'filename' => undef # create tmp
           },
           'template' => {
                # the template is in-memory string
                'content' => '...'
           },
           'output' => {
                'filename' => 'out.pdf'
           }
        }
        'on-disk' => {
          'latex' => {
                'filename' => undef, # create tmp
           },
           'template' => {
                'filepath' => 't/templates/simple01/main.tex.tx'
           },
           'output' => {
                'filename' => 'out2.pdf'
           }
        }
      }, # end processors
      # log to this file, path will be created if not exists
      'logfile' => 'xyz/abc.log',
      'latex' => {
        'latex-driver-parameters' => {
           # we want PDF output run with xelatex which
           # easily supports multi-language documents
           'format' => 'pdf(xelatex)',
           'paths' => {
              # the path to the xelatex needed only if not standard
              'xelatex' => '/non-standard-path/xyz/xelatex'
           }
        }
      },
      'verbosity' => 1,
      'cleanup' => 0,
    });

The above creates a [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates) object which has 2 "processors"
one which uses a LaTeX template from disk and one in-memory.
Default [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver) parameters are specified as well
and will be used for these processors which do not specify any.

## `untemplate()`

It creates a LaTeX source file from a template.
This is the first step in rendering the final typeset document.
which is done by ["format()"](#format).

Note that calling this method is not necessary
if you intend to call ["format()"](#format) next.
The latter will call the former if needed.

The full list of arguments is as follows:

- **processor** : specify the name of the "processor" to use.
The "processor" must be a key to the **processors** parameter
passed to the constructor.
- **template-data** : specify the data for the template's variables
as a hash or array ref, depending on the structure of the template in use.
This data is passed on to the template using the key `data`.
So if your template data is this:

        {
          name => 'aa',
        }

    Then your template will access `name`'s value via ` <: $data.name :` >

    See ["TEMPLATE PROCESSING"](#template-processing) for more on the syntax of the template files.

- **latex**, **template** : optionally, overwrite "processor"'s
**latex**, **template** fields by specifying any of these fields here
in exactly the same format as that of the **processors** parameter
passed to the constructor (["new()"](#new)).

### RETURN

On failure, ["untemplate()"](#untemplate) returns back `undef`.

On success, it returns back a hash(ref) with two entries:

- **latex** : contains **fileapth**, **filename** and **basedir**
of the produced LaTeX source file.
- **template** : it contains **fileapth**, **filename**, **basedir**
and **content**. The last one will be undefined if
the template used if the template was a file read from disk.
The first three will be undefined otherwise.

## `format()`

It renders the final typeset document.
It will call ["untemplate()"](#untemplate) if is
required to produce the intermediate LaTeX
source file. If that file was specified,
then it will render the final document
by calling [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver).

The full list of arguments, provided by a hashref, is as follows:

- **processor** : specify the name of the "processor" to use.
The "processor" must be a key to the **processors** parameter
passed to the constructor.
- **template-data** : specify the data for the template's variables
as a hash or array ref, depending on the structure of the template in use.
This data is only needed if the intermediate LaTeX source file needs to
be produced.
- **latex**, **template**, **output** : optionally, overwrite "processor"'s
**latex**, **template**, **output** fields by specifying any of these fields here
in exactly the same format as that of the **processors** parameter
passed to the constructor (["new()"](#new)).

### RETURN

On failure, ["format()"](#format) returns back `undef`.

On success, it returns back a hash(ref) with three entries:

- **latex** : contains **fileapth**, **filename** and **basedir**
of the produced LaTeX source file.
- **template** : it contains **fileapth**, **filename**, **basedir**
and **content**. The last one will be undefined if
the template used if the template was a file read from disk.
The first three will be undefined otherwise.
- **output** : it contains **fileapth**, **filename** and **basedir**
pointing to the output typeset document it created.

## `max_size_for_filecopy($maxsize)`

It gets or sets (with optional parameter `$maxsize`) the maximum size for doing a
recursive file copy. Recursive file copies are done for template extra files
which may be needed for processing the template or running latex. They are
specified if **template->basedir** is explicitly set (then the whole **basedir** will be copied)
or when **template->auxfiles** are specified as an arrayref of files/dirs to copy individually.
In order to reduce the risk
of unintentionally copying vast files and directories there is a limit
to the total (recursively calculated)
size of files/directories to be copied. This can be set here.
The default is 3MB. However if you set this limit to a negative integer
no checks will be make and file copying will be done unreservedly.

## `verbosity($verbosity)`

It gets or sets (with optional parameter `$verbosity`) the verbosity level.

## `cleanup($c)`

It gets or sets (with optional parameter `$c`) the **cleanup** parameter
which contols the cleaning up of temporary
files and directories or not. Set it to 1 to clean up. This is currently
the default. Set it to 0 to keep these files for inspection during debugging.

## `templater($t)`

It gets or sets (with optional parameter `$t`) the templater
object. This is the object which convertes the LaTeX template
into LaTeX source. Currently only [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate)
is supported.

## `templater_reset()`

Reset the templater object which means to forget all the templates
it knows and had possibly loaded in memory. After a reset all
"processors" will be forgotten as well.

## `templater_parameters($m, $n)`

It gets or sets (with optional parameter `$m` and possiblt `$n`) the
parameters to be passed to the templater's
([Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate)) constructor:

- If no parameter is specified then it returns all the parameters as a hash(ref).
- If the first parameter is a hash, then its copies all its entries possibly
overwriting existing values.
- If the first parameter is a scalar and the second is omitted then it returns
the value for this parameter if it exists.
- If the first parameter is a scalar and the second is a scalar then it sets
the value for this parameter to the second parameter.

These are some common templater paramaters:

- **syntax** : specify the template syntax to be either `Kolon` or `TTerse`. Default is `Kolon`.
- **suffix** : specify the template files suffix. Default is `.tx` (do not forget the dot).
- **verbose** : set the verbosity. Default is current verbosity.

See [Text::Xslate#Text::Xslate-%3Enew(%options)](https://metacpan.org/pod/Text%3A%3AXslate%23Text%3A%3AXslate-%253Enew%28%25options%29) for more.

## `log($l)`

It gets or sets (with optional parameter `$l`) the logger
object. Currently the logger is of type [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog).

## `latex_driver_executable($program_name)`

This is an exported sub (and not a method)

It enquires [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver) for what is the fullpath to the
program named `$program_name`. The program can be `latex`, `dvips`,
`makeindex`, `pdflatex` etc. If the program is not found it returns `undef`.

The parameter is optional, if it is omitted a hash(ref) with all known
paths is returned.

Note that [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver)'s paths are detected during its installation.
Paths can be set during running ["format()"](#format) by passing it
**latex->latex-driver-parameters->paths** (a hashref mapping program names
to their paths).

## `processors()`

It returns the hash(ref) of known "processors" as they were
set up during construction.

## `loaded_info()`

It returns the hash(ref) of extra information relating to the "processors".

# STARTING WITH LaTeX

Currently, the best place to get started with LaTeX is at
the site [https://www.overleaf.com/](https://www.overleaf.com/) (which I am not affiliated in any way).
There is no subscription involved or any registration required.

Click on [Templates](https://www.overleaf.com/latex/templates) and search for anything
you are interested to typeset your data with. For example, if you are scraping a news
website you may be interested in the
[Committee Times](https://www.overleaf.com/latex/templates/newspaper-slash-news-letter-template/wjxxhkxdjxhw) template.
First check its license and if you agree with that, click on **View Source**, copy the contents and paste
them into your new LaTeX file, let's call that `main.tex` located in a new directory `templates/committee-times`.

Firstly, run latex on it to with `latex main.tex` to see if there are any required files
you need to install. For example it requires package `newspaper`. These packages are
located at the [Comprehensive TeX Archive Network (CTAN) ](https://metacpan.org/pod/%20https%3A#ctan.org). Search the package,
download it, locate and change to your LaTeX installation directory (for example `/usr/share/texlive/texmf-dist`),
change to `tex`. Decide which flavour of LaTeX this package is for, e.g. `latex` or `xelatex`,
change to that directory and unzip the downloaded file there. This is the hard way.
The easy way is via your package manager. For example on Fedora with `dnf`
there is this package `texlive-newspaper.noarch`. Easy. Running latex will tell you
if it requires more packages to be installed.

Now study that LaTeX source file and identify what template variables
and control structures to use in order to turn it into a template.
Rename the file to `main.tex.tx` and you are ready.

Naturally, there will be a lot of head banging and hair pulling before you
manage to produce anything decent.

# LaTeX TEMPLATES

Creating a LaTeX template is very easy. You need to start with
a LaTeX document and identify those sections which can be
replaced by the template variables. You can also identify
repeated sections and replace them with loops.
It is exactly the same procedure as with creating HTML templates
or email messages templates.

# TEMPLATE PROCESSING

The LaTeX templates will be processed with [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) and must
follow its rules. It understands two template syntaxes:

- it's own [Text::Xslate::Syntax::Kolon](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3AKolon)
- and a subset of Template Toolkit 2 [Text::Xslate::Syntax::TTerse](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3ATTerse)

The default syntax is [Text::Xslate::Syntax::Kolon](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3AKolon). This can be changed
via the parameters to the constructor of [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates) by
specifying

    'templater-parameters' => {
        'syntax' => 'Kolon' #or 'TTerse'
    }

or setting it before running ["untemplate()"](#untemplate) with

    $latte->templater_parameters('syntax' => 'Kolon');

The data for the template variables comes bundled into a hashref
which comes bundled into a hashref of a single key `data`. Therefore
all references must be preceded by key `data.`

So if your template data is this:

    {
      name => 'aa',
    }

Then your template will access `name`'s value via ` <: $data.name :` >.

[Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) supports loops and conditional statements etc. etc. Read
[Text::Xslate::Syntax::Kolon](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3AKolon) and/or [Text::Xslate::Syntax::TTerse](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3ATTerse).

# AUTHOR

Andreas Hadjiprocopis, `<bliako at cpan.org>`

# HUGS

!Almaz!

# BUGS

Please report any bugs or feature requests to `bug-latex-easy-templates at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-Easy-Templates](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-Easy-Templates).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::Easy::Templates

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=LaTeX-Easy-Templates](https://rt.cpan.org/NoAuth/Bugs.html?Dist=LaTeX-Easy-Templates)

- Review this module at PerlMonks

    [https://www.perlmonks.org/?node\_id=21144](https://www.perlmonks.org/?node_id=21144)

- Search CPAN

    [https://metacpan.org/release/LaTeX-Easy-Templates](https://metacpan.org/release/LaTeX-Easy-Templates)

# ACKNOWLEDGEMENTS

- LaTeX - excellent typography, superb aesthetics.

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Andreas Hadjiprocopis.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
