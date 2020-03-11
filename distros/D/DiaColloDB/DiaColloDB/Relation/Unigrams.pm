## -*- Mode: CPerl -*-
## File: DiaColloDB::Relation::Unigrams.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profiling relation: unigram database (using DiaColloDB::PackedFile)

package DiaColloDB::Relation::Unigrams;
use DiaColloDB::Relation;
use DiaColloDB::PackedFile;
use DiaColloDB::Utils qw(:fcntl :sort :env :run :pack :file :jobs);
use Fcntl qw(:DEFAULT :seek);
use File::Basename qw(dirname);
use version;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Relation);

## $PFCLASS : object class for nested PackedFile objects
our $PFCLASS = 'DiaColloDB::PackedFile::MMap';

##==============================================================================
## Constructors etc.

## $ug = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- user options
##    base     => $basename,   ##-- file basename (default=undef:none); use files "${base}.dba1", "${base}.dba2", "${base}.hdr"
##    flags    => $flags,      ##-- fcntl flags or open-mode (default='r')
##    perms    => $perms,      ##-- creation permissions (default=(0666 &~umask))
##    pack_i   => $pack_i,     ##-- pack-template for IDs (default='N')
##    pack_f   => $pack_f,     ##-- pack-template for frequencies (default='N')
##    pack_d   => $pack_d,     ##-- pack-tempalte for dates (default='n')
##    keeptmp  => $bool,       ##-- keep temporary files? (default=false)
##    mmap     => $bool,       ##-- use mmap access? (default=true)
##    logCompat => $level,     ##-- log-level for compatibility warnings (default='warn')
##    ##
##    ##-- size info (after open() or load())
##    size1    => $size1,      ##-- == $r1->size()
##    size2    => $size2,      ##-- == $r2->size()
##    sizeN    => $sizeN,      ##-- == $rN->size()
##    ##
##    ##-- low-level data
##    r1 => $r1,               ##-- pf: [$end2]      @ $i1				: constant (logical index)
##    r2 => $r2,               ##-- pf: [$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)	: sorted by $d1 for each $i1
##    rN => $rN,               ##-- pf: [$fN]        @ $date - $ymin                    : totals by date
##    ymin => $dmin,           ##-- constant == $coldb->{xdmin}
##    N  => $N,                ##-- sum($f12) [always used for version <= 0.11; used here only for slice==0]
##    version => $version,     ##-- file version, for compatibility checks
##   )
sub new {
  my $that = shift;
  my $ug   = bless({
		    base  =>undef,
		    flags =>'r',
		    perms =>(0666 & ~umask),
		    pack_i=>'N',
		    pack_f=>'N',
		    pack_d=>'n',
		    N  => 0,
		    version => $DiaColloDB::VERSION,
		    logCompat => 'warn',
		    #keeptmp => 0,
		    #mmap => 1,
		    @_
		   }, (ref($that)||$that));
  $ug->{$_} //= $ug->mmclass($PFCLASS)->new() foreach (qw(r1 r2 rN));
  $ug->{class} = ref($ug);
  return $ug->open() if (defined($ug->{base}));
  return $ug;
}

sub DESTROY {
  $_[0]->close() if ($_[0]->opened);
}

##==============================================================================
## Persistent API: disk usage

## @files = $obj->diskFiles()
##  + returns disk storage files, used by du() and timestamp()
sub diskFiles {
  return map {"$_[0]{base}$_"} (qw(.hdr .dba1 .dba1.hdr .dba2 .dba2.hdr));
}

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: open/close

