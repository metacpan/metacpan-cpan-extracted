## -*- Mode: CPerl -*-
## File: DiaColloDB::Corpus::Compiled.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, source corpus (pre-compiled)

package DiaColloDB::Corpus::Compiled;

use DiaColloDB::threads;
use DiaColloDB::threads::shared;
our ($HAVE_THREADS);
BEGIN {
  $HAVE_THREADS = $DiaColloDB::threads::shared::MODULE ? 1 : 0;
}

use DiaColloDB::Corpus;
use DiaColloDB::Corpus::Filters;
use DiaColloDB::Logger;
use DiaColloDB::Utils qw(:fcntl :jobs);
use File::Basename qw(basename dirname);
use File::Path qw(make_path remove_tree);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Persistent DiaColloDB::Corpus);

##==============================================================================
## Constructors etc.

## $corpus = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- NEW in DiaColloDB::Corpus::Compiled
##    dbdir   => $dbdir,     ##-- data directory for compiled corpus
##    flags   => $flags,     ##-- open mode flags (fcntl flags or perl-style; default='r')
##    filters => \%filters,  ##-- corpus filters ( DiaColloDB::Corpus::Filters object or HASH-ref )
##    njobs   => $njobs,     ##-- number of parallel worker jobs for create(); default=-1 (= nCores)
##    temp    => $bool,      ##-- implicitly unlink() on exit?
##    logThreads => $level   ##-- log-level for thread stuff (default='off')
##    ##
##    ##-- INHERITED from DiaColloDB::Corpus
##    #files => \@files,      ##-- source files (OVERRIDE: unused)
##    #dclass => $dclass,     ##-- DiaColloDB::Document subclass for loading (OVERRIDE force 'DiaColloDB::Document::JSON')
##    dopts  => \%opts,      ##-- options for $dclass->fromFile() (override default={})
##    cur    => $i,          ##-- index of current file
##    logOpen => $level,     ##-- log-level for open(); default='info'
##   )
sub new {
  my $that = shift;
  my $corpus  = $that->SUPER::new(
                                  ##-- new
                                  dbdir  => undef,
                                  flags  => 'r',
                                  #filters => DiaColloDB::Corpus::Filters->new(),
                                  #temp    => 0,
                                  #opened => 0,
                                  njobs => -1,
                                  logThreads => 'off',

                                  @_, ##-- user arguments

                                  ##-- strong overrides
                                  dclass => 'DiaColloDB::Document::JSON',
                                 );
  $corpus->{filters} = DiaColloDB::Corpus::Filters->new() if (!exists($corpus->{filters}));
  return $corpus->open() if (defined($corpus->{dbdir}));
  return $corpus;
}

sub DESTROY {
  my $obj = $_[0];
  $obj->unlink() if ($obj->{temp});
  $obj->close() if ($obj->opened);
}

##==============================================================================
## Persistent API

## @keys = $obj->headerKeys()
##  + keys to save as header; default implementation returns all keys of all non-references
sub headerKeys {
  return (grep {$_ !~ m{^log|^(?:cur|dbdir|njobs|opened|flags|files|list|glob|compiled|append|temp)$}} keys %{$_[0]});
}

## @files = $obj->diskFiles()
##  + returns disk storage files, used by du() and timestamp()
##  + default implementation returns $obj->{file} or glob("$obj->{base}*")
sub diskFiles {
  my $obj = shift;
  return ($obj->{dbdir}) if ($obj->{dbdir});
  return qw();
}

## $bool = $obj->unlink(%opts)
##  + override %opts:
##      close => $bool,  ##-- implicitly call $obj->close() ? (default=1)
##  + unlinks disk files
##  + implcitly calls $obj->close() if available
sub unlink {
  my ($obj,%opts) = @_;
  my $dbdir = $obj->datadir;
  #$obj->vlog($obj->{logOpen}, "unlink(", $obj->dbdir, ")") if ($obj->opened);
  $obj->close() if (!exists($opts{close}) || $opts{close});
  return (-e $dbdir ? File::Path::remove_tree($dbdir) : 1);
}

