#!/usr/bin/perl -w

use lib qw(. ./blib/lib ./blib/arch lib lib/blib/lib lib/blib/arch);
use DiaColloDB;
use DiaColloDB::Utils qw(:json :time);
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
use strict;

#use DiaColloDB::Relation::TDF; ##-- DEBUG

BEGIN {
  select STDERR; $|=1; select STDOUT;
}

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

##-- program vars
our $prog       = basename($0);
our ($help,$version);

our %log        = (level=>'TRACE', rootLevel=>'FATAL');
our $dburl      = undef;
our %cli        = (opts=>{});
our $http_user  = undef;

our $rel  = 'cof';
our %query = (
	      query =>'',	##-- target query, common
	      date  =>undef,    ##-- target date(s), common
	      slice =>1,        ##-- date slice, common
	      ##
	      #aquery=>'',	##-- target query(ta), arg1
	      adate  =>undef,	##-- target date(s), arg1
	      aslice =>undef,	##-- date slice, arg1
	      ##
	      bquery =>'',	##-- target query, arg2
	      bdate  =>undef,	##-- target date(s), arg2
	      bslice =>undef,	##-- date slice, arg2
	      ##
	      groupby=>'l',     ##-- result aggregation (empty:all available attributes, no restrictions)
	      ##
	      eps => 0,		##-- smoothing constant (old default=0.5)
	      score =>'ld',	##-- score func
	      diff=>'adiff',    ##-- diff-op
	      kbest =>10,	##-- k-best items per date
	      cutoff =>undef,	##-- minimum score cutoff
	      global =>0,       ##-- trim globally (vs. slice-locally)?
	      strings => 1,	##-- debug: want strings?
	      onepass => 0,     ##-- use fast but incorrect 1-pass method?
	     );
our %save = (format=>undef);

our $outfmt  = 'text'; ##-- output format: 'text' or 'json'
our $pretty  = 1;
our $dotime  = 1; ##-- report timing?
our $niters  = 1; ##-- number of benchmark iterations

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,

	   ##-- general
	   'log-level|level|log=s' => sub { $log{level} = uc($_[1]); },
	   'client-option|db-option|do|O=s%' => \%cli,
	   'subclient-option|suboption|so|SO=s%' => \$cli{opts},

	   ##-- query options
	   #'difference|diff|D|compare|comp|cmp!' => \$diff,
	   #'profile|prof|prf|P' => sub { $diff=0 },
	   'collocations|collocs|collo|col|cofreqs|cof|co|f12|f2|12|2' => sub { $rel='cof' },
	   'unigrams|ug|u|f1|1' => sub { $rel='xf' },
	   'ddc' => sub { $rel='ddc' },
	   'tdf|tdm|matrix|mat|vector-space|vs|vector|vec' => sub { $rel='tdf' },
	   ##
	   (map {("${_}date|${_}d=s"=>\$query{"${_}date"})} ('',qw(a b))), 				  ##-- date,adate,bdate
	   (map {("${_}date-slice|${_}ds|${_}slice|${_}sl|${_}s=s"=>\$query{"${_}slice"})} ('',qw(a b))), ##-- slice,aslice,bslice
	   ##
	   'group-by|groupby|group|gb|g=s' => \$query{groupby},
	   ##
	   'difference|diff|D|compare|comp|cmp=s' => \$query{diff},
	   'epsilon|eps|e=f'  => \$query{eps},
	   'mutual-information-log-frequency|milf|mi' => sub {$query{score}='milf'},
	   'mutual-information-1|mi1' => sub {$query{score}='mi1'},
	   'mutual-information-3|mi3' => sub {$query{score}='mi3'},
	   'log-dice|logdice|ld|dice' => sub {$query{score}='ld'},
	   'log-likelihood|loglik|logl|ll' => sub {$query{score}='ll'},
	   'frequency|freq|f'         => sub {$query{score}='f'},
	   'frequency-per-million|fpm|fm'  => sub {$query{score}='fm'},
	   'log-frequency|logf|lf' => sub { $query{score}='lf' },
	   'log-frequency-per-million|logfm|lfm' => sub { $query{score}='lfm' },
	   'k-best|kbest|k=i' => \$query{kbest},
	   'no-k-best|nokbest|nok' => sub {$query{kbest}=undef},
	   'cutoff|C=f' => \$query{cutoff},
	   'no-cutoff|nocutoff|noc' => sub {$query{cutoff}=undef},
	   'global|G!' => \$query{global},
	   'local|L!' => sub { $query{global}=!$_[1]; },
	   'strings|S!' => \$query{strings},
	   'one-pass|onepass|1-pass|1pass|1p|single-pass|singlepass|single!' => \$query{onepass},
	   'two-pass|teopass|2-pass|2pass|2p|multi-pass|multipass|multi|mp!' => sub { $query{onepass}=!$_[1]; },

	   ##-- I/O
	   'user|U=s' => \$http_user,
	   'text|t' => sub {$outfmt='text'},
	   'json|j' => sub {$outfmt='json'},
	   'html' => sub {$outfmt='html'},
	   'pretty|p!' => \$pretty,
	   'ugly!' => sub {$pretty=!$_[1]},
	   'null|noout' => sub {$outfmt=''},
	   'score-format|sf|format|fmt=s' => \$save{format},
	   'timing|times|time|T!' => \$dotime,
	   'bench|n-iterations|iterations|iters|i=i' => \$niters,
	  );

