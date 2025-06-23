## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Relation::TDF.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profiling relation: co-occurence frequencies via (term x document) raw-frequency matrix
##  + formerly DiaColloDB::Relation::Vsem.pm ("vector-space distributional semantic index")

package DiaColloDB::Relation::TDF;
use DiaColloDB::Relation;
use DiaColloDB::Relation::TDF::Query;
use DiaColloDB::Utils qw(:pack :fcntl :file :math :json :list :pdl :temp :env :run :jobs :sort);
use DiaColloDB::PackedFile;
#use DiaColloDB::Temp::Hash;
#use DiaColloDB::Temp::Array;
use DiaColloDB::PDL::MM;
use DiaColloDB::PDL::Utils;
use File::Path qw(make_path remove_tree);
use PDL;
use PDL::IO::FastRaw;
use PDL::CCS;
use PDL::CCS::IO::FastRaw;
use Fcntl qw(:DEFAULT SEEK_SET SEEK_CUR SEEK_END);
use File::Basename qw(dirname);
use version;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Relation);
BEGIN {
  no warnings 'once';
  $PDL::BIGPDL = 1; ##-- avoid 'Probably false alloc of over 1Gb PDL' errors

  PDL::no_clone_skip_warning() ##-- silence 'check out PDL::Parallel::threads' warning
      if (UNIVERSAL::can('PDL','no_clone_skip_warning'));
}


##==============================================================================
## Constructors etc.

## $vs = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##   ##-- user options
##   base   => $basename,   ##-- relation basename
##   flags  => $flags,      ##-- i/o flags (default: 'r')
##   mgood  => $regex,      ##-- positive filter regex for metadata attributes
##   mbad   => $regex,      ##-- negative filter regex for metadata attributes
##   submax => $submax,     ##-- choke on requested tdm cross-subsets if dense subset size ($NT_sub * $ND_sub) > $submax; default=2**29 (512M)
##   mquery => \%mquery,    ##-- qinfo templates for meta-fields (default: textClass hack for genre): ($mattr=>$TEMPLATE, ...)
##   ##
##   ##-- logging options
##   logvprofile => $level, ##-- log-level for vprofile() (default='trace')
##   logvdebug => $level,   ##-- log-level for vprofile() debugging (default=undef:none)
##   logio => $level,       ##-- log-level for low-level I/O operations (default=undef:none)
##   logCompat => $level,   ##-- log-level for compatibility warnings (default='warn')
##   ##
##   ##-- modelling options (formerly via DocClassify)
##   minFreq    => $fmin,   ##-- minimum total term-frequency for model inclusion (default=undef:use $coldb->{tfmin})
##   minDocFreq => $dfmin,  ##-- minimim "doc-frequency" (#/docs per term) for model inclusion (default=4)
##   minDocSize => $dnmin,  ##-- minimum doc size (#/tokens per doc) for model inclusion (default=4; formerly $coldb->{vbnmin})
##   maxDocSize => $dnmax,  ##-- maximum doc size (#/tokens per doc) for model inclusion (default=inf; formerly $coldb->{vbnmax})
##   #smoothf    => $f0,     ##-- smoothing constant to avoid log(0); default=1
##   vtype      => $vtype,  ##-- PDL::Type for storing compiled values (default=float; auto-promoted if required)
##   itype      => $itype,  ##-- PDL::Type for storing compiled integers (default=long)
##   ##
##   ##-- guts: aux: info
##   N => $tdm0Total,       ##-- total number of (doc,term) frequencies counted
##   dbreak => $dbreak,     ##-- inherited from $coldb on create()
##   version => $version,   ##-- file version, for compatibility checks
##   ##
##   ##-- guts: aux: term-tuples ($NA:number of term-attributes, $NT:number of term-tuples)
##   attrs  => \@attrs,       ##-- known term attributes
##   tvals  => $tvals,        ##-- pdl($NA,$NT) : [$apos,$ti] => $avali_at_term_ti
##   tsorti => $tsorti,       ##-- pdl($NT,$NA) : [,($apos)]  => $tvals->slice("($apos),")->qsorti
##   tpos   => \%a2pos,       ##-- term-attribute positions: $apos=$a2pos{$aname}
##   ##
##   ##-- guts: aux: metadata ($NM:number of metas-attributes, $NC:number of cats (source files))
##   meta => \@mattrs         ##-- known metadata attributes
##   meta_e_${ATTR} => $enum, ##-- metadata-attribute enum
##   mvals => $mvals,         ##-- pdl($NM,$NC) : [$mpos,$ci] => $mvali_at_ci
##   msorti => $msorti,       ##-- pdl($NC,$NM) : [,($mpos)]  => $mvals->slice("($mpos),")->qsorti
##   mpos  => \%m2pos,        ##-- meta-attribute positions: $mpos=$m2pos{$mattr}
##   ##
##   ##-- guts: model (formerly via DocClassify dcmap=>$dcmap)
##   tdm => $tdm,             ##-- term-doc matrix : PDL::CCS::Nd ($NT,$ND): [$ti,$di] -> f($ti,$di)
##   tym => $tym,             ##-- term-year matrix: PDL::CCS::Nd ($NT,$NY): [$ti,$yi] -> f($ti,$yi)
##   cf  => $cf_pdl,          ##-- cat-freq pdl:     dense:       ($NC)    : [$ci]     -> f($ci)
##   yf  => $yf_pdl,          ##-- year-freq pdl:    dense:       ($NY)    : [$yi-$y0] -> f($yi)
##   y0  => $y0,              ##-- minimum year: scalar
##   #tf  => $tf_pdl,          ##-- term-freq pdl:   dense:       ($NT)    : [$ti]     -> f($ti)
##   #tw  => $tw_pdl,          ##-- term-weight pdl: dense:       ($NT)    : [$ti]     -> ($wRaw=0) + ($wCooked=1)*w($ti)
##   #                         ##   + where w($t) = 1 - H(Doc|T=$t) / H_max(Doc) ~ DocClassify termWeight=>'max-entropy-quotient'
##   c2date => $c2date,       ##-- cat-dates   : dense ($NC)   : [$ci]   -> $date
##   c2d    => $c2d,          ##-- cat->doc map: dense (2,$NC) : [*,$ci] -> [$di_off,$di_len]
##   d2c    => $d2c,          ##-- doc->cat map: dense ($ND)   : [$di]   -> $ci
##   #...
##   )
sub new {
  my $that = shift;
  my $vs   = $that->SUPER::new(
			       flags => 'r',
			       mgood => $DiaColloDB::TDF_MGOOD_DEFAULT,
			       mbad  => $DiaColloDB::TDF_MBAD_DEFAULT,
			       submax => 2**29,
			       mquery => {
					  'doc.genre' => '* #HAS[textClass,/^\Q__W2__\E/]',
					  'doc.pnd'   => '* #has[author,/\Q__W2__\E/]',
					 },
			       minFreq => undef,
			       minDocFreq => 4,
			       minDocSize => 4,
			       maxDocSize => 'inf',
			       #smoothf => 1,
			       vtype => 'float',
			       itype => 'long',
			       meta  => [],
			       attrs => [],
			       ##
			       logvprofile  => 'trace',
                               logvdebug  => undef, #trace,
			       logio => undef, #'trace',
			       logCompat => 'warn',
			       ##
			       version => $DiaColloDB::VERSION,
			       ##
			       @_
			      );
  return $vs->open() if ($vs->{base});
  return $vs;
}

##==============================================================================
## TDF API: Utils

