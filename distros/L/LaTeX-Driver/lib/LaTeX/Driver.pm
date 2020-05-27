# LaTeX::Driver
#
# DESCRIPTION
#   Driver module that encapsulates the details of formatting a LaTeX document
#
# AUTHOR
#   Chris Travers <chris.travers@gmail.com>  (current maintainer)
#
# COPYRIGHT
#   Copyright (C) 2020  Erik Huelsmann.
#   Copyright (C) 2014  Chris Travers.
#   Copyright (C) 2009-2013 Ford & Mason Ltd.
#   Copyright (C) 2006-2007 Andrew Ford.
#   Portions Copyright (C) 1996-2006 Andy Wardley.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#

package LaTeX::Driver;

use strict;
use warnings;

use 5.008005;

use parent 'Class::Accessor';
use Cwd;                                # from PathTools
use English qw( -no_match_vars );       # standard Perl class
use Exception::Class ( 'LaTeX::Driver::Exception' );
use File::Copy;                         # standard Perl class
use File::Compare;                      # standard Perl class
use File::Path;                         # standard Perl class
use File::Slurp;
use File::Spec;                         # from PathTools
use IO::File;                           # from IO
use Readonly;
use File::pushd;                        # temporary cwd changes
use Capture::Tiny qw(capture);

Readonly our $DEFAULT_MAXRUNS => 10;

our $VERSION = "1.0.0";

__PACKAGE__->mk_accessors( qw( basename basedir basepath options
                               source output tmpdir format timeout stderr
                               formatter preprocessors postprocessors _program_path
                               maxruns extraruns stats texinputs_path
                               undefined_citations undefined_references
                               labels_changed rerun_required ) );

our $DEBUG; $DEBUG = 0 unless defined $DEBUG;
our $DEBUGPREFIX;


# LaTeX executable paths set at installation time by the Makefile.PL

our @PROCESSORS      = qw(xelatex lulaatex pdflatex latex);
our @AUXILLARY_PROGS = qw(bibtex makeindex);
our @POSTPROCESSORS  = qw(dvips dvipdfm ps2pdf pdf2ps);
our @PROGRAM_NAMES   = (@PROCESSORS, @AUXILLARY_PROGS, @POSTPROCESSORS);

our %program_path = map { ( $_ => $_ ) } @PROGRAM_NAMES;

our @LOGFILE_EXTS = qw( log blg ilg );
our @TMPFILE_EXTS = qw( aux log lot toc bbl ind idx cit cbk ibk );


our $DEFAULT_TMPDIR  = 'latexdrv';
our $DEFAULT_DOCNAME = 'latexdoc';

# valid output formats and program alias

our $DEFAULT_FORMAT = 'pdf';

our %FORMATTERS  = (
    dvi        => [ 'latex' ],
    ps         => [ 'latex', 'dvips' ],
    postscript => [ 'latex', 'dvips' ],
    pdf        => [ 'xelatex' ],
    'pdf(pdflatex)' => [ 'pdflatex' ],
    'pdf(xelatex)'  => [ 'xelatex' ],
    'ps(xelatex)'  => [ 'xelatex', 'pdf2ps' ],
    'pdf(dvi)'      => [ 'latex', 'dvipdfm' ],
    'pdf(ps)'       => [ 'latex', 'dvips', 'ps2pdf' ],
    'ps(pdf)'       => [ 'pdflatex', 'pdf2ps' ],
    'ps(pdflatex)'       => [ 'pdflatex', 'pdf2ps' ],
    'ps(xelatex)'       => [ 'xelatex', 'pdf2ps' ],
);




