## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Upgrade::v0_04_dlimits.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: auto-magic upgrade: v0.04: date-limits @$coldb{qw(xdmin xdmax)}

package DiaColloDB::Upgrade::v0_04_dlimits;
use DiaColloDB::Upgrade::Base;
use DiaColloDB::Utils qw(:pack);
use strict;
our @ISA = qw(DiaColloDB::Upgrade::Base);

##==============================================================================
## API

## $version = $up->toversion()
##  + returns default target version; default just returns $DiaColloDB::VERSION
sub toversion {
  return '0.04.000';
}

## $bool = $up->needed()
##  + returns true iff local index in $dbdir needs upgrade
sub needed {
  my $up = shift;
  return !defined($up->{hdr}{xdmin}) || !defined($up->{hdr}{xdmax});
}

## $bool = $up->upgrade()
##  + performs upgrade
sub upgrade {
  my $up = shift;

  ##-- backup
  $up->backup() or return undef;

  ##-- xdmin, xdmax: from xenum
  my $dbdir = $up->{dbdir};
  my $hdr   = $up->dbheader;
  my $xenum = $DiaColloDB::XECLASS->new(base=>"$dbdir/xenum")
    or $up->logconfess("failed to open (tuple+date) enum $dbdir/xenum.*: $!");
  my $pack_xdate  = '@'.(packsize($hdr->{pack_id}) * scalar(@{$hdr->{attrs}})).$hdr->{pack_date};
  my ($dmin,$dmax) = (undef,undef);
  my ($d);
  foreach (@{$xenum->toArray}) {
    next if (!$_ || !($d=unpack($pack_xdate,$_))); ##-- ignore null keys and dates
    $dmin = $d if (!defined($dmin) || $d < $dmin);
    $dmax = $d if (!defined($dmax) || $d > $dmax);
  }
  $dmin //= 0;
  $dmax //= 0;
  $up->vlog('info', "extracted date-range \"xdmin\":$dmin, \"xdmax\":$dmax");

  ##-- update header
  @$hdr{qw(xdmin xdmax)} = ($dmin,$dmax);
  return $up->updateHeader();
}

##==============================================================================
## Backups & Rollback

## @files = $up->revert_created()
##  + returns list of files created by this upgrade, for use with default rollback() implementation
sub revert_created {
  return qw();
}

## @files = $up->revert_updated()
##  + returns list of files updated by this upgrade, for use with default rollback() implementation
sub revert_updated {
  return qw(header.json);
}


##==============================================================================
## Footer
1; ##-- be happy
