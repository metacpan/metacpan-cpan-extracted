## -*- Mode: CPerl -*-
## File: DiaColloDB.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, top-level

package DiaColloDB;
use 5.010; ##-- v5.10.0: for // operator

use DiaColloDB::Compat;
use DiaColloDB::Client;
use DiaColloDB::Logger;
use DiaColloDB::EnumFile;
#use DiaColloDB::EnumFile::Identity;
use DiaColloDB::EnumFile::FixedLen;
use DiaColloDB::EnumFile::FixedMap;
use DiaColloDB::EnumFile::MMap;
use DiaColloDB::EnumFile::Tied;
use DiaColloDB::MultiMapFile;
use DiaColloDB::MultiMapFile::MMap;
use DiaColloDB::PackedFile;
use DiaColloDB::PackedFile::MMap;
use DiaColloDB::Relation;
use DiaColloDB::Relation::Unigrams;
use DiaColloDB::Relation::Cofreqs;
use DiaColloDB::Relation::DDC;
#use DiaColloDB::Relation::TDF; ##-- loaded on-demand
use DiaColloDB::Profile;
use DiaColloDB::Profile::Multi;
use DiaColloDB::Profile::MultiDiff;
use DiaColloDB::Corpus;
use DiaColloDB::Corpus::Compiled;
use DiaColloDB::Corpus::Filters qw(:defaults);
use DiaColloDB::Persistent;
use DiaColloDB::Utils qw(:math :fcntl :json :sort :pack :regex :file :si :run :env :temp :jobs);
#use DiaColloDB::Temp::Vec;
use DiaColloDB::Timer;
use DDC::Any; ##-- for query parsing
use Fcntl;
use File::Path qw(make_path remove_tree);
use version;
use strict;


##==============================================================================
## Globals & Constants

our $VERSION = "0.12.013";
our @ISA = qw(DiaColloDB::Client);

## $TDF_MGOOD_DEFAULT
##  + default positive meta-field regex for document parsing (tdf only)
##  + don't use qr// here, since Storable doesn't like pre-compiled Regexps
our $TDF_MGOOD_DEFAULT = q/^(?:author|pnd|title|basename|collection|flags|textClass|genre)$/;

## $TDF_MBAD_DEFAULT
##  + default negative meta-field regex for document parsing (tdf only)
##  + don't use qr// here, since Storable doesn't like pre-compiled Regexps.
our $TDF_MBAD_DEFAULT = q/_$/;

## $ECLASS
##  + enum class
#our $ECLASS = 'DiaColloDB::EnumFile';
our $ECLASS = 'DiaColloDB::EnumFile::MMap';

## $XECLASS
##  + fixed-length enum class
#our $XECLASS = 'DiaColloDB::EnumFile::FixedLen';
our $XECLASS = 'DiaColloDB::EnumFile::FixedLen::MMap';

## $MMCLASS
##  + multimap class
#our $MMCLASS = 'DiaColloDB::MultiMapFile';
our $MMCLASS = 'DiaColloDB::MultiMapFile::MMap';

## %TDF_OPTS : tdf: default options for DiaColloDB::Relation::TDF->new()
our %TDF_OPTS = (
		 mgood => $TDF_MGOOD_DEFAULT, ##-- positive filter regex for metadata attributes
		 mbad  => $TDF_MBAD_DEFAULT,  ##-- negative filter regex for metadata attributes
		 ##
		 minFreq=>undef,    ##-- minimum total term-frequency for model inclusion (default=from $coldb->{tfmin})
		 minDocFreq=>4,     ##-- minimim "doc-frequency" (#/docs per term) for model inclusion
		 minDocSize=>4,     ##-- minimum doc size (#/tokens per doc) for model inclusion (default=8; formerly $coldb->{vbnmin})
	                            ##   + for kern[page?] (n:%sigs,%toks): 1:0%,0%, 2:5.1%,0.5%, 4:18%,1.6%, 5:22%,2.3%, 8:34%,4.6%, 10:40%,6.5%, 16:54%,12.8%
		 maxDocSize=>'inf', ##-- maximum doc size (#/tokens per doc) for model inclusion (default=inf; formerly $coldb->{vbnmax})
		 ##
		 #smoothf=>1,       ##-- smoothing constant
		 #saveMem=>1, 	    ##-- slower but memory-friendlier compilation
		 ##
		 vtype=>'float',    ##-- store compiled values as 32-bit floats
		 itype=>'long',     ##-- store compiled indices as 32-bit integers
                );

## $NJOBS
##  + number of parallel jobs for various operations
##  + setting this to 0 (zero) will run in pure serial
##  + on unix/linux, setting this to "-1" will use the total number of cores on your system,
##    otherwise behaves like 0
our $NJOBS = -1;

##==============================================================================
## Constructors etc.