#------------------------------------------------------------------------
# new(%options)
#
# Constructor for the Latex driver
#------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $options = ref $_[0] ? shift : { @_ };
    my ($volume, $basedir, $basename, $basepath, $orig_ext, $cleanup);
    my ($formatter, @postprocessors);

    $DEBUG       = $options->{DEBUG} || 0;
    $DEBUGPREFIX = $options->{DEBUGPREFIX} if exists $options->{DEBUGPREFIX};

    # Sanity check first - check we're running on a supported OS

    $class->throw("not available on $OSNAME")
        if $OSNAME =~ m/ ^ ( MacOS | os2 | VMS ) $ /ix;


    # Examine the options - we need at least a source to work with and
    # it should be a scalar reference or a valid filename.

    my $source = delete $options->{source};
    $class->throw("no source specified")
        unless $source;

    if (ref $source) {
        $class->throw("source is an invalid reference $source")
            if ref $source ne 'SCALAR';
    }
    else {
        $source =~ s/ ( [.] tex ) $ //x;
        $orig_ext = $1;
        $class->throw("source file ${source}.tex does not exist")
            unless -f $source or -f "${source}.tex";
    }


    # Determine how the document is to be processed.  Either specified
    # explicitly in the format parameter or if an output file is
    # specified it is taken from that, or the default is take.

    my $output = $options->{output};
    my $format;
    $format = lc($options->{format})
        if $options->{format};

    if ($output and (!ref $output)) {
        my ($volume, $dir, $file) = File::Spec->splitpath($output);
        $class->throw("output directory $dir does not exist")
            unless $dir and -d $dir;
        if ((!$format) and ($file =~ / [.] ( \w+ ) $ /x)) {
            $format = lc($1);
        }
    }


    # There is a formatter and zero or more postprocessors for each
    # format; there are also special formats 'pdf(dvi)', 'pdf(ps)' and
    # 'ps(pdf)' that specify alternate routes to generate the format.

    $format ||= $DEFAULT_FORMAT;
    $class->throw("invalid output format: '$format'")
        unless exists $FORMATTERS{$format};

    ($formatter, @postprocessors) = @{$FORMATTERS{$format}};

    # discard the parenthesized part of special formats

    $format =~ s/\(.*\)//;


    # If a temporary directory was specified or the LaTeX source was
    # given as a scalar reference then a temporary directory is
    # created and the document source written to that directory or
    # copied in if the source is a file.

    my $tmpdir = $options->{tmpdir};
    if ($tmpdir or ref $source) {
        $basedir = $class->_setup_tmpdir($tmpdir);
        $cleanup = 'rmdir' if ((!defined($tmpdir)) or ($tmpdir eq "1"));
        if (ref $source) {
            $basename = $DEFAULT_DOCNAME;
            $basepath = File::Spec->catfile($basedir, $basename);
            write_file($basepath . ".tex", $source)
                or $class->throw("cannot create temporary latex file");
        }
        else {
            ($basename = $source) =~ s{.*/}{};
            $basepath = File::Spec->catfile($basedir, $basename);
            copy("$source$orig_ext", "${basepath}.tex")
                or $class->throw("cannot copy $source$orig_ext to temporary directory");
            $output  ||= "${source}.$format";
        }
    }

    # Otherwise the source was given as a filename, so the base name
    # and directory are taken from the source name.

    else {
        ($volume, $basedir, $basename) = File::Spec->splitpath($source);
        $basename =~ s/\.tex$//;
        if ($basedir and $volume) {
            $basedir = File::Spec->catfile($volume, $basedir);
        }
        $basedir ||= getcwd;
        $basedir =~ s{(.)/$}{$1};
        $basepath = File::Spec->catfile($basedir, $basename);
    }


    # Set up a mapping of program name to full pathname.
    # This is initialized from the paths detemined at installation
    # time, but any specified in the paths option override these
    # values.

    $options->{paths} ||= {};

    my $path = {};

    map { $path->{$_} = $program_path{$_}; } @PROGRAM_NAMES;
    map { $path->{$_} = $options->{paths}->{$_}; } keys %{ $options->{paths} };


    # Set up the texinputs path

    my $texinputs_path = $options->{TEXINPUTS} || $options->{texinputs} || [];
    $texinputs_path = [ split(/:/, $texinputs_path) ] unless ref $texinputs_path;

    # see http://tex.stackexchange.com/questions/149714/149865#149865

    my $texinputs_sep = $OSNAME eq "MSWin32" ? ';' : ':';


    # construct and return the object

    return $class->SUPER::new( { basename       => $basename,
                                 basedir        => $basedir,
                                 basepath       => $basepath,
                                 format         => $format,
                                 output         => $output,
                                 cleanup        => $cleanup || '',
                                 options        => $options,
                                 maxruns        => $options->{maxruns}   || $DEFAULT_MAXRUNS,
                                 extraruns      => $options->{extraruns} ||  0,
                                 timeout        => $options->{timeout},
                                 capture_stderr => $options->{capture_stderr} || 0,
                                 formatter      => $formatter,
                                 _program_path  => $path,
                                 texinputs_path => join($texinputs_sep, ('.', @{$texinputs_path}, '')),
                                 preprocessors  => [],
                                 postprocessors => \@postprocessors,
                                 stats          => { runs => {} } } );

}


#------------------------------------------------------------------------
# run()
#
# Runs the formatter and other programs to generate the ouptut.
#------------------------------------------------------------------------

