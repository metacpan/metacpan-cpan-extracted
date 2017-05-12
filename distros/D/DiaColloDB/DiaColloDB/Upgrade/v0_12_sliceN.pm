## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Upgrade::v0_12_sliceN.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: auto-magic upgrade: v0.11.x -> v0.12.x: allow slice-wise N

package DiaColloDB::Upgrade::v0_12_sliceN;
use DiaColloDB::Upgrade::Base;
use DiaColloDB::Compat::v0_11;
use DiaColloDB::Utils qw(:pack :env :run :file :pdl);
use version;
use strict;
our @ISA = qw(DiaColloDB::Upgrade::Base);

##==============================================================================
## API

## $version = $CLASS_OR_OBJECT->toversion()
##  + returns default target version; default just returns $DiaColloDB::VERSION
sub toversion {
  return '0.12.000';
}

## $bool = $CLASS_OR_OBJECT->upgrade()
##  + performs upgrade
sub upgrade {
  my $up = shift;

  ##-- backup
  $up->backup() or return undef;

  ##-- read header
  my $dbdir = $up->{dbdir};
  my $hdr   = $up->dbheader();

  ##-- convert relations: unigrams
  {
    my $ug = DiaColloDB::Relation::Unigrams->new(base=>"$dbdir/xf", logCompat=>'off')
      or $up->logconfess("failed to open unigram index $dbdir/xf.*: $!");
    $up->info("upgrading unigram index $dbdir/xf.*");
    $up->warn("unigram data in $dbdir/xf.* doesn't seem to be v0.11 format; trying to upgrade anyways")
      if (!$ug->isa('DiaColloDB::Compat::v0_11::Relation::Unigrams'));

    ##-- xf: extract total counts by date
    my $r2     = $ug->{r2}; ##-- pf: [$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)
    my $packas = $r2->{packas};
    my ($buf, $d,$f);
    my %fN = qw();
    for (my $i=0; $i < $ug->{size2}; ++$i) {
      $r2->read(\$buf);
      ($d,$f) = unpack($packas,$buf);
      $fN{$d} += $f;
    }

    ##-- xf: create $rN by date
    my @dates  = sort {$a<=>$b} keys %fN;
    my $ymin   = $dates[0];
    my $rN     = $ug->{rN} = DiaColloDB::PackedFile->new(file=>"$dbdir/xf.dbaN", flags=>'rw', perms=>$ug->{perms}, packas=>"$ug->{pack_f}");
    $rN->store(($_-$ymin)=>$fN{$_}) foreach (@dates);
    $rN->flush();

    ##-- xf: update header
    $ug->{ymin}    = $ymin;
    $ug->{sizeN}   = $rN->size;
    $ug->{version} = $up->toversion;
    $ug->saveHeader()
      or $up->logconfess("failed to save new unigram index header $dbdir/xf.hdr");
  }

  ##-- convert relations: cofreqs
  {
    my $cof = DiaColloDB::Relation::Cofreqs->new(base=>"$dbdir/cof", logCompat=>'off')
      or $up->logconfess("failed to open co-frequency index $dbdir/cof.*: $!");
    $up->info("upgrading co-frequency index $dbdir/cof.*");
    $up->warn("co-frequency data in $dbdir/cof.* doesn't seem to be v0.11 format; trying to upgrade anyways")
      if (!$cof->isa('DiaColloDB::Compat::v0_11::Relation::Cofreqs'));

    ##-- cof: extract total counts by date
    my $r2     = $cof->{r2}; ##-- pf: [$end3,$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)
    my $packas = $r2->{packas};
    my ($buf, $end3,$d,$f);
    my %fN = qw();
    for (my $i=0; $i < $cof->{size2}; ++$i) {
      $r2->read(\$buf);
      ($end3,$d,$f) = unpack($packas,$buf);
      $fN{$d} += $f;
    }

    ##-- cof: create $rN by date
    my @dates  = sort {$a<=>$b} keys %fN;
    my $ymin   = $dates[0];
    my $rN     = $cof->{rN} = DiaColloDB::PackedFile->new(file=>"$dbdir/cof.dbaN", flags=>'rw', perms=>$cof->{perms}, packas=>"$cof->{pack_f}");
    $rN->store(($_-$ymin)=>$fN{$_}) foreach (@dates);
    $rN->flush();

    ##-- cof: update header
    $cof->{ymin}    = $ymin;
    $cof->{sizeN}   = $rN->size;
    $cof->{version} = $up->toversion;
    $cof->saveHeader()
      or $up->logconfess("failed to save new co-frequency index header $dbdir/cof.hdr");
  }

  ##-- convert relations: tdf
  if ($hdr->{index_tdf} && -r "$dbdir/tdf.hdr") {
    DiaColloDB::Compat->usecompat('v0_11::Relation::TDF');
    my $vs = DiaColloDB::Relation::TDF->new(base=>"$dbdir/tdf", logCompat=>'off')
      or $up->logconfess("failed to open (term x document) index $dbdir/tdf.*: $!");
    $up->info("upgrading (term x document)  index $dbdir/tdf.*");
    $up->warn("term-document data in $dbdir/tdf.* doesn't seem to be v0.11 format; trying to upgrade anyways")
      if (!$vs->isa('DiaColloDB::Compat::v0_11::Relation::TDF'));

    ##-- tdf: create {yf}, {ymin}
    my ($cf,$c2date) = @$vs{qw(cf c2date)};
    my ($ymin,$ymax) = $c2date->minmax;
    my $NY           = $ymax-$ymin+1;
    $cf->indadd( ($c2date-$ymin), my $yf=mmzeroes("$dbdir/tdf.d/yf.pdl",$vs->vtype,$NY) );
    undef $yf;

    ##-- tdf: update header
    $vs->{y0}      = $ymin;
    $vs->{version} = $up->toversion;
    $vs->saveHeader()
      or $up->logconfess("failed to save new (term x document) index header $dbdir/tdf.hdr");
  }

  ##-- cleanup
  if (0 && !$up->{keep}) {
    $up->info("removing temporary file(s)");
  }

  ##-- update header
  return $up->updateHeader();
}

