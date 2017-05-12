#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin";
use FileSystem::LL::FAT qw( MBR_2_partitions debug_partitions
			    emit_fat32 interpret_directory
			    check_bootsector interpret_bootsector
			    check_FAT_array FAT_2array cluster_chain
			    read_FAT_data write_dir list_dir compress_FAT
			    uncompress_FAT
			 );

my($use_fat, $offset, $depth, $have_mbr, $e_offset) = (0, 0, 0, 'maybe', 0);
my($emit_fat32, $rootdir_outdir, $dump_bootsector, $partit, $list, $FAT_out,
   $c_fat, $u_fat, $r_bs, $r_FAT, $r_rootdir, $bs_out, $ignore_FAT,
   $emit_cl_chain, $assume_FAT_flavor, $help);

eval {
  require Getopt::Long;
  Getopt::Long::GetOptions(
    'nFAT=i' => \$use_fat,
    'offset=i' => \$offset,
    'extra-offset=i' => \$e_offset,
    'partition=i' => \$partit,
    'extract-rootdir=s' => \$rootdir_outdir,
    'try-MBR!' => \$have_mbr,
    'output-FAT=s' => \$FAT_out,
    'output-bs=s' => \$bs_out,
    'compress-FAT!' => \$c_fat,
    'uncompress-FAT=i' => \$u_fat,
    'list!' => \$list,
    'depth=i' => \$depth,
#    'emit_fat32=s' => \$emit_fat32,
    'dump-bs!' => \$dump_bootsector,
    'read-bs=s' => \$r_bs,
    'help!' => \$help,
    'read-FAT=s' => \$r_FAT,
    'ignore-FAT!' => \$ignore_FAT,
    'read-rootdir=s' => \$r_rootdir,
    'emit-cl-chain=s' => \$emit_cl_chain,
    'assume-FAT-flavor=i' => \$assume_FAT_flavor,
  ) or $help = 1;
} or $list=1, warn "getopt failed: $@, assume -list";

(@ARGV == 0 and !$help) or die <<EOD;
usage: $0 [-nFAT=N -offset=BYTES -extract-rootdir=ROOTDIR -rootdir
	   -dump-bs -notry-MBR -read-bs=FILE -read-FAT=FILE -read-rootdir=FILE
	   -extra-offset=N -ignore-FAT -partition=PART_NUM
	   -output-bs=FILE
	   -output-FAT=FILE -compress-FAT -assume-FAT-flavor=12|16|32
	   -emit-cl-chain=START,LEN[cl] ]       [ < \\.\f: ]

usage: $0 -uncompress-FAT=12|16|32  < compressed_fat_file > fat_file

	defaults: offset=0 depth=0 nFAT=0 try-mbr=1 extra-offset=0

Reads raw filesystem data from STDIN; can optionally read bootsector,
FAT table, and raw directory data from separate files.  Of course,
file extraction and recursive directory listing still requires access
to the raw filesystem data, but one can still use bootsector, FAT
table, and/or start directory data in separate files.  (This -
together with efficent compressing scheme - allows frequent backups of
fragile data, and use of it later.)

Can ignore FAT tables completely (would assume that files are
continuous, and directories take at most one cluster).  Can emit
bootsector, FAT table (compressed or uncompressed), list files,
extract files and chains of clusters.  E.g., on DOSISH systems

  $0 -ignore-FAT -read-rootdir=s_dir -depth=2 -list  <\\.\f:
  $0 -ignore-FAT -read-rootdir=s_dir          -list -read-bs=f.bootsector
  $0 -ignore-FAT -read-rootdir=s_dir          -list -assume-FAT-flavor=32

(useful when a directory is converted to a file by chkdsk, so FAT is
ruined; if one has a backup of FAT, usually it should be more reliable
to use the old version of FAT instead of ignoring FAT).

(Non-recursive listing is the only operation where the only
information used about the disk is the "flavor" of FAT, which is
12/16/32 for FAT12/FAT16/FAT32.  So this is the only operation which
may be done with access to ONLY the file image of the starting
directory, as far as -assume-FAT-flavor option is given.)

EOD

sub read_file ($) {
  my $f = shift;
  local $/;
  open IN, '<', $f or die "Can't open $f for read";
  binmode IN;
  my $c = <IN>;
  close IN or die "Can't close $f for read";
  $c
}

sub syswrite_file ($$) {
  my $f = shift;
  local $/;
  open O, '>', $f or die "Can't open $f for write";
  binmode O;
  syswrite O, $_[0], length $_[0];
  close O or die "Can't close $f for write";
}