sub run {
    my $self = shift;

    $DEBUG = $self->options->{DEBUG} || 0;

    # Check that the file exists

    $self->throw(sprintf('file %s.tex does not exist', $self->basepath))
        unless -f $self->basepath . '.tex';


    # Run any preprocessors (none specified yet).

    map { $self->$_ } @{$self->preprocessors};


    # Run LaTeX and friends until an error occurs, the document
    # stabilizes, or the maximum number of runs is reached.

    my $maxruns   = $self->maxruns;
    my $extraruns = $self->extraruns;
  RUN:
    foreach my $run (1 .. $maxruns) {

        if ($self->need_to_run_latex or $extraruns-- > 0) {
            $self->run_latex;
        }
        elsif ($self->need_to_run_bibtex) {
            $self->run_bibtex;
        }
        elsif ($self->need_to_run_makeindex) {
            $self->run_makeindex;
        }
    }


    # Run any postprocessors (e.g.: dvips, ps2pdf, etc).

    foreach my $postproc (@{$self->postprocessors}) {
        my $method = $postproc;
        if ($self->can($method)) {
            $self->$method();
        }
        else {
            $method = 'run_' . $postproc;
            if ($self->can($method)) {
                $self->$method();
            }
            else {
                $self->throw("cannot find postprocessor $postproc");
            }
        }
    }


    # Return any output

    $self->copy_to_output
        if $self->output;

    return 1;
}



#------------------------------------------------------------------------
# destructor
#
#------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;

    debug('DESTROY called') if $DEBUG;

    $self->cleanup();
    return;
}


#------------------------------------------------------------------------
# run_latex()
#
# Run the latex processor (latex or pdflatex depending on what is configured).
#------------------------------------------------------------------------

sub run_latex {
    my $self = shift;

    my $basename = $self->basename;
    my $exitcode = $self->run_command($self->formatter =>
                                      "\\nonstopmode\\def\\TTLATEX{1}\\input{./$basename}");

    # If an error occurred attempt to extract the interesting lines
    # from the log file.  Even without errors the log file may contain
    # interesting warnings indicating that LaTeX or one of its friends
    # must be rerun.

    my $errors = "";
    my $logfile = $self->basepath . ".log";

    if (my $fh = IO::File->new($logfile, "r")) {
        $self->reset_latex_required;
        my $matched = 0;
        while ( my $line = <$fh> ) {
            debug($line) if $DEBUG >= 9;
            # TeX errors start with a "!" at the start of the
            # line, and followed several lines later by a line
            # designator of the form "l.nnn" where nnn is the line
            # number.  We make sure we pick up every /^!/ line,
            # and the first /^l.\d/ line after each /^!/ line.
            if ( $line =~ /^(!.*)/ ) {
                $errors .= $1 . "\n";
                $matched = 1;
            }
            elsif ( $matched && ($line =~ /^(l\.\d.*)/) ) {
                $errors .= $1 . "\n";
                $matched = 0;
            }
            elsif ( $line =~ /^Output written on (.*) \((\d+) pages, (\d+) bytes\)./ ) {
                my ($ofile, $pages, $bytes) = ($1, $2, $3);
                $self->{stats}{pages} = $pages;
                $self->{stats}{bytes} = $bytes;
            }
            elsif ( $line =~ /^LaTeX Warning: Reference .*? on page \d+ undefined/ ) {
                $self->undefined_references(1);
            }
            elsif ( $line =~ /^LaTeX Warning: Citation .* on page \d+ undefined/ ) {
                debug('undefined citations detected') if $DEBUG;
                $self->undefined_citations(1);
            }
            elsif ( $line =~ /LaTeX Warning: There were undefined references./i ) {
                debug('undefined reference detected') if $DEBUG;
                $self->undefined_references(1)
                    unless $self->undefined_citations;
            }
            elsif ( $line =~ /No file $basename\.(toc|lof|lot)/i ) {
                debug("missing $1 file") if $DEBUG;
                $self->undefined_references(1);
            }
            elsif ( $line =~ /^LaTeX Warning: Label\(s\) may have changed./i ) {
                debug('labels have changed') if $DEBUG;
                $self->labels_changed(1);
            }
            elsif ( $line =~ /^Package longtable Warning: Table widths have changed[.] Rerun LaTeX[.]/i) {
                debug('table widths changed') if $DEBUG;
                $self->rerun_required(1);
            }

            # A number of packages emit 'rerun' warnings (revtex4,
            # pdfmark, etc); this regexp catches most of those.

            elsif ( $line =~ /Rerun to get (.*) right/i) {
                debug("$1 changed") if $DEBUG;
                $self->rerun_required(1);
            }
        }
    }
    else {
        $errors = "failed to open $logfile for input";
    }

    if ($exitcode or $errors) {
        $self->throw($self->formatter . " exited with errors:\n$errors");
    }

    $self->stats->{runs}{formatter}++;

    return;
}

sub reset_latex_required {
    my $self = shift;
    $self->rerun_required(0);
    $self->undefined_references(0);
    $self->labels_changed(0);
    return;
}

sub need_to_run_latex {
    my $self = shift;

    my $auxfile = $self->basepath . '.aux';
    return 1
        if $self->undefined_references
        || $self->labels_changed
        || $self->rerun_required
        || ! -f $auxfile;
    return;
}


#------------------------------------------------------------------------
# run_bibtex()
#
# Run bibtex to generate the bibliography
# bibtex reads references from the .aux file and writes a .bbl file
# It looks for .bib file in BIBINPUTS and TEXBIB
# It looks for .bst file in BSTINPUTS
#------------------------------------------------------------------------

