#!/usr/bin/perl -w

use lib qw(. ./blib/lib ./blib/arch lib lib/blib/lib lib/blib/arch);
use DiaColloDB;
use DiaColloDB::Utils qw(:si);
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
use strict;

#use DiaColloDB::Relation::TDF; ##-- DEBUG
#use DiaColloDB::Document::TCF; ##-- DEBUG

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

##-- program vars
our $prog       = basename($0);
our ($help,$version);

our %log        = (level=>'TRACE', rootLevel=>'FATAL');
our $dbdir      = undef;

our $globargs   = 1; ##-- glob @ARGV?
our $listargs   = 0; ##-- args are file-lists?
our $union      = 0; ##-- args are db-dirs?
our $lazy_union = 0; ##-- union mode: create a list-client config?
our $dotime     = 1; ##-- report timing?
our %corpus   = (dclass=>'DDCTabs', dopts=>{});
our %coldb    = (
		 pack_id=>'N',
		 pack_date=>'n',
		 pack_f=>'N',
		 pack_off=>'N',
		 pack_len=>'n',
		 dmax=>5,
		 cfmin=>2,
		 tfmin=>2,
		 fmin_l=>undef,
		 keeptmp=>0,
		 mmap => 1,
		 debug => 0,
		 tdfopts=>{
			   minDocFreq => 4,
			   minDocSize => 8,
			   #maxDocSize => 'inf',
			  },
		 vbreak=>'#file',
		);
our %uopts = qw(); ##-- user-options, for lazy-union creation

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
sub pack64 {
  $coldb{$_}=($_[1] ? 'Q>' : 'N') foreach qw(pack_id pack_f pack_off);
  $coldb{pack_len}=($_[1] ? 'n' : 'N');
  $coldb{tdfopts}{itype} = $_[1] ? 'ccs_indx' : 'long';
  $coldb{tdfopts}{vtype} = $_[1] ? 'double' : 'float';
}
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   #'verbose|v=i' => \$verbose,

	   ##-- corpus options
	   'glob|g!' => \$globargs,
	   'list|l!' => \$listargs,
	   'union|u|merge!' => \$union,
	   'lazy-union|list-union|lazy|lu!' => \$lazy_union,
	   'document-class|dclass|dc=s' => \$corpus{dclass},
	   'document-option|docoption|dopt|do|dO=s%' => \$corpus{dopts},
	   'by-sentence|bysentence' => sub { $corpus{dopts}{eosre}='^$' },
	   'by-paragraph|byparagraph' => sub { $corpus{dopts}{eosre}='^%%\$DDC:BREAK\.p=' },
	   'by-doc|bydoc|by-file|byfile' => sub { $corpus{dopts}{eosre}='' },

	   ##-- coldb options
	   'index-attributes|attributes|attrs|a=s' => \$coldb{attrs},
	   'nofilters|no-filters|F|all|A|no-prune|noprune|use-all-the-data' => sub {
	     $coldb{$_} = 0  foreach (grep {$_ =~ /fmin/} keys %coldb);
	     $coldb{$_} = '' foreach (qw(pgood pbad wgood wbad lgood lbad));
	     $coldb{tdfopts}{$_} = 0 foreach (grep {$_ =~ /min.*Freq/} keys %{$coldb{tdfopts}});
	     $coldb{tdfopts}{$_} = 1 foreach (grep {$_ =~ /min.*Size/} keys %{$coldb{tdfopts}});
	     $coldb{tdfopts}{$_} = 'inf' foreach (grep {$_ =~ /max.*(Freq|Size)/} keys %{$coldb{tdfopts}});
	     $coldb{tdfopts}{$_} = ''    foreach (qw(mgood mbad));
	   },
	   '64bit|64|quad|Q!'   => sub { pack64( $_[1]); },
	   '32bit|32|long|L|N!' => sub { pack64(!$_[1]); },
	   'mmap!' => \$coldb{mmap},
	   'debug!' => \$coldb{debug},
	   'max-distance|maxd|dmax|n=i' => \$coldb{dmax},
	   'min-term-frequency|min-tf|mintf|tfmin|min-frequency|min-f|minf|fmin=i' => \$coldb{tfmin},
	   'min-lemma-frequency|min-lf|minlf|lfmin=i' => \$coldb{fmin_l},
	   'min-cofrequency|min-cf|mincf|cfmin=i' => \$coldb{cfmin},
	   'index-tdf|index-tdm|tdf|tdm!' => \$coldb{index_tdf},
	   'tdf-dbreak|tdf-break|dbreak|db|vbreak|vb=s' => \$coldb{dbreak},
	   'tdf-min-term-frequency|tdf-tfmin|tdf-fmin=i' => \$coldb{tdfopts}{minFreq},
	   'tdf-min-document-frequency|tdf-dfmin=i' => \$coldb{tdfopts}{minDocFreq},
	   'tdf-break-min-size|tdf-break-min|tdf-nmin|vbnmin|vbmin=s' => \$coldb{tdfopts}{minDocSize},
	   'tdf-break-max-size|tdf-break-max|tdf-nmax|vbnmax|vbmax=s' => \$coldb{tdfopts}{maxDocSize},
	   'tdf-option|tdm-option|tdfopt|tdmopt|tdmo|tdfo|to|tO=s%' => sub { $coldb{tdfopts}{$_[1]}=$_[2] },
	   'keeptmp|keep!' => \$coldb{keeptmp},
	   'option|O=s%' => sub { $coldb{$_[1]}=$uopts{$_[1]}=$_[2]; },

	   ##-- I/O and logging
	   'timing|times|time|t!' => \$dotime,
	   'log-level|level|ll=s' => sub { $log{level} = uc($_[1]); },
	   'log-option|logopt|lo=s' => \%log,
	   'output|outdir|od|o=s' => \$dbdir,
	  );

