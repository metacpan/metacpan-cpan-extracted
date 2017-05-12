## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Upgrade::v0_09_multimap.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: auto-magic upgrade: v0.08.x -> v0.09.x: MultiMapFile format

package DiaColloDB::Upgrade::v0_09_multimap;
use DiaColloDB::Upgrade::Base;
use DiaColloDB::Compat::v0_08;
use strict;
our @ISA = qw(DiaColloDB::Upgrade::Base);

##==============================================================================
## API
## + Upgrade: v0_09_multimap: v0.08.x -> v0.09.x : MultiMapFile format change

## $version = $up->toversion()
##  + returns default target version; default just returns $DiaColloDB::VERSION
sub toversion {
  return '0.09.000';
}

## $bool = $up->upgrade()
##  + performs upgrade
sub upgrade {
  my $up = shift;

  ##-- backup
  $up->backup() or $up->logconfess("backup failed");

  ##-- open header
  my $dbdir = $up->{dbdir};
  my $hdr   = $up->dbheader;

  ##-- convert by attribute
  foreach my $attr (@{$hdr->{attrs}}) {
    my $base = "$dbdir/${attr}_2x";
    my $mmf  = $DiaColloDB::MMCLASS->new(base=>$base, logCompat=>'off')
      or $up->logconfess("failed to open attribute multimap $base.*");

    ##-- sanity check(s)
    $up->info("upgrading $base.*");
    $up->warn("multimap data in $base.* doesn't seem to be v0.08 format; trying to upgrade anyways")
      if (!$mmf->isa('DiaColloDB::Compat::v0_08::MultiMapFile'));

    ##-- convert
    my $tmp = $DiaColloDB::MMCLASS->new(flags=>'rw', pack_i=>$mmf->{pack_i})
      or $up->logconfess("upgrade(): failed to create new DiaColloDB::MultiMapFile object for $base.*");
    $tmp->fromArray($mmf->toArray)
      or $up->logconfess("upgrade(): failed to convert data for $base.*");
    $mmf->close();
    $tmp->save($base)
      or $up->logconfess("upgrade(): failed to save new data for $base.*");
  }

  ##-- update header
  return $up->updateHeader();
}

##==============================================================================
## Backup & Revert

## $bool = $up->backup()
##  + perform backup any files we expect to change to $up->backupdir()
##  + call this from $up->upgrade()
sub backup {
  my $up = shift;
  $up->SUPER::backup() or return undef;
  return 1 if (!$up->{backup});

  my $dbdir = $up->{dbdir};
  my $hdr   = $up->dbheader;
  my $backd = $up->backupdir;

  ##-- backup: by attribute
  foreach my $base (map {"$dbdir/${_}_2x"} @{$hdr->{attrs}}) {
    $up->info("backing up $base.*");
    DiaColloDB::Utils::copyto_a([glob "$base.*"], $backd)
      or $up->logconfess("backup failed for $base.*: $!");
  }
  return 1;
}

## @files = $up->revert_created()
##  + returns list of files created by this upgrade, for use with default rollback() implementation
sub revert_created {
  return qw();
}

## @files = $up->revert_updated()
##  + returns list of files updated by this upgrade, for use with default rollback() implementation
sub revert_updated {
  my $up = shift;
  my $hdr = $up->dbheader;

  my @mmfiles = map {
    my $base="${_}_2x";
    map {"$base.$_"} qw(hdr ma mb)
  } @{$hdr->{attrs}};

  return (@mmfiles, 'header.json');
}


##==============================================================================
## Footer
1; ##-- be happy