sub run_bibtex {
    my $self = shift;

    my $basename = $self->basename;
    my $exitcode = $self->run_command(bibtex => $basename, 'BIBINPUTS');

    # TODO: extract meaningful error message from .blg file

    $self->throw("bibtex $basename failed ($exitcode)")
        if $exitcode;

    # Make a backup of the citations file for future comparison, reset
    # the undefined citations flag and mark the driver as needing to
    # re-run the formatter.

    my $basepath = $self->basepath;
    copy("$basepath.cit", "$basepath.cbk");

    $self->undefined_citations(0);
    $self->rerun_required(1);
    return;
}


#------------------------------------------------------------------------
# $self->need_to_run_bibtex
#
# LaTeX reports 'Citation ... undefined' if it sees a citation
# (\cite{xxx}, etc) and hasn't read a \bibcite{xxx}{yyy} from the aux
# file.  Those commands are written by parsing the bbl file, but will
# not be seen on the run after bibtex is run as the citations tend to
# come before the \bibliography.
#
# The latex driver sets undefined_citations if it sees the message,
# but we need to look at the .aux file and check whether the \citation
# lines match those seen before the last time bibtex was run.  We
# store the citation commands in a .cit file, this is copied to a cbk
# file by the bibtex method once bibtex has been run.  Doing this
# check saves an extra run of bibtex and latex.
#------------------------------------------------------------------------

sub need_to_run_bibtex {
    my $self = shift;

    if ($self->undefined_citations) {
        my $auxfile = $self->basepath . '.aux';
        my $citfile = $self->basepath . '.cit';
        my $cbkfile = $self->basepath . '.cbk';

        my $auxfh = IO::File->new($auxfile, 'r') or return;
        my $citfh = IO::File->new($citfile, 'w')
            or $self->throw("failed to open $citfile for output: $!");

        while ( my $line = <$auxfh> ) {
            print($citfh $line) if $line =~ /^\\citation/;
        }
        undef $auxfh;
        undef $citfh;

        return if -e $cbkfile and (compare($citfile, $cbkfile) == 0);
        return 1;
    }
    return;
}


#------------------------------------------------------------------------
# $self->run_makeindex()
#
# Run makeindex to generate the index
#
# makeindex has a '-s style' option which specifies the style file.
# The environment variable INDEXSTYLE defines the path where the style
# file should be found.
# TODO: sanity check the indexoptions? don't want the caller
# specifying the output index file name as that might screw things up.
#------------------------------------------------------------------------

sub run_makeindex {
    my $self = shift;

    my $basename = $self->basename;
    my @args;
    if (my $stylename = $self->options->{indexstyle}) {
        push @args, '-s', $stylename;
    }
    if (my $index_options = $self->options->{indexoptions}) {
        push @args, $index_options;
    }
    my $exitcode = $self->run_command(makeindex => [@args, $basename]);

    # TODO: extract meaningful error message from .ilg file

    $self->throw("makeindex $basename failed ($exitcode)")
        if $exitcode;


    # Make a backup of the raw index file that was just processed, so
    # that we can determine whether makeindex needs to be rerun later.

    my $basepath = $self->basepath;
    copy("$basepath.idx", "$basepath.ibk");

    $self->rerun_required(1);
    return;
}


#------------------------------------------------------------------------
# $self->need_to_run_makeindex()
#
# Determine whether makeindex needs to be run.  Checks that there is a
# raw index file and that it differs from the backup file (if that exists).
#------------------------------------------------------------------------

sub need_to_run_makeindex {
    my $self = shift;

    my $basepath = $self->basepath;
    my $raw_index_file = "$basepath.idx";
    my $backup_file    = "$basepath.ibk";

    return unless -e $raw_index_file;
    return if -e $backup_file and (compare($raw_index_file, $backup_file) == 0);
    return 1;
}


#------------------------------------------------------------------------
# $self->run_dvips()
#
# Run dvips to generate PostScript output
#------------------------------------------------------------------------

sub run_dvips {
    my $self = shift;

    my $basename = $self->basename;

    my $exitstatus = $self->run_command(dvips => [$basename, '-o']);

    $self->throw("dvips $basename failed ($exitstatus)")
        if $exitstatus;
    return;
}


#------------------------------------------------------------------------
# $self->run_ps2pdf()
#
# Run ps2pdf to generate PDF from PostScript output
#------------------------------------------------------------------------

sub run_ps2pdf {
    my $self = shift;

    my $basename = $self->basename;

    my $exitstatus = $self->run_command(ps2pdf => ["$basename.ps", "$basename.pdf"]);

    $self->throw("ps2pdf $basename failed ($exitstatus)")
        if $exitstatus;
    return;
}


