## -*- Mode: CPerl -*-
##
## File: Compat::v0_09::DiaColloDB.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, top-level: v0.09.x compatibility hack

package DiaColloDB::Compat::v0_09::DiaColloDB;
use DiaColloDB;
use DiaColloDB::Compat::v0_09::Relation;
use DiaColloDB::Compat::v0_09::Relation::Unigrams;
use DiaColloDB::Compat::v0_09::Relation::Cofreqs;
use DiaColloDB::Utils qw(:math :fcntl :json :sort :pack :regex :file :si :run :env :temp);
use DDC::Any; ##-- for query parsing
use File::Path qw(make_path remove_tree);
use Fcntl;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB DiaColloDB::Compat);

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
##    index_tdf => $bool, ##-- tdf: create/use (term x document) frequency matrix index? (default=undef: if available)
##    index_cof => $bool, ##-- cof: create/use co-frequency index (default=1)
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
##    logCorpusFile => $level,  ##-- log-level for corpus file-parsing (default='info')
##    logCorpusFileN => $N,     ##-- log corpus file-parsing only for every N files (0 for none; default:undef ~ $corpus->size()/100)
##    logExport => $level,      ##-- log-level for export messages (default='info')
##    logProfile => $level,     ##-- log-level for verbose profiling messages (default='trace')
##    logRequest => $level,     ##-- log-level for request-level profiling messages (default='debug')
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
##    ${a}2x   => $a2x,     ##-- attribute multimap: $a2x : ($dbdir/${a}_2x.*) : $ai=>@xis  : N=>N*
##    pack_x$a => $fmt      ##-- pack format: extract attribute-id $ai from a packed tuple-string $xs ; $ai=unpack($coldb->{"pack_x$a"},$xs)
##    ##
##    ##-- tuple data (+dates)
##    xenum  => $xenum,     ##-- enum: tuples ($dbdir/xenum.*) : [@ais,$di]<=>$xi : N*n<=>N
##    pack_x => $fmt,       ##-- symbol pack-format for $xenum : "${pack_id}[Nattrs]${pack_date}"
##    xdmin => $xdmin,      ##-- minimum date
##    xdmax => $xdmax,      ##-- maximum date
##    ##
##    ##-- relation data
##    xf    => $xf,       ##-- ug: $xi => $f($xi) : N=>N
##    cof   => $cof,      ##-- cf: [$xi1,$xi2] => $f12
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
		      index_tdf => undef,
		      index_cof => 1,
		      dbreak => undef,
		      tdfopts => {},

		      ##-- filters
		      pgood => $DiaColloDB::PGOOD_DEFAULT,
		      pbad  => $DiaColloDB::PBAD_DEFAULT,
		      wgood => $DiaColloDB::WGOOD_DEFAULT,
		      wbad  => $DiaColloDB::WBAD_DEFAULT,
		      lgood => $DiaColloDB::LGOOD_DEFAULT,
		      lbad  => $DiaColloDB::LBAD_DEFAULT,
		      #vsmgood => $DiaColloDB::TDF_MGOOD_DEFAULT,
		      #vsmbad  => $DiaColloDB::TDF_MBAD_DEFAULT,

		      ##-- logging
		      logOpen => 'info',
		      logCreate => 'info',
		      logCorpusFile => 'info',
		      logCorpusFileN => undef,
		      logExport => 'info',
		      logProfile => 'trace',
		      logRequest => 'debug',

		      ##-- limits
		      maxExpand => 65535,

		      ##-- administrivia
		      version => "v0.09.000",
		      #upgraded=>[],

		      ##-- attributes
		      #lenum => undef, #$ECLASS->new(pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_len}),
		      #l2x   => undef, #$MMCLASS->new(pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_id}),
		      #pack_xl => 'N',

		      ##-- tuples (+dates)
		      #xenum  => undef, #$XECLASS::FixedLen->new(pack_i=>$coldb->{pack_id}, pack_s=>$coldb->{pack_x}),
		      #pack_x => 'Nn',

		      ##-- relations
		      #xf    => undef, #DiaColloDB::Relation::Unigrams->new(packas=>$coldb->{pack_f}),
		      #cof   => undef, #DiaColloDB::Relation::Cofreqs->new(pack_f=>$pack_f, pack_i=>$pack_i, dmax=>$dmax, fmin=>$cfmin),
		      #ddc   => undef, #DiaColloDB::Relation::DDC->new(),
		      #tdf   => undef, #DiaColloDB::Relation::TDF->new(),

		      @_,	##-- user arguments
		     },
		     ref($that)||$that);
  $coldb->{class}  = ref($coldb);
  $coldb->{pack_w} = $coldb->{pack_id};
  $coldb->{pack_x} = $coldb->{pack_w} . $coldb->{pack_date};
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
  $coldb->loadHeader()
    or $coldb->logconfess("open(): failed to load header file", $coldb->headerFile, ": $!");
  @$coldb{keys %opts} = values %opts; ##-- clobber header options with user-supplied values

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
  my $axat = 0;
  foreach my $attr (@$attrs) {
    ##-- open: ${attr}*
    my $abase = (-r "$dbdir/${attr}_enum.hdr" ? "$dbdir/${attr}_" : "$dbdir/${attr}"); ##-- v0.03-compatibility hack
    $coldb->{"${attr}enum"} = $ECLASS->new(base=>"${abase}enum", %efopts)
      or $coldb->logconfess("open(): failed to open enum ${abase}enum.*: $!");
    $coldb->{"${attr}2x"} = $MMCLASS->new(base=>"${abase}2x", %mmopts)
      or $coldb->logconfess("open(): failed to open expansion multimap ${abase}2x.*: $!");
    $coldb->{"pack_x$attr"} //= "\@${axat}$coldb->{pack_id}";
    $axat += packsize($coldb->{pack_id});
  }

  ##-- open: xenum
  $coldb->{xenum} = $XECLASS->new(base=>"$dbdir/xenum", %efopts, pack_s=>$coldb->{pack_x})
      or $coldb->logconfess("open(): failed to open tuple-enum $dbdir/xenum.*: $!");
  if (!defined($coldb->{xdmin}) || !defined($coldb->{xdmax})) {
    ##-- hack: guess date-range if not specified
    $coldb->vlog('warn', "Warning: extracting date-range from xenum: you should update $coldb->{dbdir}/header.json");
    my $pack_xdate  = '@'.(packsize($coldb->{pack_id}) * scalar(@{$coldb->attrs})).$coldb->{pack_date};
    my ($dmin,$dmax,$d) = ('inf','-inf');
    foreach (@{$coldb->{xenum}->toArray}) {
      next if (!$_);
      next if (!defined($d = unpack($pack_xdate,$_))); ##-- strangeness: getting only 9-bytes in $_ for 10-byte values in file and toArray(): why?!
      $dmin = $d if ($d < $dmin);
      $dmax = $d if ($d > $dmax);
    }
    $coldb->vlog('warn', "extracted date-range \"xdmin\":$dmin, \"xdmax\":$dmax");
    @$coldb{qw(xdmin xdmax)} = ($dmin,$dmax);
  }

  ##-- open: xf
  $coldb->{xf} = DiaColloDB::Compat::v0_09::Relation::Unigrams->new(file=>"$dbdir/xf.dba", flags=>$flags, packas=>$coldb->{pack_f}, logCompat=>'off')
    or $coldb->logconfess("open(): failed to open tuple-unigrams $dbdir/xf.dba: $!");
  $coldb->{xf}{N} = $coldb->{xN} if ($coldb->{xN} && !$coldb->{xf}{N}); ##-- compat

  ##-- open: cof
  if ($coldb->{index_cof}//1) {
    $coldb->{cof} = DiaColloDB::Compat::v0_09::Relation::Cofreqs->new(base=>"$dbdir/cof", flags=>$flags,
								      pack_i=>$coldb->{pack_id}, pack_f=>$coldb->{pack_f},
								      dmax=>$coldb->{dmax}, fmin=>$coldb->{cfmin},
								      logCompat=>'off',
								     )
      or $coldb->logconfess("open(): failed to open co-frequency file $dbdir/cof.*: $!");
  }

  ##-- open: ddc (undef if ddcServer isn't set in ddc.hdr or $coldb)
  $coldb->{ddc} = DiaColloDB::Relation::DDC->new(-r "$dbdir/ddc.hdr" ? (base=>"$dbdir/ddc") : qw())->fromDB($coldb)
    // 'DiaColloDB::Relation::DDC';

  ##-- open: tdf (if available)
  if ($coldb->{index_tdf}) {
    $coldb->{tdfopts}     //= {};
    $coldb->{tdfopts}{$_} //= $DiaColloDB::TDF_OPTS{$_} foreach (keys %DiaColloDB::TDF_OPTS);                ##-- tdf: default options
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
	  (ref($_[0]) ? (map {($_."enum",$_."2x")} @{$_[0]->attrs}) : qw()),
	  qw(xenum xf cof tdf),
	 );
}