if ($version) {
  print STDERR "$prog version $DiaColloDB::VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}
pod2usage({-exitval=>0,-verbose=>0}) if ($help);
die("$prog: ERROR: no output location specified: use the -output (-o) option!\n") if (!defined($dbdir));


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- setup logger
DiaColloDB::Logger->ensureLog(%log);

##-- setup corpus
push(@ARGV,'-') if (!@ARGV);
$globargs  = 0 if ($lazy_union); ##-- allow "real" remote URLs for lazy union
my $corpus = DiaColloDB::Corpus->new(%corpus);
$corpus->open(\@ARGV, 'glob'=>$globargs, 'list'=>$listargs, ($union ? (logOpen=>'off') : qw()))
  or die("$prog: failed to open corpus: $!");

##-- create db
my $timer = DiaColloDB::Timer->start();
my ($coldb);
if ($lazy_union) {
  $coldb = DiaColloDB::Client::list->new(%uopts)
    or die("$prog: failed to create lazy union list-client: $!");
  $coldb->open($corpus->{files})
    or die("$prog: failed to open lazy union list-client: $!");
  $coldb->saveHeaderFile($dbdir)
    or die("$prog: failed to save lazy union list-client configuration to 'rcfile://$dbdir': $!");
}
else {
  $coldb = DiaColloDB->new(%coldb)
    or die("$prog: failed to create new DiaColloDB object: $!");
  if ($union) {
    ##-- union: create from dbdirs
    $coldb->union($corpus->{files}, dbdir=>$dbdir, flags=>'rw')
      or die("$prog: DiaColloDB::union() failed: $!");
  } else {
    ##-- !union: create from corpus
    $coldb->create($corpus, dbdir=>$dbdir, flags=>'rw', attrs=>($coldb{attrs}||'l,p'))
      or die("$prog: DiaColloDB::create() failed: $!");
  }
}

##-- cleanup
#my $du = si_str($coldb->du());
$coldb->close() if ($coldb);

##-- timing
if ($dotime) {
  (my $du = `du -h "$dbdir"`) =~ s/\s.*\z//s;
  $coldb->info("operation completed in ", $timer->timestr, "; db size = ${du}B");
}

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

dcdb-create.perl - create a DiaColloDB diachronic collocation database

=head1 SYNOPSIS

 dcdb-create.perl [OPTIONS] [INPUT(s)...]

 General Options:
   -help                ##-- this help message
   -version             ##-- report version information and exit

 Corpus Options:
   -list , -nolist      ##-- INPUT(s) are/aren't file-lists (default=no)
   -glob , -noglob      ##-- do/don't glob INPUT(s) argument(s) (default=do)
   -union, -nounion     ##-- do/don't trate INPUT(s) as DB directories to be merged (default=don't)
   -lazy , -nolazy      ##-- do/don't create "lazy" list-client (union mode only; default=don't)
   -dclass CLASS        ##-- set corpus document class (default=DDCTabs)
   -dopt OPT=VAL        ##-- set corpus document option, e.g.
                        ##   eosre=EOSRE  # eos regex (default='^$')
                        ##   foreign=BOOL # disable D*-specific heuristics
   -bysent              ##-- track collocations by sentence (default)
   -byparagraph         ##-- track collocations by paragraph
   -bypage              ##-- track collocations by page
   -bydoc               ##-- track collocations by document

 Indexing Options:
   -attrs ATTRS         ##-- select index attributes (default=l,p)
                        ##   known attributes: l, p, w, doc.title, ...
   -use-all-the-data    ##-- disable default frequency- and regex-filters
   -64bit               ##-- use 64-bit quads where available
   -32bit               ##-- use 32-bit integers where available
   -dmax DIST           ##-- maximum distance for indexed co-occurrences (default=5)
   -tfmin TFMIN         ##-- minimum global term frequency (default=2)
   -lfmin LFMIN         ##-- minimum global lemma frequency (default=undef:tfmin)
   -cfmin CFMIN         ##-- minimum relation co-occurrence frequency (default=2)
   -[no]tdf             ##-- do/don't create (term x document) index relation (default=if available)
   -tdf-dbreak BREAK    ##-- set tdf matrix "document" granularity (e.g. s,p,page,file; default=file)
   -tdf-fmin VFMIN      ##-- set minimum tdf term frequency (default=undef: TFMIN)
   -tdf-dfmin VDFMIN    ##-- set minimum tdf term "document"-frequency (default=4)
   -tdf-nmin VNMIN      ##-- set minimum number of content tokens per tdf "document" (default=8)
   -tdf-nmax VNMAX      ##-- set maximum number of content tokens per tdf "document" (default=inf)
   -tdf-option OPT=VAL  ##-- set arbitrary tdf matrix option, e.g.
                        ##   minFreq=INT            # minimum term frequency (default=undef: use TFMIN)
                        ##   minDocFreq=INT         # minimum term document-"frequency" (default=4)
                        ##   minDocSize=INT         # minimum document size (#/terms) (default=4)
                        ##   maxDocSize=INT         # maximum document size (#/terms) (default=inf)
                        ##   mgood=REGEX            # positive regex for document-level metatdata
                        ##   mbad=REGEX             # negative regex for document-level metatdata
   -option OPT=VAL      ##-- set arbitrary DiaColloDB option, e.g.
                        ##   pack_id=PACKFMT        # pack-format for IDs
                        ##   pack_f=PACKFMT         # pack-format for frequencies
                        ##   pack_date=PACKFMT      # pack-format for dates
                        ##   (p|w|l)good=REGEX      # positive regex for (postags|words|lemmata)
                        ##   (p|w|l)bad=REGEX       # negative regex for (postags|words|lemmata)
                        ##   (p|w|l)goodfile=FILE   # positive list-filefor (postags|words|lemmata)
                        ##   (p|w|l)badfile=FILE    # negative list-file for (postags|words|lemmata)
                        ##   ddcServer=HOST:PORT    # server for ddc relations
                        ##   ddcTimeout=SECONDS     # timeout for ddc relations
   -noprune             ##-- disable all pruning filters

 I/O and Logging Options:
   -log-level LEVEL     ##-- set log-level (default=TRACE)
   -log-option OPT=VAL  ##-- set log option (e.g. logdate, logtime, file, syslog, stderr, ...)
   -[no]keep            ##-- do/don't keep temporary files (default=don't)
   -[no]mmap            ##-- do/don't use mmap for file access (default=do)
   -[no]debug           ##-- do/don't enable painful debugging checks (default=don't)
   -[no]times           ##-- do/don't report operating timing (default=do)
   -output OUT          ##-- output directory or client configuration file (required)

=cut

###############################################################
## DESCRIPTION
###############################################################
=pod

=head1 DESCRIPTION

dcdb-create.perl
compiles a L<DiaColloDB|DiaColloDB> diachronic collocation database
from a tokenized and annotated input corpus,
or merges multiple existing L<DiaColloDB|DiaColloDB> databases
into a single database directory.
The resulting database can be queried with
the
L<dcdb-query.perl(1)|dcdb-query.perl> script,
or wrapped into a web-service with
the help of the L<DiaColloDB::WWW|DiaColloDB::WWW> utilities,
which see for details.

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

File(s), glob(s), file-list(s) to be indexed or existing indices to be merged.
Interpretation depends on the L<-glob|/-glob>, L<-list|/-list>, L<-union|/-union>,
and L<-lazy|/-lazy>
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

=back

=cut


###############################################################
# Corpus Options
=pod

=head2 Corpus Options

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

Do/don't trate INPUT(s) as DB directories to be merged.
Creates a new physical DB by merging data from the argument
INPUT(s).
Default=don't.

=item -lazy

=item -nolazy

Enable/disable "lazy union" mode.
If enabled, INPUT(s) are treated as DB URLs to be merged "lazily",
and only a simple L<DiaColloDB::Client::list|DiaColloDB::Client::list>
configuration file F<OUT> is created, suitable for passing to
L<dcdb-query.perl|dcdb-query.perl> as F<rcfile://OUT>.  User
options specified with L<-option OPT=VAL|/-option-OPT-VAL> will
clobber the L<DiaColloDB::Client::list|DiaColloDB::Client::list> defaults
(e.g. C<fudge>, C<fork>, etc.). Unlike L<-union|/-union> mode,
no physical DB is created in L<-lazy|/-lazy> mode; queries to the lazy
client are deferred to the underlying DB URLs specified in the configuration
file.  The lazy configuration should behave like a physical DB created with L<-union|/-union>,
can be created in near constant time,
requires only a few bytes of disk space,
and may even process queries faster than a physical DB if you have the
L<forks|forks> module installed.

Default=off.

Aliases: -lazy-union, -list-union, -lu

=item -dclass CLASS

Set corpus document class (default=DDCTabs).
See L<DiaColloDB::Document/SUBCLASSES> for a list
of supported input formats.
If you are using the default L<DDCTabs|DiaColloDB::Document::DDCTabs> document class
on your own (non-D*) corpus, you may also want to specify
L<C<-dopt foreign=1>|/"-dopt OPT=VAL">.

=item -dopt OPT=VAL

Set corpus document option, e.g.
L<C<-dopt eosre=EOSRE>|DDCTabs/new> sets the end-of-sentence regex
for the default L<DDCTabs|DiaColloDB::Document::DDCTabs> document class,
and L<C<-dopt foreign=1|DDCTabs/new> disables D*-specific hacks.

Aliases: -document-option, -docoption, -dO

=item -bysent

Track collocations by sentence (default).

=item -byparagraph

Track collocations by paragraph.

=item -bypage

Track collocations by page.

=item -bydoc

Track collocations by document.

=back

=cut


###############################################################
# Indexing Options
=pod

=head2 Indexing Options

=over 4

=item -attrs ATTRS

Select attributes to be indexed (default=l,p).
Known attributes include C<l, p, w, doc.title, doc.author>, etc.

=item -use-all-the-data

Disables default frequency- and regex-based pruning filter options,
inspired by Mark Lauersdorf; equivalent to:

 -tfmin=0 \
 -lfmin=0 \
 -cfmin=0 \
 -tdf-tfmin=0 \
 -tdf-dfmin=0 \
 -tdf-nmin=0 \
 -tdf-nmax=inf \
 -O=pgood='' \
 -O=wgood='' \
 -O=lgood='' \
 -O=pbad='' \
 -O=wbad='' \
 -O=lbad='' \
 -tO=mgood='' \
 -tO=mbad=''

Aliases: -all, -noprune, -nofilters, -F

=item -64bit

Use 64-bit quads to index integer IDs where available.

=item -32bit

Use 32-bit integers where available (default).

=item -dmax DIST

Specify maximum distance for indexed co-occurrences (default=5).

=item -tfmin TFMIN

Specify minimum global term frequency (default=2).
A "term" in this sense is an n-tuple of indexed attributes
B<not including> the "date" component.

=item -lfmin LFMIN

Specify minimum global lemma frequency (default=undef:TFMIN).

=item -cfmin CFMIN

Specify minimum relation co-occurrence frequency (default=2).

=item -[no]tdf

Do/don't create (term x document) index relation (default=if available).

=item -tdf-dbreak BREAK

Set tdf matrix "document" granularity (e.g. s,p,page,file; default=file).

=item -tdf-fmin VFMIN

Set minimum tdf term frequency (default=undef: use TFMIN).

=item -tdf-dfmin VDFMIN

Set minimum term document-"frequency" (default=4).

=item -tdf-nmin VNMIN

Set minimum number of content tokens per tdf "document" (default=8).

=item -tdf-nmax VNMAX

Set maximum number of content tokens per tdf "document" (default=inf).

=item -tdf-option OPT=VAL

Set arbitrary L<tdf matrixDiaColloDB|DiaColloDB::Relation::TDF> option, e.g.

 minFreq=INT            # -tdf-fmin: minimum term frequency
 minDocFreq=INT         # -tdf-dfmin: minimum term document-"frequency"
 minDocSize=INT         # -tdf-nmin: minimum document size (#/terms)
 maxDocSize=INT         # -tdf-nmax: maximum document size (#/terms)
 mgood=REGEX            # positive regex for document-level metatdata
 mbad=REGEX             # negative regex for document-level metatdata

Alias: -tO

=item -option OPT=VAL

Set arbitrary L<DiaColloDB|DiaColloDB> index option, e.g.

 pack_id=PACKFMT        # pack-format for IDs
 pack_f=PACKFMT         # pack-format for frequencies
 pack_date=PACKFMT      # pack-format for dates
 (p|w|l)good=REGEX      # positive regex for (postags|words|lemmata)
 (p|w|l)bad=REGEX       # negative regex for (postags|words|lemmata)
 (p|w|l)goodfile=REGEX  # positive list-file for (postags|words|lemmata)
 (p|w|l)badfile=REGEX   # negative list-file for (postags|words|lemmata)
 ddcServer=HOST:PORT    # server for ddc relations
 ddcTimeout=SECONDS     # timeout for ddc relations

Alias: -O

=back

=cut

###############################################################
# I/O and Logging Options
=pod

=head2 I/O and Logging Options

=over 4

=item -log-level LEVEL

Set L<DiaColloDB::Logger|DiaColloDB::Logger> log-level (default=TRACE).

=item -log-option OPT=VAL

Set arbitrary L<DiaColloDB::Logger|DiaColloDB::Logger> option (e.g. logdate, logtime, file, syslog, stderr, ...).

=item -[no]keep

Do/don't keep temporary files (default=don't)

=item -[no]mmap

Do/don't use mmap() for low-level index file access (default=do)

=item -[no]debug

Do/don't enable painful debugging checks (default=don't)

=item -[no]times

Do/don't report operating timing (default=do)

=item -output OUT

Output directory or filename (required).

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
L<dcdb-info.perl(1)|dcdb-info.perl>,
L<dcdb-query.perl(1)|dcdb-query.perl>,
L<dcdb-export.perl(1)|dcdb-export.perl>,
L<perl(1)|perl>.

=cut