##----------------------------------------------------------------------
## Compiled API: disk files etc.

## $dirname = $corpus->datadir()
## $dirname = $corpus->datadir($dir)
BEGIN { *dbdir = \&datadir; }
sub datadir {
  my $dir = $_[1] // $_[0]{dbdir};
  $dir =~ s{/$}{} if ($dir);
  return $dir;
}

## $bool = $corpus->truncate()
##  + removes all disk data (including header) and resets $corpus->{size}=0
sub truncate {
  my $corpus = shift;
  return undef if (!$corpus->unlink(close=>0));
  $corpus->{size} = 0;
  return $corpus;
}

## $filters = $ccorpus->filters()
##  + return corpus filters as a DiaColloDB::Corpus::Filters object
sub filters {
  return $_[0]{filters} if (UNIVERSAL::isa($_[0]{filters},'DiaColloDB::Corpus::Filters'));
  return DiaColloDB::Corpus::Filters->null() if (!defined($_[0]{filters}));
  return DiaColloDB::Corpus::Filters->new( %{$_[0]{filters}} );
}

##==============================================================================
## Corpus API: open/close

## $bool = $corpus->open([$dbdir], %opts);  ##-- compat
## $bool = $corpus->open($dbdir,   %opts);  ##-- new
##  + opens corpus "$base.*"
##  + \@ARGV should be a single-element $dbdir, or (dbdir=>$dbdir) must exist or be specified in %opts
##  + DiaColloDB::Corpus %opts:
##     compiled => $bool, ##-- implicit
##     glob => $bool,     ##-- (ignored) whether to glob arguments
##     list => $bool,     ##-- (ignored) whether arguments are file-lists
sub open {
  my ($corpus,$argv,%opts) = @_;
  delete @opts{qw(compiled glob list)};
  $corpus  = $corpus->new() if (!ref($corpus));
  $corpus->close() if ($corpus->opened);
  @$corpus{keys %opts} = values(%opts);

  ##-- sanity check(s): dbdir
  my $dbdir = $corpus->dbdir;
  if (UNIVERSAL::isa($argv,'ARRAY')) {
    if (@$argv==1) {
      $dbdir = $argv->[0]; ##-- single-element list
    } else {
      $corpus->logconfess("open(): can't handle multi-element array");
    }
  } elsif (defined($argv)) {
    $dbdir = $argv;      ##-- simple scalar
  }
  $corpus->{dbdir} = $corpus->dbdir($dbdir)
    or $corpus->logconfess("open(): no {dbdir} specified!");

  my $flags = $corpus->{flags} = (fcflags($corpus->{flags}) | ($corpus->{append} ? fcflags('>>') : 0));
  $corpus->vlog($corpus->{logOpen}, "open(", fcperl($flags), "$dbdir)");

  ##-- flag-dependent dispatch
  if (fcwrite($flags) && fctrunc($flags)) {
    ##-- truncate: remove any stale corpus
    $corpus->truncate()
      or $corpus->logconfess("open(): failed to truncate stale corpus $corpus->{dbdir}/: $!");
  }
  if (fcwrite($flags) && fccreat($flags)) {
    ##-- create: data-directory
    my $datadir = $corpus->datadir;
    -d $datadir
      or make_path($datadir)
      or $corpus->logconfess("open(): could not create data directory '$datadir': $!");
  }
  if (fcread($flags) && !fctrunc($flags)) {
    ##-- read-only, no create
    $corpus->loadHeaderFile
      or $corpus->logconfess("open(): failed to load header-file ", $corpus->headerFile);
  }

  ##-- force options: dclass, files, opened
  $corpus->{opened} = 1;
  $corpus->{dclass} = 'DiaColloDB::Document::JSON';
  delete $corpus->{files};

  return $corpus;
}