## $coldb_or_undef = $coldb->close()
##  + INHERITED from DiaColloDB

## $bool = $coldb->opened()
##  + INHERITED from DiaColloDB

## @files = $obj->diskFiles()
##  + returns list of dist files for this db
##  + INHERITED from DiaColloDB

##==============================================================================
## Create/compile

##--------------------------------------------------------------
## create: utils

## $multimap = $coldb->create_xmap($base, \%xs2i, $packfmt, $label="multimap")
BEGIN { *create_xmap = DiaColloDB::Compat->nocompat('create_xmap'); }

## \@attrs = $coldb->attrs()
## \@attrs = $coldb->attrs($attrs=$coldb->{attrs}, $default=[])
##  + parse attributes in $attrs as array
##  + INHERITED from DiaColloDB

## $aname = $CLASS_OR_OBJECT->attrName($attr)
##  + returns canonical (short) attribute name for $attr
##  + supports aliases in %ATTR_ALIAS = ($alias=>$name, ...)
##  + see also:
##     %ATTR_RALIAS = ($name=>\@aliases, ...)
##     %ATTR_CBEXPR = ($name=>$ddcCountByExpr, ...)
##     %ATTR_TITLE = ($name_or_alias=>$title, ...)
##  + INHERITED from DiaColloDB
our %ATTR_ALIAS = %DiaColloDB::ATTR_ALIAS;
our %ATTR_RALIAS = %DiaColloDB::ATTR_RALIAS;
our %ATTR_TITLE = %DiaColloDB::ATTR_TITLE;
our %ATTR_CBEXPR = %DiaColloDB::ATTR_CBEXPR;