##==============================================================================
## Backup & Revert

## $bool = $up->backup()
##  + perform backup any files we expect to change to $up->backupdir()
sub backup {
  my $up = shift;
  $up->SUPER::backup() or return undef;
  return 1 if (!$up->{backup});

  my $dbdir = $up->{dbdir};
  my $hdr   = $up->dbheader;
  my $backd = $up->backupdir;

  ##-- backup: top-level
  foreach my $base (map {"$dbdir/$_"} qw(xf cof tdf)) {
    $up->info("backing up $base.*");
    copyto_a([grep {-e $_} map {($_,"$_.hdr")} ($base,"$base.dbaN")], $backd)
      or $up->logconfess("backup failed for $base.*: $!");
  }

  ##-- backup: tdf.d
  foreach my $base (map {"$dbdir/tdf.d/$_"} qw(yf.pdl)) {
    $up->info("backing up $base.*");
    copyto_a([grep {-e $_} map {($_,"$_.hdr")} ($base)], "$backd/tdf.d")
      or $up->logconfess("backup failed for $base*: $!");
  }

  return 1;
}

## @files = $up->revert_created()
##  + returns list of files created by this upgrade, for use with default revert() implementation
sub revert_created {
  my $up  = shift;
  my $hdr = $up->dbheader;

  return (
	  ##-- unigrams
	  (grep {!-e $up->backupdir."/$_"} map {"xf.$_"} qw(dbaN dbaN.hdr)),

	  ##-- cofreqs
	  (grep {!-e $up->backupdir."/$_"} map {"cof.$_"} qw(dbaN dbaN.hdr)),

	  ##-- tdf
	  (grep {-e "$up->{dbdir}/$_" && !-e $up->backupdir."/$_"} map {"tdf.d/$_"} qw(yf.pdl yf.pdl.hdr)),

	  ##-- header
	  #'header.json',
	 );
}

## @files = $up->revert_updated()
##  + returns list of files updated by this upgrade, for use with default revert() implementation
sub revert_updated {
  my $up  = shift;
  my $hdr = $up->dbheader;

  return (
	  ##-- unigrams
	  "xf.hdr",
	  (grep {-e $up->backupdir."/$_"} map {"xf.$_"} qw(dbaN dbaN.hdr)),

	  ##-- cofreqs
	  "cof.hdr",
	  (grep {-e $up->backupdir."/$_"} map {"cof.$_"} qw(dbaN dbaN.hdr)),

	  ##-- tdf
	  (grep {-e $up->backupdir."/$_"} map {"tdf.$_"} qw(hdr d/yf.pdl d/yf.pdl.hdr)),

	  ##-- header
	  'header.json',
	 );
}


##==============================================================================
## Footer
1; ##-- be happy