#------------------------------------------------------------------------
# $self->run_pdf2ps()
#
# Run ps2pdf to generate PostScript from PDF output
#------------------------------------------------------------------------

sub run_pdf2ps {
    my $self = shift;

    my $basename = $self->basename;

    my $exitstatus = $self->run_command(pdf2ps => ["$basename.pdf", "$basename.ps"]);

    $self->throw("pdf2ps $basename failed ($exitstatus)")
        if $exitstatus;
    return;
}


#------------------------------------------------------------------------
# $self->run_command($progname, $config, $dir, $args, $env)
#
# Run a command in the specified directory, setting up the environment
# and allowing for the differences between operating systems.
#------------------------------------------------------------------------

sub run_command {
    my ($self, $progname, $args, $envvars) = @_;

    $args = [ $args ]
        unless ref $args;

    # get the full path to the executable for this output format
    my $program = $self->program_path($progname)
        || $self->throw("$progname cannot be found, please specify its location");

    my $dir  = $self->basedir;
    my $null = File::Spec->devnull();
    my $cmd;

    $args ||= '';


    # Set up localized environment variables in preparation for running the command
    # Note that the localized hash slice assignment of %ENV ensures that
    # the localization is done at the same block level as the system().
    # Even doing something like  local($ENV{$_}) = $val for @{$envvars}
    # puts the localization in a deeper level block so the previous value
    # is restored before the system() call is made.

    $envvars ||= "TEXINPUTS";
    $envvars = [ $envvars ] unless ref $envvars;
    local(@ENV{@{$envvars}}) = map { $self->texinputs_path } @{$envvars};
    $self->stats->{runs}{$progname}++;
    debug("running '$program $args'") if $DEBUG;
    my $cwd = pushd($dir);

    # Format the command appropriately for our O/S

    my $exit_status;
    my $exit_error;
    my ($stdout, $stderr);
    if ($OSNAME eq 'MSWin32') {
        $args = join(' ', @$args);
        $cmd  = "\"$program\" $args";
        ($stdout, $stderr) = capture {
            $exit_status = system($cmd);
            $exit_error = "$!";
        };
    }
    else {
        $args = "'$args'" if $args =~ / \\ /mx;
        ($stdout, $stderr) = capture {
            $exit_status = system($program, @$args);
            $exit_error = "$!";
        };
    }
    if ($exit_status == -1) {
        $self->throw( "Failure to start $program: $exit_error" );
    }
    $self->{stderr} .= $stderr
        if $self->{capture_stderr};

    return $exit_status;
}


#------------------------------------------------------------------------
# $self->copy_to_output
#
#------------------------------------------------------------------------

sub copy_to_output {
    my $self = shift;
    my $output = $self->output or return;

    # construct file name of the generated document
    my $file = $self->basepath . '.' . $self->format;

    if (ref $output) {
        $$output = read_file($file);
    }
    else {
        # see if we can rename the generated file to the desired output
        # file - this may fail, e.g. across filesystem boundaries (and
        # it's quite common for /tmp to be a separate filesystem

        if (rename($file, $output)) {
            debug("renamed $file to $output") if $DEBUG;
        }
        elsif (copy($file, $output)) {
            debug("copied $file to $output") if $DEBUG;
        }
        else {
            $self->throw("failed to copy $file to $output");
        }
    }
    return;
}



#------------------------------------------------------------------------
# _setup_tmpdir($dirname)
#
# create a temporary directory
#------------------------------------------------------------------------

sub _setup_tmpdir {
    my ($class, $dirname) = @_;

    my $tmp  = File::Spec->tmpdir();

    if ($dirname and ($dirname ne 1)) {
        $dirname = File::Spec->catdir($tmp, $dirname);
        eval { mkpath($dirname, 0, oct(700)) } unless -d $dirname;
    }
    else {
        my $n = 0;
        do {
            $dirname = File::Spec->catdir($tmp, "$DEFAULT_TMPDIR$$" . '_' . $n++);
        } while (-e $dirname);
        eval { mkpath($dirname, 0, oct(700)) };
    }
    $class->throw("cannot create temporary directory: $@")
        if $@;

    debug(sprintf("setting up temporary directory '%s'\n", $dirname)) if $DEBUG;

    return $dirname;
}


#------------------------------------------------------------------------
# $self->cleanup
#
# cleans up the temporary files
# TODO: work out exactly what this should do
#------------------------------------------------------------------------

sub cleanup {
    my ($self, $what) = @_;
    my $cleanup = $self->{cleanup};
    debug('cleanup called') if $DEBUG;
    if ($cleanup eq 'rmdir') {
        if ((!defined $what) or ($what ne 'none')) {
            debug('cleanup removing directory tree ' . $self->basedir) if $DEBUG;
            rmtree($self->basedir);
        }
    }
    return;
}