## $vtype = $vs->vtype()
##  + get PDL::Type for storing compiled values
sub vtype {
  return $_[0]{vtype} if (UNIVERSAL::isa($_[0]{vtype},'PDL::Type'));
  return $_[0]{vtype} = (PDL->can($_[0]{vtype}//'float') // PDL->can('float'))->();
}

## $itype = $vs->itype()
##  + get PDL::Type for storing indices
sub itype {
  return $_[0]{itype} if (UNIVERSAL::isa($_[0]{vtype},'PDL::Type'));
  foreach ($_[0]{itype}, 'indx', 'long') {
    return $_[0]{itype} = PDL->can($_)->() if (defined($_) && PDL->can($_));
  }
}

## $packas = $vs->vpack()
##  + pack-template for $vs->vtype e.g. "f*"
sub vpack {
  return $PDL::Types::pack[ $_[0]->vtype->enum ];
}

## $packas = $vs->ipack()
##  + pack-template for $vs->itype e.g. "l*"
sub ipack {
  return $PDL::Types::pack[ $_[0]->itype->enum ];
}


##==============================================================================
## Persistent API: disk usage

## @files = $obj->diskFiles()
##  + returns disk storage files, used by du() and timestamp()
sub diskFiles {
  return ("$_[0]{base}.hdr", "$_[0]{base}.d");
}

##==============================================================================
## Persistent API: header

## @keys = $obj->headerKeys()
##  + keys to save as header; default implementation returns all keys of all non-references
sub headerKeys {
  my $obj = shift;
  return (qw(meta attrs vtype itype), grep {$_ !~ m/(?:flags|perms|base|log)/} $obj->SUPER::headerKeys);
}

## $hdr = $obj->headerData()
##  + returns reference to object header data; default returns anonymous HASH-ref for $obj->headerKeys()
##  + override stringifies {vtype}, {itype}
sub headerData {
  my $obj = shift;
  my $hdr = $obj->SUPER::headerData(@_);
  $hdr->{vtype} = "$hdr->{vtype}" if (ref($hdr->{vtype}));
  $hdr->{itype} = "$hdr->{itype}" if (ref($hdr->{itype}));
  return $hdr;
}


##==============================================================================
## Relation API: open/close

## $vs_or_undef = $vs->open($base)
## $vs_or_undef = $vs->open($base,$flags)
## $vs_or_undef = $vs->open()
sub open {
  my ($vs,$base,$flags) = @_;
  $base  //= $vs->{base};
  $flags //= $vs->{flags};
  $vs->close() if ($vs->opened);
  $vs->{base}  = $base;
  $vs->{flags} = $flags = fcflags($flags);

  my ($hdr); ##-- save header, for version-checking
  if (fcread($flags) && !fctrunc($flags)) {
    $hdr = $vs->readHeader()
      or $vs->logconfess("failed to read header data from '$vs->{base}.hdr': $!");
    $vs->loadHeaderData($hdr)
      or $vs->logconfess("failed to load header data from '$vs->{base}.hdr': $!");
  }

  ##-- check compatibility
  my $min_version = qv(0.12.000);
  if ($hdr && (!defined($hdr->{version}) || version->parse($hdr->{version}) < $min_version)) {
    $vs->vlog($vs->{logCompat}, "using v0.11 compatibility mode for $vs->{base}.*; consider running \`dcdb-upgrade.perl ", dirname($vs->{base}), "\'");
    #DiaColloDB::Compat->usecompat('v0_11');
    DiaColloDB::Compat->usecompat('v0_11::Relation::TDF');
    bless($vs, 'DiaColloDB::Compat::v0_11::Relation::TDF');
    $vs->{version} = $hdr->{version};
    return $vs->open($base,$flags);
  }

  ##-- open: maybe create directory
  my $vsdir = "$vs->{base}.d";
  if (!-d $vsdir) {
    $vs->logconfess("open(): no such directory '$vsdir'") if (!fccreat($flags));
    make_path($vsdir)
      or $vs->logconfess("open(): could not create relation directory '$vsdir': $!");
  }

  ##-- open: model data
  my %ioopts = (ReadOnly=>!fcwrite($flags), mmap=>1, log=>$vs->{logio});
  defined($vs->{tdm} = readPdlFile("$vsdir/tdm", class=>'PDL::CCS::Nd', %ioopts))
    or $vs->logconfess("open(): failed to load term-document frequency matrix from $vsdir/tdm.*: $!");
  defined($vs->{tym} = readPdlFile("$vsdir/tym", class=>'PDL::CCS::Nd', %ioopts))
    or $vs->logconfess("open(): failed to load term-year frequency matrix from $vsdir/tym.*: $!");
  defined($vs->{cf}  = readPdlFile("$vsdir/cf.pdl", %ioopts))
    or $vs->logconfess("open(): failed to load cat-frequencies from $vsdir/cf.pdl: $!");
  defined($vs->{yf}  = readPdlFile("$vsdir/yf.pdl", %ioopts))
    or $vs->logconfess("open(): failed to load year-frequencies from $vsdir/yf.pdl: $!");

  defined(my $ptr0 = $vs->{ptr0} = readPdlFile("$vsdir/tdm.ptr0.pdl", %ioopts))
    or $vs->logwarn("open(): failed to load Harwell-Boeing pointer from $vsdir/tdm.ptr0.pdl: $!");
  defined(my $ptr1 = $vs->{ptr1} = readPdlFile("$vsdir/tdm.ptr1.pdl", %ioopts))
    or $vs->logwarn("open(): failed to load Harwell-Boeing pointer from $vsdir/tdm.ptr1.pdl: $!");
  defined(my $pix1 = $vs->{pix1} = readPdlFile("$vsdir/tdm.pix1.pdl", %ioopts))
    or $vs->logwarn("open(): failed to load Harwell-Boeing indices from $vsdir/tdm.pix1.pdl: $!");
  $vs->{tdm}->setptr(0, $ptr0)        if (defined($ptr0));
  $vs->{tdm}->setptr(1, $ptr1,$pix1)  if (defined($ptr1) && defined($pix1));

  ##-- open: aux data: piddles
  foreach (qw(tvals tsorti mvals msorti d2c c2d c2date)) {
    defined($vs->{$_}=readPdlFile("$vsdir/$_.pdl", %ioopts))
      or $vs->logconfess("open(): failed to load piddle data from $vsdir/$_.pdl: $!");
  }

  ##-- open: metadata: enums
  my %efopts = (flags=>$vs->{flags}); #, pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_len}
  foreach my $mattr (@{$vs->{meta}}) {
    $vs->{"meta_e_$mattr"} = $DiaColloDB::ECLASS->new(base=>"$vsdir/meta_e_$mattr", %efopts)
      or $vs->logconfess("open(): failed to open metadata enum $vsdir/meta_e_$mattr: $!");
  }

  return $vs;
}

## $vs_or_undef = $vs->close()
sub close {
  my $vs = shift;
  if ($vs->opened && fcwrite($vs->{flags})) {
    $vs->saveHeader() or return undef;
#   $vs->{dcmap}->saveDir("$vs->{base}_map.d", %{$vs->{dcio}//{}})
#     or $vs->logconfess("close(): failed to save mapper data to $vs->{base}_map.d: $!");
  }
  delete @$vs{qw(base N tdm tym cf yf tw attrs tvals tsorti tpos meta mvals msorti mpos d2c c2d d2date)};
  return $vs;
}

## $bool = $obj->opened()
sub opened {
  my $vs = shift;
  return UNIVERSAL::isa($vs->{tdm},'PDL::CCS::Nd');
}

##==============================================================================
## Relation API: creation

##--------------------------------------------------------------
## Relation API: creation: create

## $vs = $CLASS_OR_OBJECT->create($coldb,$tokdat_file,%opts)
##  + populates current database for $coldb
##  + reqires:
##    - (temporary, tied) doc-arrays @$coldb{qw(docmeta docoff)}
##    - temp file "$coldb->{dbdir}/vtokens.bin": pack($coldb->{pack_t}, @wattrs)
##      OR
##      wdmfile=>$wdmfile option
##  + %opts: clobber %$vs, also:
##    (
##     docmeta=>\@docmeta,  ##-- for union(): override $coldb->{docmeta}
##                          ##   $docmeta[$ci] = {id=>$id, nsigs=>$nsigs, file=>$rawfile, date=>$date, label=>$label, meta=>\%meta}
##     wdmfile=>$wdmfile,   ##-- for union(): txt ~ "$ai0 $ai1 ... $aiN $doci $f"; default is generated from 'vtokens.bin'
##     ivalmax=>$imax,      ##-- for union(): maximum integer value (for auto-promotion)
##     reusedir=>$bool,     ##-- for union(): set to true if we're running in a "clean" directory
##     logas   => $logas,   ##-- log label (default: 'create()')
##    )
sub create {
  my ($vs,$coldb,$datfile,%opts) = @_;
  env_push(LC_ALL=>'C');

  ##-- create/clobber
  $vs = $vs->new() if (!ref($vs));
  @$vs{keys %{$coldb->{tdfopts}//{}}} = values %{$coldb->{tdfopts}//{}};
  @$vs{keys %opts} = values %opts;

  ##-- sanity check(s)
  my $docmeta = $opts{docmeta} // $coldb->{docmeta};
  my $docoff  = $coldb->{docoff};
  my $wdmfile = $opts{wdmfile};
  my $base    = $vs->{base};
  my $logas   = $opts{logas} || 'create()';
  my $logCreate = $vs->{logCreate} // $coldb->{logCreate} // 'trace';
  $vs->logconfess("$logas: no source document array {docmeta} in parent DB") if (!UNIVERSAL::isa($docmeta,'ARRAY'));
  $vs->logconfess("$logas: no source document offsets {docoff} in parent DB") if (!$wdmfile && !UNIVERSAL::isa($coldb->{docoff},'ARRAY'));
  $vs->logconfess("$logas: wdmfile=$wdmfile specified but unreadable") if ($wdmfile && !-r $wdmfile);
  $vs->logconfess("$logas: no 'base' key defined") if (!$base);

  ##-- non-persistent option keys
  delete @$vs{grep {exists $opts{$_}} qw(docmeta wdmfile logas reusedir)}; #ivalmax

  ##-- open packed token-attribute file
  my $vtokfile = "$coldb->{dbdir}/vtokens.bin";
  my ($vtokfh);
  $wdmfile
    or CORE::open($vtokfh, "<:raw", $vtokfile)
    or $vs->logconfess("$logas: could not open temporary token file $vtokfile: $!");

  ##-- initialize: output directory
  my $vsdir = "$base.d";
  $vsdir =~ s{/$}{};
  !-d $vsdir
    or $opts{reusedir}
    or remove_tree($vsdir)
    or $vs->logconfess("$logas: could not remove stale $vsdir: $!");
  -d $vsdir
    or make_path($vsdir)
    or $vs->logconfess("$logas: could not create TDF directory $vsdir: $!");

  ##-- initialize: index-type (auto-promote)
  my $imax0    = $opts{ivalmax};
  my $nnz_v    = $vtokfh ? ((-s $vtokfh) / packsize($coldb->{pack_t})) : undef;
  my $nsigs0   = $docoff ? $docoff->[$#$docoff] : undef;
  my $nterms0  = $coldb->{tenum}->size;
  my $imax     = lmax($imax0, $nnz_v, $nsigs0, $nterms0);
  my $imintype = DiaColloDB::Utils::mintype($imax, qw(ushort long indx));
  $vs->info("$logas: using PDL integer type $imintype (max value = $imax)");
  $vs->{itype} = $imintype;

  ##-- initialize: logging
  my $nfiles    = scalar(@$docmeta);
  my $logFileN  = $coldb->{logCorpusFileN} // max2(1,int($nfiles/10));

  ##-- initialize: metadata
  my %meta = qw(); ##-- ( $meta_attr => {n=>$nkeys, s2i=>\%s2i, vals=>$pdl}, ... )
  my $mgood = $vs->{mgood} ? qr{$vs->{mgood}} : undef;
  my $mbad  = $vs->{mbad}  ? qr{$vs->{mbad}}  : undef;

  ##-- create temp file: tdm0.dat (sorted via system sort command)
  my $NA      = scalar(@{$coldb->{attrs}});
  my $NC      = $nfiles;
  my $itype   = $vs->itype;
  my $vtype   = $vs->vtype;
  my $pack_t   = $coldb->{pack_t};
  my $len_t    = packsize($pack_t);
  my $pack_ix = $vs->ipack;
  (my $pack_ix1 = $pack_ix) =~ s/\*$//;
  my $len_ix  = packsize($pack_ix,0);
  my $pack_nz = $vs->vpack;
  my $pack_date = $PDL::Types::pack[ ushort->enum ];
  my $len_date  = packsize($pack_date,0);
  my %tmpargs   = (UNLINK=>!$coldb->{keeptmp});
  my $tdm0file  = $wdmfile || "$vsdir/tdm0.dat";   # txt ~ "$ai0 $ai1 ... $aiN $doci $f"
  my ($tdm0fh);
  if (!$wdmfile) {
    ##-- v0.12.012_03 : use temporary $tdm0file.tmp so that later (sort TMPFILE) can do its parallel thing
    CORE::open($tdm0fh, ">:raw", "$tdm0file.tmp")
        or $vs->logconfess("$logas: failed to open temporary file $tdm0file.tmp: $!");
  }

  ##-- create cat-wise piddle files c2date.pdl, c2d.pdl
  my $c2datefile = "$vsdir/c2date.pdl";				##-- c2date ($NC): [$ci]   -> $date
  CORE::open(my $c2datefh, ">:raw", $c2datefile)
    or $vs->logconfess("$logas: failed to create piddle file $c2datefile: $!");
  writePdlHeader("$c2datefile.hdr", ushort, 1, $NC)
    or $vs->logconfess("$logas: failed to write piddle header $c2datefile.hdr: $!");
  my $c2dfile = "$vsdir/c2d.pdl";				##-- c2d  (2,$NC): [0,$ci] => $di_off, [1,$ci] => $di_len
  CORE::open(my $c2dfh, ">:raw", $c2dfile)
      or $vs->logconfess("$logas: failed to create piddle file $c2dfile: $!");
  writePdlHeader("$c2dfile.hdr", $itype, 2, 2,$NC)
    or $vs->logconfess("$logas: failed to write piddle header $c2dfile.hdr: $!");

  ##-- create: tdf-sig: simulate DocClassify::Mapper::trainCorpus(): populate tdm0.*, c2date.*, c2d.*
  $vs->vlog($logCreate, "$logas: processing input documents [NA=$NA, NC=$nfiles]");
  my $json   = DiaColloDB::Utils->jsonxs();
  my $minDocSize = $vs->{minDocSize} = max2(($vs->{minDocSize}//0),1);
  my $maxDocSize = $vs->{maxDocSize} = min2(($vs->{maxDocSize}//'inf'),'inf');
  my ($doc,$filei,$doclabel,$docid);
  my ($mattr,$mval,$mdata,$mvali,$mvals);
  my ($ts,$ti,$f, $sigi_in,$sigj_in,$sigi_out0,$sigi_out, $toki,$tokj,%sig,$sign,$buf);
  my ($tmp);
  $sigi_in = $sigi_out = (0,0);
  foreach $doc (@$docmeta) {
    $doclabel = $doc->{file} // $doc->{meta}{basename} // $doc->{meta}{file_} // $doc->{label};
    $vs->vlog($coldb->{logCorpusFile}, sprintf("$logas: processing signatures [%3.0f%%]: %s", 100*($filei-1)/$nfiles, $doclabel))
      if ($logFileN && ($filei++ % $logFileN)==0);

    $docid = $doc->{id} // ++$docid;

    #$vs->debug("c2date: id=$docid/$NC ; doc=$doclabel");
    $c2datefh->seek($docid*$len_date, SEEK_SET);
    $c2datefh->print(pack($pack_date, $doc->{date}));

    $c2dfh->seek($docid*$len_ix*2, SEEK_SET);
    $c2dfh->print(pack($pack_ix1, $sigi_out0=$sigi_out));

    ##-- parse metadata
    #$vs->debug("meta: id=$docid/$NC ; doc=$doclabel");
    while (($mattr,$mval) = each %{$doc->{meta}//{}}) {
      next if ((defined($mgood) && $mattr !~ $mgood) || (defined($mbad) && $mattr =~ $mbad));
      if (!defined($mdata=$meta{$mattr})) {
	$mdata = $meta{$mattr} = {
				  n=>1,
				  s2i=>tmphash("$vsdir/ms2i_${mattr}", utf8keys=>1, %tmpargs),
				  vals=>tmparrayp("$vsdir/mvals_$mattr", $pack_ix1, %tmpargs),
				 };
	$mdata->{s2i}{''} = 0;
      }
      $mvali = ($mdata->{s2i}{($mval//'')} //= $mdata->{n}++);
      $mdata->{vals}[$docid] = $mvali;
    }

    ##-- parse document signatures into $tdm0file.tmp (unsorted for now)
    #$vs->debug("sigs: id=$docid/$NC ; doc=$doclabel");
    if (defined $vtokfh) {
      $sigj_in = $sigi_in + $doc->{nsigs};
      for ( ; $sigi_in < $sigj_in; ++$sigi_in) {
	$toki = $docoff->[$sigi_in];
	$tokj = $docoff->[$sigi_in+1];

	#$vs->logconfess("$logas: bad offset in $vtokfile") if ($vtokfh->tell != $toki*$len_t); ##-- DEBUG

	##-- parse signature
	%sig  = qw();
	$sign = $tokj - $toki;
	for ( ; $toki < $tokj; ++$toki) {
	  CORE::read($vtokfh, $buf, $len_t)
	      or $vs->logconfess("$logas: read() failed on $vtokfile: $!");
	  ++$sig{$buf};
	}
	next if ($sign <= $minDocSize || $sign >= $maxDocSize);

	##-- populate tdm0.dat
	while (($ts,$f) = each %sig) {
	  $tdm0fh->print(join(' ', unpack($pack_t,$ts), $sigi_out, $f),"\n");
	}
	++$sigi_out;
      }
    } else {
      $sigi_out += $doc->{nsigs};
    }

    ##-- update c2d (length)
    $c2dfh->print(pack($pack_ix1, $sigi_out - $sigi_out0));
  }

  ##-- cleanup
  $c2dfh->close() or $vs->logconfess("$logas: close failed for tempfile $c2dfile: $!");
  $c2datefh->close() or $vs->logconfess("$logas: close failed for tempfile $c2datefile: $!");
  !$tdm0fh or $tdm0fh->close() or $vs->logconfess("$logas: close failed for tempfile $tdm0file.tmp: $!");
  tied(@{$_->{vals}})->flush() foreach (values %meta);

  ##-- v0.12.012_03: sort tdm0file.tmp -> tdm0file
  if (!$wdmfile) {
    runcmd(join(' ', sortCmd(), (map {"-nk$_"} (1..($NA+1))), "$tdm0file.tmp", "-o", $tdm0file))==0
      or $vs->logconfess("$logas: failed to sort for $tdm0file.tmp: $!");
    CORE::unlink("$tdm0file.tmp")
      or $vs->logconfess("$logas: failed to unlink $tdm0file.tmp: $!");
  }

  ##-- create: filter: filter by term-frequency (default: use coldb term-filtering only)
  $vs->{minFreq} //= 0;
  my ($wbad);
  if ($vs->{minFreq} > 0) {
    my $fmin = $vs->{minFreq};
    $vs->vlog($logCreate, "$logas: filter: by term-frequency (minFreq=$vs->{minFreq})");
    $wbad = tmphash("$vsdir/wbad", %tmpargs);
    CORE::open($tdm0fh, "<:raw", $tdm0file)
	or $vs->logconfess("$logas: re-open failed for $tdm0file: $!");
    my ($w,$f);
    my ($wcur,$fcur) = ('INITIAL','inf');
    my $NT0 = 0;
    my $NT1 = 0;
    while (defined($_=<$tdm0fh>)) {
      ($w,$f) = /^(.*) [0-9]+ ([0-9]+)$/;
      if ($w eq $wcur) {
	$fcur += $f;
      } else {
	++$NT0;
	if ($fcur < $fmin) {
	  $wbad->{$wcur} = undef;
	} else {
	  ++$NT1;
	}
	($wcur,$fcur)  = ($w,$f);
      }
    }
    ++$NT0;
    if ($fcur < $fmin) {
      $wbad->{$wcur} = undef;
    } else {
      ++$NT1;
    }
    CORE::close($tdm0fh);

    my $nwbad = ($NT0-$NT1);
    my $pwbad = $NT0 ? sprintf("%.2f%%", 100*$nwbad/$NT0) : 'nan%';
    $vs->vlog($logCreate, "$logas: filter: will prune $nwbad of $NT0 term tuple type(s) ($pwbad)");
  }

  ##-- create: tdf-filter: filter by doc-frequency
  $vs->{minDocFreq} //= 0;
  if ($vs->{minDocFreq} > 0) {
    $vs->vlog($logCreate, "$logas: filter: by doc-frequency (minDocFreq=$vs->{minDocFreq})");
    my $cmdfh = opencmd("cut -d\" \" -f-$NA $tdm0file | uniq -c |")
      or $vs->logconfess("$logas: failed to open pipe from uniq for doc-frequency filter");
    $wbad //= tmphash("$vsdir/wbad", %tmpargs);
    my $fmin = $vs->{minDocFreq};
    my $NT0  = 0;
    my $NT1  = 0;
    my ($f,$w);
    while (defined($_=<$cmdfh>)) {
      chomp;
      ($f,$w) = split(' ',$_,2);
      ++$NT0;
      if ($f < $fmin) {
	$wbad->{$w} = undef;
      } else {
	++$NT1;
      }
    }
    CORE::close($cmdfh);

    my $nwbad = ($NT0-$NT1);
    my $pwbad = $NT0 ? sprintf("%.2f%%", 100*$nwbad/$NT0) : 'nan%';
    $vs->vlog($logCreate, "$logas: filter: will prune $nwbad of $NT0 term tuple type(s) ($pwbad)");
  }

  ##-- create: filter: term-enum $tvals (+temporary %$ts2i)
  $vs->vlog($logCreate, "$logas: extracting term tuples");
  my $NT   = 0;
  my $NT0  = 0;
  my $ttxtfh = opencmd("cut -d\" \" -f-$NA $tdm0file | uniq |")
    or $vs->logconfess("$logas: open failed for pipe from uniq for term-values: $!");
  my $tvalsfile = "$vsdir/tvals.pdl";
  CORE::open(my $tvalsfh, ">:raw", $tvalsfile)
    or $vs->logconfess("$logas: open failed for term-values piddle $tvalsfile: $!");

  ##-- %$ts2i: text proto-enum: "$ai1 $ai2 ... $aiN" => $ti
  #$vs->vlog("debug", "$logas: using temporary term translation table $vsdir/ts2i.*");
  #my $ts2i = tmphash("$vsdir/ts2i", %tmpargs);
  ##--
  $vs->vlog("debug", "$logas: using in-memory term translation hash");
  my $ts2i = {};

  ##-- create: filter: term-enum: always include "null" term
  {
    my @tnull = map {0} (1..$NA);
    $ts2i->{join(' ', @tnull)} = 0;
    $tvalsfh->print(pack($pack_ix, @tnull));
  }

  ##-- create: filter: term-enum: enumerate "normal" terms in $tvalsfile
  while (defined($_=<$ttxtfh>)) {
    chomp;
    ++$NT0;
    next if ($wbad && exists($wbad->{$_}));
    $tvalsfh->print(pack($pack_ix, split(' ',$_)));
    $ts2i->{$_} = ++$NT;
  }
  ++$NT;
  $tvalsfh->close()
    or $vs->logconfess("$logas: failed to close term-values piddle file $tvalsfile: $!");
  $ttxtfh->close()
    or $vs->logconfess("$logas: failed to close term-values sort pipe: $!");
  writePdlHeader("$tvalsfile.hdr", $itype, 2, $NA,$NT)
    or $vs->logconfess("$logas: failed to write term-values header $tvalsfile.hdr: $!");
  defined(my $tvals = readPdlFile($tvalsfile))
    or $vs->logconfess("$logas: failed to mmap term-values file $tvalsfile: $!");
  ++$NT0; ##-- allow for "null" term
  my $pprunet = $NT0 ? sprintf("%.2f%%", 100*($NT0-$NT)/$NT0) : 'nan%';
  $vs->vlog($logCreate, "$logas: extracted $NT of $NT0 unique term tuples ($pprunet pruned)");

  ##-- create: tdf-matrix: tdm0: ccs
  my $ND  = $sigi_out;
  $vs->vlog($logCreate, "$logas: creating raw term-document matrix $vsdir/tdm.* (NT=$NT, ND=$ND)");
  my $ixfile = "$vsdir/tdm.ix";
  CORE::open(my $ixfh, ">:raw", $ixfile)
      or $vs->logconfess("$logas: open failed for tdm index file $ixfile: $!");
  my $nzfile = "$vsdir/tdm.nz";
  CORE::open(my $nzfh, ">:raw", $nzfile)
      or $vs->logconfess("$logas: open failed for tdm value file $nzfile: $!");
  CORE::open($tdm0fh, "<:raw", $tdm0file)
      or $vs->logconfess("$logas: re-open failed for tdm text file $tdm0file: $!");
  my ($di);
  my $nnz0 = 0;
  my $nnz  = 0;
  my ($w);
  while (defined($_=<$tdm0fh>)) {
    ++$nnz0;
    ($w,$di,$f) = m{^(.*) ([0-9]+) ([0-9]+)$};
    next if (!defined($ti=$ts2i->{$w}));
    ++$nnz;
    $ixfh->print(pack($pack_ix,$ti,$di));
    $nzfh->print(pack($pack_nz,$f));
  }
  $nzfh->print(pack($pack_nz,0)); ##-- include "missing" value
  CORE::close($nzfh)
      or $vs->logconfess("$logas: close failed for tdm value file $nzfile: $!");
  CORE::close($ixfh)
      or $vs->logconfess("$logas: close failed for tdm index file $ixfile: $!");
  CORE::close($tdm0fh);
  undef $ts2i;
  my $density  = sprintf("%.2g%%", $nnz / ($ND*$NT));
  my $pprunenz = $nnz0 ? sprintf("%.2f%%", 100*($nnz0-$nnz)/$nnz0) : 'nan%';
  $vs->vlog($logCreate, "$logas: created raw term-document matrix (density=$density, $pprunenz pruned)");

  ##-- create: tdm0: read in as piddle
  writePdlHeader("$vsdir/tdm.ix.hdr", $itype, 2, 2,$nnz)
    or $vs->logconfess("$logas: failed to save tdm index header $vsdir/tdm.ix.hdr: $!");
  writePdlHeader("$vsdir/tdm.nz.hdr", $vtype, 1, $nnz+1)
    or $vs->logconfess("$logas: failed to save tdm value header $vsdir/tdm.nz.hdr: $!");
  writeCcsHeader("$vsdir/tdm.hdr", $itype,$vtype,[$NT,$ND])
    or $vs->logconfess("$logas: failed to save CCS header $vsdir/tdm.hdr: $!");
  defined(my $tdm = readPdlFile("$vsdir/tdm", class=>'PDL::CCS::Nd'))
    or $vs->logconfess("$logas: failed to map CCS term-document matrix from $vsdir/tdm.*");

  ##-- create: aux: N
  ## + previously computed as $tdm->_vals->sum()
  ##   - large Zipfian matrices lose LOTS of precision (~50%) if we only use sum(), e.g. dtak+dtae
  ##   - IEEE-floats get us 24-bit integer precision  --> max N = 16M
  ##   - IEEE-doubles get us 53-bit integer precision --> max N = 18P
  ## + map-reduce on uint64_t accumulator would be a better solution (max N = 16E), but isn't immediately pdl-able
  $vs->{N} = $tdm->_vals->dsum;
  $vs->vlog($logCreate, "$logas: computed total corpus size = $vs->{N}");

  ##-- create: aux: d2c: [$di] => $ci
  $vs->vlog($logCreate, "$logas: creating doc<->category translation piddles (ND=$ND, NC=$NC)");
  defined(my $c2d = readPdlFile("$vsdir/c2d.pdl"))
    or $vs->logconfess("$logas: failed to mmap $vsdir/c2d.pdl");
  $c2d->slice("(1),")->rld(sequence($itype,$NC), my $d2c=mmzeroes("$vsdir/d2c.pdl",$itype,$ND));
  undef $c2d;

  ##-- create: aux: cf: ($NC): [$ci] -> f($ci)
  $vs->vlog($logCreate, "$logas: creating cat-frequency piddle $vsdir/cf.pdl (NC=$NC)");
  $tdm->_nzvals->indadd( $d2c->index($tdm->_whichND->slice("(1),")), my $cf=mmzeroes("$vsdir/cf.pdl",$vtype,$NC));
  #undef $cf;

  ##-- create: aux: yf: ($NY): [$yi] -> f($yi)
  defined(my $c2date = readPdlFile("$c2datefile"))
    or $vs->logconfess("$logas: failed to mmap $c2datefile");
  my ($ymin,$ymax) = $c2date->minmax;
  my $NY = $ymax-$ymin+1;
  $vs->vlog($logCreate, "$logas: creating year-frequency piddle $vsdir/yf.pdl (NY=$NY)");
  $cf->indadd( ($c2date-$ymin), my $yf=mmzeroes("$vsdir/yf.pdl",$vtype,$NY) );
  $vs->{y0} = $ymin;

  ##-- cleanup: yf,cf
  undef $yf;
  undef $cf;

  ##-- create: aux: tym: ($NT,$NY): [$ti,$yi] -> f($ti,$yi)
  $vs->vlog($logCreate, "$logas: creating term-year matrix $vsdir/tym.*");

  ##-- tym: create using local memory-optimized pdl-pp method
  my $tymsub = PDL->can('diacollo_tym_create_'.$vs->itype) || \&PDL::diacollo_tym_create_long;
  $tymsub->($tdm->_whichND, $tdm->_vals, $d2c, $c2date, (my $tym_nnz=pdl($itype,0)), "$vsdir/tym.ix", "$vsdir/tym.nz");
  writePdlHeader("$vsdir/tym.ix.hdr", $itype, 2, 2,$tym_nnz)
    or $vs->logconfess("$logas: failed to save tym index header $vsdir/tym.ix.hdr: $!");
  writePdlHeader("$vsdir/tym.nz.hdr", $vtype, 1, $tym_nnz+1)
    or $vs->logconfess("$logas: failed to save tdm value header $vsdir/tym.nz.hdr: $!");
  writeCcsHeader("$vsdir/tym.hdr", $itype,$vtype,[$NT,$ymax+1])
    or $vs->logconfess("$logas: failed to save CCS header $vsdir/tym.hdr: $!");

  ##-- tym: cleanup
  undef $c2date;
  undef $c2d;
  undef $d2c;

  ##-- create: aux: tdm: pointers
  $vs->vlog($logCreate, "$logas: creating tdm matrix Harwell-Boeing pointers");
  my ($ptr0) = $tdm->getptr(0);
  $ptr0      = $ptr0->convert($itype) if ($ptr0->type != $itype);
  $ptr0->writefraw("$vsdir/tdm.ptr0.pdl")
    or $vs->logconfess("$logas: failed to write $vsdir/tdm.ptr0.pdl: $!");
  undef $ptr0;

  my ($ptr1,$pix1) = $tdm->getptr(1);
  $ptr1 = $ptr1->convert($itype) if ($ptr1->type != $itype);
  $pix1 = $pix1->convert($itype) if ($pix1->type != $itype && pdl($itype,$pix1->nelem)->sclr >= 0); ##-- check for overflow
  $ptr1->writefraw("$vsdir/tdm.ptr1.pdl")
    or $vs->logconfess("$logas: failed to write $vsdir/tdm.ptr1.pdl: $!");
  $pix1->writefraw("$vsdir/tdm.pix1.pdl")
    or $vs->logconfess("$logas: failed to write $vsdir/tdm.pix1.pdl: $!");
  undef $ptr1;
  undef $pix1;
  undef $tdm;

  ##-- create: aux: tsorti
  $vs->vlog($logCreate, "$logas: creating term-attribute sort-indices (NA=$NA x NT=$NT)");
  my $tsorti = mmzeroes("$vsdir/tsorti.pdl", $itype, $NT,$NA); ##-- [,($apos)] => $tvals->slice("($apos),")->qsorti
  foreach (0..($NA-1)) {
    $tvals->slice("($_),")->qsorti($tsorti->slice(",($_)"));
  }
  undef $tsorti;
  ##
  $vs->{attrs} = $coldb->{attrs}; ##-- save local copy of attributes

  ##-- create: aux: metadata attributes
  @{$vs->{meta}} = sort keys %meta;
  my %efopts     = (flags=>$vs->{flags}, pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_len});
  my $NM         = scalar @{$vs->{meta}};
  $mvals         = $vs->{mvals} = mmzeroes("$vsdir/mvals.pdl", $itype,$NM,$NC); ##-- [$mpos,$ci] => $mvali_at_ci : keep
  my ($menum);
  foreach (0..($NM-1)) {
    $vs->vlog($logCreate, "$logas: creating metadata enum for attribute '$vs->{meta}[$_]'");
    $mattr = $vs->{meta}[$_];
    $mdata = $meta{$mattr};
    $menum = $vs->{"meta_e_$mattr"} = $DiaColloDB::ECLASS->new(%efopts);
    if ($mdata->{vals}) {
      $#{$mdata->{vals}} = ($NC-1);   ##-- ensure correct size for toPdl(), avoid 'bus error' trying to mmap() beyond file boundaries
      tied(@{$mdata->{vals}})->flush; ##-- ensure data has been flushed to disk
    }
    defined(my $mmvals = readPdlFile("$vsdir/mvals_$mattr.pf", ReadOnly=>1,Dims=>[$NC],Datatype=>$itype))
      or $vs->logconfess("$logas: failed to mmap $vsdir/mvals_$mattr.pf");
    ($tmp=$mvals->slice("($_),")) .= $mmvals;
    undef $mmvals;
    delete $mdata->{vals};
    $menum->fromHash($mdata->{s2i})
      or $vs->logconfess("$logas: failed to create metadata enum for attribute '$mattr': $!");
    $menum->save("$vsdir/meta_e_$mattr")
      or $vs->logconfess("$logas: failed to save metadata enum $vsdir/meta_e_$mattr: $!");
  }
  ##
  $vs->vlog($logCreate, "$logas: creating metadata sort-indices (NM=$NM x NC=$NC)");
  my $msorti = $vs->{msorti} = mmzeroes("$vsdir/msorti.pdl", $itype, $NC,$NM); ##-- [,($mi)] => $mvals->slice("($mi),")->qsorti
  foreach (0..($NM-1)) {
    $mvals->slice("($_),")->qsorti($msorti->slice(",($_)"));
  }

  ##-- save: header
  $vs->vlog($logCreate, "$logas: saving to $base*");
  $vs->saveHeader()
    or $vs->logconfess("$logas: failed to save header data: $!");

  ##-- cleanup: temps
  if (!$coldb->{keeptmp}) {
    $wdmfile
      or CORE::unlink($tdm0file)
      or $vs->logconfess("$logas: failed to unlink tempfile $tdm0file: $!");
  }

  ##-- return
  env_pop();
  return $vs;
}

##--------------------------------------------------------------
## Relation API: creation: union

## $vs = CLASS_OR_OBJECT->union($coldb, \@dbargs, %opts)
##  + merge multiple tdf indices into new object
##  + @dbargs : array of sub-objects ($coldb,...) containing {tdf} keys
##  + %opts: clobber %$vs
##  + hack: creates temp-files utdm0.dat and udocmeta.tmp and calls create()
sub union {
  my ($vs,$coldb,$dbargs,%opts) = @_;
  #$vs->logconfess("union(): not yet implemented");
  env_push(LC_ALL=>'C');

  ##-- union: create/clobber
  $vs = $vs->new() if (!ref($vs));
  @$vs{keys %{$coldb->{tdfopts}//{}}} = values %{$coldb->{tdfopts}//{}};
  @$vs{keys %opts} = values %opts;

  ##-- union: sanity checks
  my $base = $vs->{base};
  $vs->logconfess("union(): no 'base' key defined") if (!$base);

  ##-- union: output directory
  my $vsdir = "$base.d";
  $vsdir =~ s{/$}{};
  !-d $vsdir
    or remove_tree($vsdir)
      or $vs->logconfess("union(): could not remove stale $vsdir: $!");
  make_path($vsdir)
    or $vs->logconfess("union(): could not create TDF directory $vsdir: $!");

  ##-- union: logging
  my $logCreate = $coldb->{logCreate};
  my $logLocal  = 'trace';

  ##-- union: save local copy of attributes
  $vs->{attrs} = $coldb->{attrs};

  ##-- union: index-type (auto-promote)
  my $Nnz     = lsum(map {$_->{tdf}{tdm}->_nnz} grep {$_->{tdf}} @$dbargs);
  my $NTmax   = lsum(map {$_->{tdf}->nTerms} grep {$_->{tdf}} @$dbargs);
  my $ND      = lsum(map {$_->{tdf}->nDocs} grep {$_->{tdf}} @$dbargs);
  my $NC      = lsum(map {$_->{tdf}->nCats} grep {$_->{tdf}} @$dbargs);
  my $ivalmax = lmax($Nnz, $NTmax, $ND, $NC);

  ##-- union: common variables
  my $itype = $vs->itype;
  my $vtype = $vs->vtype;
  my $pack_ix = $vs->ipack;
  (my $pack_ix1 = $pack_ix) =~ s/\*$//;
  my %tmpargs = (UNLINK=>!$coldb->{keeptmp});
  my ($tmp,$tmp1);

  ##-- union: tdm0.dat (txt)
  my $NA       = scalar @{$vs->{attrs}};
  my $tdm0file = "$vsdir/utdm0.dat";
  $vs->vlog($logCreate, "union(): extracting attribute-document data to $tdm0file");
  my $tdm0fh   = opencmd("|-:raw", join(' ', sortCmd(), (map {"-nk$_"} (1..($NA+1))), "-o", $tdm0file))
    or $vs->logconfess("union(): failed to create pipe to sort for tempfile $tdm0file: $!");
  my $Doff = 0;
  foreach my $dbai (grep {$dbargs->[$_]{tdf}} (0..$#$dbargs)) {
    my $dba  = $dbargs->[$dbai];
    my $dbvs = $dba->{tdf};
    $vs->vlog($logCreate, "union(): processing tdm data for $dbvs->{base}");
    my $dbtvals = $dbvs->{tvals};
    my $dbtix   = $dbvs->{tdm}->_whichND->slice("(0),");
    my $dbdix   = $dbvs->{tdm}->_whichND->slice("(1),") + $Doff;
    my $dbvals  = $dbvs->{tdm}->_nzvals;
    my $dbtnull = zeroes($dbtvals->type,1)->slice("*".$dbtix->nelem);
    my (@tavals);
    foreach my $tai (0..$#{$vs->{attrs}}) {
      my $ta = $vs->{attrs}[$tai];
      my $dbtpos = $dbvs->tpos($ta);
      if (!defined($dbtpos)) {
	$tavals[$tai] = $dbtnull;
      } else {
	my $i2u = $dba->{"_union_${ta}i2u"}->toPdl();
	$tavals[$tai] = $i2u->index($dbtvals->slice("($dbtpos),"))->index($dbtix);
	$tavals[$tai]->sever;
      }
    }
    #$vs->vlog('trace', "union(): $dbvs->{base}: appending to $tdm0file"); ##-- DEBUG
    wcols(@tavals,$dbdix,$dbvals, $tdm0fh);
    $Doff += $dbvs->nDocs;
  }
  $tdm0fh->close()
    or $vs->logconfess("union(): close failed for tempfile $tdm0fh: $!");

  ##-- union: create temporary metadata array
  $vs->vlog($logCreate, "union(): extracting document metadata to $vsdir/udocmeta.*");
  my $docmeta = tmparray("$vsdir/udocmeta", pack_o=>'J', pack_l=>'J', %tmpargs)
    or $vs->logconfess("union(): could not tie temporary doc-data array to $vsdir/udocmeta.*: $!");
  my $uci = 0;
  foreach my $dbai (grep {$dbargs->[$_]{tdf}} 0..$#$dbargs) {
    my $dba  = $dbargs->[$dbai];
    my $dbvs = $dba->{tdf};
    $vs->vlog($logCreate, "union(): processing metadata for $dbvs->{base}");
    my $dbnCats = $dbvs->nCats;
    my $dbcn    = $dbvs->{c2d}->slice("(1),");
    my $dbcdate = $dbvs->{c2date};
    my $dbmvals = $dbvs->{mvals};
    my @dbmeta  = map { {attr=>$_, pos=>$dbvs->mpos($_), enum=>$dbvs->{"meta_e_$_"}} } @{$dbvs->{meta}};
    my ($dci);
    for ($dci=0; $dci < $dbnCats; ++$dci) {
      push(@$docmeta, {
		       id    => $uci++,
		       nsigs => $dbcn->at($dci),
		       date  => $dbcdate->at($dci),
		       file  => "$dba->{dbdir}#$dci",
		       meta  => { map {($_->{attr}=>$_->{enum}->i2s($dbmvals->at($_->{pos},$dci)))} @dbmeta },
		      });
    }
  }
  tied(@$docmeta)->flush();

  ##-- guts: dispatch to create()
  $vs->vlog($logCreate, "union(): creating model data");
  $vs->logconfess("union(): create() failed for union data")
    if (!$vs->create($coldb,undef,
		     docmeta=>$docmeta,
		     wdmfile=>$tdm0file,
		     ivalmax=>$ivalmax,
		     reusedir=>1,
		     logas=>"union/create()",
		    ));

  ##-- cleanup: temps
  if (!$coldb->{keeptmp}) {
    CORE::unlink($tdm0file)
	or $vs->logconfess("union(): failed to unlink tempfile $tdm0file: $!");
  }

  ##-- union: all done
  env_pop();
  return $vs;
}


##==============================================================================
## Relation API: export

## $bool = $rel->export($outbase, $coldb, %opts)
sub export {
  my ($vs,$outbase,$coldb,%opts) = @_;
  $vs->logconfess("export() called as a class method") if (!ref($vs));

  my $outdir = "$outbase.d";
  my $logLocal = $coldb->{logExport};

  ##-- create export directory
  -d $outdir
    or make_path($outdir)
    or $vs->logconfess("export(): could not create export directory $outdir: $!");

  ##-- export: header
  $vs->saveHeader("$outbase.hdr")
    or $vs->logconfess("export(): could not export header to $outbase.hdr: $!");

  ##-- export: meta-enums
  foreach my $mattr (@{$vs->{meta}}) {
    $vs->vlog($logLocal,"exporting enum $outdir/meta_e_$mattr.dat");
    $vs->{"meta_e_$mattr"}->saveTextFile("$outdir/meta_e_$mattr.dat")
      or $vs->logconfess("export() failed for $outdir/meta_e_$mattr.dat: $!");
  }

  ##-- export: PDLs: dense (mm format)
  require 'PDL/CCS/IO/MatrixMarket.pm'
    or $vs->logconfess("export(): failed to load PDL::CCS::IO::MatrixMarket");
  foreach my $key (qw(tvals tsorti mvals msorti cf c2date c2d d2c yf)) {
    if (!defined($vs->{$key})) {
      $vs->logwarn("cannot export $outdir/$key.mm : object property {$key} is undefined!");
      next;
    }
    $vs->vlog($logLocal,"exporting $outdir/$key.mm");
    $vs->{$key}->writemm("$outdir/$key.mm")
      or $vs->logconfess("export() failed for $outdir/$key.mm: $!");
  }

  ##-- export: PDLs: sparse (mm format)
  foreach my $key (qw(tdm tym)) {
    $vs->vlog($logLocal,"exporting $outdir/$key.mm");
    $vs->{$key}->writemm("$outdir/$key.mm")
      or $vs->logconfess("export() failed for $outdir/$key.mm: $!");
  }

  return $vs;
}

##==============================================================================
## Relation API: dbinfo

## \%info = $rel->dbinfo($coldb)
##  + embedded info-hash for $coldb->dbinfo()
sub dbinfo {
  my $vs = shift;
  my $info = $vs->SUPER::dbinfo();
  my @feat = qw(dbreak attrs meta mgood mbad N minFreq minDocFreq minDocSize maxDocSize);
  @$info{@feat}   = @$vs{@feat};
  $info->{nTerms} = $vs->nTerms;
  $info->{nDocs}  = $vs->nDocs;
  $info->{nCats}  = $vs->nCats;
  $info->{nDates} = $vs->nDates;
  return $info;
}


##==============================================================================
## Relation API: profiling & comparison: top-level

##--------------------------------------------------------------
## Relation API: profile

## $mprf = $rel->profile($coldb, %opts)
## + get a relation profile for selected items as a DiaColloDB::Profile::Multi object
## + %opts: as for DiaColloDB::Relation::profile()
## + really just wraps $rel->vprofile().
sub profile {
  my ($vs,$coldb,%opts) = @_;
  return $vs->vprofile($coldb,\%opts);
}

##--------------------------------------------------------------
## Relation API: extend (pass-2 for multi-clients)

## $mprf = $rel->extend($coldb, %opts)
##  + extend f12 and f2 frequencies for \%slice2keys = $opts{slice2keys}
##  + calls $rel->profile($coldb, %opts,extend=>\%slice2keys_packed)
##  + returns a DiaColloDB::Profile::Multi containing the appropriate f12 and f2 entries
sub extend {
  my ($vs,$coldb,%opts) = @_;
  return $vs->vextend($coldb,\%opts);
}

##--------------------------------------------------------------
## Relation API: comparison (diff)

## $mpdiff = $rel->compare($coldb, %opts)
##  + get a relation comparison profile for selected items as a DiaColloDB::Profile::MultiDiff object
##  + %opts as for DiaColloDB::Relation::compare(), which this method calls
sub compare {
  my ($vs,$coldb,%opts) = @_;
  return $vs->SUPER::compare($coldb, %opts, groupby=>$vs->groupby($coldb, $opts{groupby}, relax=>0));
}


##==============================================================================
## Profile: Utils: PDL-based profiling

##--------------------------------------------------------------
## Profile: Utils: PDL-based profiling: vprofile

## $mprf = $vs->vprofile($coldb, \%opts)
## + guts for profile()
## + %opts: as for DiaColloDB::Relation::profile()
## + new/altered %opts:
##   (
##    vq      => $vq,        ##-- parsed query, DiaColloDB::Relation::TDF::Query object
##    groubpy => \%groupby,  ##-- as returned by $vs->groupby($coldb, \%opts)
##    dlo     => $dlo,       ##-- as returned by $coldb->parseDateRequest(@opts{qw(date slice fill)},1);
##    dhi     => $dhi,       ##-- as returned by $coldb->parseDateRequest(@opts{qw(date slice fill)},1);
##    dslo    => $dslo,      ##-- as returned by $coldb->parseDateRequest(@opts{qw(date slice fill)},1);
##    dshi    => $dshi,      ##-- as returned by $coldb->parseDateRequest(@opts{qw(date slice fill)},1);
##   )
sub vprofile {
  my ($vs,$coldb,$opts) = @_;

  ##-- common variables
  my $logLocal = $vs->{logvprofile};
  my $logDebug = $vs->{logvdebug}; #'debug'; #undef; #'debug';

  ##-- sanity checks / fixes
  $vs->{attrs} = $coldb->{attrs} if (!@{$vs->{attrs}//[]});

  ##-- parse query
  my $groupby = $opts->{groupby} = $vs->groupby($coldb, $opts->{groupby}, relax=>0);
  my $extendp = $opts->{extend};
  ##
  my $q = $opts->{qobj} // $coldb->parseQuery($opts->{query}, logas=>'query', default=>'', ddcmode=>-1);
  my ($qo);
  $q->setOptions($qo=DDC::Any::CQueryOptions->new) if (!defined($qo=$q->getOptions));
  #$qo->setFilters([@{$qo->getFilters}, @$gbfilters]) if (@$gbfilters);
  $opts->{qobj} //= $q;

  ##-- parse date-request
  my ($dfilter,$dslo,$dshi,$dlo,$dhi) = $coldb->parseDateRequest(@$opts{qw(date slice fill)},1);
  $dlo //= $coldb->{xdmin};
  $dhi //= $coldb->{xdmax};
  @$opts{qw(dslo dshi dlo dhi)} = ($dslo,$dshi,$dlo,$dhi);

  ##-- parse & compile query
  my %vqopts = (%$opts,coldb=>$coldb,tdf=>$vs);
  my $vq     = $opts->{vq} = DiaColloDB::Relation::TDF::Query->new($q)->compile(%vqopts);

  ##-- sanity checks: null-query
  my ($ti,$ci) = @$vq{qw(ti ci)};
  if (!$opts->{fill}) {
    if (defined($ti) && !$ti->nelem) {
      $vs->logconfess($coldb->{error}="no index term(s) matched user query \`$opts->{query}'");
    } elsif (defined($ci) && !$ci->nelem) {
      $vs->logconfess($coldb->{error}="no index document(s) matched user query \`$opts->{query}'");
    }
  }

  ##-- get query-vector
  my $tdm     = $vs->{tdm};
  my $sliceby = $opts->{slice} || 0;
  my ($qwhich,$qvals);
  if (defined($ti) && defined($ci)) {
    ##-- query-vector: both term- and document-conditions
    $vs->vlog($logLocal, "vprofile(): query vector: term+cat conditions (xsubset2d)");
    my $q_c2d     = $vs->{c2d}->dice_axis(1,$ci);
    my $di        = $q_c2d->slice("(1),")->rldseq($q_c2d->slice("(0),"))->qsort;
    my $subsize   = $ti->nelem * $di->nelem;
    $vs->vlog($logLocal, "vprofile(): requested subset size = $subsize (NT=".$ti->nelem." x Nd=".$ci->nelem.")");
    if (defined($vs->{submax}) &&  $subsize > $vs->{submax}) {
      $vs->logconfess($coldb->{error}="requested subset size $subsize (NT=".$ti->nelem." x Nd=".$ci->nelem.") too large; max=$vs->{submax}");
    }

    my $q_tdm = $tdm->xsubset2d($ti,$di)->sumover;
    $qwhich = $q_tdm->_whichND->flat;
    $qvals  = $q_tdm->_nzvals;
  }
  elsif (defined($ti)) {
    ##-- query-vector: term-conditions only
    $vs->vlog($logLocal, "vprofile(): query vector: term conditions only (pxsubset1d)");
    my $q_tdm = $tdm->pxsubset1d(0,$ti)->sumover;
    $qwhich = $q_tdm->_whichND->flat;
    $qvals  = $q_tdm->_nzvals;
  }
  elsif (defined($ci)) {
    ##-- query-vector: doc-(cat-)conditions only
    $vs->vlog($logLocal, "vprofile(): query vector: cat conditions only (pxindex1d+indadd)");
    my $q_c2d   = $vs->{c2d}->dice_axis(1,$ci);
    my $di      = $q_c2d->slice("(1),")->rldseq($q_c2d->slice("(0),")); #->qsort;

    ##-- sanity check
    #$vs->logconfess($coldb->{error}="vprofile(): unsorted doc-list when decoding cat conditions") ##-- sanity check
    #  if ($di->nelem > 1 && !all($di->slice("0:-2") <= $di->slice("1:-1")));

    ##-- find matching nz-indices WITH ptr(1): pxindex1d+indadd
    my $nzi = $tdm->pxindex1d(1,$di);
    $tdm->_vals->index($nzi)->indadd($tdm->_whichND->slice("(1),")->index($nzi),
				     my $qvec=zeroes($tdm->type, $vs->nDocs));
    $qwhich = $qvec->which;
    $qvals  = $qvec->index($qwhich);
  }

  ##-- evaluate query: get co-occurrence frequencies (dispatch depending on groupby-type (terms vs docs vs terms+docs)
  my ($pack_ix,$pack_gkey) = ($vs->ipack,$groupby->{gpack});
  my ($f1p,$f12p,$f2p);
  if ($groupby->{how} eq 't') {
    ##-- evaluate query: groupby term-attrs
    $vs->vlog($logLocal, "vprofile(): evaluating query ('$groupby->{how}': groupby term-attributes only)");
    my $cofsub = PDL->can('diacollo_cof_t_'.$vs->itype) || \&PDL::diacollo_cof_t_long;
    $cofsub->($tdm->_whichND, @$vs{qw(ptr1 pix1)}, $tdm->_vals,
	      @$vs{qw(tvals d2c c2date)},
	      $sliceby, $dlo,$dhi,
	      $qwhich, $qvals,
          $groupby->{gapos},
              ##-- argh 2025-06-22: chokes with 'diacollo_cof_t_long: input parameter 'ghaving' is null'
              #($groupby->{ghavingt}//null),
              ($groupby->{ghavingt}//empty($vs->itype)),
              ##-- /argh
	      $f1p={},
	      $f12p={},
              ($extendp // 0)
             );
    $vs->vlog($logDebug, "found ", scalar(keys %$f12p), " item2 tuple(s) in ", scalar(keys %$f1p), " slice(s)");

    ##-- force-insert 'extend' keys (for correct f2 acquisition)
    if ($extendp) {
      $f12p->{$_} //= 0 foreach (keys %{$extendp//{}});
      $vs->vlog($logDebug, "post-extend: ", scalar(keys %$f12p), " item2 tuple(s)");
    }

    ##-- get item2 keys (groupby term-attrs)
    $vs->vlog($logDebug, "vprofile(): evaluating query: f2p");
    my $gkeys2  = pdl($vs->itype, map {unpack($pack_gkey,$_)} keys %$f12p);
    $gkeys2->reshape(scalar(@{$groupby->{attrs}}), $gkeys2->nelem/scalar(@{$groupby->{attrs}}));
    my $gti2    = undef;
    foreach (0..($gkeys2->dim(0)-1)) {
      #$vs->vlog($logLocal, "vprofile(): evaluating query: f2p: terms[$_]");
      my $gtia = $vs->termIds($groupby->{attrs}[$_], $gkeys2->slice("($_),")->uniq);
      $gti2    = _intersect_p($gti2,$gtia);
    }

    #$vs->vlog($logLocal, "vprofile(): evaluating query: f2p: guts");
    my $tym = $vs->{tym};
    my $gfsub = PDL->can('diacollo_tym_gf_t_'.$vs->itype) || \&PDL::diacollo_tym_gf_t_long;
    $gfsub->($tym->_whichND, $tym->_vals,
	     $vs->{tvals},
	     $sliceby, $dlo,$dhi,
	     ($gti2//null->convert($vs->itype)),
	     $groupby->{gapos},
	     $f12p, $f2p={});
    $vs->vlog($logDebug, "got ", scalar(keys %$f2p), " independent item2 tuple-frequencies via tym");
  }
  elsif ($groupby->{how} eq 'c') {
    ##-- evaluate query: groupby doc-attrs
    $vs->vlog($logLocal, "vprofile(): evaluating query ('$groupby->{how}': groupby metadata-attributes only)");
    my $cofsub = PDL->can('diacollo_cof_c_'.$vs->itype) || \&PDL::diacollo_cof_c_long;
    $cofsub->($tdm->_whichND, @$vs{qw(ptr1 pix1)}, $tdm->_vals,
	      @$vs{qw(mvals d2c c2date)},
	      $sliceby, $dlo,$dhi,
	      $qwhich, $qvals,
	      $groupby->{gapos},
	      ($groupby->{ghavingc}//null),
	      $f1p={}, $f12p={},
              ($extendp // 0)
             );
    $vs->vlog($logDebug, "found ", scalar(keys %$f12p), " item2 tuple(s) in ", scalar(keys %$f1p), " slice(s)");

    ##-- force-insert 'extend' keys (for correct f2 acquisition)
    if ($extendp) {
      $f12p->{$_} //= 0 foreach (keys %{$extendp//{}});
      $vs->vlog($logDebug, "post-extend: ", scalar(keys %$f12p), " item2 tuple(s)");
    }

    ##-- get item2 keys (groupby doc-attrs)
    $vs->vlog($logDebug, "vprofile(): evaluating query: f2p");
    my $gkeys2  = pdl($vs->itype, map {unpack($pack_gkey,$_)} keys %$f12p);
    $gkeys2->reshape(scalar(@{$groupby->{attrs}}), $gkeys2->nelem/scalar(@{$groupby->{attrs}}));
    my $gci2    = undef;
    foreach (0..($gkeys2->dim(0)-1)) {
      my $gcia = $vs->catIds($groupby->{areqs}[$_][2]{aname}, $gkeys2->slice("($_),")->uniq);
      $gci2    = _intersect_p($gci2,$gcia);
    }

    #$vs->vlog($logLocal, "vprofile(): evaluating query: f2p: guts");
    my $gfsub = PDL->can('diacollo_gf_c_'.$vs->itype) || \&PDL::diacollo_gf_c_long;
    $gfsub->(@$vs{qw(cf mvals c2date)},
	     $sliceby,
	     ($gci2//null->convert($vs->itype)),
	     $groupby->{gapos},
	     $f12p, $f2p={});
    $vs->vlog($logDebug, "got ", scalar(keys %$f2p), " independent item2 tuple-frequencies via cf");
  }
  elsif ($groupby->{how} eq 'tc') {
    ##-- evaluate query: groupby (term+doc)-attrs
    $vs->vlog($logLocal, "vprofile(): evaluating query ('$groupby->{how}': groupby term- and metadata-attributes)");
    my $cofsub = PDL->can('diacollo_cof_tc_'.$vs->itype) || \&PDL::diacollo_cof_tc_long;
    $cofsub->($tdm->_whichND, @$vs{qw(ptr1 pix1)}, $tdm->_vals,
	      @$vs{qw(tvals mvals d2c c2date)},
	      $sliceby, $dlo,$dhi,
	      $qwhich, $qvals,
	      @$groupby{qw(gatype gapos)},
	      (map {$_//null} @$groupby{qw(ghavingt ghavingc)}),
	      $f1p={}, $f12p={},
              ($extendp // 0)
             );
    $vs->vlog($logDebug, "found ", scalar(keys %$f12p), " item2 tuple(s) in ", scalar(keys %$f1p), " slice(s)");

    ##-- force-insert 'extend' keys (for correct f2 acquisition)
    if ($extendp) {
      $f12p->{$_} //= 0 foreach (keys %{$extendp//{}});
      $vs->vlog($logDebug, "post-extend: ", scalar(keys %$f12p), " item2 tuple(s)");
    }

    ##-- get item2 keys (groupby (term+doc)-attrs)
    $vs->vlog($logDebug, "vprofile(): evaluating query: f2p (scan)");
    my $gfsub = PDL->can('diacollo_gf_tc_'.$vs->itype) || \&PDL::diacollo_gf_tc_long;
    $gfsub->($tdm->_whichND, $tdm->_vals,
	      @$vs{qw(tvals mvals d2c c2date)},
	      $sliceby, $dlo,$dhi,
	      @$groupby{qw(gatype gapos)},
	      $f12p, $f2p={});
    $vs->vlog($logDebug, "got ", scalar(keys %$f2p), " independent item2 tuple-frequencies via tdm");
  }
  else {
    $vs->logconfess($coldb->{error}="vprofile(): unknown groupby mode '$groupby->{how}'");
  }

  ##-- convert packed to native-style profiles (by date-slice)
  my @slices = $sliceby ? (map {$sliceby*$_} (($dlo/$sliceby)..($dhi/$sliceby))) : qw(0);
  my %dprfs  = map {($_=>DiaColloDB::Profile->new(label=>$_, titles=>$groupby->{titles}, N=>$vs->sliceN($sliceby,$_), f1=>($f1p->{pack($pack_ix,$_)}//0)))} @slices;
  if (@slices > 1) {
    $vs->vlog($logDebug, "vprofile(): partitioning profile data into ", scalar(@slices), " slice(s)");
    my $len_gkey = packsize($pack_gkey);
    (my $pack_ds = '@'.$len_gkey.$pack_ix) =~ s/\*$//;
    my ($key2,$gkey,$f12,$ds,$prf);
    while (($key2,$f12) = each %$f12p) {
      $ds   = unpack($pack_ds, $key2);
      $prf  = $dprfs{$ds};
      $gkey = substr($key2, 0, $len_gkey);
      $prf->{f12}{$gkey} = $f12;
      $prf->{f2}{$gkey}  = $f2p->{$key2};
    }
  } else {
    $vs->vlog($logDebug, "vprofile(): creating single-slice profile");
    @{$dprfs{$slices[0]}}{qw(f2 f12)} = ($f2p,$f12p);
  }

  ##-- compile sub-profiles
  $vs->vlog($logLocal, "vprofile(): compile sub-profile(s)");
  foreach my $prf (values %dprfs) {
    $prf->compile($opts->{score}, eps=>$opts->{eps});
  }

  ##-- collect & trim multi-profile
  $vs->vlog($logLocal, "profile(): trim and stringify");
  my $mp = DiaColloDB::Profile::Multi->new(profiles=>[@dprfs{@slices}],
					   titles=>$groupby->{titles},
					   qinfo =>$vs->qinfo($coldb, %$opts),
					  );
  $mp->trim(%$opts, extend=>undef,empty=>!$opts->{fill});
  $mp->stringify($groupby->{g2s}) if ($opts->{strings});

  return $mp;
}

##--------------------------------------------------------------
## Profile: Utils: PDL-based profiling: vextend

## \@pprfs = $vs->vextend($coldb, \%opts)
## + guts for extend()
## + %opts: as for profile(), also
## + new/altered %opts:
##   (
##    slice2keys => \%slice2keys,  ##-- f2 items to be extended
##   )
sub vextend {
  my ($vs,$coldb,$opts) = @_;

  ##-- common variables
  my $logLocal = $vs->{logvprofile};
  my $logDebug = undef; #'debug';
  $opts->{coldb} //= $coldb;

  ##-- sanity checks / fixes
  $vs->{attrs} = $coldb->{attrs} if (!@{$vs->{attrs}//[]});
  my ($slice2keys);
  if (!($slice2keys=$opts->{slice2keys})) {
    $vs->logwarn($coldb->{error}="extend(): no 'slice2keys' parameter specified!");
    return undef;
  }
  elsif (!UNIVERSAL::isa($slice2keys,'HASH')) {
    $vs->logwarn($coldb->{error}="extend(): failed to parse 'slice2keys' parameter");
    return undef;
  }

  ##-- parse groupby (override)
  my $groupby = $opts->{groupby} = $vs->groupby($coldb, $opts->{groupby}, relax=>0);
  my $s2gx    = $groupby->{s2gx};

  ##-- get packed group-keys (avoid temporary dummy-profiles, they can't handle unknown group-components)
  ##  + override also appends date-slice suffixes
  my $pack_ix = $vs->ipack;
  my ($xslice,$xkeys,$xsuff, $xkey,$xg, %extendp);
  while (($xslice,$xkeys) = each %$slice2keys) {
    $xsuff = pack($pack_ix,$xslice);
    foreach $xkey (UNIVERSAL::isa($xkeys,'HASH') ? keys(%$xkeys) : @$xkeys) {
      next if (!defined($xg = $s2gx->($xkey)));
      $extendp{$xg.$xsuff} = undef;
    }
  }

  ##-- guts: dispatch to profile()
  my $mp = $vs->profile($coldb, %$opts, kbest=>0,kbesta=>0,cutoff=>undef,global=>0,fill=>1, extend=>\%extendp);

  return $mp;
}

##==============================================================================
## Profile: Utils: domain sizes

## $NT = $vs->nTerms()
##  + gets number of terms
sub nTerms {
  return $_[0]{tdm}->dim(0);
}

## $ND = $vs->nDocs()
##  + returns number of documents (breaks)
BEGIN { *nBreaks = \&nDocs; }
sub nDocs {
  return $_[0]{tdm}->dim(1);
}

## $NC = $vs->nFiles()
##  + returns number of categories (original source files)
BEGIN { *nCategories = *nCats = \&nFiles; }
sub nFiles {
  return $_[0]{c2date}->nelem;
}

## $NY = $vs->nDates()
BEGIN { *nYears = \&nDates; }
sub nDates {
  return $_[0]{yf}->nelem;
}

## $NA = $vs->nAttrs()
##  + returns number of term-attributes
sub nAttrs {
  return $_[0]{tvals}->dim(0);
}

## $NM = $vs->nMeta()
##  + returns number of meta-attributes
sub nMeta {
  return $_[0]{mvals}->dim(0);
}

##==============================================================================
## Profile: Utils: attribute positioning

## \%tpos = $vs->tpos()
##  $tpos = $vs->tpos($tattr)
##  + get or build term-attribute position lookup hash
sub tpos {
  $_[0]{tpos} //= { (map {($_[0]{attrs}[$_]=>$_)} (0..$#{$_[0]{attrs}})) };
  return @_>1 ? $_[0]{tpos}{$_[1]} : $_[0]{tpos};
}

## \%mpos = $vs->mpos()
## $mpos  = $vs->mpos($mattr)
##  + get or build meta-attribute position lookup hash
sub mpos {
  $_[0]{mpos} //= { (map {($_[0]{meta}[$_]=>$_)} (0..$#{$_[0]{meta}})) };
  return @_>1 ? $_[0]{mpos}{$_[1]} : $_[0]{mpos};
}

##==============================================================================
## Profile: Utils: query parsing & evaluation

## $idPdl = $vs->idpdl($idPdl)
## $idPdl = $vs->idpdl(\@ids)
sub idpdl {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  my $ids = shift;
  return null->long   if (!defined($ids));
  $ids = [$ids] if (!ref($ids));
  $ids = pdl(long,$ids) if (!UNIVERSAL::isa($ids,'PDL'));
  return $ids;
}

## $tupleIds = $vs->tupleIds($attrType, $attrName, $valIdsPdl)
## $tupleIds = $vs->tupleIds($attrType, $attrName, \@valIds)
## $tupleIds = $vs->tupleIds($attrType, $attrName, $valId)
sub tupleIds {
  my ($vs,$typ,$attr,$valids) = @_;
  $valids = $valids=$vs->idpdl($valids);

  ##-- check for empty value-set
  if ($valids->nelem == 0) {
    return null->convert($vs->itype);
  }

  ##-- non-empty: get base data
  my $apos = $vs->can("${typ}pos")->($vs,$attr);
  my $vals = $vs->{"${typ}vals"}->slice("($apos),");

  ##-- check for singleton value-set & maybe do simple linear search
  if ($valids->nelem == 1) {
    return ($vals==$valids)->which;
  }

  ##-- nontrivial value-set: do vsearch lookup (too complex and doesn't work for final element)
  my $sorti   = $vs->{"${typ}sorti"}->slice(",($apos)");
  my $vals_qs = $vals->index($sorti);
  my $i0      = $valids->vsearch($vals_qs);
  my $i0_mask = ($vals_qs->index($i0) == $valids);
  $i0         = $i0->where($i0_mask);
  my $ilen    = ($valids->where($i0_mask)+1)->vsearch($vals_qs);
  $ilen      -= $i0;
  $ilen->slice("-1")->inplace->lclip(1) if ($ilen->nelem); ##-- hack for bogus 0-length at final element
  my $iseq    = $ilen->rldseq($i0);
  return $sorti->index($iseq)->qsort;
}

## $ti = $vs->termIds($tattrName, $valIdsPDL)
## $ti = $vs->termIds($tattrName, \@valIds)
## $ti = $vs->termIds($tattrName, $valId)
sub termIds {
  return $_[0]->tupleIds('t',@_[1..$#_]);
}

## $ci = $vs->catIds($mattrName, $valIdsPDL)
## $ci = $vs->catIds($mattrName, \@valIds)
## $ci = $vs->catIds($mattrName, $valId)
sub catIds {
  return $_[0]->tupleIds('m',@_[1..$#_]);
}

## $bool = $vs->hasMeta($attr)
##  + returns true iff $vs supports metadata attribute $attr
sub hasMeta {
  return defined($_[0]->mpos($_[1]));
}

## $enum_or_undef = $vs->metaEnum($mattr)
##  + returns metadata attribute enum for $attr
sub metaEnum {
  my ($vs,$attr) = @_;
  return undef if (!$vs->hasMeta($attr));
  return $vs->{"meta_e_$attr"};
}

## $cats = $vs->catSubset($terms)
## $cats = $vs->catSubset($terms,$cats)
##  + gets (sorted) cat-subset for (sorted) term-set $terms
sub catSubset {
  my ($vs,$terms,$cats) = @_;
  return $cats if (!defined($terms));
  #return DiaColloDB::Utils::_intersect_p($cats, $vs->{d2c}->index($vs->{tdm}->dice_axis(0,$terms)->_whichND->slice("(1),"))->uniq);
  my $ptr0 = $vs->{ptr0};
  my $nz_off = $ptr0->index($terms);
  my $nz_len = $ptr0->index($terms+1) - $nz_off;
  return scalar DiaColloDB::Utils::_intersect_p($cats, $vs->{d2c}->index($vs->{tdm}->_whichND->index2d(1,$nz_len->rldseq($nz_off))->uniq)->uniq);
}


##----------------------------------------------------------------------
## Profile Utils: slice frequency

## $N = $vs->sliceN($sliceBy, $dateLo)
##  + get total slice co-occurrence count, used by vprofile()
sub sliceN {
  my ($vs,$sliceby,$dlo) = @_;
  return $vs->{N} if ($sliceby==0);
  my $ymin = $vs->{y0};
  my $ihi  = min2( $dlo-$ymin+$sliceby, $vs->nDates );
  my $ilo  = max2( $dlo-$ymin,          0 );
  return $vs->{yf}->slice("$ilo:".($ihi-1))->sum;
}


##----------------------------------------------------------------------
## Profile Utils: groupby

## \%groupby = $vs->groupby($coldb, $groupby_request, %opts)
## \%groupby = $vs->groupby($coldb, \%groupby,        %opts)
##  + modified version of DiaColloDB::groupby() suitable for pdl-ized TDF relation
##  + $grouby_request : see DiaColloDB::parseRequest()
##  + returns a HASH-ref:
##    (
##     ##-- OLD: equivalent to DiaColloDB::groupby() return values
##     req => $request,    ##-- save request
##     areqs => \@areqs,   ##-- parsed attribute requests ([$attr,$ahaving, \%ainfo],...)
##                         ##   + new: %ainfo = ( aname=>$enum_name, atype=>$t_or_m, apos=>$apos )
##     attrs => \@attrs,   ##-- like $coldb->attrs($groupby_request), modulo "having" parts
##     titles => \@titles, ##-- like map {$coldb->attrTitle($_)} @attrs
##     ##
##     ##-- REMOVED: not constructed for TDF::groupby()
##     #x2g => \&x2g,       ##-- group-id extraction code suitable for e.g. DiaColloDB::Relation::Cofreqs::profile(groupby=>\&x2g)
##     #g2s => \&g2s,       ##-- stringification object suitable for DiaColloDB::Profile::stringify() [CODE,enum, or undef]
##     ##
##     ##-- NEW: equivalent to DiaColloDB::groupby() return values
##     how      => $ghow,     ##-- one of  't':groupby terms-only, 'c':groupby cats-only, 'tc':groupby terms+docs
##     gatype   => $gatype,   ##-- pdl ($NG)         : attribute types $ai : 0 iff $areqs->[$ai] is a term attribute, 1 if meta-attribute
##     gapos    => $gapos,    ##-- pdl ($NG)         : term- or meta-attribute position indices $ai : $vs->mpos($attrs[$ai]) or $vs->tpos($attrs[$ai])
##     ghavingt => $ghavingt, ##-- pdl ($NHavingTOk) : term indices $ti s.t. $ti matches groupby "having" requests, or undef
##     ghavingc => $ghavingc, ##-- pdl ($NHavingCOk) : cat  indices $ci s.t. $ci matches groupby "having" requests, or undef
##     #gaggr   => \&gaggr,   ##-- code: ($gkeys,$gdist) = gaggr($dist) : where $dist is diced to $ghaving on dim(1) and $gkeys is sorted
##     g2s     => \&g2s,    ##-- stringification object CODE-ref suitable for DiaColloDB::Profile::stringify()
##     s2g     => \&s2g,    ##-- inverse-stringification CODE-ref suitable for DiaColloDB::Profile::stringify()
##     s2gx    => \&s2gx,   ##-- inverse-stringification CODE-ref for extend(); returns undef if an unknown string component is specified
##     gpack   => $packas,  ##-- pack template for groupby-keys
##     ##
##     ##-- NEW: pdl utilties
##     #gv    => $gv,       ##-- pdl ($NG): [$gvi] => $gi : group-id enumeration
##     #gn    => $gn,       ##-- pdl ($NG): [$gvi] => $n  : number of terms in group
##    )
##  + %opts:
##     warn  => $level,    ##-- log-level for unknown attributes (default: 'warn')
##     relax => $bool,     ##-- allow unsupported attributes (default=0)
sub groupby {
  my ($vs,$coldb,$gbreq,%opts) = @_;
  return $gbreq if (UNIVERSAL::isa($gbreq,'HASH'));

  ##-- get data
  my $wlevel = $opts{warn} // 'warn';
  my $gb = { req=>$gbreq };

  ##-- get attribute requests
  my $gbareqs = $gb->{areqs} = $coldb->parseRequest($gb->{req}, %opts, logas=>'tdf groupby', allowExtra=>[map {($_,"doc.$_")} @{$vs->{meta}}]);

  ##-- get attribute names (compat)
  my $gbattrs = $gb->{attrs} = [map {$_->[0]} @$gbareqs];

  ##-- get attribute titles
  $gb->{titles} = [map {$coldb->attrTitle($_)} @$gbattrs];

  ##-- parse attribute requests into "having" id-sets and "info" hashes
  my ($areq,$aname,$ashort,$apos,$ahaving,$ainfo);
  my ($ghavingt,$ghavingc);
  foreach my $areq (@$gbareqs) {
    ($aname,$ahaving) = @$areq;
    ($ashort = $aname) =~ s/^doc\.//;
    my $ainfo = $areq->[2] = {};
    foreach ($aname,$ashort) {
      if (defined($apos=$vs->tpos($_))) {
	##-- term-attribute request
	@$ainfo{qw(atype apos aname)} = ('t',$apos,$_);
	if ($ahaving && !UNIVERSAL::isa($ahaving,'DDC::Any::CQTokAny')) {
	  my $avalids  = $coldb->enumIds($coldb->{"${_}enum"}, $ahaving, logLevel=>$coldb->{logProfile}, logPrefix=>"groupby(): fetch term-filter ids: $_");
	  my $ahavingi = $vs->termIds($_, $avalids);
	  $ghavingt    = DiaColloDB::Utils::_intersect_p($ghavingt,$ahavingi);
	}
	last;
      }
      elsif (defined($apos=$vs->mpos($_))) {
	##-- meta-attribute request
	@$ainfo{qw(atype apos aname)} = ('m',$apos,$_);
	if ($ahaving && !UNIVERSAL::isa($ahaving,'DDC::Any::CQTokAny')) {
	  my $avalids  = $coldb->enumIds($vs->{"meta_e_$_"}, $ahaving, logLevel=>$coldb->{logProfile}, logPrefix=>"groupby(): fetch meta-filter ids: $_");
	  my $ahavingi = $vs->catIds($_, $avalids);
	  $ghavingc    = DiaColloDB::Utils::_intersect_p($ghavingc,$ahavingi);
	}
	last;
      }
    }
    $vs->logconfess("groupby(): could not parse attribute request for '$aname'") if (!%$ainfo);
  }
  $vs->logconfess("groupby(): no target terms found matching 'having' conditions") if (defined($ghavingt) && $ghavingt->isempty);
  $vs->logconfess("groupby(): no target documents found matching 'having' conditions") if (defined($ghavingc) && $ghavingc->isempty);
  @$gb{qw(ghavingt ghavingc)} = ($ghavingt,$ghavingc);

  ##-- get groupby attribute indices
  my $gatype = $gb->{gatype} = pdl($vs->itype, [map {$_->[2]{atype} eq 't' ? 0 : 1} @$gbareqs]);
  my $gapos  = $gb->{gapos}  = pdl($vs->itype, [map {$_->[2]{apos}}                 @$gbareqs]);

  ##-- get groupby "how" for query optimization
  $gb->{how} = ($gatype->min==0 ? 't' : '').($gatype->max==1 ? 'c' : '');

  ##-- get stringification object (term-clauses only)
  my $pack_ix = $vs->ipack();
  (my $gpack = $pack_ix) =~ s/\*$/"[".scalar(@$gbattrs)."]"/e;
  $gb->{gpack} = $gpack;
  if ($opts{strings}//1) {
    ##-- stringify
    my @genums = map { $_->[2]{atype} eq 't' ? $coldb->{$_->[0]."enum"} : $vs->{"meta_e_".$_->[2]{aname}} } @$gbareqs;
    my (@gvals);
    $gb->{g2s} = sub {
      @gvals = unpack($gpack,$_[0]);
      return join("\t", map {$genums[$_]->i2s($gvals[$_])//''} (0..$#gvals));
    };
    $gb->{s2g} = sub {
      @gvals = split(/\t/,$_[0]);
      return pack($gpack, map {$genums[$_]->s2i($gvals[$_]//'')//0} (0..$#genums));
    };
    $gb->{s2gx} = sub {
      @gvals = split(/\t/,$_[0]);
      foreach (0..$#genums) {
        return undef if (!defined($gvals[$_] = $genums[$_]->s2i($gvals[$_]//'')));
      }
      return pack($gpack, @gvals);
    };
  } else {
    ##-- pseudo-stringify
    $gb->{g2s} = sub { return join("\t", unpack($gpack,$_[0])); };
    $gb->{s2g} = sub { return pack($gpack, split(/\t/,$_[0])); };
    $gb->{s2gx} = $gb->{s2g};
  }


  return $gb;
}


##==============================================================================
## Relation API: default: query info

## \%qinfo = $rel->qinfo($coldb, %opts)
##  + get query-info hash for profile administrivia (ddc hit links)
##  + %opts: as for profile(), additionally:
##    (
##     #qreqs => \@qreqs,      ##-- as returned by $coldb->parseRequest($opts{query})
##     #gbreq => \%groupby,    ##-- as returned by $coldb->groupby($opts{groupby})
##    )
##  + returned hash \%qinfo should have keys:
##    (
##     fcoef => $fcoef,         ##-- frequency coefficient (2*$coldb->{dmax} for CoFreqs)
##     qtemplate => $qtemplate, ##-- query template with __W1.I1__ rsp __W2.I2__ replacing groupby fields
##    )
sub qinfo {
  my ($vs,$coldb,%opts) = @_;

  ##-- parse item1 query & options
  my $q1 = $opts{qobj} ? $opts{qobj}->clone : $coldb->parseQuery($opts{query}, logas=>'qinfo', default=>'', ddcmode=>1);
  my ($qo);
  $q1->setOptions($qo=DDC::Any::CQueryOptions->new) if (!defined($qo=$q1->getOptions));
  $q1->SetMatchId(1);
  my $qf = $qo->getFilters // [];
  my ($qfi,$qfobj,$ma,$aqstr,$aq,$af,$av);
  foreach my $qfi (0..$#$qf) {
    $qfobj = $qf->[$qfi];
    next if (!UNIVERSAL::isa($qfobj,'DDC::Any::CQFHasField'));
    $ma = $coldb->attrName( $qfobj->getArg0 );
    if (defined($aqstr=$vs->{mquery}{$ma})) {
      ##-- meta-filter: from template
      $aq = $coldb->qparse($aqstr)
	or $vs->logconfess("qinfo(): failed to parse query-template '$aqstr': $coldb->{error}");
      $af = (($aq->getOptions ? $aq->getOptions->getFilters : undef)//[])->[0];
      if (UNIVERSAL::isa($aq,'DDC::Any::CQTokAny') && UNIVERSAL::isa($af,'DDC::Any::CQFHasFieldRegex')) {
	##-- meta-filter: from template: target=regex
	if ($qfobj->isa('DDC::Any::CQFHasFieldRegex')) {
	  $af->setArg1($qfobj->getArg1);
	} elsif ($qfobj->isa('DDC::Any::CQFHasFieldValue')) {
	  $af->setArg1(quotemeta($qfobj->getArg1));
	} elsif ($qfobj->isa('DDC::Any::CQFHasFieldSet')) {
	  $af->setArg1(join('|',map {"(?:".quotemeta($_).")"} @{$qfobj->getValues}));
	} else {
	  $vs->logwarn("qinfo(): can't translate '$ma' regex field template '$aqstr' to DDC-safe query");
	  next;
	}
	$qf->[$qfi] = $af;
      } else {
	##-- meta-filter: from template: target=?
	$vs->logwarn("qinfo(): can't translate non-trivial '$ma' field template '$aqstr' to DDC-safe query");
      }
    }
  }

  ##-- item2 query (via groupby, lifted from Relation::qinfoData())
  my $xi = 1;
  my $q2 = DDC::Any::CQTokAny->new();
  foreach (@{$opts{groupby}{areqs}}) {
    if ($_->[2]{atype} eq 'm') {
      ##-- meta-attribute
      $ma = $coldb->attrName( $_->[2]{aname} );
      if (defined($aqstr=$vs->{mquery}{$ma})) {
	##-- meta-attribute: from template
	$aqstr =~ s/__W2__/__W2.${xi}__/g;
	$aq = $coldb->qparse($aqstr)
	  or $vs->logconfess("qinfo(): failed to parse query-template '$aqstr': $coldb->{error}");
	$q2 = $q2->isa('DDC::Any::CQTokAny') ? $aq : ($aq->isa('DDC::Any::CQTokAny') ? $q2 : DDC::Any::CQWith->new($q2,$aq));
	push(@$qf, @{$aq->getOptions->getFilters}) if ($aq->getOptions);
      } else {
	##-- meta-attribute: default: literal #HAS filter
	$ma =~ s/^doc\.//;
	push(@$qf, DDC::Any::CQFHasField->new($ma,"__W2.${xi}__"));
      }
    }
    else {
      ##-- token-attribute (literal)
      $aq = DDC::Any::CQTokExact->new($_->[2]{aname},"__W2.${xi}__");
      $q2 = $q2->isa('DDC::Any::CQTokAny') ? $aq : ($aq->isa('DDC::Any::CQTokAny') ? $q2 : DDC::Any::CQWith->new($q2,$aq));
    }
    ++$xi;
  }
  $q2->SetMatchId(2);

  ##-- options: set filters, WITHIN
  (my $inbreak = $vs->{dbreak}) =~ s/^#//;
  $qo->setWithin([$inbreak]);
  $qo->setFilters($qf);

  ##-- construct query
  my $qboth = ($q1->isa('DDC::Any::CQTokAny') ? $q2
	       : ($q2->isa('DDC::Any::CQTokAny') ? $q1
		  : DDC::Any::CQAnd->new($q1,$q2)));
  $qboth->setOptions($qo);
  my $qtemplate = $qboth->toStringFull;
  utf8::decode($qtemplate) if (!utf8::is_utf8($qtemplate));

  return {
	  fcoef => 1,
	  qtemplate => $qtemplate,
	  qcanon => $vs->qcanon($coldb, qobj=>$q1),
	 };
}

##==============================================================================
## Footer
1;

__END__