## $bool = $corpus->close()
sub close {
  my $corpus = shift;
  $corpus->vlog($corpus->{logOpen}, "close(", $corpus->dbdir, ")") if ($corpus->opened);
  my $rc = ($corpus->opened && fcwrite($corpus->{flags}) ? $corpus->flush : 1);
  $rc &&= $corpus->SUPER::close();
  if ($rc) {
    $corpus->{opened} = 0;
    $corpus->{size}   = 0;
  }
  return $rc;
}

##----------------------------------------------------------------------
## Compiled API: open/close

## $bool = $corpus->opened()
## + Returns true iff $corpus is currently opened.
sub opened {
  my $corpus = shift;
  return $corpus->{dbdir} && $corpus->{opened};
}

## $bool = $corpus->flush()
## + flush pending data (header) to disk
sub flush {
  my $corpus = shift;
  return undef if (!$corpus->opened || !fcwrite($corpus->{flags}));
  $corpus->saveHeader()
    or $corpus->logconfess("flush(): failed to store header file ", $corpus->headerFile, ": $!");
}

## $corpus = $corpus->reopen(%opts)
## + close and re-open corpus (e.g. with different flags)
sub reopen {
  my $corpus = shift;
  my $dbdir  = $corpus->{dbdir};
  return $corpus if (!$corpus->opened);
  return $corpus->close() && $corpus->open([$dbdir], @_);
}

##==============================================================================
## Corpus API: iteration
##  + mostly inherited from DiaColloDB::Corpus

## $nfiles = $corpus->size()
sub size {
  return $_[0]{size} // 0;
}