#------------------------------------------------------------------------
# $self->program_path($progname, $optional_value)
#
#
#------------------------------------------------------------------------

sub program_path {
    my $class_or_self = shift;
    my $href     = ref $class_or_self ? $class_or_self->{_program_path} : \%program_path;
    my $progname = shift;

    return @_ ? ($href->{$progname} = shift) : $href->{$progname};
}



#------------------------------------------------------------------------
# throw($error)
#
# Throw an error message
#------------------------------------------------------------------------

sub throw {
    my ($self, @args) = @_;
    LaTeX::Driver::Exception->throw( error => join('', @args) );
    return; # not needed - but satisfies perlcritic
}

sub debug {
    my (@args) = @_;
    print STDERR $DEBUGPREFIX || "[latex] ", @args;
    print STDERR "\n" unless @args and ($args[-1] =~ / \n $ /mx);
    return;
}


1;

__END__

=head1 NAME

LaTeX::Driver - Latex driver

=head1 VERSION

1.0.0

=head1 SYNOPSIS

    use LaTeX::Driver;

    $drv = LaTeX::Driver->new( source  => \$doc_text,
                               output  => $filename,
                               format  => 'pdf',
                               %other_params );
    $ok    = $drv->run;
    $stats = $drv->stats;
    $drv->cleanup($what);

=head1 DESCRIPTION

The LaTeX::Driver module encapsulates the details of invoking the
Latex programs to format a LaTeX document.  Formatting with LaTeX is
complicated; there are potentially many programs to run and the output
of those programs must be monitored to determine whether further
processing is required.

This module runs the required commands in the directory specified,
either explicitly with the C<dirname> option or implicitly by the
directory part of C<basename>, or in the current directory.  As a
result of the processing up to a dozen or more intermediate files are
created.  These can be removed with the C<cleanup> method.


=head1 SOURCE

Source code can be found at L<https://github.com/fordmason/LaTeX-Driver>

Feel free to fork and add your stuff!

=head1 SUBROUTINES/METHODS

=over 4

=item C<new(%params)>

This is the constructor method.  It creates a driver object on which
the C<run> method is used to format the document specified.  The main
arguments are C<source> and C<output>; the C<source> argument is
required to specify the input document; C<output> is only mandatory if
C<source> is a scalar reference.

The full list of arguments is as follows:

=over 4

=item C<source>

This parameter is mandatory; it can either specify the name of the
document to be formatted or be a reference to a scalar containing the
document source.

=item C<output>

specifies the output for the formatted document; this may either be a
file name or be a scalar reference.  In the latter case the contents
of the formatted document file is copied into the scalar variable
referenced.

=item C<format>

the format of output required: one of C<"dvi"> (TeX Device Independent
format), C<"ps"> (PostScript) or C<"pdf"> (Adobe Portable Document
Format).  The follow special values are also accepted: C<"pdf(ps)">
(generates PDF via PostScript, using C<dvips> and C<ps2pdf>),
C<"pdf(dvi)"> (generates PDF via dvi, using C<dvipdfm>).  If not
specified then the format is determined from the name of the output
document if specified, or defaults to PDF.

=item C<tmpdir>

Specifies whether the formatting should be done in a temporary
directory in which case the source document is copied into the
directory before formatting.  This option can either take the value 1,
in which case a temporary directory is automatically generated, or it
is taken as the name of a subdirectory of the system temporary
directory.  A temporary directory is always created if the source
document is specified as a scalar reference.


=item C<paths>

Specifies a mapping of program names to full pathname as a hash
reference.  These paths override the paths determined at installation
time.

=item C<maxruns>

The maximum number of runs of the formatter program (defaults to 10).

=item C<extraruns>

The number of additional runs of the formatter program after the document has stabilized.

=item C<timeout>

Specifies a timeout in seconds within which any commands spawned
should finish.  

=item C<cleanup>

Specifies whether temporary files and directories should be
automatically removed when the object destructor is called.  Accepted
values are C<none> (do no cleanup), C<logfiles> (remove log files) and
C<tempfiles> (remove log and temporary files).  By default the
destructor will remove the entire contents of any automatically
generated temporary directory, but will leave all other files intact.

=item C<indexstyle>

The name of a C<makeindex> index style file that should be passed to
C<makeindex>.

=item C<indexoptions>

Specifies additional options that should be passed to C<makeindex>.
Useful options are: C<-c> to compress intermediate blanks in index
keys, C<-l> to specify letter ordering rather than word ordering,
C<-r> to disable implicit range formation.  Refer to L<makeindex(1)>
for full details.

=item C<texinputs>

Specifies one or more directories to be searched for LaTeX files.

=item C<DEBUG>

Enables debug statements if set to a non-zero value.

=item C<DEBUGPREFIX>

Sets the debug prefix, which is prepended to debug output if debug
statements.  By default there is no prefix.

=back

