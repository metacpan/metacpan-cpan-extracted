# NAME

LaTeX::Easy::Templates - Easily format content into PDF/PS/DVI with LaTeX templates.

# VERSION

Version 1.01

# SYNOPSIS

This module provides functionality to format
text content from a Perl data structure
into printer-ready documents (PDF/Postscript/DVI).
It utilises the idea of Templates and employs the
powerful LaTeX (via [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver)) in order
to format and render the final documents into
printer feed.

Its use requires
that LaTeX is already installed in your system.
Don't be alarmed! LaTeX is simple to install in any OS,
see section ["INSTALLING LaTeX"](#installing-latex) for how. In Linux
it is provided by the system package manager.

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
        usercomments => [
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

or control like:

    : for $authors -> $author {
    : # call a new template for each author and
    : # append the result here
    :   include "authors-template.tex.tx" {
    :     author => $author
    :   }
    : }

etc.

The [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates) module
will then take your data and your LaTeX template
and produce the final rendered documents.

In section ["STARTING WITH LaTeX"](#starting-with-latex) you will see how to easily build a LaTeX template
from open source, publicly available, superbly styled "_themes_".

The template engine used in this module is [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate), chosen
because of its very good performance when rendering templates.

    use LaTeX::Easy::Templates;

    # templated LaTeX document in-memory
    # (with variables to be substituted)
    my $latex_template =<<'EOLA';
    % basic LaTeX document
    \documentclass[a4,12pt]{article}
    \begin{document}
    \title{ <: $data.['title'] :> }
    \author{ <: $data.author.name :> <: $data.author['surname'] :> }
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

    sub myfunc { return "funced ".$_[0] }

    my $latte = LaTeX::Easy::Templates->new({
      debug => {verbosity=>2, cleanup=>1},
      'templater-parameters' => {
        # passing parameters to Text::Xslate's constructor
        # myfunc() will be accessible from each template
        'function' => {
          'myfunc' => \&myfunc,
        },
        'module' => [
          # and so the exports of this module:
          'Data::Roundtrip' => [qw/perl2json json2perl/],
        ],
      },
      'processors' => {
        # if it includes other in-memory templates
        # then just include them here with their name
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
    # check output xyz.pdf !

# EXPORT

- ["latex\_driver\_executable($program\_name)"](#latex_driver_executable-program_name)

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

    - **output** : specifies the file path to the output typeset document:
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
            of the rendered document and, optionally, the LaTeX "_flavour_" or "_processor_" to be used,
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
    In fact any object implementing just these three: `error()`, `warn()` and `info()`, which
    [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog) does, will be accepted.
    - **templater-parameters** : a HASH containing parameters to be
    passed on to the [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) constructor. 

        These are some common templater paramaters:

        - **syntax** : specify the template syntax to be either [Kolon](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3AKolon) or `TTerse|Text::Xslate::Syntax::TTerse`. Default is `Kolon`.
        - **suffix** : specify the template files suffix. Default is `.tx` (do not forget the dot).
        - **verbose** : set the verbosity of [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate).
        Default is the verbosity level currently set in the
        [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates) object.
        - **path** : an array(ref) of paths to be searched for included templates. This is crucial
        when templates are including other templates in different directories.
        - **function**, **module** : specify your own perl functions and modules you want to use
        from within a template. That's very handy in overcoming the limitations of the template syntax.

        See [Text::Xslate#Text::Xslate-%3Enew(%options)](https://metacpan.org/pod/Text%3A%3AXslate%23Text%3A%3AXslate-%253Enew%28%25options%29) for all the supported options.

        - **path** : an array of paths to be searched for on-disk template
        files which are dependencies, i.e. they are included by other templates (in-memory or on-disk).
        This is very important if your main template includes other templates which
        are in different directories.
        - **syntax** : the template syntax. Default is 'Kolon'.
        - **function**, **module** : a hash of user-specified or built-in perl functions (coderefs)
        to be used in the templates. And a list of modules to be included for using these.
        Quite a powerful feature of [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate).
        - **cache**, **cache\_dir** : cache level and location.
        - **line\_start**, **tag\_start**, **line\_end**, **tag\_end** : the token strings denoting
        the start and end of lines and tags.

        For example:

              'templater-parameters' => {
                # dependent templates search paths
                'path' => ['a/b/c', 'x/y/z', ...],
                # user-specified functions to be called
                # from a template
                'function' => {
                  'xyz' => sub { my (@params) = @_; ...; return ... }
                },
                # installed Perl modules can be accessed
                # from a template (caveat: complains for fully
                # qualified sub names '::')
                'module' => [
                  'Data::Roundtrip' => [qw/perl2json json2perl/],
                ],
                ...
              },

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

On failure, ["untemplate()"](#untemplate) returns `undef`.

On success, it returns a hash(ref) with two entries:

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

On failure, ["format()"](#format) returns `undef`.

On success, it returns a hash(ref) with three entries:

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

## `log($l)`

It gets or sets (with optional parameter `$l`) the logger
object. Currently the logger is of type [Mojo::Log](https://metacpan.org/pod/Mojo%3A%3ALog).

## `latex_driver_executable($program_name)`

This is an exported sub (and not a method)

It enquires [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver) for what is the fullpath to the
program named `$program_name`. The program can be `latex`, `dvips`,
`makeindex`, `pdflatex` etc.
If the program is not found or if it is not an executable
(for the current user), it returns `undef`.
If it is found and it is executable (for the current user),
its fullpath is returned.

The parameter `$program_name` is optional,
if it is omitted, it returns a hash(ref) with all known
programs (the keys)
and their full paths (the values).

Note that [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver)'s paths are detected during its installation
(according to its documentation).

Program full paths can be set during running ["format()"](#format) by passing it
the parameter
**latex->latex-driver-parameters->paths**
(a hashref mapping program names to their paths).

## `processors()`

It returns the hash(ref) of known "processors" as they were
set up during construction.

## `loaded_info()`

It returns the hash(ref) of extra information relating to the "processors".

# TEMPLATE PROCESSING

The LaTeX templates will be processed with [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) and must
follow its rules. It understands two template syntaxes:

- it's own [Text::Xslate::Syntax::Kolon](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3AKolon)
- and a subset of Template Toolkit 2 [Text::Xslate::Syntax::TTerse](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3ATTerse)

The default syntax is [Text::Xslate::Syntax::Kolon](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3AKolon). This can be changed
via the parameters to the constructor of [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates) by
specifying this:

    'templater-parameters' => {
        'syntax' => 'Kolon' #or 'TTerse'
    }

The **data** for substituting into the template variables comes bundled into a hashref
which comes bundled into a hashref keyed under the name "`data`". Therefore
all references must be preceded by key `data.`

So if your template data is this:

    {
      name => 'aa',
    }

Then your template will access `name`'s value via ` <: $data.name :` >.

[Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) supports loops and conditional statements.
It also offers a lot of [builtin functions](https://metacpan.org/pod/Text%3A%3AXslate%3A%3AManual%3A%3ABuiltin).
Additionally you can call user-specified perl subs (or subs from other modules)
from within a template.

Read
the documentation for [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate)'s syntax
[Text::Xslate::Syntax::Kolon](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3AKolon) or [Text::Xslate::Syntax::TTerse](https://metacpan.org/pod/Text%3A%3AXslate%3A%3ASyntax%3A%3ATTerse).

# TEMPLATES INCLUDING TEMPLATES

Templates which include other templates are supported.

The included and the includee templates can be a
combination of on-disk files and/or in-memory strings.
Which means in-memory templates can include on-disk and vice-versa.

## In-memory templates

The `processor` parameter to [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates)'s [constructor](#new)
should contain both the main template and all other
included templates keyed on their include name. For example, the
main template is:

     \documentclass[letterpaper,twoside,12pt]{article}
     \begin{document}
     : include "preamble.tex.tx" {data => $data};
     : for [1, 2, 3] -> $i {
       \section{Content for section <: $i :>}
       : include "content.tex.tx" {data => $data};
    : }
    \end{document}

The above _includes_ two other templates:

    :# preamble.tex.tx
    \title{ <: $data.title :> }
    \author{ <: $data.author.name :> <: $data.author.surname :> }
    \date{ <: $data.date :> }

and

    :# content.tex.tx
    <: $data.content :>

In order to load all above templates, construct the [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates)
object like this:

     my $latter = LaTeX::Easy::Template->new({
      'processors' => {
        # the main entry
        'main.tex.tx' => {
           'template' => {
                'content' => '... main.tex.tx contents ...'
           },
           'output' => {
                'filename' => 'out.pdf'
           }
        },
        # it includes these other templates:
        'preamble.tex.tx' => { # one ...
           'template' => {
                'content' => '... preamble.tex.tx contents ...'
           }
        },
        'content.tex.tx' => { # ... and two
           'template' => {
                'content' => '... content.tex.tx contents ...'
           },
        }
      } # end 'processors'

With the above, all in-memory templates required are loaded in memory.
All you need now is to specify "`main.tex.tx`" (which
is the main entry point) as the
`processor` name when
calling ["untemplate()"](#untemplate) or ["format()"](#format). You do not need
to mention the included template names at all:

    my $ret = $latter->format({
      'template-data' => $template_data,
      'output' => {
        'filepath' => ...,
      },
      # just specify the main entry template
      'processor' => 'main.tex.tx',
});

The above functionality is demonstrated and tested in
file `t/460-inmemory-template-usage-calling-other-templates.t`

## On-disk file templates

If both the main template and all templates it includes are in the
same directory then you only need to specify
the `main.tex.tx` template under key `processors`
in the parameters to [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates)'s [constructor](#new).
In this case all dependencies will
be taken care of (thank you [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate)).

Additionally, you can specify a list of directories as
paths to be searched for dependent templates. These _include paths_
can be passed on as parameters to [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates)'s
[constructor](#new), under 

     ...
     'templater-parameters' => {
       'path' => ['a/b/c', 'x/y/z', ...]
     },
     ...

     my $latter = LaTeX::Easy::Template->new({
       'templater-parameters' => {
         'path' => ['a/b/c', 'x/y/z', ...],
         ...
       },
       'processors' => {
        # the main entry
         'main.tex.tx' => {
           'template' => {
             'filepath' => '/x/y/z/main.tex.tx'
             # works also with specifying
             #   'filename' & 'basedir'  
           },
           'output' => {
                'filename' => 'out.pdf'
           }
         },
         # the dependent templates are not needed
         # to be included if in same dir
         # include them ONLY if in different dir
       } # end 'processors'
     }); # end constructor

With the above, the "`main.tex.tx`" template,
which is the main entry point, is loaded.
As long as its dependencies, i.e. the templates
it includes, are in the same directory
or are specified with their full path,
then there is nothing else you need to include.
The dependencies will be found and included as needed.

All you need now is to specify "`main.tex.tx`" as the
`processor` name when
calling ["untemplate()"](#untemplate) or ["format()"](#format). You do not need
to mention the included template names at all. Like this:

    my $ret = $latter->format({
      'template-data' => $template_data,
      'output' => {
        'filepath' => '/x/y/z/out.pdf',
      },
      # just specify the main entry template
      # dependencies will be included as needed:
      'processor' => 'main.tex.tx',
});

The above functionality is demonstrated and tested in
file `t/360-ondisk-template-usage-calling-other-templates.t`

## Mixed use of in-memory and on-disk templates

One can have a project of mixed, in-memory and on-disk, templates
one including the other in any combination. This is
straightforward, just follow the above guidelines.

Mixed templates functionality is demonstrated and tested in
file `t/500-mix-template-usage-calling-other-mix-templates.t`.

# EXAMPLE: PRINTING STICKY LABELS

We will use the LaTeX package [labels](https://ctan.org/pkg/labels?lang=en)
(documented [here](https://mirrors.ctan.org/macros/latex/contrib/labels/labels.pdf))
to prepare sticky labels for addressing envelopes etc. By the way, there
is also the [ticket](https://ctan.org/pkg/ticket?lang=en) LaTeX package
available over at CTAN (documented [here](http://mirrors.ctan.org/macros/latex/contrib/ticket/doc/manual.pdf))
which can be of similar use, printing tickets.

We will create two template files. One called `labels.tex.tx` as the
main entry point. And one called `label.tex.tx` to be called by the
first one in a loop over each label item in the input data.

Here they are:

    % I am ./templates/labels/labels.tex.tx
    \documentclass[12pt]{letter}
    \usepackage{graphicx}
    \usepackage{labels}
    \begin{document}
    : for $data -> $label {
    :   include 'label.tex.tx' { label => $label };
    : }
    \end{document}

and

    % I am ./templates/labels/label.tex.tx
    \genericlabel{
      \begin{tabular}{|c|}
        \hline
    : if $label.sender.logo {
        \includegraphics[width=1cm,angle=0]{<: $label.sender.logo :>}\\
    : }
        \hline
        <: $label.recipient.fullname :>\\
        \hline
    : for $label.recipient.addresslines -> $addressline {
        <: $addressline :>
    : }
        \\
        <: $label.recipient.postcode :>\\
        \hline
      \end{tabular}
    }

Save them on disk in the suggested directory structure.
Or, if you decide to change it, make sure you adjust
the paths in the script below.

Optionally, save a logo image to
["templates/images/logo.png" in .](https://metacpan.org/pod/.#templates-images-logo.png). If that exists then
the template will pick it up.

And here is the Perl script to harness the beast:

    use LaTeX::Easy::Templates;
    use FindBin;

    my $curdir = $FindBin::Bin;

    # the templates can be placed anywhere as long these
    # paths are adjusted. As it is now, they
    # must both be placed in ./templates/labels
    # the main entry is ./templates/labels/labels.tex.tx
    # which calls/includes ./templates/labels/label.tex.tx
    my $template_filename = File::Spec->catfile($curdir, 'templates', 'labels', 'labels.tex.tx');
    # optionally specify a logo image
    my $logo_filename = File::Spec->catfile($curdir, 'templates', 'images', 'logo.png');
    if( ! -e $logo_filename ){ $logo_filename = undef }

    my $output_filename = 'labels.pdf';

    # see LaTeX::Driver's doc for other formats, e.g. pdf(xelatex)
    my $latex_driver_and_format = 'pdf(pdflatex)';

    # debug settings:
    my $verbosity = 1;
    # keep intermediate latex file for inspection
    my $cleanup = 1;

    my $sender = {
      fullname => 'Gigi Comp',
      addresslines => [
        'Apt 5',
        '25, Jen Way',
        'Balac'
      ],
      postcode => '1An34',
      # this assumes that ./templates/images/logo.png exists, else comment it out:  
      logo => $logo_filename,
    };
    my @labels_data = map {
      {
        recipient => {
          fullname => "Teli Bingo ($_)",
          addresslines => [
            'Apt 5',
            '25, Jen Way',
            'Balac'
          ],
          postcode => '1An34',
        },
        sender => $sender,
      }
    } (1..42); # create many labels yummy

    my $latter = LaTeX::Easy::Templates->new({
      'debug' => {
        'verbosity' => $verbosity,
        'cleanup' => $cleanup
      },
      'processors' => {
        'custom-labels' => {
        'template' => {
          'filepath' => $template_filename,
        },
        'latex' => {
          'filepath' => 'xyz.tex',
          'latex-driver-parameters' => {
            'format' => $latex_driver_and_format,
          }
        }
        },
      }
    });
    die "failed to instantiate 'LaTeX::Easy::Templates'" unless defined $latter;

    my $ret = $latter->format({
      'template-data' => \@labels_data,
      'output' => {
        'filepath' => $output_filename,
      },
      'processor' => 'custom-labels',
    });
    die "failed to format the document, most likely latex command has failed." unless defined $ret;
    print "$0 : done, output in '$output_filename'.\n";

This is the result in very low resolution:

# EXAMPLE: NESTED PERL DATA STRUCTURES TO PDF

Thanks to the amazing work put in [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate)
one can have access to user-defined Perl functions,
Perl modules and macros from inside a template file.

This allows recusrsion which makes possible walking and
printing a nested Perl data structure with this
simple template:

    %templates/nested-data-structures/nested-data-structures.tex.tx
    \documentclass[12pt]{article}
    \begin{document}

    : macro walk -> $d {
    :   if( ref($d) == 'ARRAY' ){
    $\lbrack$
    :     for $d -> $item {
    :       walk($item);
    :     }
    $\rbrack,$
    :   } elsif( ref($d) == 'HASH' ){
    $\{$
    :     for $d.kv() -> $pair {
            <: $pair.key() :> $=>$
    :       walk($pair.value())
    :     }
    $\},$
    :   } elsif( ref($d) == '' ){
          <: $d :>,
    :   } else {
          beginUNKNOWN <: $d :> endUNKNOWN
    :   }
    : } # macro

    <: walk($data) :>

    \end{document}

First we create a macro which walks the input data structure
and recurses into it until a scalar is found.

The function `ref()` is Perl's builtin but it is not available
from inside an [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) template. So, we create our own
function for doing this and pass it on to the [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate)'s
constructor, as was demonstrated previously with the
`templater-parameters` hash pass to [LaTeX::Easy::Templates](https://metacpan.org/pod/LaTeX%3A%3AEasy%3A%3ATemplates)'s
[constructor](https://metacpan.org/pod/%3Cnew%28%29).

Here is a Perl script to render any data structure into PDF:

    use strict;
    use warnings;

    use LaTeX::Easy::Templates;
    use FindBin;

    my $curdir = $FindBin::Bin;

    # the templates must be placed in ./templates/nested-data-structures
    my $template_filename = File::Spec->catfile($curdir, 'templates', 'nested-data-structures', 'nested-data-structures.tex.tx');

    my $output_filename = 'nested-data-structures.pdf';

    # see LaTeX::Driver's doc for other formats, e.g. pdf(xelatex)
    my $latex_driver_and_format = 'pdf(pdflatex)';

    my $nested_data_structure = {'a' => [1,2,3], 'b' => {'c' => [4,5,6, {'z'=>1}]}};

    # debug settings:
    my $verbosity = 1;
    # keep intermediate latex file for inspection
    my $cleanup = 1;

    my $latter = LaTeX::Easy::Templates->new({
      'debug' => {
        'verbosity' => $verbosity,
        'cleanup' => $cleanup
      },
      'templater-parameters' => {
        'function' => {'ref' => sub { return ref($_[0]) } }
      },
      'processors' => {
        'nested-data-structures' => {
          'template' => {
            'filepath' => $template_filename,
          },
          'latex' => {
            'filepath' => 'xyz.tex',
            'latex-driver-parameters' => {
              'format' => $latex_driver_and_format,
            }
          },
        }
      }
    });
    die "failed to instantiate 'LaTeX::Easy::Templates'" unless defined $latter;

    my $ret = $latter->format({
      'template-data' => $nested_data_structure,
      'output' => {
        'filepath' => $output_filename,
      },
      'processor' => 'nested-data-structures',
    });
    die "failed to format the document, most likely latex command has failed." unless defined $ret;
    print "$0 : done, output in '$output_filename'.\n";

And here is the result:

Thank you LaTeX, thank you Xslate.

# STARTING WITH LaTeX

Currently, the best place to get started with LaTeX is at
the site [https://www.overleaf.com/](https://www.overleaf.com/) (which I am not affiliated in any way).
There is no subscription involved or any registration required.

Click on [Templates](https://www.overleaf.com/latex/templates)
and search the presented PDFs of example typeset documents
for a look you fancy. For example, if you are scraping a news
website you may be interested in the
[Committee Times](https://www.overleaf.com/latex/templates/newspaper-slash-news-letter-template/wjxxhkxdjxhw) template.
First check its license and if you agree with that, click on **View Source**, copy the contents and paste
them into your new LaTeX file, let's call that `main.tex` located in a new directory `templates/committee-times`.

Firstly, run latex on it  with this command `latex main.tex`.
It will fail if it can not find, in your LaTeX installation,
the packages it requires.
For example it requires package `newspaper`.
If it complains that certain packages are not found,
please read section ["INSTALLING LaTeX PACKAGES"](#installing-latex-packages).

Now study that LaTeX source file and identify what template variables
and control structures to use in order to turn it into a template.
Rename the file to `main.tex.tx` and you are ready.

Naturally, there will be a lot of head banging and hair pulling before you
manage to produce results.

# LaTeX TEMPLATES

Creating a LaTeX template is very easy. You need to start with
a usual LaTeX document and identify those sections which can be
replaced by the template variables. You can also identify
repeated sections and replace them with loops.
It is exactly the same procedure as with creating HTML templates
or email messages templates.

At this moment, the template processor is [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate).
Therefore the syntax for declaring template variables, loops,
conditionals, etc. must comply with what [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate)
expects. See
section ["TEMPLATE PROCESSING"](#template-processing) for where to start
with [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate).

A LaTeX template can live in memory as a Perl string
or on disk, as a file in its own directory or not.

If your template dependes on other templates you
can include all as files in the same directory.

If your template depends on your own
LaTeX style files, packages etc., then
include those in the same directory with
the LaTeX templates. Additionally, when specifying the location
of the template, specify `basedir` and `filename`
(instead of a single `filepath`). This will
ensure that all file dependencies contained within
`basedir` will be copied to the temporary processing
directories. See ["new()"](#new) for how this works.

# INSTALLING LaTeX

Today, as far as I know,
there are two main TeX/LaTeX distributions:
[MikTeX](https://miktex.org/)
and
[TexLive](https://www.tug.org/texlive/)

Both provide the same LaTeX. They
just package different things with it.
And both provide package managers in order
to make installing extra packages easy.

I believe [MikTeX](https://miktex.org/)
was, at some time, aimed for M$ systems and
[TexLive](https://www.tug.org/texlive/)
for the proper operating systems.

My Linux package manager installs
[TexLive](https://www.tug.org/texlive/)
and I am absolutely happy with it.

# INSTALLING LaTeX PACKAGES

In Linux, it is preferred to install
LaTeX packages
via the system package manager.

With modern TeX distributions installing
LaTeX packages is quite simple. Both
[MikTeX](https://miktex.org/)
and
[TexLive](https://www.tug.org/texlive/)
provide package installers.

See [this guide](https://en.wikibooks.org/wiki/LaTeX/Installing_Extra_Packages#Automatic_installation)
for more information.

## Manual installation

This is the hard way.

All available LaTeX packages are
located at the [Comprehensive TeX Archive Network (CTAN) site ](https://metacpan.org/pod/%20https%3A#ctan.org).
Search the package, download it, locate and change to your
LaTeX installation directory (for example `/usr/share/texlive/texmf-dist`),
change to `tex`. Decide which flavour of LaTeX (processor)
this package is for, e.g. `latex`, `pdflatex` or `xelatex`,
change to that directory and unzip the downloaded file there.

# TESTING

Some tests may fail because some required LaTeX fonts
and/or style files are missing from your LaTeX installation.
As of version 0.04 the test files which use complex
LaTeX formatting and may require extra LaTeX packages
have been designated as _author tests_ and have
been moved to the `xt/` directory. They are not
part of the usual unit tests suite run with `make test`.
They can be run using `make authortest`. If there are failures,
try installing the missing LaTeX fonts and style files
(see section ["INSTALLING LaTeX PACKAGES"](#installing-latex-packages)).
Or freshen up your LaTeX installation. In any event,
these tests are not important and their possible
failure should not cause any convern.

In order to run all tests download the
tarball distribution of this module from CPAN
(there is a link on the left side of the module's
page for that), extract it, enter the directory and do:

    perl Makefile.PL
    make all
    make test
    make authortest

# CAVEATS

There are a lot of temporary files/directories created
by this package and its dependencies (e.g. [LaTeX::Driver](https://metacpan.org/pod/LaTeX%3A%3ADriver), [Capture::Tiny](https://metacpan.org/pod/Capture%3A%3ATiny), etc.).
If you observe stray temporary files remaining in `/tmp` or equivalent, please
let me know.

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

- TeX/LaTeX - excellent typography, superb aesthetics.
Thank you Donald Knuth and Leslie Lamport and countless contributors.
- [Text::Xslate](https://metacpan.org/pod/Text%3A%3AXslate) - fast and feature-rich template engine.
Thank you Shoichi Kaji and contributors.

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Andreas Hadjiprocopis.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
