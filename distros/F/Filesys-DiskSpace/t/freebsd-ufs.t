# -*- Mode: Perl -*-

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use Filesys::DiskSpace;

local $^W = 1;

my $t = 1;

unless ($^O eq 'freebsd') {
  print "1..0\n";
  exit;
}

my $bindf  = '/bin/df';
my $mnttab = '/etc/fstab';

my ($data, $dirs);
open (MOUNT, $mnttab) || die "Error: $!\n";
while (defined (my $d = <MOUNT>)) {
  my @tab = split /\s+/, $d;
  push @$dirs, $tab[1] if $tab[2] eq 'ufs';
}
close MOUNT;
open (DF, "$bindf -i @$dirs |") || die "Error: $!\n";
while (defined (my $d = <DF>)) {
  my @tab = split /\s+/, $d;
  next if $tab[0] eq 'Filesystem';
  $$data{$tab[8]}{'used'}  = $tab[2];
  $$data{$tab[8]}{'avail'} = $tab[3];
  $$data{$tab[8]}{'iused'}  = $tab[5];
  $$data{$tab[8]}{'ifree'} = $tab[6];
}
close DF;

print "1..", scalar keys %$data, "\n";

for my $part (keys %$data) {
  my ($fs_type, $fs_desc, $used, $avail, $iused, $ifree) = df $part;
  my $res = $fs_desc eq '4.2' &&
    $$data{$part}{'used'} == $used &&
      $$data{$part}{'avail'} == $avail &&
	$$data{$part}{'iused'} == $iused &&
	  $$data{$part}{'ifree'} == $ifree;
  unless ($res) {
    print "Value: system_df perl_df\n\n";
    printf STDERR "Value: system_df perl_df\n\n";
    print "Used: $$data{$part}{'used'} <> $used\n"
      unless $$data{$part}{'used'} == $used;
    printf STDERR "Used: $$data{$part}{'used'} <> $used\n"
      unless $$data{$part}{'used'} == $used;
    print "Avail: $$data{$part}{'avail'} <> $avail\n"
      unless $$data{$part}{'avail'} == $avail;
    printf STDERR "Avail: $$data{$part}{'avail'} <> $avail\n"
      unless $$data{$part}{'avail'} == $avail;
    print "Iused: $$data{$part}{'iused'} <> $iused\n"
      unless $$data{$part}{'iused'} == $iused;
    printf STDERR "Iused: $$data{$part}{'iused'} <> $iused\n"
      unless $$data{$part}{'iused'} == $iused;
    print "Iavail: $$data{$part}{'ifree'} <> $ifree\n"
      unless $$data{$part}{'ifree'} == $ifree;
    printf STDERR "Iavail: $$data{$part}{'ifree'} <> $ifree\n"
      unless $$data{$part}{'ifree'} == $ifree;
  }
  print $res ? "" : "not ", "ok ", $t++, "\n";
}