if ($u_fat) {
  my %ok = qw(12 1 16 1 32 1);
  die "Unrecognized width of output FAT: $u_fat" unless $ok{$u_fat};
  binmode STDIN;
  binmode STDOUT;
  uncompress_FAT(\*STDIN, $u_fat, \*STDOUT);
  exit 0;
}

my $need_bootsector = 1 if
  not $assume_FAT_flavor or not defined $list or $rootdir_outdir or $FAT_out
  or $bs_out or ($list and $depth) or $dump_bootsector or $emit_cl_chain;

my %how = qw(parse_FAT 0);
$how{do_bootsector} = $need_bootsector unless $r_bs;
my %extra = qw(parse_bootsector 1 keep_labels 1);
$how{do_MBR} = $have_mbr if $have_mbr;
($ignore_FAT or $how{do_FAT} = $use_fat),
  $extra{parse_rootdir} = $how{do_rootdir} = 1
  if defined $rootdir_outdir or $list or defined $FAT_out;
$extra{raw_FAT} = 1 if defined $FAT_out and not $c_fat;
$extra{partition} = $partit if defined $partit;
%how = (%how, %extra);

my $bs_offset = $offset;

my %how_bootsector = (do_bootsector => 1, do_MBR => $how{do_MBR}, %extra);
$how_bootsector{do_FAT} = $how{do_FAT} unless $r_FAT;
$how_bootsector{do_rootdir} = $how{do_rootdir} unless $r_rootdir;

goto skip_bs unless $need_bootsector;

(-t STDIN and die "To get bootsector, I need STDIN open to \"raw disk\" file"),
  $r_bs = \*STDIN, binmode STDIN unless defined $r_bs;
my $out = read_FAT_data $r_bs, \%how_bootsector, $offset;
my $b = $out->{bootsector};

skip_bs:

if (defined $r_FAT and defined $how{do_FAT}) {
  my $o = read_FAT_data $r_FAT,
    {do_FAT => $how{do_FAT}, parse_FAT => $how{parse_FAT}, %extra}, 0, $b; # offset = 0
  %$out = (%$out, %$o);
}

my $used_FAT = $out->{FAT} unless $ignore_FAT;

if (defined $r_rootdir) {
  my $bb = $b || {guessed_FAT_flavor => $assume_FAT_flavor};
  $bb->{guessed_FAT_flavor}
    or die "Need -assume-FAT-flavor option in absense of bootsector";
  my $o = read_FAT_data $r_rootdir, {do_rootdir => 1, rootdir_is_standalone => 1, %extra}, 0, $bb, $used_FAT; # $offset = 0
  %$out = (%{$out || {}}, %$o);
}

if ($dump_bootsector and $b) {
  print "$_\t=> $b->{$_}\n" for sort keys %$b;
}

if (defined $rootdir_outdir or ($list and $depth)) {
  die "Need bootsector" unless $b;
  die "For extraction and recursive listing, I need STDIN open to \"raw disk\" file" if -t STDIN;
  binmode STDIN;
}
write_dir \*STDIN, $rootdir_outdir, \ $out->{rootdir_raw},
  $b, $used_FAT, 0, $depth, $offset + $e_offset, 1
  if defined $rootdir_outdir;
if ($list) {
  eval "binmode STDOUT, ':utf8'";
  my $bb = $b || {guessed_FAT_flavor => $assume_FAT_flavor};
  $bb->{guessed_FAT_flavor}
    or die "Need -assume-FAT-flavor option in absense of bootsector";
  list_dir \*STDIN, \ $out->{rootdir_raw}, $bb, $used_FAT,
    {qw(keep_del 1 keep_dots 1 keep_labels 1)}, $depth, $offset + $e_offset;
}

if (defined $FAT_out) {
  open oFAT, '>', $FAT_out or die "Can't open `$FAT_out' for write";
  binmode oFAT;
  if ($c_fat) {
    compress_FAT($out->{FAT}, $b->{guessed_FAT_flavor}, \*oFAT);
  } else {
    syswrite oFAT, ${ $out->{FAT_raw} }, length ${ $out->{FAT_raw} };
  }
  close oFAT or die "Can't open `$FAT_out' for write";
}

syswrite_file $bs_out, $b->{raw} if defined $bs_out;

if ($emit_cl_chain) {
  my($start, $l) = split /,/, $emit_cl_chain, 2;
  die "To raw read, I need STDIN open to \"raw disk\" file" if -t STDIN;
  ($b or die "Need bootsector") and
    $l = $1 * $b->{sector_size} * $b->{sectors_in_cluster}
      if $l =~ /^(\d+)cl$/;
  binmode STDOUT;
  FileSystem::LL::FAT::output_cluster_chain(\*STDIN, \*STDOUT, $start, $l, $b, $used_FAT, $offset + $e_offset);
}