## $coldb = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- options
##    dbdir => $dbdir,    ##-- database directory; REQUIRED
##    flags => $fcflags,  ##-- fcntl flags or open()-style mode string; default='r'
##    attrs => \@attrs,   ##-- index attributes (input as space-separated or array; compiled to array); default=undef (==>['l'])
##                        ##    + each attribute can be token-attribute qw(w p l) or a document metadata attribute "doc.ATTR"
##                        ##    + document "date" attribute is always indexed
##    info => \%info,     ##-- additional data to return in info() method (e.g. collection, maintainer)
##    #bos => $bos,        ##-- special string to use for BOS, undef or empty for none (default=undef) DISABLED
##    #eos => $eos,        ##-- special string to use for EOS, undef or empty for none (default=undef) DISABLED
##    pack_id => $fmt,    ##-- pack-format for IDs (default='N')
##    pack_f  => $fmt,    ##-- pack-format for frequencies (default='N')
##    pack_date => $fmt,  ##-- pack-format for dates (default='n')
##    pack_off => $fmt,   ##-- pack-format for file offsets (default='N')
##    pack_len => $len,   ##-- pack-format for string lengths (default='n')
##    dmax  => $dmax,     ##-- maximum distance for collocation-frequencies and implicit ddc near() queries (default=5)
##    cfmin => $cfmin,    ##-- minimum co-occurrence frequency for Cofreqs and ddc queries (default=2)
##    tfmin => $tfmin,    ##-- minimum global term-frequency WITHOUT date component (default=2)
##    fmin_${a} => $fmin, ##-- minimum independent frequency for value of attribute ${a} (default=undef:from $tfmin)
##    keeptmp => $bool,   ##-- keep temporary files? (default=0)
##    mmap => $bool,      ##-- use mmap() subclasses if available? (default: true)
##    debug => $bool,     ##-- enable painful debugging code? (default: false)
##    index_tdf => $bool, ##-- tdf: create/use (term x document) frequency matrix index? (default=undef: if available)
##    index_cof => $bool, ##-- cof: create/use co-frequency index (default=1)
##    index_xf => $bool,  ##-- xf: create/use unigram index (default=1)
##    dbreak => $dbreak,  ##-- tdf: use break-type $break for tdf index (default=undef: files)
##    tdfopts=>\%tdfopts, ##-- tdf: options for DiaColloDB::Relation::TDF->new(); default=undef (all inherited from %TDF_OPTS)
##    ##
##    ##-- runtime ddc relation options
##    ddcServer => "$host:$port", ##-- server for ddc relation
##    ddcTimeout => $seconds,     ##-- timeout for ddc relation
##    ##
##    ##-- source filtering (for create())
##    pgood  => $regex,   ##-- positive filter regex for part-of-speech tags
##    pbad   => $regex,   ##-- negative filter regex for part-of-speech tags
##    wgood  => $regex,   ##-- positive filter regex for word text
##    wbad   => $regex,   ##-- negative filter regex for word text
##    lgood  => $regex,   ##-- positive filter regex for lemma text
##    lbad   => $regex,   ##-- negative filter regex for lemma text
##    ##
##    ##-- logging
##    logOpen => $level,        ##-- log-level for open/close (default='info')
##    logCreate => $level,      ##-- log-level for create messages (default='info')
##    logThread => $level,      ##-- log-level for multithreading operations (default='debug')
##    logCorpusFile => $level,  ##-- log-level for corpus file-parsing (default='info')
##    logCorpusFileN => $N,     ##-- log corpus file-parsing only for every N files (0 for none; default:undef ~ $corpus->size()/100)
##    logExport => $level,      ##-- log-level for export messages (default='info')
##    logProfile => $level,     ##-- log-level for verbose profiling messages (default='trace')
##    logRequest => $level,     ##-- log-level for request-level profiling messages (default='debug')
##    logCompat => $level,      ##-- log-level for compatibility warnings (default='warn')
##    ##
##    ##-- runtime limits
##    maxExpand => $size,   ##-- maximum number of elements in query expansions (default=65535)
##    ##
##    ##-- administrivia
##    version=>$version,    ##-- DiaColloDB version of stored db (==$DiaColloDB::VERSION)
##    upgraded=>\@upgraded, ##-- optional administrative information about auto-magic upgrades
##    ##
##    ##-- attribute data
##    ${a}enum => $aenum,   ##-- attribute enum: $aenum : ($dbdir/${a}_enum.*) : $astr<=>$ai : A*<=>N
##                          ##    e.g.  lemmata: $lenum : ($dbdir/l_enum.*   )  : $lstr<=>$li : A*<=>N
##    ${a}2t   => $a2t,     ##-- attribute multimap: $a2t : ($dbdir/${a}_2t.*) : $ai=>@tis  : N=>N*
##    pack_t$a => $fmt      ##-- pack format: extract attribute-id $ai from a packed tuple-string $ts ; $ai=unpack($coldb->{"pack_t$a"},$ts)
##    ##
##    ##-- tuple data (-dates)
##    ##   + as of v0.10.000, packed term tuples EXCLUDING dates ("t-tuples") are mapped by $coldb->{tenum}
##    ##   + prior to v0.10.000, term tuples INCLUDING dates ("x-tuples") were mapped by $coldb->{xenum}, now obsolete
##    tenum  => $tenum,     ##-- enum: tuples ($dbdir/tenum.*) : \@ais<=>$ti : N*<=>N
##    pack_t => $fmt,       ##-- symbol pack-format for $tenum : "${pack_id}[Nattrs]"
##    xdmin => $xdmin,      ##-- minimum date (>= v0.04)
##    xdmax => $xdmax,      ##-- maximum date (>= v0.04)
##    ##
##    ##-- relation data
##    #xf    => $xf,       ##-- ug: $xi => $f($xi) : N=>N
##    #cof   => $cof,      ##-- cf: [$xi1,$xi2] => $f12
##    xf    => $xf,       ##-- ug: [$ti,$date]       => f($ti,$date)
##    cof   => $cof,      ##-- cf: [$ti1,$date,$ti2] => f($ti1,$date,$ti2)
##    ddc   => $ddc,      ##-- ddc: ddc client relation
##    tdf   => $tdf,      ##-- tdf: (term x document) frequency matrix relation
##   )
sub new {
  my $that = shift;
  my $coldb  = bless({
		      ##-- options
		      dbdir => undef,
		      flags => 'r',
		      attrs => undef,
		      #bos => undef,
		      #eos => undef,
		      pack_id => 'N',
		      pack_f  => 'N',
		      pack_date => 'n',
		      pack_off => 'N',
		      pack_len =>'n',
		      dmax => 5,
		      cfmin => 2,
		      tfmin => 2,
		      #keeptmp => 0,
		      #mmap => 1,
		      #debug => 0,
		      index_tdf => undef,
		      index_cof => 1,
		      index_xf => 1,
		      dbreak => undef,
		      tdfopts => {},

		      ##-- filters (pgood, pbad, etc. now in DiaColloDB::Corpus::Filters; default value see below)
                      %{DiaColloDB::Corpus::Filters->new},
		      #vsmgood => $TDF_MGOOD_DEFAULT,
		      #vsmbad  => $TDF_MBAD_DEFAULT,

		      ##-- logging
		      logOpen => 'info',
		      logCreate => 'info',
                      logThread => 'debug',
		      logCorpusFile => 'info',
		      logCorpusFileN => undef,
		      logExport => 'info',
		      logProfile => 'trace',
		      logRequest => 'debug',
		      logCompat => 'warn',

		      ##-- limits
		      maxExpand => 65535,

		      ##-- administrivia
		      version => "$VERSION",
		      #upgraded=>[],

		      ##-- attributes
		      #lenum => undef, #$ECLASS->new(pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_len}),
		      #l2t   => undef, #$MMCLASS->new(pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_id}),
		      #pack_tl => 'N',

		      ##-- tuples (-dates)
		      #tenum  => undef, #$XECLASS::FixedLen->new(pack_i=>$coldb->{pack_id}, pack_s=>$coldb->{pack_t}, pack_d=>$coldb->{pack_date}),
		      #pack_t => 'N',

		      ##-- relations
		      #xf   => undef, #DiaColloDB::Relation::Unigrams->new(pack_i=>$pack_i, pack_f=>$pack_f, pack_d=>$pack_date),
		      #cof => undef, #DiaColloDB::Relation::Cofreqs->new(pack_f=>$pack_f, pack_i=>$pack_i, pack_d=>$pack_date, dmax=>$dmax, fmin=>$cfmin),
		      #ddc  => undef, #DiaColloDB::Relation::DDC->new(),
		      #tdf  => undef, #DiaColloDB::Relation::TDF->new(),

		      @_,	##-- user arguments
		     },
		     ref($that)||$that);
  $coldb->{class}  = ref($coldb);
  $coldb->{pack_t} = $coldb->{pack_id};
  if (defined($coldb->{dbdir})) {
    ##-- avoid initial close() if called with dbdir=>$dbdir argument
    my $dbdir = $coldb->{dbdir};
    delete $coldb->{dbdir};
    return $coldb->open($dbdir);
  }
  return $coldb;
}

## undef = $obj->DESTROY
##  + destructor calls close() if necessary
##  + INHERITED from DiaColloDB::Client

## $cli_or_undef = $cli->promote($class,%opts)
##  + DiaColloDB::Client method override
sub promote {
  $_[0]->logconfess("promote(): not supported");
}

##========================================================================
## Create/compile
our (%ATTR_ALIAS,%ATTR_RALIAS,%ATTR_TITLE,%ATTR_CBEXPR);
use DiaColloDB::methods::compile;

##==============================================================================
## I/O: open/close

## $coldb_or_undef = $coldb->open($dbdir,%opts)
## $coldb_or_undef = $coldb->open()
sub open {
  my ($coldb,$dbdir,%opts) = @_;
  DiaColloDB::Logger->ensureLog();
  $coldb = $coldb->new() if (!ref($coldb));
  #@$coldb{keys %opts} = values %opts; ##-- clobber options after loadHeader()
  $dbdir //= $coldb->{dbdir};
  $dbdir =~ s{/$}{};
  $coldb->close() if ($coldb->opened);
  $coldb->{dbdir} = $dbdir;
  my $flags = fcflags($opts{flags} // $coldb->{flags});
  $coldb->vlog($coldb->{logOpen}, "open($dbdir)");

  ##-- open: truncate
  if (fctrunc($flags)) {
    $flags |= O_CREAT;
    !-d $dbdir
      or remove_tree($dbdir)
	or $coldb->logconfess("open(): could not remove old $dbdir: $!");
  }

  ##-- open: create
  if (!-d $dbdir) {
    $coldb->logconfess("open(): no such directory '$dbdir'") if (!fccreat($flags));
    make_path($dbdir)
      or $coldb->logconfess("open(): could not create DB directory '$dbdir': $!");
  }

  ##-- open: header
  my ($hdr);
  if (fcread($flags) && !fctrunc($flags)) {
    $hdr = $coldb->readHeader()
      or $coldb->logconfess("open(): failed to read header file '", $coldb->headerFile, "': $!");
    $coldb->loadHeaderData($hdr)
      or $coldb->logconess("failed to instantiate header from '", $coldb->headerFile, "': $!");
  }

  ##-- clobber header options with user-supplied values
  @$coldb{keys %opts} = values %opts;

  ##-- open: check compatiblity
  my $min_version_compat = '0.10.000';
  if (!$coldb->{version} || version->parse($coldb->{version}) < version->parse($min_version_compat)) {
    $coldb->vlog($coldb->{logCompat}, "using compatibility mode for DB directory '$dbdir'; consider running \`dcdb-upgrade.perl $dbdir\'");
    DiaColloDB::Compat->usecompat('v0_09');
    bless($coldb, 'DiaColloDB::Compat::v0_09::DiaColloDB');
    $coldb->{version} = $hdr->{version};
    delete $coldb->{dbdir};
    return $coldb->open($dbdir,%opts);
  }
  elsif (!defined($coldb->{xdmin}) || !defined($coldb->{xdmax})) {
    $coldb->logconfess("open(): no date-range keys {xdmin,xdmax} found in header; try running \`dcdb-upgrade.perl $dbdir'");
  }

  ##-- open: tdf: require
  $coldb->{index_tdf} = 0 if (!-r "$dbdir/tdf.hdr");
  if ($coldb->{index_tdf}) {
    if (!require "DiaColloDB/Relation/TDF.pm") {
      $coldb->logwarn("open(): require failed for DiaColloDB/Relation/TDF.pm ; (term x document) matrix modelling disabled", ($@ ? "\n: $@" : ''));
      $coldb->{index_tdf} = 0;
    }
  }

  ##-- open: common options
  my %efopts = (flags=>$flags, pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_len});
  my %mmopts = (flags=>$flags, pack_i=>$coldb->{pack_id});

  ##-- open: attributes
  my $attrs = $coldb->{attrs} = $coldb->attrs(undef,['l']);

  ##-- open: by attribute
  my $atat = 0;
  foreach my $attr (@$attrs) {
    ##-- open: ${attr}*
    my $abase = (-r "$dbdir/${attr}_enum.hdr" ? "$dbdir/${attr}_" : "$dbdir/${attr}"); ##-- v0.03-compatibility hack
    $coldb->{"${attr}enum"} = $coldb->mmclass($ECLASS)->new(base=>"${abase}enum", %efopts)
      or $coldb->logconfess("open(): failed to open enum ${abase}enum.*: $!");
    $coldb->{"${attr}2t"} = $coldb->mmclass($MMCLASS)->new(base=>"${abase}2t", %mmopts)
      or $coldb->logconfess("open(): failed to open expansion multimap ${abase}2x.*: $!");
    $coldb->{"pack_t$attr"} //= "\@${atat}$coldb->{pack_id}";
    $atat += packsize($coldb->{pack_id});
  }

  ##-- open: tenum
  $coldb->{tenum} = $coldb->mmclass($XECLASS)->new(base=>"$dbdir/tenum", %efopts, pack_s=>$coldb->{pack_t})
      or $coldb->logconfess("open(): failed to open tuple-enum $dbdir/tenum.*: $!");

  ##-- open: xf
  if ($coldb->{index_xf}//1) {
    $coldb->{xf} = DiaColloDB::Relation::Unigrams->new(base=>"$dbdir/xf", flags=>$flags, mmap=>$coldb->{mmap},
                                                       pack_i=>$coldb->{pack_id}, pack_f=>$coldb->{pack_f}, pack_d=>$coldb->{pack_date}
                                                      )
      or $coldb->logconfess("open(): failed to open tuple-unigrams $dbdir/xf.*: $!");
    $coldb->{xf}{N} = $coldb->{xN} if ($coldb->{xN} && !$coldb->{xf}{N}); ##-- compat
  }

  ##-- open: cof
  if ($coldb->{index_cof}//1) {
    $coldb->{cof} = DiaColloDB::Relation::Cofreqs->new(base=>"$dbdir/cof", flags=>$flags, mmap=>$coldb->{mmap},
						       pack_i=>$coldb->{pack_id}, pack_f=>$coldb->{pack_f}, pack_d=>$coldb->{pack_date},
						       dmax=>$coldb->{dmax}, fmin=>$coldb->{cfmin},
						      )
      or $coldb->logconfess("open(): failed to open co-frequency file $dbdir/cof.*: $!");
  }

  ##-- open: ddc (undef if ddcServer isn't set in ddc.hdr or $coldb)
  $coldb->{ddc} = DiaColloDB::Relation::DDC->new(-r "$dbdir/ddc.hdr" ? (base=>"$dbdir/ddc") : qw())->fromDB($coldb)
    // 'DiaColloDB::Relation::DDC';

  ##-- open: tdf (if available)
  if ($coldb->{index_tdf}) {
    $coldb->{tdfopts}     //= {};
    $coldb->{tdfopts}{$_} //= $TDF_OPTS{$_} foreach (keys %TDF_OPTS);                ##-- tdf: default options
    $coldb->{tdf} = DiaColloDB::Relation::TDF->new((-r "$dbdir/tdf.hdr" ? (base=>"$dbdir/tdf") : qw()),
						   dbreak => $coldb->{dbreak},
						   %{$coldb->{tdfopts}},
						  );
  }

  ##-- all done
  return $coldb;
}


