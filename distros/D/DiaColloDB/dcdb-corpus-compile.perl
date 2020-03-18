#!/usr/bin/perl -w

use lib qw(. ./blib/lib ./blib/arch lib lib/blib/lib lib/blib/arch);
use DiaColloDB;
use DiaColloDB::Corpus::Compiled;
use DiaColloDB::Utils qw(:si);
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
use strict;

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

##-- program vars
our $prog       = basename($0);
our ($help,$version);

our %log        = (level=>'TRACE', rootLevel=>'FATAL');

our $globargs   = 1; ##-- glob input corpus @ARGV?
our $listargs   = 0; ##-- input args are raw corpus file-lists?
our $union      = 0; ##-- input args are pre-compiled corpora?
our $append     = 0; ##-- append to output corpus?
our $dotime     = 1; ##-- report timing?

our $outdir     = undef; ##-- required

our %icorpus    = (dclass=>'DDCTabs', dopts=>{});
our $filters    = DiaColloDB::Corpus::Filters->new();
our %ocorpus    = (
                   base    => undef,
                   njobs   => -1,
                   filters => $filters,
                  );

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
foreach (@ARGV) { utf8::decode($_) if (!utf8::is_utf8($_)); }
GetOptions(##-- general
	   'h|help' => \$help,
	   'V|version' => \$version,
	   #'verbose|v=i' => \$verbose,
           'j|jobs|njobs|nj=f' => \$ocorpus{njobs},

	   ##-- input corpus options
	   'g|glob!' => \$globargs,
	   'l|list!' => \$listargs,
           'u|union!' => \$union,
           ##
	   'C|document-class|dclass|dc=s' => \$icorpus{dclass},
	   'D|document-option|docoption|dopt|do|dO=s%' => \$icorpus{dopts},
	   'by-sentence|bysentence' => sub { $icorpus{dopts}{eosre}='^$' },
	   'by-paragraph|byparagraph' => sub { $icorpus{dopts}{eosre}='^%%\$DDC:BREAK\.p=' },
	   'by-doc|bydoc|by-file|byfile' => sub { $icorpus{dopts}{eosre}='' },

	   ##-- filter options
           'f|filter=s%' => sub { $filters->{$_[1]}=$_[2]; },
           'F|nofilters|no-filters|all|A|no-prune|noprune|use-all-the-data' => sub { $filters->clear },

	   ##-- I/O and logging
           'a|append!' => \$append,
           'o|output-directory|outdir|output|out|od=s' => \$outdir,
	   't|timing|times|time!' => \$dotime,
           'lf|log-file|logfile=s' => \$log{file},
	   'll|log-level|level=s' => sub { $log{level} = uc($_[1]); },
	   'lo|log-option|logopt=s' => \%log,
	  );