## $ug_or_undef = $ug->open($base,$flags)
## $ug_or_undef = $ug->open($base)
## $ug_or_undef = $ug->open()
sub open {
  my ($ug,$base,$flags) = @_;
  $base  //= $ug->{base};
  $flags //= $ug->{flags};
  $ug->close() if ($ug->opened);
  $ug->{base}  = $base;
  $ug->{flags} = $flags = fcflags($flags);
  my ($hdr); ##-- save header, for version-checking
  if (fcread($flags) && !fctrunc($flags)) {
    $hdr = ($ug->readHeader() || $ug->readHeader("$ug->{base}.dba.hdr"))
      or $ug->logconfess("failed to read header data from '$ug->{base}.hdr': $!");
    $ug->loadHeaderData($hdr)
      or $ug->logconess("failed to load header data from '$ug->{base}.hdr': $!");
  }

  ##-- check compatibility
  my $min_version = qv(0.12.000);
  if ($hdr && (!defined($hdr->{version}) || version->parse($hdr->{version}) < $min_version)) {
    $ug->vlog($ug->{logCompat}, "using v0.11 compatibility mode for $ug->{base}.*; consider running \`dcdb-upgrade.perl ", dirname($ug->{base}), "\'");
    DiaColloDB::Compat->usecompat('v0_11');
    bless($ug, 'DiaColloDB::Compat::v0_11::Relation::Unigrams');
    $ug->{version} = $hdr->{version};
    return $ug->open($base,$flags);
  }

  ##-- open low-level data structures
  $ug->{r1}->open("$base.dba1", $flags, perms=>$ug->{perms}, packas=>"$ug->{pack_i}")
    or $ug->logconfess("open failed for $base.dba1: $!");
  $ug->{r2}->open("$base.dba2", $flags, perms=>$ug->{perms}, packas=>"$ug->{pack_d}$ug->{pack_f}")
    or $ug->logconfess("open failed for $base.dba2: $!");
  $ug->{rN}->open("$base.dbaN", $flags, perms=>$ug->{perms}, packas=>"$ug->{pack_f}")
    or $ug->logconfess("open failed for $base.dbaN: $!");
  $ug->{size1} = $ug->{r1}->size;
  $ug->{size2} = $ug->{r2}->size;
  $ug->{sizeN} = $ug->{rN}->size;

  return $ug;
}

## $ug_or_undef = $ug->close()
sub close {
  my $ug = shift;
  if ($ug->opened && fcwrite($ug->{flags})) {
    $ug->saveHeader() or return undef;
  }
  $ug->{r1}->close() or return undef;
  $ug->{r2}->close() or return undef;
  $ug->{rN}->close() or return undef;
  undef $ug->{base};
  return $ug;
}

## $bool = $ug->opened()
sub opened {
  my $ug = shift;
  return
    (defined($ug->{base})
     && defined($ug->{r1}) && $ug->{r1}->opened
     && defined($ug->{r2}) && $ug->{r2}->opened
     && defined($ug->{rN}) && $ug->{rN}->opened
    );
}

##--------------------------------------------------------------
## I/O: header
##  + largely INHERITED from DiaColloDB::Persistent

## @keys = $ug->headerKeys()
##  + keys to save as header
sub headerKeys {
  return grep {!ref($_[0]{$_}) && $_ !~ m{^(?:base|flags|perms|log.*|packas|reclen)$}} keys %{$_[0]};
}

## $bool = $ug->loadHeaderData($hdr)
##  + instantiates header data from $hdr
##  + overrides DiaColloDB::Persistent implementation
sub loadHeaderData {
  my ($ug,$hdr) = @_;
  if (!defined($hdr) && !fccreat($ug->{flags})) {
    $ug->logconfess("loadHeaderData() failed to load header data from ", $ug->headerFile, ": $!");
  }
  elsif (defined($hdr)) {
    return $ug->SUPER::loadHeaderData($hdr);
  }
  return $ug;
}

## $bool = $enum->saveHeader()
##  + inherited from DiaColloDB::Persistent

##--------------------------------------------------------------
## I/O: text
##  + largely INHERITED from DiaColloDB::Persistent

