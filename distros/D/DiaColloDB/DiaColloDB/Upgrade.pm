## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Upgrade.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: auto-magic upgrades: top level

package DiaColloDB::Upgrade;
use DiaColloDB;
use DiaColloDB::Upgrade::Base;
use DiaColloDB::Upgrade::v0_04_dlimits;
use DiaColloDB::Upgrade::v0_09_multimap;
use DiaColloDB::Upgrade::v0_10_x2t;
use DiaColloDB::Upgrade::v0_12_sliceN;
use Carp;
use strict;

##==============================================================================
## Globals

our @ISA = qw(DiaColloDB::Logger);

## @upgrades : list of available auto-magic upgrade sub-packages (suffixes)
our @upgrades = (
		 'v0_04_dlimits',
		 'v0_09_multimap',
		 'v0_10_x2t',
		 'v0_12_sliceN',
		);

##==============================================================================
## Top-level

## @upgrade_pkgs = $CLASS_OR_OBJECT->available()
##  + returns list of available upgrade-packages (suffixes)
sub available {
  return @upgrades;
}

## @needed = $CLASS_OR_OBJECT->needed($dbdir, \%opts?, @upgrade_pkgs)
##  + returns list of those package-names in @upgrade_pkgs which are needed for DB in $dbdir
##  + %opts are passed to upgrade-package new() methods
sub needed {
  my $that  = shift;
  my $dbdir = shift;
  my $opts  = UNIVERSAL::isa($_[0],'HASH') ? shift : {};
  return grep {
    my $pkg = $_;
    $pkg = "DiaColloDB::Upgrade::$pkg" if (!UNIVERSAL::can($pkg,'needed'));
    $that->warn("unknown upgrade package $_") if (!UNIVERSAL::can($pkg,'needed'));
    $that->uobj($pkg,$dbdir,$opts)->needed();
  } @_;
}

## @upgrades = $CLASS_OR_OBJECT->which($dbdir, \%opts?)
##  + returns a list of upgrades applied to $dbdir
##  + list is created by parsing "upgraded" field from "$dbdir/header.json"
##  + if the upgrade-item "by" keyword inherits from DiaColloDB::Upgrade::Base,
##    a new object will be created and returned in @upgrades; otherwise the
##    parsed HASH-ref is returned as-is
sub which {
  my ($that,$dbdir,$opts) = @_;
  $opts //= {};
  my $hdr = DiaColloDB::Upgrade::Base->dbheader($dbdir);
  my @ups = qw();
  foreach (@{$hdr->{upgraded}//[]}) {
    my $class = $_->{class} // $_->{by};
    $class    = "DiaColloDB::Upgrade::$class" if (!UNIVERSAL::isa($class,'DiaColloDB::Upgrade::Base'));
    push(@ups, $that->uobj($class, $dbdir, { %$opts, %$_ }));
  }
  return @ups;
}

## $bool = $CLASS_OR_OBJECT->upgrade($dbdir, \%opts?, \@upgrades_or_pkgs)
##  + applies upgrades in @upgrades to DB in $dbdir
##  + %opts are passed to upgrade-package new() methods
sub upgrade {
  my $that  = shift;
  my $dbdir = shift;
  my $opts  = UNIVERSAL::isa($_[0],'HASH') ? shift : {};
  foreach (@_) {
    my $pkg = $_;
    $pkg = "DiaColloDB::Upgrade::$pkg" if (!UNIVERSAL::can($pkg,'upgrade'));
    $that->logconfess("unknown upgrade package $_") if (!UNIVERSAL::can($pkg,'upgrade'));
    $that->info("applying upgrade package $_ to $dbdir/");
    $that->uobj($pkg,$dbdir,$opts)->upgrade()
      or $that->logconfess("upgrade via package $pkg failed for $dbdir/");
  }
  return $that;
}

##==============================================================================
## Utils

## $up = $CLASS_OR_OBJECT->uobj($pkg,$dbdir,\%opts)
##  + create or instantiate an upgrade-object $up as an instance of $pkg for $dbdir with options %opts
sub uobj {
  my $that = shift;
  my ($pkg,$dbdir,$opts) = @_;
  my ($up);
  if (ref($pkg)) {
    $up = $pkg;
    @$up{keys %$opts} = values %$opts if ($opts);
    $up->{dbdir} = $dbdir;
  } elsif (UNIVERSAL::can($pkg,'new')) {
    $up = $pkg->new(%{$opts//{}}, dbdir=>$dbdir);
  } else {
    $up = { %{$opts//{}}, dbdir=>$dbdir };
  }
  return $up;
}

##==============================================================================
## Footer
1; ##-- be happy