if ($version) {
  print STDERR "$prog version $DiaColloDB::VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}
pod2usage({-exitval=>0,-verbose=>0}) if ($help);
die("$prog: ERROR: no output corpus directory specified: use the -output (-o) option!\n") if (!defined($outdir));


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- setup logger
DiaColloDB::Logger->ensureLog(%log);
my $logger = 'DiaColloDB::Logger';
my $timer  = DiaColloDB::Timer->start();

##-- common variables
$ocorpus{flags} = $append ? '>>' : '>';
my ($ocorpus);

if ($union) {
  ##-- union: merge pre-compiled corpora
  $ocorpus = DiaColloDB::Corpus::Compiled->union(\@ARGV, %ocorpus, dbdir=>$outdir)
    or die("$prog: failed to create union corpus");
}
else {
  ##-- !union: compile raw input corpus data

  ##-- open input corpus
  push(@ARGV,'-') if (!@ARGV);
  my $icorpus = DiaColloDB::Corpus->new(%icorpus);
  $icorpus->open(\@ARGV, 'glob'=>$globargs, 'list'=>$listargs)
    or die("$prog: failed to open input corpus: $!");

  ##-- compile input corpus
  $ocorpus = $icorpus->compile($outdir, %ocorpus)
    or die("$prog: failed to compile output corpus '$outdir'.* from raw input corpus");
}

##-- cleanup
$ocorpus->close() if ($ocorpus);

##-- timing
if ($dotime) {
  (my $du = `du -h "$outdir" `) =~ s/\s.*\z//s;
  $logger->info("operation completed in ", $timer->timestr, "; compiled corpus size = ${du}B");
}

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

dcdb-corpus-compile.perl - pre-compile a DiaColloDB corpus

=head1 SYNOPSIS

 dcdb-corpus-compile.perl [OPTIONS] [INPUT(s)...]

 General Options:
   -h, -help            # this help message
   -V, -version         # report version information and exit
   -j, -jobs NJOBS      # set number of worker threads

 Input Corpus Options:
   -l, -[no]list        # INPUT(s) are/aren't file-lists (default=no)
   -g, -[no]glob        # do/don't glob INPUT(s) argument(s) (default=don't)
   -u, -[no]union       # do/don't treat INPUT(S) as pre-compiled corpus to be merged (default=don't)
   -C, -dclass CLASS    # set corpus document class (default=DDCTabs)
   -D, -dopt OPT=VAL    # set corpus document option, e.g.
                        #   eosre=EOSRE  # eos regex (default='^$')
                        #   foreign=BOOL # disable D*-specific heuristics
       -bysent          # default split by sentences (default)
       -byparagraph     # default split by paragraphs
       -bypage          # default split by page
       -bydoc           # default split by document

 Content Filter Options:
   -f, -filter KEY=VAL  # set filter option for KEY = (p|w|l)(bad|good)(_file)?
                        #   (p|w|l)good=REGEX      # positive regex for (postags|words|lemmata)
                        #   (p|w|l)bad=REGEX       # negative regex for (postags|words|lemmata)
                        #   (p|w|l)goodfile=FILE   # positive list-file for (postags|words|lemmata)
                        #   (p|w|l)badfile=FILE    # negative list-file for (postags|words|lemmata)
   -F, -nofilters       # clear all filter options

 I/O and Logging Options:
   -ll, -log-level LVL  # set log-level (default=TRACE)
   -lo, -log-option K=V # set log option (e.g. logdate, logtime, file, syslog, stderr, ...)
   -t,  -[no]times      # do/don't report operating timing (default=do)
   -a,  -[no]append     # do/don't append to existing output corpus (default=don't)
   -o,  -output OUTDIR  # set output corpus directory (required)

=cut

###############################################################
## DESCRIPTION
###############################################################
=pod

=head1 DESCRIPTION

dcdb-corpus-compile.perl pre-compiles a L<DiaColloDB::Corpus::Compiled|DiaColloDB::Corpus::Compiled>
from a tokenized and annotated input corpus represented as a L<DiaColloDB::Corpus|DiaColloDB::Corpus>
object, optionally applying L<content filters|DiaColloDB::Corpus::Filters> such as stopword lists.
The resulting compiled corpus can be used with L<dcdb-create.perl(1)|dcdb-create.perl>
to compile a L<DiaColloDB|DiaColloDB> collocation database.

Note that it is B<not> necessary to pre-compile a corpus with this script in order
to create a fully functional L<DiaColloDB|DiaColloDB> database from a source corpus,
since the L<DiaColloDB::create()|DiaColloDB::compile/create> method as invoked by
the L<dcdb-create.perl(1)|dcdb-create.perl> script should
implicitly create a (temporary) C<DiaColloDB::Corpus::Compiled> object
as and when required.

=cut


###############################################################
## OPTIONS AND ARGUMENTS
###############################################################
=pod

=head1 OPTIONS AND ARGUMENTS


=cut

###############################################################
# Arguments
###############################################################
=pod

=head2 Arguments

=over 4

=item INPUT(s)

File(s), glob(s), file-list(s), or basename(s) to be compiled.
Interpretation depends on the L<-glob|/-glob>, L<-list|/-list>, and L<-union|/-union>
options.

=back

=cut

###############################################################
# General Options
###############################################################
=pod

=head2 General Options

=over 4

=item -help

Display a brief help message and exit.

=item -version

Display version information and exit.

=item -jobs NJOBS

Run C<NJOBS> parallel compilation threads.
If specified as 0, will run only a single thread.
The default value (-1) will run as many jobs as there are cores on the (unix/linux) system;
see L<DiaColloDB::Utils/nJobs> for details.

=back

=cut


###############################################################
# Input Corpus Options
=pod

=head2 Input Corpus Options

=over 4

=item -list

=item -nolist

Do/don't treat INPUT(s) as file-lists rather than corpus data files.
Default=don't.

=item -glob

=item -noglob

Do/don't expand wildcards in INPUT(s).
Default=do.

=item -union

=item -nounion

Do/don't treat INPUT(s) as pre-compiled corpora to be merged.
Note that in C<-union> mode, no corpus content filters are applied
(they are assumed to have been applied to the INPUT(s) prior to the union call).
Default=don't

=item -dclass CLASS

Set corpus document class (default=DDCTabs).
See L<DiaColloDB::Document/SUBCLASSES> for a list
of supported input formats.
If you are using the default L<DDCTabs|DiaColloDB::Document::DDCTabs> document class
on your own (non-D*) corpus, you may also want to specify
L<C<-dopt foreign=1>|/"-dopt OPT=VAL">.

Aliases: -C, -document-class, -dclass, -dc

=item -dopt OPT=VAL

Set corpus document option, e.g.
L<C<-dopt eosre=EOSRE>|DDCTabs/new> sets the end-of-sentence regex
for the default L<DDCTabs|DiaColloDB::Document::DDCTabs> document class,
and L<C<-dopt foreign=1>|DDCTabs/new> disables D*-specific hacks.

Aliases: -D, -document-option, -docoption, -dopt, -do, -dO

=item -bysent

Split corpus (-> track collocations in compiled database) by sentence (default).

=item -byparagraph

Split corpus (-> track collocations in compiled database) by paragraph.

=item -bypage

Split corpus (-> track collocations in compiled database) by page.

=item -bydoc

Split corpus (-> track collocations in compiled database) by document.

=back

=cut


###############################################################
# Filter Options
=pod

=head2 Filter Options

=over 4

=item -use-all-the-data

Disables all content-filter options,
inspired by Mark Lauersdorf; equivalent to:

 -f=pgood='' \
 -f=wgood='' \
 -f=lgood='' \
 -f=pbad='' \
 -f=wbad='' \
 -f=lbad=''

Aliases: -F, -nofilters, -A, -all, -noprune

=back

=cut

###############################################################
# I/O and Logging Options
=pod

=head2 I/O and Logging Options

=over 4

=item -log-level LEVEL

Set L<DiaColloDB::Logger|DiaColloDB::Logger> log-level (default=TRACE).

Aliases: -ll, -log-level, -level

=item -log-option OPT=VAL

Set arbitrary L<DiaColloDB::Logger|DiaColloDB::Logger> option (e.g. logdate, logtime, file, syslog, stderr, ...).

Aliases: -lo, -log-option, -logopt

=item -[no]times

Do/don't report operating timing (default=do)

Aliases: -t, -timing, -times, -time

=item -output OUTDIR

Output directory for compiled corpus (required).

Aliases: -o, -output-directory, -outdir, -output, -out, -od

=back

=cut


###############################################################
# Bugs and Limitations
###############################################################
=pod

=head1 BUGS AND LIMITATIONS

Probably many.

=cut


###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 SEE ALSO

L<DiaColloDB(3pm)|DiaColloDB>,
L<DiaColloDB::Corpus(3pm)|DiaColloDB::Corpus>,
L<DiaColloDB::Corpus::Compiled(3pm)|DiaColloDB::Corpus::Compiled>,
L<DiaColloDB::Corpus::Filters(3pm)|DiaColloDB::Corpus::Filters>,
L<dcdb-create.perl(1)|dcdb-create.perl>,
L<perl(1)|perl>.

=cut