The constructor performs sanity checking on the options and will die
if the following conditions are detected:

=over 4

=item *

no source is specified

=item *

an invalid format is specified

=back

The constructor method returns a driver object.


=item C<run()>

Format the document.

=item C<stderr>

Holds the error output from subcommands, if the C<-capture_stderr>
option was passed to C<new()>.

=item C<stats()>

Returns a reference to a hash containing stats about the processing
that was performed, containing the following items:

=over 4

=item C<pages>

number of pages in the formatted document

=item C<bytes>

number of bytes in the formatted document

=item C<runs>

hash of the number of times each of the programs was run

=back

Note: the return value will probably become an object in a future
version of the module.


=item C<cleanup($what)>

Removes temporary intermediate files from the document directory and
resets the stats.

Not yet implemented


=item C<program_path($program_name, $opt_value)>

Get or set the path to the named program.  Can be used as a class
method to set the default path or as an object method to set the path
for that instance of the driver object.

=back


There are a number of other methods that are used internally by the
driver.  Calling these methods directly may lead to unpredictable results.

=over 4

=item C<run_latex>

Runs the formatter (C<latex> or C<pdflatex>).

=item C<need_to_run_latex>

Determines whether the formatter needs to be run.

=item C<reset_latex_required>

Reset the flags that indicate whether latex needs to be re-run
(invoked prior to each iteration of running any necessary commands).

=item C<run_bibtex>

Runs bibtex to generate the bibliography.

=item C<need_to_run_bibtex>

Determines whether bibtex needs to be run.

=item C<run_makeindex>

Runs makeindex to generate the index.

=item C<need_to_run_makeindex>

Determines whether makeindex needs to be run.

=item C<run_dvips>

Runs dvips to generate postscript output from an intermediate C<.dvi> file.

=item C<run_ps2pdf>

Runs ps2pdf to generate PDF output from an intermediate PostScript file.

=item C<run_pdf2ps>

Runs pdf2ps to generate PostScript output from an intermediate PDF file.

=item C<run_command>

Run a command in a controlled environment, allowing for operating system differences.

=item C<copy_to_output>

Copy the output to its final destination.

=item C<throw>

Throw an exception.

=item C<debug>

Print a debug message - the caller should test C<$DEBUG> to determine
whether to invoke this function.

=back


=head1 DIAGNOSTICS

The following errors may be detected by the constructor method.

=over 4

=item not available on XXX

The module is not supported on MacOS, OS/2 or VMS (or on a host of
other operating systems but these are the only ones that are
explicitly tested for).

=item no source specified

The C<source> parameter should be specified as the name of a LaTeX
source file or it should be a reference to a scalar variable holding
the LaTeX source document.

=item source is an invalid reference

C<source> is a reference, but not a reference to a scalar variable

=item source file XXX.tex does not exist

The source file specified does not exist

=item output directory DIR does not exist

An C<output> parameter was specified as a scalar value, which was
taken as the name of the output file, but the directory part of the
path does not exist.

=item invalid output format XXX

An output format was specified, either explicitly or implicitly as the
extension of the output file, but the output format specified is not
supported.

=item cannot create temporary directory

The module could not create the temporary directory, which is used if
the source is not specified as a filename, and the output is not to be
left in the same directory as the source, or if a temporary directory
name is specified explicitly.

=item cannot create temporary latex file

The module has determined that it needs to create a temporary file
containing the source document but it cannot.

=item cannot copy XXX.ext to temporary directory

The module was trying to copy the specified source file to the
temporary directory but couldn't.  Perhaps you specified the temporary
directory name explicitly but the directory does not exist or is not
writeable.

=back

The following errors may be detected when the driver's C<run()> method
is called:

=over 4

=item file XXX.tex does not exist

The source file does not exist; it may have been removed between the
time the constructor was called and the time that the driver was run.

=item PROGRAM exited with errors: ERRORS

The named program (C<latex> or C<pdflatex>) exited with the errors listed.
You may have errors in your source file.

=item bibtex FILE failed (EXITCODE)

The C<bibtex> program exited with errors.  These are not fully parsed yet.

=item failed to open BASEPATH.cit

The driver generates its own temporary file listing the citations for
a document, so that it can determine whether the citations have
changed.  This error indicates that it was unable to create the file.

=item makeindex FILE failed (EXITCODE)

The C<makeindex> program exited with errors.  These are not fully parsed yet.

=item dvips FILE failed (EXITCODE)

The C<dvips> program exited with errors.  These are not fully parsed yet.

=item ps2pdf FILE failed (EXITCODE)

The C<ps2pdf> program exited with errors.  These are not fully parsed yet.

=item PROGNAME cannot be found, please specify its location

The pathname for the specified program was not found in the modules
configuration.  The program may not have been found and the pathname
not been explicitly specified when the module was installed.

=item failed to copy FILE to OUTPUT

