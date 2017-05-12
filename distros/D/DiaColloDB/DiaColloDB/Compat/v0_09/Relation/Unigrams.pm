## -*- Mode: CPerl -*-
## File: DiaColloDB::Compat::v0_09::Relation::Unigrams.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profiling relation: unigram database (using DiaColloDB::PackedFile)

package DiaColloDB::Compat::v0_09::Relation::Unigrams;
use DiaColloDB::Compat::v0_09::Relation;
use DiaColloDB::PackedFile;
use DiaColloDB::Utils qw(:sort :env :run :pack :file);
use Fcntl qw(:seek);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::PackedFile DiaColloDB::Compat::v0_09::Relation);

##==============================================================================
## Constructors etc.

## $ug = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##   ##-- PackedFile: user options
##   file     => $filename,   ##-- default: undef (none)
##   flags    => $flags,      ##-- fcntl flags or open-mode (default='r')
##   perms    => $perms,      ##-- creation permissions (default=(0666 &~umask))
##   reclen   => $reclen,     ##-- record-length in bytes: (default: guess from pack format if available)
##   packas   => $packas,     ##-- pack-format or array; see DiaColloDB::Utils::packFilterStore();  ##-- OVERRIDE default='N'
##   ##
##   ##-- PackedFile: filters
##   filter_fetch => $filter, ##-- DB_File-style filter for fetch
##   filter_store => $filter, ##-- DB_File-style filter for store
##   ##
##   ##-- PackedFile: low-level data
##   fh       => $fh,         ##-- underlying filehandle
##   ##
##   ##-- Unigrams: high-level data
##   N        => $N,          ##-- total frequency
##   )
sub new {
  my $that = shift;
  my $ug   = $that->DiaColloDB::PackedFile::new(
						N=>0,
						packas=>'N',
						@_
					       );
  return $ug;
}

##==============================================================================
## Persistent API: disk usage: INHERITED

##==============================================================================
## API: open/close: mostly INHERITED

## $filename = $obj->headerFile()
##  + returns header filename; default returns "$obj->{base}.hdr" or "$obj->{dbdir}/header.json"
sub headerFile {
  return undef if (!ref($_[0]));
  return "$_[0]{file}.hdr" if (defined($_[0]{file}));
  return undef;
}

##==============================================================================
## API: filters: INHERITED

##==============================================================================
## PackedFile API: positioning: INHERITED

##==============================================================================
## PackedFile API: record access: INHERITED

##==============================================================================
## I/O: text
##  + largely INHERITED from DiaColloDB::PackedFile

## $bool = $ug->saveTextFh_v0_10($fh,%opts)
##  + save from text file in v0.10.x format: lines of the form:
##      N                 ##-- 1 field : N
##      FREQ ID1 DATE     ##-- 3 fields: unigram frequency for (ID1,DATE)
##  + %opts:
##      i2s => \&CODE,    ##-- code-ref for formatting indices; called as $s=CODE($i)
sub saveTextFh_v0_10 {
  my ($ug,$outfh,%opts) = @_;
  $ug->logconfess("saveTextFile(): cannot save unopened DB") if (!$ug->opened);

  $outfh->print($ug->{N}, "\n") if (defined($ug->{N})); ##-- save N line
  my $size = $ug->size();
  my $i2s  = $opts{i2s};
  my ($i,$val);
  for ($i=0, $ug->reset(); $i < $size; ++$i) {
    $val = $ug->get();
    $outfh->print($val, "\t", ($i2s ? $i2s->($i) : $i), "\n");
  }

  return $ug;
}



##==============================================================================
## PackedFile API: tie interface: INHERITED

##==============================================================================
## Relation API: create

## $ug = $CLASS_OR_OBJECT->create($coldb,$tokdat_file,%opts)
##  + populates current database from $tokdat_file,
##    a tt-style text file containing 1 token-id perl line with optional blank lines
##  + %opts: clobber %$ug, also:
##    (
##     size=>$size,  ##-- set initial size
##    )
##  + DISABLED

##==============================================================================
## Relation API: union

## $ug = CLASS_OR_OBJECT->union($coldb, \@pairs, %opts)
##  + merge multiple co-frequency indices into new object
##  + @pairs : array of pairs ([$ug,\@xi2u],...)
##    of unigram-objects $ug and tuple-id maps \@xi2u for $ug
##  + %opts: clobber %$ug
##  + implicitly flushes the new index
##  + DISABLED

##==============================================================================
## Relation API: dbinfo

## \%info = $rel->dbinfo($coldb)
##  + embedded info-hash for $coldb->dbinfo()
sub dbinfo {
  my $ug = shift;
  my $info = $ug->SUPER::dbinfo();
  $info->{N} = $ug->{N};
  $info->{size} = $ug->size();
  return $info;
}


##==============================================================================
## Relation API: default: profiling

## $prf = $ug->subprofile1(\@xids, %opts)
##  + get frequency profile for @xids (db must be opened)
##  + %opts:
##     groupby => \&gbsub,  ##-- key-extractor $key2_or_undef = $gbsub->($i2)
##     coldb   => $coldb,   ##-- for debugging
sub subprofile1 {
  my ($ug,$ids,%opts) = @_;
  $ids   = [$ids] if (!UNIVERSAL::isa($ids,'ARRAY'));

  my $fh = $ug->{fh};
  my $packf = $ug->{packas};
  my $reclen = $ug->{reclen};
  my $groupby = $opts{groupby};
  my $pf1 = 0;
  my $pf2 = {};
  my ($i,$f,$key2, $buf);

  foreach $i (@$ids) {
    CORE::seek($fh, $i*$reclen, SEEK_SET) or return undef;
    CORE::read($fh, $buf, $reclen)==$reclen or return undef;
    $f     = unpack($packf,$buf);
    $pf1  += $f;
    $key2  = $groupby ? $groupby->($i) : $i;
    next if (!defined($key2));
    $pf2->{$key2}  += $f
  }

  return DiaColloDB::Profile->new(
				  N=>$ug->{N},
				  f1=>$pf1,
				  f2=>$pf2,
				  f12=>{ %$pf2 },
				 );
}

##==============================================================================
## Relation API: default: query info

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
package DiaColloDB::Compat::v0_09::Unigrams;
use strict;
our @ISA = qw(DiaColloDB::Compat::v0_09::Relation::Unigrams);

##==============================================================================
## Footer
1;

__END__
