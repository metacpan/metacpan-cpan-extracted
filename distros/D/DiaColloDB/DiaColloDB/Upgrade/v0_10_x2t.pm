## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Upgrade::v0_10_x2t.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: auto-magic upgrade: v0.09.x -> v0.10.x: x-tuples (+date) -> t-tuples (-date)

package DiaColloDB::Upgrade::v0_10_x2t;
use DiaColloDB::Upgrade::Base;
use DiaColloDB::Compat::v0_09;
use DiaColloDB::Utils qw(:pack :env :run :file);
use version;
use strict;
our @ISA = qw(DiaColloDB::Upgrade::Base);

##==============================================================================
## API

## $version = $CLASS_OR_OBJECT->toversion()
##  + returns default target version; default just returns $DiaColloDB::VERSION
sub toversion {
  return '0.10.000';
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

  ##-- common variables
  no warnings 'portable';
  my $pack_t  = $hdr->{pack_t} = $hdr->{pack_id}."[".scalar(@{$hdr->{attrs}})."]";
  my $len_t   = packsize($pack_t);
  my $pack_xd = '@'.$len_t.$hdr->{pack_date};
  my $nbits_d = packsize($hdr->{pack_date}) * 8;
  my $nbits_t = packsize($hdr->{pack_id}) * 8;

  ##-- convert xenum to tenum
  $up->info("creating $dbdir/tenum.*");
  my $xenum = $DiaColloDB::XECLASS->new(base=>"$dbdir/xenum", pack_s=>$hdr->{pack_x})
    or $up->logconfess("failed to open $dbdir/xenum.*: $!");
  my %xeopts = map {($_=>$xenum->{$_})} qw(pack_i pack_o pack_l);
  my $xi2s = $xenum->toArray;
  my $xi2t = '';
  my $xi2d = '';
  my $ts2i  = {};
  my $nt    = 0;
  my ($xi,$xs,$xd,$ts,$ti);
  vec($xi2t, $#$xi2s, $nbits_t) = 0;  ##-- $xi2t : [$xi] => $ti
  vec($xi2d, $#$xi2s, $nbits_d) = 0;  ##-- $xi2d : [$xi] => $date
  for ($xi=0; $xi <= $#$xi2s; ++$xi) {
    $xs = $xi2s->[$xi];
    $ts = substr($xs,0,$len_t);
    $ti = $ts2i->{$ts} = $nt++ if (!defined($ti=$ts2i->{$ts}));
    vec($xi2d,$xi,$nbits_d) = unpack($pack_xd,$xs);
    vec($xi2t,$xi,$nbits_t) = $ti;
  }
  $xenum->unlink()
    or $up->logconfess("failed to remove old $dbdir/xenum.*: $!");
  my $tenum = $DiaColloDB::XECLASS->new(pack_s=>$pack_t, %xeopts);
  $tenum->fromHash($ts2i)->save("$dbdir/tenum")
    or $up->logconfess("failed to save $dbdir/tenum.*: $!");
  delete $hdr->{pack_x};

  ##-- convert attribute-wise multimaps & pack-templates
  foreach my $attr (@{$hdr->{attrs}}) {
    $up->info("creating multimap $dbdir/${attr}_2t.*");
    my $xmm = $DiaColloDB::MMCLASS->new(flags=>'r', base=>"$dbdir/${attr}_2x", logCompat=>'off')
      or $up->logconfess("failed to open $dbdir/${attr}_2x.*");
    my $mma    = $xmm->toArray();
    my %mmopts = (map {($_=>$xmm->{$_})} qw(pack_i));
    $xmm->unlink()
      or $up->logconfess("failed to unlink $dbdir/${attr}_2x.*");

    my $pack_bs = "$mmopts{pack_i}*";
    my ($ai,$tmp);
    for ($ai=0; $ai <= $#$mma; ++$ai) {
      $tmp = undef;
      $mma->[$ai] = pack($pack_bs,
			 map {defined($tmp) && $tmp==$_ ? qw(): ($tmp=$_)}
			 sort {$a<=>$b}
			 map {vec($xi2t,$_,$nbits_t)}
			 unpack($pack_bs, $mma->[$ai])
			);
    }

    my $tmm = $DiaColloDB::MMCLASS->new(flags=>'rw', %mmopts)
      or $up->logconfess("failed to create new multimap for attribute '$attr'");
    $tmm->fromArray($mma)
      or $up->logconfess("failed to convert multimap data for attirbute '$attr'");
    $tmm->save("$dbdir/${attr}_2t")
      or $up->logconfess("failed to save multimap data for attrbute '$attr' to $dbdir/${attr}_2t.*: $!");

    ##-- adopt pack template
    $hdr->{"pack_t${attr}"} = $hdr->{"pack_x${attr}"};
    delete $hdr->{"pack_x${attr}"};
  }

  ##-- convert relations: unigrams
  {
    my $xf = DiaColloDB::Relation::Unigrams->new(base=>"$dbdir/xf", logCompat=>'off')
      or $up->logconfess("failed to open unigram index '$dbdir/xf.dba': $!");
    $up->info("upgrading unigram index $dbdir/xf.*");
    $up->warn("unigram data in $dbdir/xf.* doesn't seem to be v0.09 format; trying to upgrade anyways")
      if (!$xf->isa('DiaColloDB::Compat::v0_09::Relation::Unigrams'));

    env_push('LC_ALL'=>'C');
    my $tmpfile = "$dbdir/upgrade_xf.tmp";
    my $sortfh = opencmd("| sort -nk2 -nk3 -o \"$tmpfile\"")
      or $up->logconfess("open failed for pipe to sort for '$tmpfile': $!");
    binmode($sortfh,':raw');
    $xf->saveTextFh_v0_10($sortfh, i2s=>sub { join("\t", vec($xi2t,$_[0],$nbits_t), vec($xi2d,$_[0],$nbits_d)) })
      or $up->logconfess("failed to create temporary file '$tmpfile'");
    $sortfh->close()
      or $up->logconfess("failed to close pipe to sort for '$tmpfile': $!");
    env_pop();
    $xf->unlink()
      or $up->logconfess("failed to unlink old $dbdir/xf.*: $!");

    my $tf = DiaColloDB::Relation::Unigrams->new(base=>"$dbdir/xf", flags=>'rw', version=>$up->toversion,
						 pack_i=>$hdr->{pack_id}, pack_f=>$hdr->{pack_f}, pack_d=>$hdr->{pack_date});
    $tf->loadTextFile($tmpfile)
      or $up->logconfess("failed to load unigram data from '$tmpfile': $!");
  }

  ##-- convert relations: cofreqs
  {
    my $cof = DiaColloDB::Relation::Cofreqs->new(base=>"$dbdir/cof", logCompat=>'off')
      or $up->logconfess("failed to open co-frequency index $dbdir/cof.*: $!");
    my %cofopts = (map {($_=>$cof->{$_})} qw(pack_i pack_f fmin dmax));
    $up->info("upgrading co-frequency index $dbdir/cof.*");
    $up->warn("co-frequency data in $dbdir/cof.* doesn't seem to be v0.09 format; trying to upgrade anyways")
      if (!$cof->isa('DiaColloDB::Compat::v0_09::Relation::Cofreqs'));

    env_push('LC_ALL'=>'C');
    my $tmpfile = "$dbdir/upgrade_cof.tmp";
    my $sortfh = opencmd("| sort -nk2 -nk3 -nk4 -o \"$tmpfile\"")
      or $up->logconfess("open failed for pipe to sort for '$tmpfile': $!");
    binmode($sortfh,':raw');
    $cof->saveTextFh($sortfh,
		     i2s1=>sub { join("\t", vec($xi2t,$_[0],$nbits_t), vec($xi2d,$_[0],$nbits_d)) },
		     i2s2=>sub { vec($xi2t,$_[0],$nbits_t) })
      or $up->logconfess("failed to create temporary file '$tmpfile'");
    $sortfh->close()
      or $up->logconfess("failed to close pipe to sort for '$tmpfile': $!");
    env_pop();
    $cof->unlink()
      or $up->logconfess("failed to unlink old $dbdir/cof.*: $!");

    my $tcof = DiaColloDB::Relation::Cofreqs->new(base=>"$dbdir/cof", flags=>'rw', version=>$up->toversion,
						  pack_d=>$hdr->{pack_date}, %cofopts);
    $tcof->loadTextFile($tmpfile)
      or $up->logconfess("failed to load co-frequency data from '$tmpfile': $!");
  }

  ##-- cleanup
  if (!$up->{keep}) {
    $up->info("removing temporary file(s)");
    CORE::unlink("$dbdir/upgrade_xf.tmp")
	or $up->logconfess("failed to remove temporary file $dbdir/upgrade_xf.tmp: $!");
    CORE::unlink("$dbdir/upgrade_cof.tmp")
	or $up->logconfess("failed to remove temporary file $dbdir/upgrade_cof.tmp: $!");
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

  ##-- backup: xenum
  $up->info("backing up $dbdir/xenum.*");
  copyto_a([glob "$dbdir/xenum.*"], $backd)
      or $up->logconfess("backup failed for $dbdir/xenum.*: $!");

  ##-- backup: by attribute: multimaps
  foreach my $base (map {"$dbdir/${_}_2x"} @{$hdr->{attrs}}) {
    $up->info("backing up $base.*");
    copyto_a([glob "$base.*"], $backd)
      or $up->logconfess("backup failed for $base.*: $!");
  }

  ##-- backup: relations
  foreach my $base (map {"$dbdir/$_"} qw(xf cof)) {
    $up->info("backing up $base.*");
    copyto_a([glob "$base.*"], $backd)
      or $up->logconfess("backup failed for $base.*: $!");
  }

  return 1;
}

## @files = $up->revert_created()
##  + returns list of files created by this upgrade, for use with default revert() implementation
sub revert_created {
  my $up  = shift;
  my $hdr = $up->dbheader;

  return (
	  ##-- multimaps
	  (map {
	    my $base="${_}_2t";
	    map {"$base.$_"} qw(hdr ma mb)
	  } @{$hdr->{attrs}}),

	  ##-- tenum
	  (map {"tenum.$_"} qw(hdr fix fsx)),

	  ##-- unigrams
	  (map {"xf.$_"} qw(dba1 dba1.hdr dba2 dba2.hdr hdr)),

	  ##-- cofreqs
	  (map {"cof.$_"} qw(dba3 dba3.hdr)),

	  ##-- header
	  'header.json',
	 );
}

## @files = $up->revert_updated()
##  + returns list of files updated by this upgrade, for use with default revert() implementation
sub revert_updated {
  my $up  = shift;
  my $hdr = $up->dbheader;

  return (
	  ##-- multimaps
	  (map {
	    my $base="${_}_2x";
	    map {"$base.$_"} qw(hdr ma mb)
	  } @{$hdr->{attrs}}),

	  ##-- xenum
	  (map {"xenum.$_"} qw(hdr fix fsx)),

	  ##-- unigrams
	  (map {"xf.$_"} qw(dba dba.hdr)),

	  ##-- cofreqs
	  (map {"cof.$_"} qw(dba1 dba1.hdr dba2 dba2.hdr hdr)),

	  ##-- header
	  'header.json',
	 );
}


##==============================================================================
## Footer
1; ##-- be happy