## $bool = $obj->loadTextFile($filename_or_handle, %opts)
##  + wraps loadTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $ug = $ug->loadTextFh($fh,%opts)
##  + loads from text file as saved by saveTextFh()
##  + input fh must be sorted by $i1,$d1
##  + supports multiple lines for pairs ($i1,$d1) provided the above conditions hold
##  + supports loading of $ug->{N} from single-component lines
##  + %opts: clobber %$ug
sub loadTextFh {
  my ($ug,$infh,%opts) = @_;
  if (!ref($ug)) {
    $ug = $ug->new(%opts);
  } else {
    @$ug{keys %opts} = values %opts;
  }
  $ug->logconfess("loadTextFh(): cannot load unopened database!") if (!$ug->opened);

  ##-- common variables
  ##   $r1 : [$end2]      @ $i1
  ##   $r2 : [$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)
  my ($r1,$r2,$rN)       = @$ug{qw(r1 r2 rN)};
  my ($pack_r1,$pack_r2) = map {$_->{packas}} ($r1,$r2);
  $r1->truncate();
  $r2->truncate();
  $rN->truncate();
  my ($fh1,$fh2) = ($r1->{fh},$r2->{fh});

  ##-- iteration variables
  my ($pos1,$pos2) = (0,0);
  my ($i1_cur,$f1) = (-1,undef,0);
  my ($i1,$d1);
  my $N  = 0;	  ##-- total marginal frequency as extracted from %fd
  my $N1 = 0;     ##-- total N as extracted from single-element records
  my %fd = qw();  ##-- ($d=>$f1d, ...) for $i1_cur
  my %fN  = qw(); ##-- ($d=>$fd, ...) global

  ##-- guts for inserting records from $i1_cur,%fd,$pos1,$pos2 : call on changed ($i1_cur)
  my $insert = sub {
    if ($i1_cur >= 0) {
      if ($i1_cur != $pos1) {
	##-- we've skipped one or more $i1 because it had no data-lines
	$fh1->print( pack($pack_r1,$pos2) x ($i1_cur-$pos1) );
	$pos1 = $i1_cur;
      }

      ##-- dump r2-record(s) for ($i1_cur)
      foreach (sort {$a<=>$b} keys %fd) {
	$fh2->print(pack($pack_r2, $_,$fd{$_}));
	++$pos2;
      }

      ##-- dump r1-record for $i1_cur
      $fh1->print(pack($pack_r1, $pos2));
      $pos1 = $i1_cur+1;
    }
    $i1_cur = $i1;
    %fd     = qw();
  };

  ##-- ye olde loope
  binmode($infh,':raw');
  while (defined($_=<$infh>)) {
    chomp;
    ($f1,$i1,$d1) = split(' ',$_,3);
    if (!defined($i1)) {
      $N1 += $f1;		      ##-- load N values
      next;
    }
    elsif ($i1 eq '') {
      next;			      ##-- ignore EOS counts from create()
    }
    elsif (!defined($d1)) {
      $ug->logconfess("loadTextFh(): failed to parse input line ", $infh->input_line_number);
    }
    $insert->()			      ##-- insert record(s) for ($i1_cur)
      if ($i1 != $i1_cur);
    $fd{$d1} += $f1;                  ##-- buffer frequencies for ($i1_cur,$d1_cur)
    $fN{$d1} += $f1;                  ##-- track N by date
    $N       += $f1;		      ##-- track marginal N
  }
  $i1 = -1;
  $insert->();                        ##-- write record(s) for final ($i1_cur)

  ##-- create $rN by date
  my @dates  = sort {$a<=>$b} keys %fN;
  my $ymin   = $ug->{ymin} = $dates[0];
  $rN->{fh}->print(pack("($rN->{packas})*", map {$fN{$_}//0} ($ymin..$dates[$#dates])));

  ##-- adopt final $N and sizes
  $ug->{N} = $N1>$N ? $N1 : $N;
  foreach (qw(1 2 N)) {
    my $r = $ug->{"r$_"};
    $r->flush();
    $ug->{"size$_"} = $r->size;
  }

  return $ug;
}

## $bool = $obj->saveTextFile($filename_or_handle, %opts)
##  + wraps saveTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $ug->saveTextFh($fh,%opts)
##  + save from text file with lines of the form:
##      N                 ##-- 1 field : N
##      FREQ ID1 DATE     ##-- 3 fields: unigram frequency for (ID1,DATE)
##  + %opts:
##      i2s => \&CODE,    ##-- code-ref for formatting indices; called as $s=CODE($i)
sub saveTextFh {
  my ($ug,$outfh,%opts) = @_;
  $ug->logconfess("saveTextFile(): cannot save unopened DB") if (!$ug->opened);

  ##-- common variables
  ##   $r1 : [$end2]      @ $i1
  ##   $r2 : [$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)
  my ($r1,$r2) = @$ug{qw(r1 r2)};
  my ($pack1,$pack2) = map {$_->{packas}} ($r1,$r2);
  my $i2s  = $opts{i2s};

  ##-- iteration variables
  my ($buf1,$i1,$s1,$end2);
  my ($buf2,$off2,$d1,$f1);

  ##-- ye olde loope
  binmode($outfh,':raw');
  $outfh->print($ug->{N}, "\n");
  for ($r1->seek($i1=0), $r2->seek($off2=0); !$r1->eof(); ++$i1) {
    $r1->read(\$buf1) or $ug->logconfess("saveTextFile(): failed to read record $i1 from $r1->{file}: $!");
    $end2 = unpack($pack1,$buf1);
    $s1   = $i2s ? $i2s->($i1) : $i1;

    for ( ; $off2 < $end2 && !$r2->eof(); ++$off2) {
      $r2->read(\$buf2) or $ug->logconfess("saveTextFile(): failed to read record $off2 from $r2->{file}: $!");
      ($d1,$f1) = unpack($pack2,$buf2);

      $outfh->print(join("\t", $f1, $s1, $d1), "\n");
    }
  }

  return $ug;
}


##==============================================================================
## Relation API: create

## $ug = $CLASS_OR_OBJECT->create($coldb,$tokdat_file,%opts)
##  + populates current database from $tokdat_file,
##    a tt-style text file containing with lines of the form:
##      TID DATE	##-- single token
##	"\n"		##-- blank line --> EOS
##  + %opts: clobber %$ug
sub create {
  my ($ug,$coldb,$datfile,%opts) = @_;

  ##-- create/clobber
  $ug = $ug->new() if (!ref($ug));
  @$ug{keys %opts} = values %opts;

  ##-- ensure openend
  $ug->opened
    or $ug->open()
      or $ug->logconfess("create(): failed to open unigrams database: $!");

  env_push(LC_ALL=>'C');
  my $cmdfh = opencmd("sort -nk1 -nk2 ".sortJobs()." $datfile | uniq -c |")
    or $ug->logconfess("create(): failed to open pipe from sort: $!");
  $ug->loadTextFh($cmdfh)
    or $ug->logconfess("create(): failed to load unigram data: $!");
  $cmdfh->close()
    or $ug->logconfess("create(): failed to close pipe from sort: $!");
  env_pop();

  ##-- save header
  $ug->saveHeader()
    or $ug->logconfess("create(): failed to save header: $!");

  ##-- done
  return $ug;
}

##==============================================================================
## Relation API: union

## $ug = CLASS_OR_OBJECT->union($coldb, \@pairs, %opts)
##  + merge multiple co-frequency indices into new object
##  + @pairs : array of pairs ([$ug,\@ti2u],...)
##    of unigram-objects $ug and tuple-id maps \@ti2u for $ug
##    - \@ti2u may also be a mapping object supporting a toArray() method
##  + %opts: clobber %$ug
##  + implicitly flushes the new index
sub union {
  my ($ug,$coldb,$pairs,%opts) = @_;

  ##-- create/clobber
  $ug = $ug->new() if (!ref($ug));
  @$ug{keys %opts} = values %opts;

  ##-- tempfile (input for sort)
  my $tmpfile = "$ug->{base}.udat";
  my $tmpfh   = IO::File->new(">$tmpfile")
    or $ug->logconfess("union(): open failed for tempfile $tmpfile: $!");
  binmode($tmpfh,':raw');

  ##-- stage1: dump argument relations to text tempfile
  $ug->vlog('trace', "union(): stage1: collect items");
  my ($pair,$pxf,$pi2u,$pi2s);
  my $pairi =0;
  foreach $pair (@$pairs) {
    ($pxf,$pi2u) = @$pair;
    $pi2u = $pi2u->toArray() if (UNIVERSAL::can($pi2u,'toArray'));
    $pxf->saveTextFh($tmpfh, i2s=>sub { $pi2u->[$_[0]] })
      or $ug->logconfess("union(): failed to extract data for argument $pairi");
    ++$pairi;
  }
  $tmpfh->close()
    or $ug->logconfess("union(): failed to close tempfile $tmpfile: $!");

  ##-- stage2: sort & load tempfile
  env_push(LC_ALL=>'C');
  $ug->vlog('trace', "union(): stage2: load unigram frequencies");
  my $sortfh = opencmd("sort -n -k2 -k3 ".sortJobs()." $tmpfile |")
    or $ug->logconfess("union(): open failed for pipe from sort: $!");
  binmode($sortfh,':raw');
  $ug->loadTextFh($sortfh)
    or $ug->logconfess("union(): failed to load unigram frequencies from $tmpfile: $!");
  $sortfh->close()
    or $ug->logconfess("union(): failed to close pipe from sort: $!");
  env_pop();

  ##-- stage3: header
  $ug->saveHeader()
    or $ug->logconfess("union(): failed to save header: $!");

  ##-- cleanup: unlink temp file(s)
  CORE::unlink($tmpfile) if (!$ug->{keeptmp});

  return $ug;
}

##==============================================================================
## Relation API: dbinfo

## \%info = $rel->dbinfo($coldb)
##  + embedded info-hash for $coldb->dbinfo()
sub dbinfo {
  my $ug = shift;
  my $info = $ug->SUPER::dbinfo();
  @$info{qw(size1 size2 sizeN N)} = @$ug{qw(size1 size2 sizeN N)};
  return $info;
}


##==============================================================================
## Utils: lookup

## $N = $cof->sliceN($sliceBy, $dateLo)
##  + get total slice co-occurrence count, used by subprofile1()
##  + INHERITED from DiaColloDB::Relation

##==============================================================================
## Relation API: default

##--------------------------------------------------------------
## Relation API: default: sliceN

## $N = $rel->sliceN($sliceBy, $dateLo)
##  + get total slice-wise co-occurrence count for a slice of size $sliceBy starting at $dateLo
##  + INHERITED from DiaColloDB::Relation

##--------------------------------------------------------------
## Relation API: default: profile

## \%slice2prf = $rel->subprofile1(\@tids,\%opts)
##  + get slice-wise joint co-frequency profile(s) for @tids (db must be opened; f1 and f12 only)
##  + %opts: as for profile(), also:
##     coldb => $coldb,   ##-- parent DiaColloDB object (for shared data, debugging)
##     dreq  => \%dreq,   ##-- parsed date request
sub subprofile1 {
  my ($ug,$tids,$opts) = @_;

  ##-- common variables
  $tids = [$tids] if (!UNIVERSAL::isa($tids,'ARRAY'));
  my $coldb = $opts->{coldb};
  my $slice = $opts->{slice};
  my $dreq  = $opts->{dreq};
  my $dfilter = $dreq->{dfilter};
  my $groupby = $opts->{groupby}{ti2g};
  my $extend  = $opts->{extend};
  my $onepass = $opts->{onepass};
  my $pack_id = $coldb->{pack_id};

  ##-- vars: relation-wise
  ##   $r1 : [$end2]      @ $i1
  ##   $r2 : [$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)
  my ($r1,$r2)       = @$ug{qw(r1 r2)};
  my ($pack1,$pack2) = map {$_->{packas}} ($r1,$r2);
  my $pack2d = $ug->{pack_d};
  my $pack2f = '@'.packsize("$ug->{pack_i}").$ug->{pack_f};
  my $size1  = $ug->{size1} // ($ug->{size1}=$r1->size);
  my $size2  = $ug->{size2} // ($ug->{size2}=$r2->size);

  ##-- setup %slice2prf
  my %slice2prf = map {
    ($_ => DiaColloDB::Profile->new(f1=>0, N=>$ug->sliceN($slice,$_)))
  } ($slice ? (map {$_*$slice} (($dreq->{slo}/$slice)..($dreq->{shi}/$slice))) : 0);


  ##-- ye olde loope
  my ($i1,$beg2,$end2, $pos2,$d1,$ds,$dprf,$f1, $key2,$buf);
  foreach $i1 (@$tids) {
    next if ($i1 >= $size1);
    $beg2 = ($i1==0 ? 0 : unpack($pack1,$r1->fetchraw($i1-1,\$buf)));
    $end2 = unpack($pack1, $r1->fetchraw($i1,\$buf));

    ##-- check groupby "having" filter
    $key2 = $groupby ? $groupby->($i1) : pack($pack_id,$i1);

    next if ($beg2 >= $size2);
    for ($pos2=$beg2; $pos2 < $end2; ++$pos2) {
      ($d1,$f1) = unpack($pack2, $r2->fetchraw($pos2,\$buf));

      ##-- check date-filter & get slice-local profile $dprf
      next if ($dfilter && !$dfilter->($d1));
      $ds   = $slice ? int($d1/$slice)*$slice : 0;
      $dprf = $slice2prf{$ds};
      $dprf->{f1} += $f1;

      next if (!defined($key2)					##-- item2 selection via groupby CODE-ref
               || ($extend && !exists($extend->{$ds}{$key2}))	##-- ... or via 'extend' parameter
              );
      $dprf->{f12}{$key2} += $f1;
      $dprf->{f2}{$key2}  += $f1;
    }
  }

  return \%slice2prf;
}

##--------------------------------------------------------------
## Relation API: default: subprofile2

##  \%slice2prf = $rel->subprofile2(\%slice2prf, \%opts)
##  + populate f2 frequencies for profiles in \%slice2prf
##  + %opts: as for subprofile1()
##  + INHERITED from DiaColloDB::Relation : no-op

##--------------------------------------------------------------
## Relation API: default: qinfo

## \%qinfo = $rel->qinfo($coldb, %opts)
##  + get query-info hash for profile administrivia (ddc hit links)
##  + %opts: as for profile(), additionally:
##    (
##     qreqs => \@qreqs,      ##-- as returned by $coldb->parseRequest($opts{query})
##     gbreq => \%groupby,    ##-- as returned by $coldb->groupby($opts{groupby})
##    )
sub qinfo {
  my ($rel,$coldb,%opts) = @_;
  my ($q1strs,$q2strs,$qxstrs,$fstrs) = $rel->qinfoData($coldb,%opts);

  my @qstrs = (@$q1strs, @$q2strs, @$qxstrs);
  @qstrs    = ('*') if (!@qstrs);
  my $qstr = ('('.join(' WITH ', @qstrs).') =1'
	      .' #SEPARATE'
	      .(@$fstrs ? (' '.join(' ',@$fstrs)) : ''),
	     );
  return {
	  fcoef => 1,
	  qtemplate => $qstr,
	 };
}

##==============================================================================
## Pacakge Alias(es)
package DiaColloDB::Unigrams;
use strict;
our @ISA = qw(DiaColloDB::Relation::Unigrams);

##==============================================================================
## Footer
1;

__END__
