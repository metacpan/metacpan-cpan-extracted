## -*- Mode: CPerl -*-
## File: DiaColloDB::methods::export.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, top-level import/export methods
##  + really just adds methods to top-level DiaColloDB package

##-- dummy package
package DiaColloDB::methods::export;
use strict;
1;

package DiaColloDB;
use strict;

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
  $coldb->{tenum}->load() if ($coldb->{tenum} && !$coldb->{tenum}->loaded);
  foreach (@$adata) {
    $_->{enum}->load() if ($_->{enum} && !$_->{enum}->loaded);
  }

  ##-- dump: common: stringification
  my $pack_t = $coldb->{pack_t};
  my ($ts2txt,$ti2txt);
  if ($export_sdat) {
    $coldb->vlog($coldb->{logExport}, "dbexport(): preparing tuple-stringification structures");

    foreach (@$adata) {
      my $i2s     = $_->{i2s} = $_->{enum}->toArray;
      $_->{i2txt} = sub { return $i2s->[$_[0]//0]//''; };
    }

    my $ti2s = $coldb->{tenum}->toArray;
    my @ai2s = map {$_->{i2s}} @$adata;
    my (@t);
    $ts2txt = sub {
      @t = unpack($pack_t,$_[0]);
      return join("\t", (map {$ai2s[$_][$t[$_]//0]//''} (0..$#ai2s)));
    };
    $ti2txt = sub {
      @t = unpack($pack_t, $ti2s->[$_[0]//0]//'');
      return join("\t", (map {$ai2s[$_][$t[$_]//0]//''} (0..$#ai2s)));
    };
  }

  ##-- dump: tenum: raw
  $coldb->vlog($coldb->{logExport}, "dbexport(): exporting tuple-enum file $outdir/tenum.dat (raw)");
  $coldb->{tenum}->saveTextFile("$outdir/tenum.dat")
    or $coldb->logconfess("export failed for $outdir/tenum.dat");

  ##-- dump: xenum: stringified
  if ($export_sdat) {
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting tuple-enum file $outdir/tenum.sdat (strings)");
    $coldb->{tenum}->saveTextFile("$outdir/tenum.sdat", pack_s=>$ts2txt)
      or $coldb->logconfess("dbexport() failed for $outdir/tenum.sdat");
  }

  ##-- dump: by attribute: enum
  foreach (@$adata) {
    ##-- dump: by attribute: enum
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting attribute enum file $outdir/$_->{a}_enum.dat");
    $_->{enum}->saveTextFile("$outdir/$_->{a}_enum.dat")
      or $coldb->logconfess("dbexport() failed for $outdir/$_->{a}_enum.dat");
  }

  ##-- dump: by attribute: a2t
  foreach (@$adata) {
    ##-- dump: by attribute: a2t: raw
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting attribute expansion multimap $outdir/$_->{a}_2t.dat (raw)");
    $_->{a2t}->saveTextFile("$outdir/$_->{a}_2t.dat")
      or $coldb->logconfess("dbexport() failed for $outdir/$_->{a}_2t.dat");

    ##-- dump: by attribute: a2x: stringified
    if ($export_sdat) {
      $coldb->vlog($coldb->{logExport}, "dbexport(): exporting attribute expansion multimap $outdir/$_->{a}_2t.sdat (strings)");
      $_->{a2t}->saveTextFile("$outdir/$_->{a}_2t.sdat", a2s=>$_->{i2txt}, b2s=>$ti2txt)
	or $coldb->logconfess("dbexport() failed for $outdir/$_->{a}_2t.sdat");
    }
  }

  ##-- dump: xf
  if ($coldb->{xf}) {
    ##-- dump: xf: raw
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting tuple-frequency index $outdir/xf.dat (raw)");
    $coldb->{xf}->saveTextFile("$outdir/xf.dat")
      or $coldb->logconfess("export failed for $outdir/xf.dat");

    ##-- dump: xf: stringified
    if ($export_sdat) {
      $coldb->vlog($coldb->{logExport}, "dbexport(): exporting tuple-frequency index $outdir/xf.sdat (strings)");
      $coldb->{xf}->saveTextFile("$outdir/xf.sdat", i2s=>$ti2txt)
	or $coldb->logconfess("dbexport() failed for $outdir/xf.sdat");
    }
  }

  ##-- dump: cof
  if ($coldb->{cof} && $export_cof) {
    $coldb->vlog($coldb->{logExport}, "dbexport(): exporting co-frequency index $outdir/cof.dat (raw)");
    $coldb->{cof}->saveTextFile("$outdir/cof.dat")
      or $coldb->logconfess("export failed for $outdir/cof.dat");

    if ($export_sdat) {
      $coldb->vlog($coldb->{logExport}, "dbexport(): exporting co-frequency index $outdir/cof.sdat (strings)");
      $coldb->{cof}->saveTextFile("$outdir/cof.sdat", i2s=>$ti2txt)
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


1; ##-- be happy