if ($version) {
  print STDERR "$prog version $DiaColloDB::VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>1,-verbose=>0,-msg=>"$prog: ERROR: no DBURL specified!"}) if (@ARGV<1);
pod2usage({-exitval=>1,-verbose=>0,-msg=>"$prog: ERROR: no QUERY specified!"}) if (@ARGV<2);


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- setup logger
DiaColloDB::Logger->ensureLog(%log);

##-- parse user options
if ($http_user) {
  my ($user,$pass) = split(/:/,$http_user,2);
  $pass //= '';
  if ($pass eq '') {
    print STDERR "Password: ";
    $pass = <STDIN>;
    chomp $pass;
  }
  @{$cli{opts}}{qw(user password)} = @cli{qw(user password)} = ($user,$pass),
}

##-- open db client
$dburl = shift(@ARGV);
my ($cli);
if ($dburl !~ m{^[a-zA-Z]+://} && -d $dburl) {
  ##-- hack for local directory URLs without scheme
  $cli = DiaColloDB->new(dbdir=>$dburl,%cli);
} else {
  ##-- use client interface for any URL with a scheme
  $cli = DiaColloDB::Client->new($dburl,%cli);
}
die("$prog: failed to create new DiaColloDB::Client object for $dburl: $!") if (!$cli);

##-- client query
do { utf8::decode($_) if (!utf8::is_utf8($_)) } foreach (@ARGV);
our $isDiff = (@ARGV > 1);
$query{query}  = shift;
$query{bquery} = @ARGV ? shift : $query{query};
$rel  = "d$rel" if ($isDiff);

##-- DEBUG queries
if (0 && $query{query} eq 'debug') {
  #$query{query} = '$p=NN !#has[textClass,/politik/i]';
  #$query{query} = 'Mann #has[textClass,/zeitung/i]';
  #$query{query} = '* #has[textClass,/Zeitung/i]';
  #$query{query} = 'Katze && Maus';
  #$query{query} = '* #has[genre,/Zeitung/]';
  #$query{query} = 'Katze && Maus && Hund';
  #$query{query} = 'Mann with $p=NN';
  ##
  #($isDiff,$rel,@query{qw(query bquery slice diff groupby)}) = (1,'dtdf','* #has[author,/Habermas/]','* #has[author,/Cassirer/]',0,'min','l,p=NN');
  #($isDiff,$rel,@query{qw(query bquery slice adate bdate)}) = (1,'d2','Bewegung','Bewegung',0,'1900:1910','1990:2000');
  #($isDiff,$rel,@query{qw(query bquery slice onepass groupby)}) = (1,'d2','Mann','Frau',0,1,'l,p=ADJA');
  #($isDiff,$rel,@query{qw(query bquery slice groupby)}) = (1,'diff-ddc','$p=PAV=2 #has[textClass,/Wiss*/]','$p=PAV=2 #has[textClass,/Bell*/]',0,'l');
  ##
  #($rel,@query{qw(query slice)}) = ('ddc', '$p=ADJA=2 Haus', 0);
  #($rel,@query{qw(query slice)}) = ('tdf', 'Haus', 0);
  ##
  #($rel,@query{qw(query groupby slice date)}) = ('cof','Mann','l,p=ADJA',0,'1914:1915');
  #($rel,@query{qw(query groupby slice date)}) = ('ug','/mann$/i','l,p=NN',0,'1914:1915');
  #($rel,@query{qw(query groupby slice date)}) = ('tdf','Mann','l,p=ADJA',0,'1914:1915'); ##-- TODO
  #
  #($rel,@query{qw(query groupby slice)}) = ('ddc','"$p=ADJA=2 Mann"','l,p',0);
  #($rel,@query{qw(query groupby slice)}) = ('ddc','"$p=ADJA=2 Kaffee"','l',0);
  ##
  ($rel,@query{qw(query date groupby slice)}) = ('ddc','near(flood,{frequency,uncertainty,risk}=2,8) #fmin 1', 2004, '[@const]', 1);
}
##--/DEBUG queries

if ($niters != 1) {
  $cli->info("performing $niters query iterations");
}
my $timer = DiaColloDB::Timer->start();
foreach my $iter (1..$niters) {
  my $mp = $cli->query($rel, %query)
    or die("$prog: query() failed for relation '$rel', query '$query{query}'".($isDiff ? " - '$query{bquery}'" : '').": $cli->{error}");

  ##-- dump stringified query
  my $outfile = ($iter==1 ? '-' : '/dev/null');
  if ($outfmt eq 'text') {
    $mp->trace("saveTextFile()");
    $mp->saveTextFile($outfile,%save);
  }
  elsif ($outfmt eq 'json') {
    $mp->trace("saveJsonFile()");
    $mp->saveJsonFile($outfile, pretty=>$pretty,canonical=>$pretty); #utf8=>0
  }
  elsif ($outfmt eq 'html') {
    $mp->trace("saveHtmlFile()");
    $mp->saveHtmlFile($outfile,verbose=>!$pretty,%save);
  }
}

##-- cleanup
$cli->close();

##-- timing
if ($dotime || $niters > 1) {
  $cli->info("operation completed in ", $timer->timestr,
	     ($niters > 1 ? sprintf(" (%.2f iter/sec)", $niters/$timer->elapsed) : qw()),
	    );
}


__END__

###############################################################
## pods
###############################################################
=pod

=encoding utf8

=head1 NAME

dcdb-query.perl - query a DiaColloDB diachronic collocation database

=head1 SYNOPSIS

 dcdb-query.perl [OPTIONS] DBURL QUERY1 [QUERY2]

 General Options:
   -help                 # display a brief usage summary
   -version              # display program version
   -[no]time             # do/don't report operation timing (default=do)
   -iters NITERS         # benchmark NITERS iterations of query

 Query Options:
   -col, -ug, -ddc, -tdf # select profile type (collocations, unigrams, ddc client, tdf matrix; default=-col)
   -(a|b)?date DATES     # set target DATE or /REGEX/ or MIN-MAX
   -(a|b)?slice SLICE    # set target date slice (default=1)
   -groupby GROUPBY      # set result aggregation (default=l)
   -kbest KBEST          # return only KBEST items per date-slice (default=10)
   -nokbest              # disable k-best pruning
   -cutoff CUTOFF        # set minimum score for returned items (default=none)
   -nocutoff             # disable cutoff pruning
   -[no]global           # do/don't trim profiles globally (vs. locally by date-slice; default=don't)
   -[no]strings          # debug: do/don't stringify returned profile (default=do)
   -1pass , -2pass       # do/don't use fast but incorrect 1-pass method (default=don't)
   -O  KEY=VALUE         # set DiaColloDB::Client option
   -SO KEY_=VALUE        # set sub-client option (for list:// clients)

 Scoring Options:
   -f                    # score by raw frequency
   -lf                   # score by log-frequency
   -fm                   # score by frequency per million tokens
   -lfm                  # score by log-frequency per million tokens
   -milf                 # score by pointwise mutual information x log-frequency product
   -mi1                  # score by raw pointwise mutual information
   -mi3                  # score by pointwise mutual information^3 (Rychlý 2008)
   -ld                   # score by scaled log-Dice coefficient (Rychlý 2008)
   -ll                   # score by 1-sided log-likelihood ratio (Evert 2008)
   -eps EPS              # smoothing constant (default=0)
   -diff DIFFOP          # diff operation (adiff|diff|sum|min|max|avg|havg|gavg; default=adiff)

 I/O Options:
   -user USER[:PASSWD]   # user credentials for HTTP queries
   -text		 # use text output (default)
   -json                 # use json output
   -null                 # don't output profile at all
   -[no]pretty           # do/don't pretty-print json output (default=do)
   -log-level LEVEL      # set minimum DiaColloDB log-level

 Arguments:
   DBURL                # DB URL (file://, rcfile://, http://, or list://)
   QUERY1               # space-separated target1 string(s) LIST or /REGEX/ or DDC-query
   QUERY2               # space-separated target2 string(s) LIST or /REGEX/ or DDC-query (for diff profiles)

 Grouping and Filtering:
   GROUPBY is a space- or comma-separated list of the form ATTR1[=FILTER1] ..., where:
   - ATTR is the name or alias of a supported attribute (e.g. 'lemma', 'pos', etc.), and
   - FILTER is either a |-separated LIST of literal values or a /REGEX/[gimsadlu]*

 Diff Operations:
   DIFF is one of: adiff diff sum min max avg havg gavg lavg

=cut

###############################################################
## DESCRIPTION
###############################################################
=pod

=head1 DESCRIPTION

dcdb-query.perl
is a command-line utility for querying a
L<DiaColloDB|DiaColloDB> diachronic collocation database.

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

=item DBURL

URL identifying the L<DiaColloDB|DiaColloDB>
database to be queried,
in a form accepted by L<DiaColloDB::Client-E<gt>open()|DiaColloDB::Client/open>.
In particular, I<DBURL> can be a local L<DiaColloDB|DiaColloDB> database directory,
in which case it will be queried via
the L<DiaColloDB::Client::file|DiaColloDB::Client::file> class.
A local L<DiaColloDB::Client|DiaColloDB::Client> configuration file L<RCFILE>
can be specified using the F<rcfile://RCFILE> syntax.

=item QUERY1

Primary target query as accepted by
L<DiaColloDB-E<gt>parseQuery|DiaColloDB/parseQuery>,
usually a space-separated of target string(s) C<LIST>,
a target C</REGEX/> or a DDC-query string.

=item QUERY2

Optional comparsion target query.
If specified, a "diff" profile is computed
as for L<DiaColloDB::compare()|DiaColloDB/compare>,
otherwise a unary profile is computed
as for L<DiaColloDB::profile()|DiaColloDB/profile>.

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

=item -time

=item -notime

Do/don't report operation timing (default=do).

=item -iters NITERS

Benchmark NITERS iterations of query (default=1).

=back

=cut

###############################################################
# Query Options
=pod

=head2 Query Options

=over 4

=item -col

Request "collocation" profiling via L<DiaColloDB::Relation::Cofreqs|DiaColloDB::Relation::Cofreqs> (default).

=item -ug

Request "unigram" profiling via L<DiaColloDB::Relation::Unigrams|DiaColloDB::Relation::Unigrams>

=item -ddc

Request profiling via L<DiaColloDB::Relation::DDC|DiaColloDB::Relation::DDC>.
Slow and generally inefficient, but very flexible.
Requires that the underlying DB be associated with a DDC server,
e.g. by means of the L<C<ddcServer>|DiaColloDB/new> DB key.

=item -tdf

Request (term x document) matrix profiling via L<DiaColloDB::Relation::TDF|DiaColloDB::Relation::TDF>.
Requires TDF support in the underlying DB.

=item -date DATES

=item -adate DATES

Set L<primary target|/QUERY1> date C<DATE> or C</REGEX/> or date-range C<MIN:MAX>.
Either C<MIN> or or C<MAX> may be an asterisk (C<*>) to indicate the
minimum rsp. maximum date indexed in the corpus.

=item -bdate DATES

As for L<-adate|/-adate DATES>, but specifies date for the
L<comparison target|/QUERY2>.

=item -slice SLICE

=item -aslice SLICE

Set the L<primary target|/QUERY1> date slice (default=1).

=item -bslice SLICE

Set the L<comparison target|/QUERY2> date slice (default=1).

=item -groupby GROUPBY

Aggregate collocates by the attributes specified in
I<GROUPBY>, which should be a list of indexed attributes
with optional restriction clauses as accepted by
L<DiaColloDB-E<gt>parseQuery|DiaColloDB/parseQuery>,
or (in L<-ddc|/-ddc> mode only) a DDC L<count-by list|http://odo.dwds.de/~moocow/software/ddc/ddc_query.html#rule_l_countkeys>
enclosed in square brackets C<[ I<l_countkeys> ]>.

=item -kbest KBEST

Return only KBEST items per date-slice (default=10).

=item -nokbest

Disable k-best pruning.

=item -cutoff CUTOFF

Set minimum score for returned items (unary profiles only; default=none).

=item -nocutoff

Disable cutoff pruning.


=item -[no]global

Do/don't trim profiles globally (vs. locally by date-slice; default=don't).

=item -[no]strings

Debug: do/don't stringify returned profile (default=do).

=item -1pass

Use fast but incorrect single-pass frequency acquisition method.

=item -2pass

Use slower but correct 2-pass frequency acqusition method (default).

=item -O KEY=VALUE

Set a L<DiaColloDB::Client|DiaColloDB::Client> option.

=back

=cut


###############################################################
# Scoring Options
=pod

=head2 Scoring Options

See L<DiaColloDB::Profile|DiaColloDB::Profile> for supported scoring functions.

=over 4

=item -f

score by raw frequency

=item -lf

score by log-frequency

=item -fm

score by frequency per million tokens

=item -lfm

score by log-frequency per million tokens

=item -milf

score by pointwise mutual information x log-frequency product

=item -mi1

score by raw pointwise mutual information

=item -mi3

score by pointwise mutual information^3 (Rychlý 2008)

=item -ld

score by scaled log-Dice coefficient (Rychlý 2008; default)

=item -ll

score by 1-sided log-likelihood ratio (Evert 2008)

=item -eps EPS

score function smoothing constant  (default=0.5)

=item -diff DIFFOP

diff operation to use for
L<comparison profiles|/QUERY2>.
Known values:

 adiff  # absolute score difference (default)
 diff   # raw score difference
 sum    # sum
 min    # minimum
 max    # maximum
 avg    # average
 havg   # pseudo-harmonic average
 gavg   # pseudo-geometric average

=back

=cut

###############################################################
# I/O and Logging Options
=pod

=head2 I/O and Logging Options

=over 4 

=item -user USER[:PASSWD]

Specify user credentials for HTTP queries

=item -text

generate text output (default).

=item -json

generate json output.

=item -html

generate HTML output.

=item -null

don't output profile data at all (for timing and debugging).

=item -[no]pretty

do/don't pretty-print json output (default=do)

=item -score-format FORMAT

L<sprintf|perlfunc/sprintf>-format for score formatting,
used by text and HTML output modes.

=item -log-level LEVEL

set minimum L<DiaColloDB::Logger|DiaColloDB::Logger> log-level.

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
L<dcdb-create.perl(1)|dcdb-create.perl>,
L<dcdb-info.perl(1)|dcdb-info.perl>,
L<dcdb-export.perl(1)|dcdb-export.perl>,
perl(1).

=cut