The driver failed to copy the formatted file to the specified output
location.


=back



=head1 CONFIGURATION AND ENVIRONMENT


=head1 DEPENDENCIES

C<LaTeX::Driver> depends on latex and friends being installed.


=head1 INCOMPATIBILITIES

None known.


=head1 BUGS AND LIMITATIONS

This is beta software - there are bound to be bugs and misfeatures.
If you have any comments about this software I would be very grateful
to hear them; email me at E<lt>a.ford@ford-mason.co.ukE<gt>.

Among the things I am aware of are:

=over 4

=item *

I haven't worked out how I am going to deal with tex-related environment variables.

=back


=head1 FUTURE DIRECTIONS

=over 4

=item *

Look at how path variables could be specified to the filter
(C<TEXINPUTS>, C<TEXINPUTS_latex>, C<TEXINPUTS_pdflatex>,
C<BIBINPUTS>, etc), and how these should interact with the system
paths.

=item *

Investigate pre- and post-processors and other auxiliary programs.

=back


=head1 BACKGROUND

This module has its origins in the original C<latex> filter that was
part of Template Toolkit prior to version 2.16.  That code was fairly
simplistic; it created a temporary directory, copied the source text
to a file in that directory, and ran either C<latex> or C<pdflatex> on
the file once; if postscript output was requested then it would run
C<dvips> after running C<latex>.  This did not cope with documents
that contained forward references, a table of contents, lists of
figures or tables, bibliographies, or indexes.

The current module does not create a temporary directory for
formatting the document; it is given the name and location of an
existing LaTeX document and runs the latex programs in the directory
specified (the Template Toolkit plugin will be modified to set up a
temporary directory, copy the source text in, then run this module,
extract the output and remove the temporary directory).


=head1 INTERNALS

This section is aimed at a technical audience.  It documents the
internal methods and subroutines as a reference for the module's
developers, maintainers and anyone interesting in understanding how it
works.  You don't need to know anything about them to use the module
and can safely skip this section.




=head2 Formatting with LaTeX or PDFLaTeX

LaTeX documents can be formatted with C<latex> or C<pdflatex>; the
former generates a C<.dvi> file (device independent - TeX's native
output format), which can be converted to PostScript or PDF; the
latter program generates PDF directly.

finds inputs in C<TEXINPUTS>, C<TEXINPUTS_latex>, C<TEXINPUTS_pdflatex>, etc


=head2 Generating indexes

The standard program for generating indexes is C<makeindex>, is a
general purpose hierarchical index generator.  C<makeindex> accepts
one or more input files (C<.idx>), sorts the entries, and produces an
output (C<.ind>) file which can be formatted.

The style of the generated index is specified by a style file
(C<.ist>), which is found in the path specified by the C<INDEXSTYLE>
environment variable.

An alternative to C<makeindex> is C<xindy>, but that program is not
widespread yet.


=head2 Generating bibliographies with BiBTeX

BiBTeX generates a bibliography for a LaTeX document.  It reads the
top-level auxiliary file (C<.aux>) output during the running of latex and
creates a bibliography file (C<.bbl>) that will be incorporated into the
document on subsequent runs of latex.  It looks up the entries
specified by \cite and \nocite commands in the bibliographic database
files (.bib) specified by the \bibliography commands.  The entries are
formatted according to instructions in a bibliography style file
(C<.bst>), specified by the \bibliographystyle command.

Bibliography style files are searched for in the path specified by the
C<BSTINPUTS> environment variable; for bibliography files it uses the
C<BIBINPUTS> environment variable.  System defaults are used if these
environment variables are not set.


=head2 Running Dvips

The C<dvips> program takes a DVI file produced by TeX and converts it
to PostScript.


=head2 Running ps2pdf

The C<ps2pdf> program invokes Ghostscript to converts a PostScript file to PDF.


=head2 Running on Windows

Commands are executed with C<cmd.exe>.  The syntax is:

   cmd /c "cd $dir && $program $args"

This changes to the specified directory and executes the program
there, without affecting the working directory of the the Perl process.

Need more information on how to set environment variables for the invoked programs.


=head2 Miscellaneous Information

This is a placeholder for information not yet incorporated into the rest of the document.

May want to mention the kpathsea library, the C<kpsewhich> program,
the web2c TeX distribution, TeX live, tetex, TeX on Windows, etc.


=head1 AUTHOR

Andrew Ford E<lt>a.ford@ford-mason.co.ukE<gt>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2011 Ford & Mason Ltd.  All Rights Reserved.

Copyright (C) 2007 Andrew Ford.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::Latex>, L<latex(1)>, L<makeindex(1)>,
L<bibtex(1)>, L<dvips(1)>, The dvips manual

There are a number of books and other documents that cover LaTeX:

=over 4

=item *

The LaTeX Companion

=item *

Web2c manual

=back

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