## @dbkeys = $coldb->dbkeys()
sub dbkeys {
  return (
	  (ref($_[0]) ? (map {($_."enum",$_."2t")} @{$_[0]->attrs}) : qw()),
	  qw(tenum xf cof tdf),
	 );
}

## $coldb_or_undef = $coldb->close()
sub close {
  my $coldb = shift;
  return $coldb if (!ref($coldb));
  $coldb->vlog($coldb->{logOpen}, "close(".($coldb->{dbdir}//'').")");
  foreach ($coldb->dbkeys) {
    next if (!defined($coldb->{$_}));
    return undef if (!$coldb->{$_}->close());
    delete $coldb->{$_};
  }
  $coldb->{dbdir} = undef;
  return $coldb;
}

## $bool = $coldb->opened()
sub opened {
  my $coldb = shift;
  return (defined($coldb->{dbdir})
	  && !grep {!$_->opened} grep {defined($_)} @$coldb{$coldb->dbkeys}
	 );
}

## @files = $obj->diskFiles()
##  + returns list of dist files for this db
sub diskFiles {
  my $coldb = shift;
  return ("$coldb->{dbdir}/header.json", map {$_->diskFiles} grep {UNIVERSAL::can(ref($_),'diskFiles')} values %$coldb);
}

##==============================================================================
## I/O: header
##  + largely INHERITED from DiaColloDB::Persistent

## @keys = $coldb->headerKeys()
##  + keys to save as header
sub headerKeys {
  return (qw(attrs upgraded), grep {!ref($_[0]{$_}) && $_ !~ m{^(?:dbdir$|flags$|njobs$|perms$|info$|tdfopts$|log|debug)}} keys %{$_[0]});
}

## $bool = $coldb->loadHeaderData()
## $bool = $coldb->loadHeaderData($data)
sub loadHeaderData {
  my ($coldb,$hdr) = @_;
  if (!defined($hdr) && !fccreat($coldb->{flags})) {
    $coldb->logconfess("loadHeader() failed to load header data from ", $coldb->headerFile, ": $!");
  }
  elsif (defined($hdr)) {
    $coldb->{version} = undef;
    return $coldb->SUPER::loadHeaderData($hdr);
  }
  return $coldb;
}

## $bool = $coldb->saveHeader()
## $bool = $coldb->saveHeader($headerFile)
##  + INHERITED from DiaColloDB::Persistent

##========================================================================
## export/import
use DiaColloDB::methods::export;


##==============================================================================
## Info

## \%info = $coldb->dbinfo()
##  + get db info
sub dbinfo {
  my $coldb = shift;
  my $adata = $coldb->attrData();
  my $du    = $coldb->du();
  my $info  = {
	       ##-- literals
	       (map {exists($coldb->{$_}) ? ($_=>$coldb->{$_}) : qw()}
		qw(dbdir bos eos dmax cfmin xdmin xdmax version upgraded label collection maintainer)),

	       ##-- disk usage
	       du_b => $du,
	       du_h => si_str($du),

	       ##-- timestamp
	       timestamp => $coldb->timestamp,

	       ##-- attributes
	       attrs => [map {
		 {(
		   name  => $_->{a},
		   title => $coldb->attrTitle($_->{a}),
		   size  => $_->{enum}->size,
		   alias => $ATTR_RALIAS{$_->{a}},
		 )}
	       } @$adata],

	       ##-- relations
	       #relations => [$coldb->relations],
	       relations => { map {($_=>$coldb->{$_}->dbinfo($coldb))} $coldb->relations },

	       ##-- overrides
	       %{$coldb->{info}//{}},
	      };
  return $info;
}


##==============================================================================
## Profiling

##--------------------------------------------------------------
## Profiling: Wrappers
##  + INHERITED from DiaColloDB::Client

## $mprf = $coldb->query($rel,%opts)
##  + get a generic DiaColloDB::Profile::Multi object for $rel
##  + calls $coldb->profile() or $coldb->compare() as appropriate
##  + INHERITED from DiaColloDB::Client

## $mprf = $coldb->profile1(%opts)
##  + get unigram frequency profile for selected items as a DiaColloDB::Profile::Multi object
##  + really just wraps $coldb->profile('xf', %opts)
##  + %opts: see profile() method
##  + INHERITED from DiaColloDB::Client

## $mprf = $coldb->profile2(%opts)
##  + get co-frequency profile for selected items as a DiaColloDB::Profile::Multi object
##  + really just wraps $coldb->profile('cof', %opts)
##  + %opts: see profile() method
##  + INHERITED from DiaColloDB::Client

## $mprf = $coldb->compare1(%opts)
##  + get unigram comparison profile for selected items as a DiaColloDB::Profile::MultiDiff object
##  + really just wraps $coldb->compare('xf', %opts)
##  + %opts: see compare() method
##  + INHERITED from DiaColloDB::Client

## $mprf = $coldb->compare2(%opts)
##  + get co-frequency comparison profile for selected items as a DiaColloDB::Profile::MultiDiff object
##  + really just wraps $coldb->profile('cof', %opts)
##  + %opts: see compare() method
##  + INHERITED from DiaColloDB::Client


##--------------------------------------------------------------
## Profiling: Utils

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $relname = $coldb->relname($rel)
##  + returns an appropriate relation name for profile() and friends
##  + returns $rel if $coldb->{$rel} supports a profile() method
##  + otherwise heuristically parses $relationName /xf|f?1|ug/ or /f1?2|c/
sub relname {
  my ($coldb,$rel) = @_;
  if (UNIVERSAL::can($coldb->{$rel},'profile')) {
    return $rel;
  }
  elsif ($rel =~ m/^(?:[ux]|f?1$)/) {
    return 'xf';
  }
  elsif ($rel =~ m/^(?:c|f?1?2$)/) {
    return 'cof';
  }
  elsif ($rel =~ m/^(?:v|vec|vs|vsem|sem|td[mf])$/) {
    return 'tdf';
  }
  return $rel;
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $obj_or_undef = $coldb->relation($rel)
##  + returns an appropriate relation-like object for profile() and friends
##  + wraps $coldb->{$coldb->relname($rel)}
sub relation {
  return $_[0]->{$_[0]->relname($_[1])};
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## @relnames = $coldb->relations()
##  + gets list of defined relations
sub relations {
  return grep {UNIVERSAL::isa(ref($_[0]{$_}),'DiaColloDB::Relation')} keys %{$_[0]};
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## \@ids = $coldb->enumIds($enum,$req,%opts)
##  + parses enum IDs for $req, which is one of:
##    - a DDC::Any::CQTokExact, ::CQTokInfl, ::CQTokSet, ::CQTokSetInfl, or ::CQTokRegex : interpreted
##    - an ARRAY-ref     : list of literal symbol-values
##    - a Regexp ref     : regexp for target strings, passed to $enum->re2i()
##    - a string /REGEX/ : regexp for target strings, passed to $enum->re2i()
##    - another string   : space-, comma-, or |-separated list of literal values
##  + %opts:
##     logLevel => $logLevel, ##-- logging level (default=undef)
##     logPrefix => $prefix,  ##-- logging prefix (default="enumIds(): fetch ids")
sub enumIds {
  my ($coldb,$enum,$req,%opts) = @_;
  $opts{logPrefix} //= "enumIds(): fetch ids";
  if (UNIVERSAL::isa($req,'DDC::Any::CQTokInfl') || UNIVERSAL::isa($req,'DDC::Any::CQTokExact')) {
    ##-- CQuery: CQTokExact
    $coldb->vlog($opts{logLevel}, $opts{logPrefix}, " (", ref($req), ")");
    return [$enum->s2i($req->getValue)];
  }
  elsif (UNIVERSAL::isa($req,'DDC::Any::CQTokSet') || UNIVERSAL::isa($req,'DDC::Any::CQTokSetInfl')) {
    ##-- CQuery: CQTokSet
    $coldb->vlog($opts{logLevel}, $opts{logPrefix}, " (", ref($req), ")");
    return [map {$enum->s2i($_)} @{$req->getValues}];
  }
  elsif (UNIVERSAL::isa($req,'DDC::Any::CQTokRegex')) {
    ##-- CQuery: CQTokRegex
    $coldb->vlog($opts{logLevel}, $opts{logPrefix}, " (", ref($req), ")");
    return $enum->re2i($req->getValue);
  }
  elsif (UNIVERSAL::isa($req,'DDC::Any::CQTokAny')) {
    $coldb->vlog($opts{logLevel}, $opts{logPrefix}, " (", ref($req), ")");
    return undef;
  }
  elsif (UNIVERSAL::isa($req,'ARRAY')) {
    ##-- compat: array
    $coldb->vlog($opts{logLevel}, $opts{logPrefix}, " (ARRAY)");
    return [map {$enum->s2i($_)} @$req];
  }
  elsif (UNIVERSAL::isa($req,'Regexp') || $req =~ m{^/}) {
    ##-- compat: regex
    $coldb->vlog($opts{logLevel}, $opts{logPrefix}, " (REGEX)");
    return $enum->re2i($req);
  }
  elsif (!ref($req)) {
    ##-- compat: space-, comma-, or |-separated literals
    $coldb->vlog($opts{logLevel}, $opts{logPrefix}, " (STRINGS)");
    return [grep {defined($_)} map {$enum->s2i($_)} grep {($_//'') ne ''} map {s{\\(.)}{$1}g; $_} split(/(?:(?<!\\)[\,\s\|])+/,$req)];
  }
  else {
    ##-- reference: unhandled
    $coldb->logconfess($coldb->{error}="$opts{logPrefix}: can't handle request of type ".ref($req));
  }
  return [];
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## ($dfilter,$sliceLo,$sliceHi,$dateLo,$dateHi) = $coldb->parseDateRequest($dateRequest='', $sliceRequest=0, $fill=0, $ddcMode=0)
## \%dateRequest                                = $coldb->parseDateRequest($dateRequest='', $sliceRequest=0, $fill=0, $ddcMode=0)
##   + parses date request and returns limit and filter information as a list (list context) or HASH-ref (scalar context);
##   + %dateRequest =
##     (
##      dfilter => $dfilter,  ##-- filter-sub, called as: $wanted=$dfilter->($date); undef for none
##      slo  => $sliceLo,     ##-- minimum slice (inclusive)
##      shi  => $sliceHi,     ##-- maximum slice (inclusive)
##      dlo  => $dateLo,      ##-- minimum date (inclusive); undef for none, always defined if $fill is true
##      dhi  => $dateHi,      ##-- maximum date (inclusive); undef for none, always defined if $fill is true
##     )
sub parseDateRequest {
  my ($coldb,$date,$slice,$fill,$ddcmode) = @_;
  my ($dfilter,$slo,$shi,$dlo,$dhi);
  $date //= '';
  if ($date =~ /^[\s\*]*$/) {
    ##-- empty date request or universal wildcard: ignore
    $dlo = $dhi = undef;
  }
  elsif (UNIVERSAL::isa($date,'Regexp') || $date =~ /^\//) {
    ##-- date request: regex string
    $coldb->logconfess("parseDateRequest(): can't handle date regex '$date' in ddc mode") if ($ddcmode);
    my $dre  = regex($date);
    $dfilter = sub { $_[0] =~ $dre };
  }
  elsif ($date =~ /^\s*((?:[0-9]+|\*?))\s*[\-\:]+\s*((?:[0-9]+|\*?))\s*$/) {
    ##-- date request: range MIN:MAX (inclusive)
    ($dlo,$dhi) = ($1,$2);
    $dlo  = $coldb->{xdmin} if (($dlo//'') =~ /^\*?$/);
    $dhi  = $coldb->{xdmax} if (($dhi//'') =~ /^\*?$/);
    $dlo += 0;
    $dhi += 0;
    $dfilter = sub { $_[0]>=$dlo && $_[0]<=$dhi };
  }
  elsif ($date =~ /[\s\,\|]+/) {
    ##-- date request: list
    $coldb->logconfess("parseDateRequest(): can't handle date list '$date' in ddc mode") if ($ddcmode);
    my %dwant = map {($_=>undef)} grep {($_//'') ne ''} split(/[\s\,\|]+/,$date);
    $dfilter  = sub { exists($dwant{$_[0]}) };
  }
  else {
    ##-- date request: single value
    $dlo = $dhi = $date;
    $dfilter = sub { $_[0] == $date };
  }

  ##-- force-fill?
  if ($fill) {
    $dlo = $coldb->{xdmin} if (!$dlo || $dlo < $coldb->{xdmin});
    $dhi = $coldb->{xdmax} if (!$dhi || $dhi > $coldb->{xdmax});
  }

  ##-- slice-range
  ($slo,$shi) = map {$slice ? ($slice*int($_/$slice)) : 0} (($dlo//$coldb->{xdmin}),($dhi//$coldb->{xdmax}));

  return wantarray
    ? ($dfilter,$slo,$shi,$dlo,$dhi)
    : { dfilter=>$dfilter, slo=>$slo, shi=>$shi, dlo=>$dlo, dhi=>$dhi };
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $compiler = $coldb->qcompiler();
##  + get DDC::Any::CQueryCompiler for this object (cached in $coldb->{_qcompiler})
sub qcompiler {
  return $_[0]{_qcompiler} ||= DDC::Any::CQueryCompiler->new();
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $cquery_or_undef = $coldb->qparse($ddc_query_string)
##  + wraps parse in an eval {...} block and sets $coldb->{error} on failure
sub qparse {
  my ($coldb,$qstr) = @_;
  my ($q);
  eval { $q=$coldb->qcompiler->ParseQuery($qstr); };
  if ($@ || !defined($q)) {
    $coldb->{error}="$@";
    return undef;
  }
  return $q;
}


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $cquery = $coldb->parseQuery([[$attr1,$val1],...], %opts) ##-- compat: ARRAY-of-ARRAYs
## $cquery = $coldb->parseQuery(["$attr1:$val1",...], %opts) ##-- compat: ARRAY-of-requests
## $cquery = $coldb->parseQuery({$attr1=>$val1, ...}, %opts) ##-- compat: HASH
## $cquery = $coldb->parseQuery("$attr1=$val1, ...", %opts)  ##-- compat: string
## $cquery = $coldb->parseQuery($ddcQueryString, %opts)      ##-- ddc string (with shorthand ","->WITH, "&&"->WITH)
##  + guts for parsing user target and groupby requests
##  + returns a DDC::Any::CQuery object representing the request
##  + index-only items "$l" are mapped to $l=@{}
##  + if query request is wrapped in "(...)" or "[...]", native parsing is NOT attempted
##  + %opts:
##     warn  => $level,       ##-- log-level for unknown attributes (default: 'warn')
##     logas => $reqtype,     ##-- request type for warnings
##     default => $attr,      ##-- default attribute (for query requests)
##     mapand => $bool,       ##-- map CQAnd to CQWith? (default=true unless '&&' occurs in query string)
##     ddcmode => $bool,      ##-- force ddc query parsing? (0:no:default, >0:always, <0:fallback)
sub parseQuery {
  my ($coldb,$req,%opts) = @_;
  my $req0   = $req;
  my $wlevel = $opts{warn} // 'warn';
  my $defaultIndex = $opts{default};
  my $logas = $opts{logas}//'';
  my $ddcmode = $opts{ddcmode} || 0;

  ##-- compat: accept ARRAY or HASH requests
  my $areqs = (UNIVERSAL::isa($req,'ARRAY') ? [@$req]
	       : (UNIVERSAL::isa($req,'HASH') ? [%$req]
		  : undef));

  ##-- ddcmode: detect "[...]" queries
  $ddcmode = 1 if ($req =~ s{^\s*\[(.*)\]\s*$}{$1});

  ##-- compat: parse into attribute-local requests $areqs=[[$attr1,$areq1],...]
  my $sepre  = qr{[\s\,]};
  my $charre = qr{(?:\\[^ux0-9]|[\w\x{80}-\x{ffff}])};
  my $attrre = qr{(?:\$?(?:doc\.)?${charre}+)};
  my $orre   = qr{(?:\s*\|?\s*)};
  my $setre  = qr{(?:(?:${charre}+)(?:${orre}${charre}+)*)};	##-- value: |-separated barewords
  my $regre  = qr{(?:/(?:\\/|[^/]*)/(?:[gimsadlux]*))};		##-- value regexes
  my $valre  = qr{(?:${setre}|${regre})};
  my $reqre  = qr{(?:(?:${attrre}(?:[:=]${valre})?)|${valre})};
  if (!$areqs
      && ($ddcmode <= 0)			##-- allow native parsing?
      && $req =~ m/^${sepre}*			##-- initial separators (optional)
		   (?:${reqre}${sepre}+)*	##-- separated components
		   (?:${reqre})			##-- final component
		   ${sepre}*			##-- final separators (optional)
		   $/x) {
    $coldb->debug("parseQuery($logas): parsing native query request [ddcmode=$ddcmode]") if ($coldb->{debug});
    $areqs = [grep {defined($_)} ($req =~ m/${sepre}*(${reqre})/g)];
  }

  ##-- construct DDC query $q
  my ($q);
  if ($areqs) {
    ##-- compat: diacollo<=v0.06-style attribute-wise request in @$areqs; construct DDC query by hand
    my ($attr,$areq,$aq);
    foreach (@$areqs) {
      if (UNIVERSAL::isa($_,'ARRAY')) {
	##-- compat: attribute request: ARRAY
	($attr,$areq) = @$_;
      } elsif (UNIVERSAL::isa($_,'HASH')) {
	##-- compat: attribute request: HASH
	($attr,$areq) = %$_;
      } else {
	##-- compat: attribute request: STRING (native)
	next if (uc($_) eq 'WITH'); ##-- avoid ddc keyword
	($attr,$areq) = m{^(${attrre})[:=](${valre})$} ? ($1,$2) : ($_,undef);
	$attr =~ s/\\(.)/$1/g;
	$areq =~ s/\\(.)/$1/g if (defined($areq));
      }

      ##-- compat: parse defaults
      ($attr,$areq) = ('',$attr)   if (defined($defaultIndex) && !defined($areq));
      $attr = $defaultIndex//'' if (($attr//'') eq '');
      $attr =~ s/^\$//;

      $coldb->debug("parseQuery($logas): parsing native request clause: (".($attr//'')." = ".($areq//'').")") if ($coldb->{debug});

      if (UNIVERSAL::isa($areq,'DDC::Any::CQuery')) {
	##-- compat: value: ddc query object
	$aq = $areq;
	$aq->setIndexName($attr) if ($aq->can('setIndexName') && $attr ne '');
      }
      elsif (UNIVERSAL::isa($areq,'ARRAY')) {
	##-- compat: value: array --> CQTokSet @{VAL1,...,VALN}
	$aq = DDC::Any::CQTokSet->new($attr, '', $areq);
      }
      elsif (UNIVERSAL::isa($areq,'RegExp') || (($opts{ddcmode}||0)<1 && $areq && $areq =~ m{^${regre}$})) {
	##-- compat: value: regex --> CQTokRegex /REGEX/
	my $re = regex($areq)."";
	$re =~ s{\G(.*?\(\?\^[^adlu:]*)[adlu]*}{$1}g; ##-- trim perl-5.14 character-set modifiers: they break KWIC-links, since DDC (PCRE) doesn't support them!
	$re =~ s{^\(\?\^[adlu]*\:(.*)\)$}{$1};        ##-- trim redundant top-level grouping inserted by qr{}-stringification
	$aq = DDC::Any::CQTokRegex->new($attr, $re);
      }
      elsif (!$areq || $areq =~ /^\s*${reqre}\s*$/) {
	##-- compat: value: space- or |-separated literals --> CQTokExact $a=@VAL or CQTokSet $a=@{VAL1,...VALN} or CQTokAny $a=*
	##   + also applies to empty $areq, e.g. in groupby clauses
	my $vals = [grep {($_//'') ne ''} map {s{\\(.)}{$1}g; $_} split(/(?:(?<!\\)[\,\s\|])+/,($areq//''))];
	$aq = (@$vals<=1
	       ? (($vals->[0]//'*') eq '*'
		  ? DDC::Any::CQTokAny->new($attr,'*')
		  : DDC::Any::CQTokExact->new($attr,$vals->[0]))
	       : DDC::Any::CQTokSet->new($attr,($areq//''),$vals));
      }
      elsif ($ddcmode && ($areq//'') ne '') {
	##-- compat: ddcmode: parse requests as ddc queries
	$aq = $coldb->qparse($areq)
	  or $coldb->logconfess($coldb->{error}="parseQuery(): failed to parse request \`$areq': $coldb->{error}");
      }
      ##-- push request to query
      $q = $q ? DDC::Any::CQWith->new($q,$aq) : $aq;
    }
  }
  else {
    ##-- ddc: diacollo>=v0.06: ddc request parsing: allow shorthands (',' --> 'WITH'), ('INDEX=VAL' --> '$INDEX=VAL'), and ($INDEX --> $INDEX=@{})
    my $compiler = $coldb->qcompiler();
    my ($err);
    while (!defined($q)) {
      #$coldb->trace("req=$req\n");
      undef $@;
      eval { $q=$compiler->ParseQuery($req); };
      last if (!($err=$@) && defined($q));
      if ($err =~ /syntax error/) {
	if ($err =~ /unexpected ','/) {
	  ##-- (X Y) --> (X WITH Y)
	  $req =~ s/(?!<\\)\s*,\s*/ WITH /;
	  next;
	}
	elsif ($err =~ /expecting '='/) {
	  ##-- ($INDEX) --> ($INDEX=*) (for group-by)
	  $req =~ s/(\$\w+)(?!\s*\=)/$1=*/;
	  next;
	}
	elsif ($err =~ /unexpected SYMBOL, expecting INTEGER at line \d+, near token \`([^\']*)\'/) {
	  ##-- (INDEX=) --> ($INDEX=)
	  my $tok = $1;
	  $req =~ s/(?!<\$)(\S+)\s*=\s*\Q$tok\E/\$$1=$tok/;
	  next;
	}
      }
      $coldb->logconfess("parseQuery(): could not parse request '$req0': ", ($err//''));
    }
  }

  ##-- tweak query: map CQAnd to CQWith
  $q = $q->mapTraverse(sub {
			 return UNIVERSAL::isa($_[0],'DDC::Any::CQAnd') ? DDC::Any::CQWith->new($_[0]->getDtr1,$_[0]->getDtr2) : $_[0];
		       })
    if ($opts{mapand} || (!defined($opts{mapand}) && $req0 !~ /\&\&/));

  $coldb->debug("parseQuery($logas): parsed query: ", $q->toString) if ($coldb->{debug});

  return $q;
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## \@aqs = $coldb->queryAttributes($cquery,%opts)
##  + utility for decomposing DDC queries into attribute-wise requests
##   + returns an ARRAY-ref [[$attr1,$val1], ...]
##   + each value $vali is empty or undef (all values), a CQTokSet, a CQTokExact, CQTokRegex, or CQTokAny
##   + chokes on unsupported query types or filters
##   + %opts:
##     warn  => $level,       ##-- log-level for unknown attributes (default: 'warn')
##     logas => $reqtype,     ##-- request type for warnings
##     default => $attr,      ##-- default attribute (for query requests)
##     allowExtra => \@attrs, ##-- allow extra attributes @attrs (may also be HASH-ref)
##     allowUnknown => $bool, ##-- allow unknown attributes? (default: 0)
sub queryAttributes {
  my ($coldb,$cquery,%opts) = @_;
  my $wlevel = $opts{warn} // 'warn';
  my $default = $opts{default};
  my $logas  = $opts{logas}//'';

  my $warnsub = sub {
    $coldb->logconfess($coldb->{error}="queryAttributes(): can't handle ".join('',@_)) if (!$opts{relax});
    $coldb->vlog($wlevel, "queryAttributes(): ignoring ", @_);
  };

  my $areqs = [];
  my ($q,$attr,$aq);
  foreach $q (@{$cquery->Descendants}) {
    if (!defined($q)) {
      ##-- NULL: ignore
      next;
    }
    elsif ($q->isa('DDC::Any::CQWith')) {
      ##-- CQWith: ignore (just recurse)
      next;
    }
    elsif ($q->isa('DDC::Any::CQueryOptions')) {
      ##-- CQueryOptions: check for nontrivial user requests
      $warnsub->("#WITHIN clause") if (@{$q->getWithin});
      $warnsub->("#CNTXT clause") if ($q->getContextSentencesCount);
    }
    elsif ($q->isa('DDC::Any::CQToken')) {
      ##-- CQToken: create attribute clause
      $warnsub->("negated query clause in native $logas request (".$q->toString.")") if ($q->getNegated);
      $warnsub->("explicit term-expansion chain in native $logas request (".$q->toString.")") if ($q->can('getExpanders') && @{$q->getExpanders});

      my $attr = $q->getIndexName || $default;
      if (ref($q) =~ /^DDC::\w+::CQTok(?:Exact|Set|Regex|Any)$/) {
	$aq = $q;
      } elsif (ref($q) =~ /^DDC::\w+::CQTokInfl$/) {
	$aq = DDC::Any::CQTokExact->new($q->getIndexName, $q->getValue);
      } elsif (ref($q) =~ /^DDC::\w+::CQTokSetInfl$/) {
	$aq = DDC::Any::CQTokSet->new($q->getIndexName, $q->getValue, $q->getValues);
      } elsif (ref($q) =~ /^DDC::\w+::CQTokPrefix$/) {
	$aq = DDC::Any::CQTokRegex->new($q->getIndexName, '^'.quotemeta($q->getValue));
      } elsif (ref($q) =~ /^DDC::\w+::CQTokSuffix$/) {
	$aq = DDC::Any::CQTokRegex->new($q->getIndexName, quotemeta($q->getValue).'$');
      } elsif (ref($q) =~ /^DDC::\w+::CQTokInfix$/) {
	$aq = DDC::Any::CQTokRegex->new($q->getIndexName, quotemeta($q->getValue));
      } else {
	$warnsub->("token query clause of type ".ref($q)." in native $logas request (".$q->toString.")");
      }
      $aq=undef if ($aq && $aq->isa('DDC::Any::CQTokAny')); ##-- empty value, e.g. for groupby
      push(@$areqs, [$attr,$aq]);
    }
    elsif ($q->isa('DDC::Any::CQFilter')) {
      ##-- CQFilter
      if ($q->isa('DDC::Any::CQFHasField')) {
	##-- CQFilter: CQFHasField
	my $attr = $q->getArg0;
	if ($q->isa('DDC::Any::CQFHasFieldValue')) {
	  $aq = DDC::Any::CQTokExact->new($attr, $q->getArg1);
	}
	elsif ($q->isa('DDC::Any::CQFHasFieldSet')) {
	  $aq = DDC::Any::CQTokSet->new($attr, $q->getArg1, $q->getValues);
	}
	elsif ($q->isa('DDC::Any::CQFHasFieldRegex')) {
	  $aq = DDC::Any::CQTokRegex->new($attr, $q->getArg1);
	}
	elsif ($q->isa('DDC::Any::CQFHasFieldPrefix')) {
	  $aq = DDC::Any::CQTokRegex->new($attr, '^'.quotemeta($q->getArg1));
	}
	elsif ($q->isa('DDC::Any::CQFHasFieldSuffix')) {
	  $aq = DDC::Any::CQTokRegex->new($attr, quotemeta($q->getArg1).'$');
	}
	elsif ($q->isa('DDC::Any::CQFHasFieldInfix')) {
	  $aq = DDC::Any::CQTokRegex->new($attr, quotemeta($q->getArg1));
	}
	else {
	  $warnsub->("filter of type ".ref($q)." unsupported in native $logas request (".$q->toString.")");
	}
	$aq=undef if ($aq && $aq->isa('DDC::Any::CQTokAny')); ##-- empty value, e.g. for groupby
	push(@$areqs, [$attr,$aq]);
      }
      elsif ($q->isa('DDC::Any::CQFRandomSort') || $q->isa('DDC::Any::CQFRankSort')) {
	##-- CQFilter: CQFRandomSort, CQFRanksort: ignore
	next;
      }
      elsif ($q->isa('DDC::Any::CQFSort') && ($q->getArg1 ne '' || $q->getArg2 ne '')) {
	##-- CQFilter: CQFSort: other
	$warnsub->("filter of type ".ref($q)." with nontrivial bounds in native $logas request (".$q->toString.")");
      }
    }
    else {
      ##-- something else
      $warnsub->("query clause of type ".ref($q)." in native $logas request (".$q->toString.")");
    }
  }

  ##-- check for unsupported attributes & normalize attribute names
  my $allowExtra = $opts{allowExtra};
  $allowExtra    = { map {($_=>undef)} @$allowExtra } if (!UNIVERSAL::isa($allowExtra,'HASH'));
  @$areqs = grep {
    $attr = $coldb->attrName($_->[0]);
    if ( !$opts{allowUnknown} && !$coldb->hasAttr($attr) && !($allowExtra && exists($allowExtra->{$attr})) ) {
      $warnsub->("unsupported attribute '".($_->[0]//'(undef)')."' in $logas request");
      0
    } else {
      $_->[0] = $attr;
      1
    }
  } @$areqs;

  return $areqs;
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## \@aqs = $coldb->parseRequest($request, %opts)
##  + guts for parsing user target and groupby requests into attribute-wise ARRAY-ref [[$attr1,$val1], ...]
##  + see parseQuery() method for supported $request formats and %opts
##  + wraps $coldb->queryAttributes($coldb->parseQuery($request,%opts))
sub parseRequest {
  my ($coldb,$req,%opts) = @_;
  return $coldb->queryAttributes($coldb->parseQuery($req,%opts),%opts);
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## \%groupby = $coldb->groupby($groupby_request, %opts)
## \%groupby = $coldb->groupby(\%groupby,        %opts)
##  + $grouby_request : see parseRequest()
##  + returns a HASH-ref:
##    (
##     req => $request,      ##-- save request
##     ti2g => \&ti2g,       ##-- group-tuple extraction code ($ti => $gtuple) : $g_packed = $ti2g->($ti)
##     ts2g => \&ts2g,       ##-- group-tuple extraction code ($ts => $gtuple) : $g_packed = $ts2g->($ts)
##     g2s   => \&g2s,       ##-- stringification object suitable for DiaColloDB::Profile::stringify() [CODE,enum, or undef] : $g_str = $g2s->($g_packed)
##     s2g   => \&s2g,       ##-- inverse-stringification object (for 2nd-pass processing)
##     g2txt => \&g2txt,     ##-- compatible join()-string stringifcation sub (decimal numeric strings)
##     txt2g => \&txt2g,     ##-- compatible inverse-string stringifcation sub (decimal numeric strings)
##     tpack => \@tpack,     ##-- group-attribute-wise pack-templates, given @ttuple
##     gpack => \@gpack,     ##-- group-attribute-wise pack-templates, given @gtuple
##     areqs => \@areqs,     ##-- parsed attribute requests ([$attr,$ahaving],...)
##     attrs => \@attrs,     ##-- like $coldb->attrs($groupby_request), modulo "having" parts
##     titles => \@titles,   ##-- like map {$coldb->attrTitle($_)} @attrs
##    )
##  + %opts:
##     warn  => $level,    ##-- log-level for unknown attributes (default: 'warn')
##     relax => $bool,     ##-- allow unsupported attributes (default=0)
##     tenum => $tenum,    ##-- enum to use for \&t2g and \&t2s (default: $coldb->{tenum})
sub groupby {
  my ($coldb,$gbreq,%opts) = @_;
  return $gbreq if (UNIVERSAL::isa($gbreq,'HASH'));

  ##-- get data
  my $wlevel = $opts{warn} // 'warn';
  my $gb = { req=>$gbreq };

  ##-- get attribute requests
  my $gbareqs = $gb->{areqs} = $coldb->parseRequest($gb->{req}, %opts,logas=>'groupby');

  ##-- get attribute names (compat)
  my $gbattrs = $gb->{attrs} = [map {$_->[0]} @$gbareqs];

  ##-- get attribute titles
  $gb->{titles} = [map {$coldb->attrTitle($_)} @$gbattrs];

  ##-- get groupby-sub
  my $tenum  = $opts{tenum} // $coldb->{tenum};
  my $pack_id = $coldb->{pack_id};
  my $pack_ids = "($pack_id)*";
  my $len_id  = packsize($pack_id);
  my @gbtpack = @{$gb->{tpack} = [map {$coldb->{"pack_t$_"}} @$gbattrs]};
  my $gbtpack = join('',@gbtpack);
  my @gbgpack = @{$gb->{gpack} = [map {'@'.($_*$len_id).$pack_id} (0..$#$gbattrs)]};
  my ($ids);
  my @gbids  = (
		map {
		  ($_->[1] && !UNIVERSAL::isa($_->[1],'DDC::Any::CQTokAny')
		   ? {
		      map {($_=>undef)}
		      @{$coldb->enumIds($coldb->{"$_->[0]enum"}, $_->[1], logLevel=>$coldb->{logProfile}, logPrefix=>"groupby(): fetch filter ids: $_->[0]")}
		     }
		   : undef)
		} @$gbareqs);

  my (@gi,$ti2g_code,$ts2g_code);
  if (grep {$_} @gbids) {
    ##-- group-by code: with having-filters
    $ts2g_code = (''
		  .qq{ \@gi=unpack('$gbtpack',\$_[0]);}
		  .qq{ return undef if (}.join(' || ', map {"!exists(\$gbids[$_]{\$gi[$_]})"} grep {defined($gbids[$_])} (0..$#gbids)).qq{);}
		  .qq{ return pack('$pack_ids',\@gi); }
		 );
  }
  else {
    ##-- group-by code: no filters
    $ts2g_code = qq{ pack('$pack_ids', unpack('$gbtpack', \$_[0])) };
  }
  my $ts2g_sub  = eval qq{sub {$ts2g_code}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile tuple-based aggregation code sub {$ts2g_code}: $@") if (!$ts2g_sub);
  $@='';
  $gb->{ts2g} = $ts2g_sub;

  ($ti2g_code = $ts2g_code) =~ s{\$_\[0\]}{\$tenum->i2s(\$_[0])};
  my $ti2g_sub  = eval qq{sub {$ti2g_code}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile id-based aggregation code sub {$ti2g_code}: $@") if (!$ti2g_sub);
  $@='';
  $gb->{ti2g} = $ti2g_sub;

  ##-- get stringification sub(s)
  my ($genum,@genums,$g2scode,$s2gcode);
  if (@$gbattrs == 1) {
    ##-- stringify a single attribute
    $genum   = $coldb->{$gbattrs->[0]."enum"};
    $g2scode = qq{ \$genum->i2s(unpack('$pack_id',\$_[0])) };
    $s2gcode = qq{ pack('$pack_id', \$genum->s2i(\$_[0]) // 0) };
  }
  else {
    @genums = map {$coldb->{$_."enum"}} @$gbattrs;
    $g2scode = (''
		.qq{ \@gi=unpack('$pack_ids', \$_[0]); }
		.q{ join("\t",}.join(', ', map {"\$genums[$_]->i2s(\$gi[$_])"} (0..$#genums)).q{)}
	       );
    $s2gcode = (''
		.qq{ \@gi=split(/\\t/, \$_[0]); }
		.qq{ pack('$pack_ids',}.join(', ', map {"\$genums[$_]->s2i(\$gi[$_]) // 0"} (0..$#genums)).q{)}
	       );
  }
  my $g2s = eval qq{sub {$g2scode}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile stringification code sub {$g2scode}: $@") if (!$g2s);
  $@='';
  $gb->{g2s} = $g2s;

  my $s2g = eval qq{sub {$s2gcode}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile inverse-stringification code sub {$s2gcode}: $@") if (!$s2g);
  $@='';
  $gb->{s2g} = $s2g;


  ##-- get pseudo-stringification sub ("\t"-joined decimal integer ids)
  my ($g2txt_code,$txt2g_code);
  if (@$gbattrs == 1) {
    ##-- stringify a single attribute
    $g2txt_code = qq{ unpack('$pack_id',\$_[0]) };
    $txt2g_code = qq{ pack('$pack_id',\$_[0] // 0) };
  }
  else {
    $g2txt_code = qq{ join("\t",unpack('$pack_ids', \$_[0])); };
    $txt2g_code = qq{ pack('$pack_ids', split(/\t/, \$_[0] // 0)); };
  }
  my $g2txt = eval qq{sub {$g2txt_code}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile pseudo-stringification code sub {$g2txt_code}: $@") if (!$g2txt);
  $@='';
  $gb->{g2txt} = $g2txt;

  my $txt2g = eval qq{sub {$txt2g_code}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile inverse pseudo-stringification code sub {$txt2g_code}: $@") if (!$txt2g);
  $@='';
  $gb->{txt2g} = $txt2g;

  return $gb;
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $cqfilter = $coldb->query2filter($attr,$cquery,%opts)
##  + converts a CQToken to a CQFilter, for ddc parsing
##  + %opts:
##     logas => $logas,   ##-- log-prefix for warnings
sub query2filter {
  my ($coldb,$attr,$q,%opts) = @_;
  return undef if (!defined($q));
  my $logas = $opts{logas} || 'query2filter';

  ##-- document attribute ("doc.ATTR" convention)
  my $field = $coldb->attrName( $attr // $q->getIndexName );
  $field = $1 if ($field =~ /^doc\.(.*)$/);
  if (UNIVERSAL::isa($q, 'DDC::Any::CQTokAny')) {
    return undef;
  } elsif (UNIVERSAL::isa($q, 'DDC::Any::CQTokExact') || UNIVERSAL::isa($q, 'DDC::Any::CQTokInfl')) {
    return DDC::Any::CQFHasField->new($field, $q->getValue, $q->getNegated);
  } elsif (UNIVERSAL::isa($q, 'DDC::Any::CQTokSet') || UNIVERSAL::isa($q, 'DDC::Any::CQTokSetInfl')) {
    return DDC::Any::CQFHasFieldSet->new($field, $q->getValues, $q->getNegated);
  } elsif (UNIVERSAL::isa($q, 'DDC::Any::CQTokRegex')) {
    return DDC::Any::CQFHasFieldRegex->new($field, $q->getValue, $q->getNegated);
  } elsif (UNIVERSAL::isa($q, 'DDC::Any::CQTokPrefix')) {
    return DDC::Any::CQFHasFieldPrefix->new($field, $q->getValue, $q->getNegated);
  } elsif (UNIVERSAL::isa($q, 'DDC::Any::CQTokSuffix')) {
    return DDC::Any::CQFHasFieldSuffix->new($field, $q->getValue, $q->getNegated);
  } elsif (UNIVERSAL::isa($q, 'DDC::Any::CQTokInfix')) {
    return DDC::Any::CQFHasFieldInfix->new($field, $q->getValue, $q->getNegated);
  } else {
    $coldb->logconfess("can't handle metadata restriction of type ", ref($q), " in $logas request: \`", $q->toString, "'");
  }
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## ($CQCountKeyExprs,\$CQRestrict,\@CQFilters) = $coldb->parseGroupBy($groupby_string_or_request,%opts)
##  + for ddc-mode parsing
##  + %opts:
##     date => $date,
##     slice => $slice,
##     matchid => $matchid,    ##-- default match-id
sub parseGroupBy {
  my ($coldb,$req,%opts) = @_;
  $req //= $coldb->attrs;

  ##-- groupby clause: date
  my $gbdate = ($opts{slice}<=0
		? DDC::Any::CQCountKeyExprConstant->new($opts{slice}||'0')
		: DDC::Any::CQCountKeyExprDateSlice->new('date',$opts{slice}));

  ##-- groupby clause: user request
  my $gbexprs   = [$gbdate];
  my $gbfilters = [];
  my ($gbrestr);
  if (!ref($req) && $req =~ m{^\s*(?:\#by)?\s*\[(.*)\]\s*$}) {
    ##-- ddc-style request; no restriction-clauses are allowed
    my $cbstr = $1;
    my $gbq = $coldb->qparse("count(*) #by[$cbstr]")
      or $coldb->logconfess($coldb->{error}="failed to parse DDC groupby request \`$req': $coldb->{error}");
    push(@$gbexprs, @{$gbq->getKeys->getExprs});
    $_->setMatchId($opts{matchid}//0)
      foreach (grep {UNIVERSAL::isa($_,'DDC::Any::CQCountKeyExprToken') && !$_->HasMatchId} @$gbexprs);
  }
  else {
    ##-- native-style request with optional restrictions
    my $gbreq  = $coldb->parseRequest($req, logas=>'groupby', default=>undef, relax=>1, allowUnknown=>1);
    my ($filter);
    foreach (@$gbreq) {
      push(@$gbexprs, $coldb->attrCountBy($_->[0], 2));
      if ($_->[0] =~ /^doc\./) {
	##-- document attribute ("doc.ATTR" convention)
	push(@$gbfilters, $filter) if (defined($filter=$coldb->query2filter($_->[0], $_->[1])));
      }
      else {
	##-- token attribute
	if (defined($_->[1]) && !UNIVERSAL::isa($_->[1], 'DDC::Any::CQTokAny')) {
	  $gbrestr = (defined($gbrestr) ? DDC::Any::CQWith->new($gbrestr,$_->[1]) : $_->[1]);
	}
      }
    }
  }

  ##-- finalize: expression list
  my $xlist = DDC::Any::CQCountKeyExprList->new;
  $xlist->setExprs($gbexprs);

  return ($xlist,$gbrestr,$gbfilters);
}

##--------------------------------------------------------------
## Profiling: Generic

## $mprf = $coldb->profile($relation, %opts)
##  + get a relation profile for selected items as a DiaColloDB::Profile::Multi object
##  + %opts:
##    (
##     ##-- selection parameters
##     query => $query,           ##-- target request ATTR:REQ...
##     date  => $date1,           ##-- string or array or range "MIN-MAX" (inclusive) : default=all
##     ##
##     ##-- aggregation parameters
##     slice   => $slice,         ##-- date slice (default=1, 0 for global profile)
##     groupby => $groupby,       ##-- string or array "ATTR1[:HAVING1] ...": default=$coldb->attrs; see groupby() method
##     ##
##     ##-- scoring and trimming parameters
##     eps     => $eps,           ##-- smoothing constant (default=0)
##     score   => $func,          ##-- scoring function (f|fm|lf|lfm|mi|ld) : default="f"
##     kbest   => $k,             ##-- return only $k best collocates per date (slice) : default=-1:all
##     cutoff  => $cutoff,        ##-- minimum score
##     global  => $bool,          ##-- trim profiles globally (vs. locally for each date-slice?) (default=0)
##     ##
##     ##-- profiling and debugging parameters
##     strings => $bool,          ##-- do/don't stringify output profile(s) (default=do)
##     fill    => $bool,          ##-- if true, returned multi-profile will have null profiles inserted for missing slices
##     onepass => $bool,          ##-- if true, use fast but incorrect 1-pass method (Cofreqs profiling only, >= v0.09.001)
##    )
##  + sets default %opts and wraps $coldb->relation($rel)->profile($coldb, %opts)
sub profile {
  my ($coldb,$rel,%opts) = @_;

  ##-- defaults
  $coldb->profileOptions(\%opts);

  ##-- debug
  $coldb->vlog($coldb->{logRequest},
	       "profile("
	       .join(', ',
		     map {"$_->[0]='".quotemeta($_->[1]//'')."'"}
		     ([rel=>$rel],
		      [query=>$opts{query}],
		      [groupby=>UNIVERSAL::isa($opts{groupby},'ARRAY') ? join(',', @{$opts{groupby}}) : $opts{groupby}],
		      (map {[$_=>$opts{$_}]} qw(date slice score eps kbest cutoff global onepass)),
		     ))
	       .")");

  ##-- relation
  my ($reldb);
  if (!defined($reldb=$coldb->relation($rel||'cof'))) {
    $coldb->logwarn($coldb->{error}="profile(): unknown relation '".($rel//'-undef-')."'");
    return undef;
  }

  ##-- delegate
  return $reldb->profile($coldb,%opts);
}

## \%opts = $CLASS_OR_OBJECT->profileOptions(\%opts)
##  + instantiates default options for profile() method
sub profileOptions {
  my ($that,$opts) = @_;

  ##-- defaults
  $opts->{query}     = (grep {defined($_)} @$opts{qw(query q lemma lem l)})[0] // '';
  $opts->{date}    //= '';
  $opts->{slice}   //= 1;
  $opts->{groupby} ||= join(',', map {quotemeta($_)} @{$that->attrs}) if (ref($that));
  $opts->{score}   //= 'f';
  $opts->{eps}     //= 0; #0.5;
  $opts->{kbest}   //= -1;
  $opts->{cutoff}  //= '';
  $opts->{global}  //= 0;
  $opts->{strings} //= 1;
  $opts->{fill}    //= 0;
  $opts->{onepass} //= 0;

  return $opts;
}

##--------------------------------------------------------------
## Profiling: extend (pass-2 for multi-clients)

## $mprf = $coldb->extend($relation, %opts)
##  + get independent f2 frequencies for $opts{slice2keys}, which is EITHER
##    - a HASH-ref {$slice1=>\@keys1, ...},
##      OR
##    - a JSON-string encoding a such a HASH-ref
##  + %opts, as for profile(), except:
##    (
##     ##-- selection parameters
##     query => $query,           ##-- target request ATTR:REQ... : mostly IGNORED (but used e.g. by ddc back-end)
##     slice2keys => \%slice2keys, ##-- target f2-items or JSON-string
##     ##-- scoring and trimming parameters : IGNORED
##     ##-- profiling and debugging parameters: IGNORED
##    )
##  + returns a DiaColloDB::Profile::Multi containing the appropriate f2 entries
sub extend {
  my ($coldb,$rel,%opts) = @_;

  ##-- defaults
  $coldb->profileOptions(\%opts);

  ##-- items
  $opts{slice2keys} //= '';
  $opts{slice2keys}   = DiaColloDB::Utils::loadJsonString($opts{slice2keys})
    if ($opts{slice2keys} && !ref($opts{slice2keys}));

  ##-- debug
  $coldb->vlog($coldb->{logRequest},
	       "extend("
	       .join(', ',
		     map {"$_->[0]='".quotemeta($_->[1]//'')."'"}
		     ([rel=>$rel],
		      [query=>$opts{query}],
		      [groupby=>UNIVERSAL::isa($opts{groupby},'ARRAY') ? join(',', @{$opts{groupby}}) : $opts{groupby}],
		      (map {[$_=>$opts{$_}]} qw(date slice)),
		     ))
	       .")");

  ##-- relation
  my ($reldb);
  if (!defined($reldb=$coldb->relation($rel||'cof'))) {
    $coldb->logwarn($coldb->{error}="extend(): unknown relation '".($rel//'-undef-')."'");
    return undef;
  }

  ##-- delegate
  return $reldb->extend($coldb,%opts);
}



##--------------------------------------------------------------
## Profiling: Comparison (diff)

## $mprf = $coldb->compare($relation, %opts)
##  + get a relation comparison profile for selected items as a DiaColloDB::Profile::MultiDiff object
##  + %opts:
##    (
##     ##-- selection parameters
##     (a|b)?query => $query,       ##-- target query as for parseRequest()
##     (a|b)?date  => $date1,       ##-- string or array or range "MIN-MAX" (inclusive) : default=all
##     ##
##     ##-- aggregation parameters
##     groupby     => $groupby,     ##-- string or array "ATTR1[:HAVING1] ...": default=$coldb->attrs; see groupby() method
##     (a|b)?slice => $slice,       ##-- date slice (default=1, 0 for global profile)
##     ##
##     ##-- scoring and trimming parameters
##     eps     => $eps,           ##-- smoothing constant (default=0)
##     score   => $func,          ##-- scoring function (f|fm|lf|lfm|mi|ld) : default="f"
##     kbest   => $k,             ##-- return only $k best collocates per date (slice) : default=-1:all
##     cutoff  => $cutoff,        ##-- minimum score (UNUSED for comparison profiles)
##     global  => $bool,          ##-- trim profiles globally (vs. locally for each date-slice?) (default=0)
##     diff    => $diff,          ##-- low-level score-diff operation (diff|adiff|sum|min|max|avg|havg); default='adiff'
##     ##
##     ##-- profiling and debugging parameters
##     strings => $bool,          ##-- do/don't stringify (default=do)
##    )
##  + sets default %opts and wraps $coldb->relation($rel)->compare($coldb, %opts)
BEGIN { *diff = \&compare; }
sub compare {
  my ($coldb,$rel,%opts) = @_;
  $rel //= 'cof';

  ##-- defaults and '[ab]OPTION' parsing
  $coldb->compareOptions(\%opts);

  ##-- debug
  $coldb->vlog($coldb->{logRequest},
	       "compare("
	       .join(', ',
		     map {"$_->[0]=".quotemeta($_->[1]//'')."'"}
		     ([rel=>$rel],
		      (map {["a$_"=>$opts{"a$_"}]} (qw(query date slice))),
		      (map {["b$_"=>$opts{"b$_"}]} (qw(query date slice))),
		      [groupby=>(UNIVERSAL::isa($opts{groupby},'ARRAY') ? join(',',@{$opts{groupby}}) : $opts{groupby})],
		      (map {[$_=>$opts{$_}]} qw(score eps kbest cutoff global diff)),
		     ))
	       .")");

  ##-- relation
  my ($reldb);
  if (!defined($reldb=$coldb->relation($rel||'cof'))) {
    $coldb->logwarn($coldb->{error}="profile(): unknown relation '".($rel//'-undef-')."'");
    return undef;
  }

  ##-- delegate
  return $reldb->compare($coldb,%opts);
}

## \%opts = $CLASS_OR_OBJECT->compareOptions(\%opts)
##  + instantiates default options for compare() method
sub compareOptions {
  my ($that,$opts) = @_;

  ##-- defaults and '[ab]OPTION' parsing
  foreach my $ab (qw(a b)) {
    $opts->{"${ab}query"} = ((grep {defined($_)} @$opts{map {"${ab}$_"} qw(query q lemma lem l)}),
			     (grep {defined($_)} @$opts{qw(query q lemma lem l)}),
			    )[0]//'';
  }
  foreach my $attr (qw(date slice)) {
    $opts->{"a$attr"} = ((map {defined($opts->{"a$_"}) ? $opts->{"a$_"} : qw()} @{$ATTR_RALIAS{$attr}}),
			 (map {defined($opts->{$_})    ? $opts->{$_}    : qw()} @{$ATTR_RALIAS{$attr}}),
			)[0]//'';
    $opts->{"b$attr"} = ((map {defined($opts->{"b$_"}) ? $opts->{"b$_"} : qw()} @{$ATTR_RALIAS{$attr}}),
			 (map {defined($opts->{$_})    ? $opts->{$_}    : qw()} @{$ATTR_RALIAS{$attr}}),
			)[0]//'';
  }
  delete @$opts{keys %ATTR_ALIAS};

  ##-- diff defaults
  $opts->{diff} //= 'adiff';
  $opts->{fill} //= 1;

  ##-- common defaults
  $that->profileOptions($opts);

  return $opts;
}

##==============================================================================
## Footer
1;

__END__
