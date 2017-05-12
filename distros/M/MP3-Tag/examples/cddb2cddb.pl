#!/usr/bin/perl -w
use strict;

my %opt;
use Getopt::Std 'getopts';
getopts('r:', \%opt);			# n-th record to chose

#use lib 'J:\test-programs-other\.cpan\tagged-CVS\CDDB-1.11';

$_ = <>;
/^\s*#\s*xmcd\s*$/ or die "Unexpected format: `$_'";
$_ = <>;
$_ = <> while /^\s*#\s*$/;
/^\s*#\s*Track frame offsets:\s*$/ or die "Unexpected format: `$_'";
$_ = <>;
$_ = <> while /^\s*#\s*$/;
my @offsets;
(push @offsets, $1), $_ = <> while defined and /^\s*#\s*(\d+)\s*$/;
$_ = <> while /^\s*#\s*$/;
/^\s*#\s*Disc length: (\d+)(\s.*)?$/ or die "Unexpected format: `$_'";
my $len = $1;
$_ = <>;
$_ = <> while /^\s*#\s*(|(Revision|Submitted via|Processed by|Normalized):\s.*)$/;
/^\s*DISCID\s*=\s*([\da-f]+)\s*$/i or die "Unexpected format: `$_'";
my $id = $1;

use CDDB;

my $d = new CDDB or die;

warn "submitting $id, len=$len, offsets @offsets\n";
my @disks = $d->get_discs($id, \@offsets, $len) or die "No disks found!\n";
for my $disk (@disks) {
    warn "@$disk\n";
}
my $rec = $opt{r} || 1;
if (@disks == 1 or defined $opt{r}) {
  my ($disc_genre, $disc_id, $disc_title) = @{$disks[$rec - 1]};
  my $info = $d->get_disc_details($disc_genre, $disc_id);
  print $info->{xmcd_record};
}