## $atitle = $CLASS_OR_OBJECT->attrTitle($attr_or_alias)
##  + returns an attribute title for $attr_or_alias
##  + INHERITED from DiaColloDB

## $acbexpr = $CLASS_OR_OBJECT->attrCountBy($attr_or_alias,$matchid=0)
##  + INHERITED from DiaColloDB

## $aquery_or_filter_or_undef = $CLASS_OR_OBJECT->attrQuery($attr_or_alias,$cquery)
##  + returns a CQuery or CQFilter object for condition $cquery on $attr_or_alias
##  + INHERITED from DiaColloDB

## \@attrdata = $coldb->attrData()
## \@attrdata = $coldb->attrData(\@attrs=$coldb->attrs)
##  + get attribute data for \@attrs
##  + return @attrdata = ({a=>$attr, i=>$i, enum=>$aenum, pack_x=>$pack_xa, a2x=>$a2x, ...})
sub attrData {
  my ($coldb,$attrs) = @_;
  $attrs //= $coldb->attrs;
  my ($attr);
  return [map {
    $attr = $coldb->attrName($attrs->[$_]);
    {i=>$_, a=>$attr, enum=>$coldb->{"${attr}enum"}, pack_x=>$coldb->{"pack_x$attr"}, a2x=>$coldb->{"${attr}2x"}}
  } (0..$#$attrs)];
}

## $bool = $coldb->hasAttr($attr)
##  + INHERITED from DiaColloDB


##--------------------------------------------------------------
## create: from corpus

## $bool = $coldb->create($corpus,%opts)
##  + %opts:
##     $key => $val,  ##-- clobbers $coldb->{$key}
##  + DISABLED
BEGIN { *create = DiaColloDB::Compat->nocompat('create'); }

##--------------------------------------------------------------
## create: union (aka merge)

## $coldb = $CLASS_OR_OBJECT->union(\@coldbs_or_dbdirs,%opts)
##  + populates $coldb as union over @coldbs_or_dbdirs
##  + clobbers argument dbs {_union_${a}i2u}, {_union_xi2u}, {_union_argi}
##  + DISABLED
BEGIN { *merge = *union = DiaColloDB::Compat->nocompat('union'); }

##--------------------------------------------------------------
## I/O: header
##  + largely INHERITED from DiaColloDB::Persistent

## @keys = $coldb->headerKeys()
##  + keys to save as header
##  + INHERITED from DiaColloDB

## $bool = $coldb->loadHeaderData()
## $bool = $coldb->loadHeaderData($data)
##  + INHERITED from DiaColloDB

## $bool = $coldb->saveHeader()
## $bool = $coldb->saveHeader($headerFile)
##  + INHERITED from DiaColloDB::Persistent

##==============================================================================
## Export/Import

## $bool = $coldb->dbexport()
## $bool = $coldb->dbexport($outdir,%opts)
##  + $outdir defaults to "$coldb->{dbdir}/export"
##  + %opts:
##     export_sdat => $bool,  ##-- whether to export *.sdat (stringified tuple files for debugging; default=0)
##     export_cof  => $bool,  ##-- do/don't export cof.* (default=do)
##     export_tdf  => $bool,  ##-- do/don't export tdf.* (default=do)
sub dbexport {
  my ($coldb,$outdir,%opts) = @_;
  $coldb->logconfess("cannot dbexport() an un-opened DB") if (!$coldb->opened);
  $outdir //= "$coldb->{dbdir}/export";
  $outdir  =~ s{/$}{};
  $coldb->vlog('info', "export($outdir/)");

  ##-- options
  my $export_sdat = exists($opts{export_sdat}) ? $opts{export_sdat} : 0;
  my $export_cof  = exists($opts{export_cof}) ? $opts{export_cof} : 1;
  my $export_tdf  = exists($opts{export_tdf}) ? $opts{export_tdf} : 1;

  ##-- create export directory
  -d $outdir
    or make_path($outdir)
      or $coldb->logconfess("dbexport(): could not create export directory $outdir: $!");

  ##-- dump: header
  $coldb->saveHeader("$outdir/header.json")
    or $coldb->logconfess("dbexport(): could not export header to $outdir/header.json: $!");

  ##-- dump: load enums
  my $adata  = $coldb->attrData();
  $coldb->vlog($coldb->{logExport}, "dbexport(): loading enums to memory");
  $coldb->{xenum}->load() if ($coldb->{xenum} && !$coldb->{xenum}->loaded);
  foreach (@$adata) {
    $_->{enum}->load() if ($_->{enum} && !$_->{enum}->loaded);
  }

  ##-- dump: common: stringification
  my $pack_x = $coldb->{pack_x};
  my ($xs2txt,$xi2txt);
  if ($export_sdat) {
    $coldb->vlog($coldb->{logExport}, "dbexport(): preparing tuple-stringification structures");

    foreach (@$adata) {
      my $i2s     = $_->{i2s} = $_->{enum}->toArray;
      $_->{i2txt} = sub { return $i2s->[$_[0]//0]//''; };
    }

    my $xi2s = $coldb->{xenum}->toArray;
    my @ai2s = map {$_->{i2s}} @$adata;
    my (@x);
    $xs2txt = sub {
      @x = unpack($pack_x,$_[0]);
      return join("\t", (map {$ai2s[$_][$x[$_]//0]//''} (0..$#ai2s)), $x[$#x]//0);
    };
    $xi2txt = sub {
      @x = unpack($pack_x, $xi2s->[$_[0]//0]//'');
      return join("\t", (map {$ai2s[$_][$x[$_]//0]//''} (0..$#ai2s)), $x[$#x]//0);
    };
  }

  ##-- dump: xenum: raw
  $coldb->vlog($coldb->{logExport}, "dbexport(): exporting raw tuple-enum file $outdir/xenum.dat");
  $coldb->{xenum}->saveTextFile("$outdir/xenum.dat", pack_s=>$pack_x)
    or $coldb->logconfess("export failed for $outdir/xenum.dat");

  ##-- dump: xenum: stringified
  if ($export_sdat) {
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting stringified tuple-enum file $outdir/xenum.sdat");
    $coldb->{xenum}->saveTextFile("$outdir/xenum.sdat", pack_s=>$xs2txt)
      or $coldb->logconfess("dbexport() failed for $outdir/xenum.sdat");
  }

  ##-- dump: by attribute: enum
  foreach (@$adata) {
    ##-- dump: by attribute: enum
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting attribute enum file $outdir/$_->{a}_enum.dat");
    $_->{enum}->saveTextFile("$outdir/$_->{a}_enum.dat")
      or $coldb->logconfess("dbexport() failed for $outdir/$_->{a}_enum.dat");
  }

  ##-- dump: by attribute: a2x
  foreach (@$adata) {
    ##-- dump: by attribute: a2x: raw
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting attribute expansion multimap $outdir/$_->{a}_2x.dat (raw)");
    $_->{a2x}->saveTextFile("$outdir/$_->{a}_2x.dat")
      or $coldb->logconfess("dbexport() failed for $outdir/$_->{a}_2x.dat");

    ##-- dump: by attribute: a2x: stringified
    if ($export_sdat) {
      $coldb->vlog($coldb->{logExport}, "dbexport(): exporting attribute expansion multimap $outdir/$_->{a}_2x.sdat (strings)");
      $_->{a2x}->saveTextFile("$outdir/$_->{a}_2x.sdat", a2s=>$_->{i2txt}, b2s=>$xi2txt)
	or $coldb->logconfess("dbexport() failed for $outdir/$_->{a}_2x.sdat");
    }
  }

  ##-- dump: xf
  if ($coldb->{xf}) {
    ##-- dump: xf: raw
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting tuple-frequency index $outdir/xf.dat");
    $coldb->{xf}->setFilters($coldb->{pack_f});
    $coldb->{xf}->saveTextFile("$outdir/xf.dat", keys=>1)
      or $coldb->logconfess("export failed for $outdir/xf.dat");
    $coldb->{xf}->setFilters();

    ##-- dump: xf: stringified
    if ($export_sdat) {
      $coldb->vlog($coldb->{logExport}, "dbexport(): exporting stringified tuple-frequency index $outdir/xf.sdat");
      $coldb->{xf}->saveTextFile("$outdir/xf.sdat", key2s=>$xi2txt)
      or $coldb->logconfess("dbexport() failed for $outdir/xf.sdat");
    }
  }

  ##-- dump: cof
  if ($coldb->{cof} && $export_cof) {
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting raw co-frequency index $outdir/cof.dat");
    $coldb->{cof}->saveTextFile("$outdir/cof.dat")
      or $coldb->logconfess("export failed for $outdir/cof.dat");

    if ($export_sdat) {
      $coldb->vlog($coldb->{logExport}, "dbexport(): exporting stringified co-frequency index $outdir/cof.sdat");
      $coldb->{cof}->saveTextFile("$outdir/cof.sdat", i2s=>$xi2txt)
	or $coldb->logconfess("export failed for $outdir/cof.sdat");
    }
  }

  ##-- dump: tdf
  if ($coldb->{tdf} && $coldb->{index_tdf} && $export_tdf) {
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting term-document index $outdir/tdf.*");
    $coldb->{tdf}->export("$outdir/tdf", $coldb)
      or $coldb->logconfess("export failed for $outdir/tdf.*");
  }

  ##-- all done
  $coldb->vlog($coldb->{logExport}, "dbexport(): export to $outdir complete.");
  return $coldb;
}

## $coldb = $coldb->dbimport()
## $coldb = $coldb->dbimport($txtdir,%opts)
##  + import ColocDB data from $txtdir
##  + TODO
sub dbimport {
  my ($coldb,$txtdir,%opts) = @_;
  $coldb = $coldb->new() if (!ref($coldb));
  $coldb->logconfess("dbimport(): not yet implemented");
}

##==============================================================================
## Info

## \%info = $coldb->dbinfo()
##  + get db info
##  + INHERITED from DiaColloDB


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
##  + INHERITED from DiaColloDB

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $obj_or_undef = $coldb->relation($rel)
##  + returns an appropriate relation-like object for profile() and friends
##  + wraps $coldb->{$coldb->relname($rel)}
##  + INHERITED from DiaColloDB

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## @relnames = $coldb->relations()
##  + gets list of defined relations
##  + INHERITED from DiaColloDB

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
##  + INHERITED from DiaColloDB

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## ($dfilter,$sliceLo,$sliceHi,$dateLo,$dateHi) = $coldb->parseDateRequest($dateRequest='', $sliceRequest=0, $fill=0, $ddcMode=0)
##   + parses date request and returns limit and filter information as a list (list context) or HASH-ref (scalar context);
##   + %dateRequest =
##     (
##      dfilter => $dfilter,  ##-- filter-sub, called as: $wanted=$dfilter->($date); undef for none
##      slo  => $sliceLo,     ##-- minimum slice (inclusive)
##      shi  => $sliceHi,     ##-- maximum slice (inclusive)
##      dlo  => $dateLo,      ##-- minimum date (inclusive); undef for none, always defined if $fill is true
##      dhi  => $dateHi,      ##-- maximum date (inclusive); undef for none, always defined if $fill is true
##     )
##  + INHERITED from DiaColloDB

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## \%slice2xids = $coldb->xidsByDate(\@xids, $dateRequest, $sliceRequest, $fill)
##   + parse and filter \@xids by $dateRequest, $sliceRequest
##   + returns a HASH-ref from slice-ids to \@xids in that date-slice
##   + if $fill is true, returned HASH-ref has a key for each date-slice in range
##  + OBSOLETE in DiaColloDB
sub xidsByDate {
  my ($coldb,$xids,$date,$slice,$fill) = @_;
  my ($dfilter,$slo,$shi,$dlo,$dhi) = $coldb->parseDateRequest($date,$slice,$fill);

  ##-- filter xids
  my $xenum  = $coldb->{xenum};
  my $pack_x = $coldb->{pack_x};
  my $pack_i = $coldb->{pack_id};
  my $pack_d = $coldb->{pack_date};
  my $pack_xd = "@".(packsize($pack_i) * scalar(@{$coldb->{attrs}})).$pack_d;
  my $d2xis  = {}; ##-- ($dateKey => \@xis_at_date, ...)
  my ($xi,$d);
  foreach $xi (@$xids) {
    $d = unpack($pack_xd, $xenum->i2s($xi));
    next if (($dfilter && !$dfilter->($d)) || $d < $coldb->{xdmin} || $d > $coldb->{xdmax});
    $d = $slice ? int($d/$slice)*$slice : 0;
    push(@{$d2xis->{$d}}, $xi);
  }

  ##-- force-fill?
  if ($fill && $slice) {
    for ($d=$slo; $d <= $shi; $d += $slice) {
      $d2xis->{$d} //= [];
    }
  }

  return $d2xis;
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $compiler = $coldb->qcompiler();
##  + get DDC::Any::CQueryCompiler for this object (cached in $coldb->{_qcompiler})
##  + INHERITED from DiaColloDB

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $cquery_or_undef = $coldb->qparse($ddc_query_string)
##  + wraps parse in an eval {...} block and sets $coldb->{error} on failure
##  + INHERITED from DiaColloDB


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $cquery = $coldb->parseQuery([[$attr1,$val1],...], %opts) ##-- compat: ARRAY-of-ARRAYs
## $cquery = $coldb->parseQuery(["$attr1:$val1",...], %opts) ##-- compat: ARRAY-of-requests
## $cquery = $coldb->parseQuery({$attr1=>$val1, ...}, %opts) ##-- compat: HASH
## $cquery = $coldb->parseQuery("$attr1=$val1, ...", %opts)  ##-- compat: string
## $cquery = $coldb->parseQuery($ddcQueryString, %opts)      ##-- ddc string (with shorthand ","->WITH, "&&"->WITH)
##  + guts for parsing user target and groupby requests
##  + returns a DDC::Any::CQuery object representing the request
##  + index-only items "$l" are mapped to $l=@{}
##  + %opts:
##     warn  => $level,       ##-- log-level for unknown attributes (default: 'warn')
##     logas => $reqtype,     ##-- request type for warnings
##     default => $attr,      ##-- default attribute (for query requests)
##     mapand => $bool,       ##-- map CQAnd to CQWith? (default=true unless '&&' occurs in query string)
##     ddcmode => $bool,      ##-- force ddc query mode? (default=false)
##  + INHERITED from DiaColloDB

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
##  + INHERITED from DiaColloDB

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## \@aqs = $coldb->parseRequest($request, %opts)
##  + guts for parsing user target and groupby requests into attribute-wise ARRAY-ref [[$attr1,$val1], ...]
##  + see parseQuery() method for supported $request formats and %opts
##  + wraps $coldb->queryAttributes($coldb->parseQuery($request,%opts))
##  + INHERITED from DiaColloDB

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## \%groupby = $coldb->groupby($groupby_request, %opts)
## \%groupby = $coldb->groupby(\%groupby,        %opts)
##  + $grouby_request : see parseRequest()
##  + returns a HASH-ref:
##    (
##     req => $request,      ##-- save request
##     #x2g => \&x2g,        ##-- group-tuple extraction code suitable for e.g. DiaColloDB::Relation::Cofreqs::profile(groupby=>\&x2g) ##--OLD
##     xi2g => \&xi2g,       ##-- group-tuple extraction code ($xi => $gtuple) suitable for e.g. DiaColloDB::Relation::Cofreqs::profile(groupby=>\&x2g) ##--OLD
##     xs2g => \&xs2g,       ##-- group-tuple extraction code ($xs => $gtuple)
##     g2s => \&g2s,         ##-- stringification object suitable for DiaColloDB::Profile::stringify() [CODE,enum, or undef]
##     g2txt => \&g2txt,     ##-- compatible join()-string stringifcation sub
##     xpack => \@xpack,     ##-- group-attribute-wise pack-templates, given @xtuple
##     gpack => \@gpack,     ##-- group-attribute-wise pack-templates, given @gtuple
##     areqs => \@areqs,     ##-- parsed attribute requests ([$attr,$ahaving],...)
##     attrs => \@attrs,     ##-- like $coldb->attrs($groupby_request), modulo "having" parts
##     titles => \@titles,   ##-- like map {$coldb->attrTitle($_)} @attrs
##    )
##  + %opts:
##     warn  => $level,    ##-- log-level for unknown attributes (default: 'warn')
##     relax => $bool,     ##-- allow unsupported attributes (default=0)
##     xenum => $xenum,    ##-- enum to use for \&x2g and \&g2s (default: $coldb->{xenum})
##  + OVERRIDES DiaColloDB
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
  my $xenum  = $opts{xenum} // $coldb->{xenum};
  my $pack_id = $coldb->{pack_id};
  my $pack_ids = "($pack_id)*";
  my $len_id  = packsize($pack_id);
  my @gbxpack = @{$gb->{xpack} = [map {$coldb->{"pack_x$_"}} @$gbattrs]};
  my $gbxpack = join('',@gbxpack);
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

  my (@gi,$xi2g_code,$xs2g_code);
  if (grep {$_} @gbids) {
    ##-- group-by code: with having-filters
    $xs2g_code = (''
		  .qq{ \@gi=unpack('$gbxpack',\$_[0]);}
		  .qq{ return undef if (}.join(' || ', map {"!exists(\$gbids[$_]{\$gi[$_]})"} grep {defined($gbids[$_])} (0..$#gbids)).qq{);}
		  .qq{ return pack('$pack_ids',\@gi); }
		 );
  }
  else {
    ##-- group-by code: no filters
    $xs2g_code = qq{ pack('$pack_ids', unpack('$gbxpack', \$_[0])) };
  }
  my $xs2g_sub  = eval qq{sub {$xs2g_code}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile tuple-based aggregation code sub {$xs2g_code}: $@") if (!$xs2g_sub);
  $@='';
  $gb->{xs2g} = $xs2g_sub;

  ($xi2g_code = $xs2g_code) =~ s{\$_\[0\]}{\$xenum->i2s(\$_[0])};
  my $xi2g_sub  = eval qq{sub {$xi2g_code}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile id-base aggregation code sub {$xi2g_code}: $@") if (!$xi2g_sub);
  $@='';
  $gb->{xi2g} = $xi2g_sub;

  ##-- get stringification sub
  my ($genum,@genums,$g2scode);
  if (@$gbattrs == 1) {
    ##-- stringify a single attribute
    $genum   = $coldb->{$gbattrs->[0]."enum"};
    $g2scode = qq{ \$genum->i2s(unpack('$pack_id',\$_[0])) };
  }
  else {
    @genums = map {$coldb->{$_."enum"}} @$gbattrs;
    $g2scode = (''
		.qq{ \@gi=unpack('$pack_ids', \$_[0]); }
		.q{ join("\t",}.join(', ', map {"\$genums[$_]->i2s(\$gi[$_])"} (0..$#genums)).q{)}
	       );
  }
  my $g2s = eval qq{sub {$g2scode}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile stringification code sub {$g2scode}: $@") if (!$g2s);
  $@='';
  $gb->{g2s} = $g2s;

  ##-- get pseudo-stringification sub ("\t"-joined decimal integer ids)
  my ($g2txt_code);
  if (@$gbattrs == 1) {
    ##-- stringify a single attribute
    $g2txt_code = qq{ unpack('$pack_id',\$_[0]) };
  }
  else {
    $g2txt_code = qq{ join("\t",unpack('$pack_ids', \$_[0])); };
  }
  my $g2txt = eval qq{sub {$g2txt_code}};
  $coldb->logconfess($coldb->{error}="groupby(): could not compile pseudo-stringification code sub {$g2txt_code}: $@") if (!$g2txt);
  $@='';
  $gb->{g2txt} = $g2txt;

  return $gb;
}

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## $cqfilter = $coldb->query2filter($attr,$cquery,%opts)
##  + converts a CQToken to a CQFilter, for ddc parsing
##  + %opts:
##     logas => $logas,   ##-- log-prefix for warnings
##  + INHERITED from DiaColloDB

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## ($CQCountKeyExprs,\$CQRestrict,\@CQFilters) = $coldb->parseGroupBy($groupby_string_or_request,%opts)
##  + for ddc-mode parsing
##  + %opts:
##     date => $date,
##     slice => $slice,
##     matchid => $matchid,    ##-- default match-id
##  + INHERITED from DiaColloDB

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
##     strings => $bool,          ##-- do/don't stringify (default=do)
##     fill    => $bool,          ##-- if true, returned multi-profile will have null profiles inserted for missing slices
##     onepass => $bool,          ##-- if true, use fast but incorrect 1-pass method (Cofreqs profiling only)
##    )
##  + sets default %opts and wraps $coldb->relation($rel)->profile($coldb, %opts)
##  + INHERITED from DiaColloDB

## \%opts = $CLASS_OR_OBJECT->profileOptions(\%opts)
##  + instantiates default options for profile() method
##  + INHERITED from DiaColloDB

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
##  + INHERITED from DiaColloDB

## \%opts = $CLASS_OR_OBJECT->compareOptions(\%opts)
##  + instantiates default options for compare() method
##  + INHERITED from DiaColloDB

##==============================================================================
## Footer
1;

__END__
