# -*- Mode: Perl -*-

# Submited by Lupe Christoph <lupe@lupe-christoph.de> for Solaris 2.6

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use Filesys::DiskSpace;

local $^W = 1;

my $t = 1;

unless ($^O eq 'solaris') {
  print "1..0\n";
  exit;
}

my $bindf  = '/usr/sbin/df';
my $mnttab = '/etc/mnttab';

my ($data, $dirs);
open (MOUNT, $mnttab) || die "Error: $!\n";
while (defined (my $d = <MOUNT>)) {
  my @tab = split /\s+/, $d;
  push @$dirs, $tab[1] if $tab[2] eq 'ufs';
}
close MOUNT;
open (DF, "$bindf -k @$dirs |") || die "Error: $!\n";
while (defined (my $d = <DF>)) {
  my @tab = split /\s+/, $d;
  next if $tab[0] eq 'Filesystem';
  $$data{$tab[5]}{'used'}  = $tab[2];
  $$data{$tab[5]}{'avail'} = $tab[3];
}
close DF;
open (DF, "$bindf -o i @$dirs |") || die "Error: $!\n";
while (defined (my $d = <DF>)) {
  my @tab = split /\s+/, $d;
  next if $tab[0] eq 'Filesystem';
  $$data{$tab[4]}{'iused'}  = $tab[1];
  $$data{$tab[4]}{'iavail'} = $tab[2];
}
close DF;

print "1..", scalar keys %$data, "\n";

for my $part (keys %$data) {
  my ($fs_type, $fs_desc, $used, $avail, $iused, $iavail) = df $part;
  my $res = $fs_desc eq '4.2' &&
    $$data{$part}{'used'} == $used &&
    $$data{$part}{'avail'} == $avail &&
    $$data{$part}{'iused'} == $iused &&
    $$data{$part}{'iavail'} == $iavail;
  unless ($res) {
    print "Value: system_df perl_df\n\n";
    print "Used: $$data{$part}{'used'} <> $used\n"
      unless $$data{$part}{'used'} == $used;
    print "Avail: $$data{$part}{'avail'} <> $avail\n"
      unless $$data{$part}{'avail'} == $avail;
    print "Iused: $$data{$part}{'iused'} <> $iused\n"
      unless $$data{$part}{'iused'} == $iused;
    print "Iavail: $$data{$part}{'iavail'} <> $iavail\n"
      unless $$data{$part}{'iavail'} == $iavail;
  }
  print $res ? "" : "not ", "ok ", $t++, "\n";
}