## $bool = $corpus->iok()
##  + true if iterator is valid
sub iok {
  return $_[0]{cur} < ($_[0]{size}//0);
}

## $label = $corpus->ifile()
## $label = $corpus->ifile($pos)
##  + current iterator label
sub ifile {
  my $pos = $_[1] // $_[0]{cur};
  return undef if ($pos >= $_[0]{size});
  return "$_[0]{dbdir}/$pos.json";
}

## $doc_or_undef = $corpus->idocument()
## $doc_or_undef = $corpus->idocument($pos)
##  + gets current document
sub idocument {
  my ($corpus,$pos) = @_;
  $pos //= $corpus->{cur};
  return undef if ($pos >= $corpus->size);
  return $corpus->{dclass}->fromFile($corpus->ifile($pos), %{$corpus->{dopts}//{}});
}


##==============================================================================
## Corpus::Compiled API: corpus compilation

## $ccorpus = CLASS_OR_OBJECT->create($src_corpus, %opts)
##  + compile or append a single $src_corpus to $opts{dbdir}, returns $ccorpus
##  + honors $opts{flags} for append and truncate
sub create {
  my ($that,$icorpus,%opts) = @_;
  my $ocorpus = ref($that) ? $that : $that->new();
  my $logas = 'create()';
  $ocorpus->vlog('info',$logas);

  ##-- save options
  my $odir = $ocorpus->dbdir($opts{dbdir})
    or $ocorpus->logconfess("$logas: no output corpus {dbdir} specified");

  my $flags = (fcflags($ocorpus->{flags}) | fcflags($opts{flags})) || fcflags('w');
  delete $opts{dbdir};

  ##-- (re-)open output corpus
  if (!$ocorpus->opened || ($ocorpus->{dbdir} ne $odir)) {
    $ocorpus->open([$odir], %opts, flags=>$flags)
      or $ocorpus->logconfess("$logas: failed to (re-)open output corpus '$odir' in mode '", fcperl($flags));
  }
  @$ocorpus{keys %opts} = values %opts;

  ##-- check whether we're doing any filtering at all
  my $filters  = $ocorpus->filters();
  my $dofilter = !$filters->isnull();
  if ($dofilter) {
    $ocorpus->vlog('info', "$logas: corpus content filters enabled");
    foreach (grep {defined($filters->{$_})} sort keys %$filters) {
      $ocorpus->vlog('info', "  + filter $_ => $filters->{$_}");
    }
  } else {
    $ocorpus->vlog('info', "$logas: corpus content filters disabled");
  }

  ##-- common data
  my $nfiles   = $icorpus->size();
  my $logFileN = $ocorpus->{logFileN} || int($nfiles / 20) || 1;
  my @outkeys  = keys %{DiaColloDB::Document->new};

  my $osize    = $ocorpus->size();
  my $outdir   = $ocorpus->datadir();

  my $filei_shared = 0;
  share( $filei_shared );

  ##--------------------------------------------
  my $cb_worker = sub {
    my $thrid = shift || DiaColloDB::threads->tid();
    $logas .= "#$thrid";
    (*STDERR)->autoflush(1);
    $ocorpus->vlog($ocorpus->{logThreads}, "$logas: starting worker thread #$thrid");

    ##-- initialize: disable auto-deletion
    $ocorpus->{temp} = 0;

    ##-- initialize filters (formerly in DiaColloDB.pm)
    my $cfilters = $dofilter ? $filters->compile() : {}
      or $ocorpus->logconfess("$logas: failed to compile corpus content filters: $!");
    ##
    ##-- initialize: filters: variables
    my ($pgood, $pbad, $wgood, $wbad, $lgood, $lbad ) = @$cfilters{map {("${_}good","${_}bad")} qw(p w l)};
    my ($pgoodh,$pbadh,$wgoodh,$wbadh,$lgoodh,$lbadh) = @$cfilters{map {("${_}goodfile","${_}badfile")} qw(p w l)};
    my ($tok,$w,$p,$l);

    my ($filei);
    while (1) {
      {
        lock($filei_shared);
        $filei = $filei_shared;
        ++$filei_shared;
      }
      last if ($filei >= $nfiles);

      my $idoc    = $icorpus->idocument($filei);
      my $infile  = $icorpus->ifile($filei);
      my $outfile = "$outdir/".($filei+$osize).".json";

      #$ocorpus->vlog('info', sprintf("processing files [%3.0f%%]: %s -> %s", 100*($filei-1)/$nfiles, $infile, $outfile))
      $ocorpus->vlog('info', sprintf("%s: processing files [%3.0f%%]: %s", $logas, 100*($filei-1)/$nfiles, $infile))
        if ($logFileN && ($filei % $logFileN)==0);

      ##-- apply filters
      if ($dofilter) {
        my $ftokens = [];
        foreach $tok (@{$idoc->{tokens}}) {
          if (ref($tok)) {
            ##-- normal token: apply filters
            ($w,$p,$l) = @$tok{qw(w p l)};
            next if ((defined($pgood)    && $p !~ $pgood) || ($pgoodh && !exists($pgoodh->{$p}))
                     || (defined($pbad)  && $p =~ $pbad)  || ($pbadh  &&  exists($pbadh->{$p}))
                     || (defined($wgood) && $w !~ $wgood) || ($wgoodh && !exists($wgoodh->{$w}))
                     || (defined($wbad)  && $w =~ $wbad)  || ($wbadh  &&  exists($wbadh->{$w}))
                     || (defined($lgood) && $l !~ $lgood) || ($lgoodh && !exists($lgoodh->{$l}))
                     || (defined($lbad)  && $l =~ $lbad)  || ($lbadh  &&  exists($lbadh->{$l}))
                    );
          }
          push(@$ftokens,$tok) if (defined($tok) || (@$ftokens && defined($ftokens->[$#$ftokens])));
        }
        $idoc->{tokens} = $ftokens;
      }

      ##-- create output document
      my $odoc = {};
      @$odoc{@outkeys} = @$idoc{@outkeys};

      ##-- dump output document (json)
      DiaColloDB::Utils::saveJsonFile($odoc,$outfile, pretty=>0,canonical=>0)
          or $ocorpus->logconfess("$logas: failed to save JSON data for '$infile' to '$outfile': $!");
    }

    $ocorpus->vlog($ocorpus->{logThreads}, "$logas: worker thread #$thrid exiting normally");
    $ocorpus->{logOpen} = 'off'; ##-- suppress 'close()' messages from worker threads
  };
  ##--/cb_worker

  ##-- spawn workers
  my $njobs = nJobs($ocorpus->{njobs});
  if ($njobs==0 || !$HAVE_THREADS) {
    $ocorpus->info("$logas: running in serial mode");
    $cb_worker->(0);
  } else {
    $ocorpus->info("$logas: running in parallel mode with $njobs job(s)");
    my @workers = (map {threads->new($cb_worker,$_)} (1..$njobs));
    foreach my $thrid (1..$njobs) {
      my $worker = $workers[$thrid-1];
      $worker->join();
      if (defined(my $err=$worker->error)) {
        $ocorpus->logconfess("$logas: error for worker thread #$thrid: $err");
      }
    }
  }

  ##-- adopt list of compiled files
  $ocorpus->{size} += $nfiles;

  ##-- save header (happens implicitly on DESTROY() via close())
  #$ocorpus->saveHeader()
  #  or $ocorpus->logconfess("$logas: failed to save header file ", $ocorpus->headerFile, ": $!");

  return $ocorpus;
}


##==============================================================================
## Corpus::Compiled API: union

## $ccorpus = $ccorpus->union(\@sources, %opts)
##  + merge source corpora \@sources to $opts{dbdir}, destructive
##  + each $src in \@sources is either a Corpus::Compiled object or a simple scalar (dbdir of a Corpus::Compiled object)
##  + honors $opts{flags} for append and truncate
##  + no filters are applied
sub union {
  my ($that,$sources,%opts) = @_;
  my $ocorpus = ref($that) ? $that : $that->new();
  my $logas = 'union()';
  $ocorpus->vlog('info',$logas);

  ##-- save options before open()
  my $odir = $ocorpus->dbdir($opts{dbdir})
    or $ocorpus->logconfess("$logas: no output corpus {dbdir} specified");
  my $flags = (fcflags($ocorpus->{flags}) | fcflags($opts{flags})) || fcflags('w');
  delete $opts{dbdir};

  ##-- (re-)open output corpus
  if (!$ocorpus->opened || ($ocorpus->{dbdir} ne $odir)) {
    $ocorpus->open([$odir], %opts, flags=>$flags)
      or $ocorpus->logconfess("$logas: failed to (re-)open output corpus '$odir' in mode '", fcperl($flags));
  }
  @$ocorpus{keys %opts} = values %opts;

  ##-- union: guts
  foreach my $src (UNIVERSAL::isa($sources,'ARRAY') ? @$sources : $sources) {
    my $idir    = ref($src) ? $src->{dbdir} : $src;
    $ocorpus->vlog('info',"$logas: processing $idir");

    my $icorpus = ref($src) ? $src : DiaColloDB::Corpus::Compiled->new(dbdir=>$src,logOpen=>undef)
      or $ocorpus->logconfess("union(): failed to open input corpus '$src': $!");

    my $nifiles = $icorpus->{size};
    my $osize   = $ocorpus->size;

    my ($filei,$infile,$outfile);
    for ($filei=0; $filei < $nifiles; ++$filei) {
      $infile  = $icorpus->ifile($filei);
      $outfile = "$odir/".($filei+$osize).".json";

      ##-- link
      link($infile,$outfile)
        or symlink($infile,$outfile)
        or $ocorpus->logconfess("union(): failed to create output link $outfile -> $infile: $!");
    }
    $ocorpus->{size} += $nifiles;
  }

  ##-- all done
  #$ocorpus->vlog('info', "merged ", scalar(@$sources), " input corpora to $odir");
  return $ocorpus;
}


##==============================================================================
## Footer
1;

__END__




