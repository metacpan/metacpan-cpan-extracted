package FileSystem::LL::FAT;

#use 5.008008;
#use warnings;

require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use FileSystem::LL::FAT ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	MBR_2_partitions debug_partitions emit_fat32 interpret_directory
	check_bootsector interpret_bootsector
	check_FAT_array FAT_2array cluster_chain read_FAT_data
	write_file write_dir list_dir compress_FAT uncompress_FAT
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = '0.05';
use strict;

my $lim_read = $ENV{FAT_READ_NEEDS_1SECTOR};
$lim_read = ($^O eq 'os2') unless defined $lim_read; #Bug in OS/2 FAT32 driver?
$lim_read = $lim_read ? 512 : (1<<24);

# Preloaded methods go here.
sub decode_fields ($$) {
  my ($fields2, $in) = (shift,shift);
  my $lastfield = @$fields2/2 - 1;
  my $extract = join ' ', @$fields2[map 2*$_ + 1, 0 .. $lastfield];
  my @values = unpack $extract, $in;
  map( ($$fields2[2*$_] => $values[$_]),  0 .. $lastfield);
}



sub MBR_2_partitions ($) {
  my $bootsect = shift;
  return # die "Expect to have \\x55\\xAA in MBR"
    unless length($bootsect) == 512 and "\x55\xAA" eq substr $bootsect, -2;
  # Up to offset 1BEh the MBR consists purely of machine code and data (strings
  # etc.). At offset 1BEh the first primary partition is defined, this takes 16
  # bytes, after which the second primary partition is defined, followed by
  # the third and fourth, the data structures are the same.

  my ($code, @parts) = unpack 'a446 a16 a16 a16 a16 v', $bootsect;
  my $check = pop @parts;

  # 00h 1 Set to 80h if this partition is active.
  # 01h 1 Partition's starting head.
  # 02h 2 Partition's starting [48]sector and track.
  # 04h 1 Partition's [49]ID number.
  # 05h 1 Partition's ending head.
  # 06h 2 Partition's ending [50]sector and track.
  # 08h 4 Starting LBA.
  # 0Ch 4 Partition's length in sectors.

  # Format of sector and track information.Bits 15-6 Bits 5-0
  #                                          Track    Sector
  # ID numbers:
  # 0Bh Win95 OSR2+ FAT32 (512MB-2TB)			(primary?)
  # 0Ch Win95 OSR2+ FAT32 (512MB-2TB LBA)			(extended?)
  my @part = (	# code	=> 'A446',
	      is_active		 => 'C',
	      start_head	 => 'C',
	      start_sec_track	 => 'v',
	      type		 => 'C',
	      end_head		 => 'C',
	      end_sec_track	 => 'v',
	      start_lba		 => 'V',
	      sectors		 => 'V',
	     );

  my @part_value = map { {raw => $_, decode_fields \@part, $_} } @parts;
  for my $p (@part_value) {
    $p->{start_sec}   = $p->{start_sec_track} & 0x3f;
    $p->{start_track} = $p->{start_sec_track} >> 6;
    $p->{end_sec}     = $p->{end_sec_track} & 0x3f;
    $p->{end_track}   = $p->{end_sec_track} >> 6;
  }
  ({bootcode => $code, signature => $check}, @part_value);
}

sub debug_partitions ($@) {
  my($fh, @partitions) = @_;
  my $n;
  for my $p (@partitions) {
    $n++;
    print $fh "  Part $n\n";
    print $fh "$_\t=> $p->{$_}\n" for sort keys %$p;
  }
}

# Experimental convertor from empty fat to empty fat32...
sub emit_fat32 ($$$$) {		# Also, essentially, seeks to bootsector
  my($p, $b, $emit_prefat32, $reader) = (shift, shift, shift, shift);

  my $offset_in_sectors = $p->{start_lba};
  die "The partition type is not defined" unless $p->{type};
  die "start_lba value is 0" unless $offset_in_sectors;

  substr($b, 446 + 4, 1) = chr 0x0B; # Win95 OSR2+ FAT32 (512MB-2TB) (primary?)
  die "Need emit_prefat32 defined too in presence of partition table"
    unless defined $emit_prefat32;
  open F32, "> $emit_prefat32" or die "Error opening `$emit_prefat32' for write: $!";
  binmode F32;
  syswrite F32, $b;
  if ($offset_in_sectors > 1) {
    my $in = $reader->(512*($offset_in_sectors - 1));
    syswrite F32, $in;
  }
  close F32 or die "Error closing `$emit_prefat32' for write: $!";
}

# Directory Entry Layout.
#
#    The old style directory entry had 10 reserved bytes starting at 0Ch,
#                            these are now used.
# 00h 8 Filename padded with spaces if required (see above).
# 08h 3 Filename extension padded with spaces if required.
# 0Bh 1 File Attribute Byte.
# 0Ch 10 Reserved or extra data.
# 16h 2 Time of last write to file (last modified or when created).
# 18h 2 Date of last write to file (last modified or when created).
# 1Ah 2 Starting cluster.
# 1Ch 4 File size (set to zero if a directory).
#
#
# Extra data Layout (previously reserved area).
#
#    The old style directory entry had 10 reserved bytes starting at 0Ch,
#     these are now used as follows. Presumably these fields are used if
#                                 non-zero.
#                            Offset Length Field
# 0Ch 1 Reserved for use by Windows NT.
# 0Dh 1 Tenths of a second at time of file creation, 0-199 is valid.
# 0Eh 2 Time when file was created.
# 10h 2 Date when file was created.
# 12h 2 Date when file was last accessed.
# 14h 2 High word of cluster number (always 0 for FAT12 and FAT16).

my @file_f = (	basename	=> 'A8',
		ext	=> 'A3',
		attrib	=> 'C',
		name_ext_case	=> 'C',
		creation_01sec	=> 'C',
		time_creation	=> 'v',
		date_create	=> 'v',
		date_access	=> 'v',
		cluster_high	=> 'v',
		time_write	=> 'v',
		date_write	=> 'v',
		cluster_low	=> 'v',
		size	=> 'V',
  );

my @lfn_f = (	seq_number	=> 'C',
		name_chars_1	=> 'a10',
		attrib	=> 'C',
		nt_reserved	=> 'C',
		checksum_dosname => 'C',
		name_chars_2	=> 'a12',
		cluster_low	=> 'v',
		name_chars_3	=> 'a4',
  );

my $nn = 0;
my %file_attrib = map +($_ => 1<<($nn++)),
  qw(is_readonly is_hidden is_system is_volume_label
     is_subdir is_archive is_device);

sub dos_chksum ($$) {
  my ($n,$ext,$sum) = (shift, shift, 0);
  $sum = ((($sum & 1)<<7) + ($sum >> 1) + ord $_) & 0xFF
    for split //, sprintf "%-8s%-3s", $n, $ext;
  $sum
}

sub interpret_directory ($$;$$$) {
  my ($dir, $is_fat32, $keep_del, $keep_dots, $keep_labels) =
    (shift, shift, shift, shift, shift);
  my ($res, @files, @lfn, $lfn_checksum, $lfn_seq, $lfn_tot, $lfn_del);
  while (length $dir) {
    $dir =~ s/^((.).{31})//s or die "short directory!";
    $res = 'end', last if $2 eq "\0";		# No entries after this point
    next if not $keep_del and 0xE5 == ord $2;	# deleted or not filled
    my %f = decode_fields \@file_f, $1;
    $f{deleted} = 0;
    $f{deleted} = 1 if 0xE5 == ord $2;		# deleted or not filled
    if ($f{attrib} == 0x0F) {	# LFN
      # next;
      %f = decode_fields \@lfn_f, $1;
      if (not $keep_del) {	# XXX How to process? Ignore seq numbers???
	@lfn = (), next if $f{seq_number} & 0x80; # Deleted entry
      } else {			# Deleted entry for non-deleted file?
	@lfn = (), next if $f{seq_number} & 0x80 and $f{seq_number} != 0xE5;
	if ($f{seq_number} == 0xE5) {
	  die "Deleted LFN subrecord in middle of LFN" if @lfn and !$lfn_del;
	  $lfn_del = 1;
	  $f{deleted} = 1;
	} else {		# Ignore deleted LFN preceeding a valid LFN
	  @lfn = () if @lfn and $lfn_del;
	  $lfn_del = 0;
	}
      }
      $f{raw} = $1;
      unless ($f{deleted}) {
	die "LFN start unexpected" if @lfn and $f{seq_number} & 0x40;
	die "LFN continuation unexpected" unless @lfn or $f{seq_number} & 0x40;

	die "LFN continuation out-of-order: $f{seq_number} after $lfn_seq"
	  if @lfn and $f{seq_number} != ($lfn_seq & ~0x40) - 1;
	$lfn_seq = $f{seq_number};

	die "Mismatch in checksums"
	  if @lfn and $lfn_checksum != $f{checksum_dosname};
      }
      $lfn_checksum = $f{checksum_dosname};
      $f{lfn_chars} = "$f{name_chars_1}$f{name_chars_2}$f{name_chars_3}";
      $f{lfn_chars} =~ s/\0\0(\xFF\xFF){0,11}$// # may be non-terminated...
	# or die "LFN `$f{lfn_chars}' not terminated by 0x0000"
	  unless @lfn;
      if (@lfn) {
	$lfn_tot = "$f{lfn_chars}$lfn_tot"
      } else {
	$lfn_tot = $f{lfn_chars}
      }
      push @lfn, \%f;
      next;
    }
    $f{raw} = $1;
    $f{basename} =~ s/^\x05/\xE5/;
    @lfn = (), next
      if not $keep_dots and $f{basename} =~ /^\.\.?$/ and $f{ext} eq ''; # . ..
    # DOSname is mangled for deleted files, so there is no point in checksum...
    @lfn = (), warn("Mis-attached LFN (chksum mismatch: $lfn_checksum vs `$f{basename}.$f{ext}')")
      if @lfn and not $lfn_del and $lfn_checksum != dos_chksum($f{basename}, $f{ext});
    next if ($f{attrib} & 0x08) and not $keep_labels;
    if ($is_fat32) {
      $f{cluster} = $f{cluster_low} + ($f{cluster_high} << 16);
    } else {
      $f{cluster} = $f{cluster_low};	# cluster_high has EA info?
    }
    $f{basename}  = lc $f{basename}  if $f{name_ext_case} & (1<<3);
    $f{ext}	  = lc $f{ext}	     if $f{name_ext_case} & (1<<4);
    my $ext = length $f{ext} ? ".$f{ext}" : '';
    $f{dos_name} = $f{name} = "$f{basename}$ext";
    $f{time_create} = $f{time_creation} + $f{creation_01sec}/100;
    $f{$_} = $f{attrib} & $file_attrib{$_} for keys %file_attrib;
    if (@lfn) {
      $f{lfn_raw} = [@lfn];
      $f{name} = join '', map chr, unpack 'v*', $lfn_tot;
      $f{lfn_name_UTF16} = $lfn_tot;
    }
    push @files, \%f;
    @lfn = ();
  }
  $res ||= 'mid' if @lfn;
  ($res, \@files);
}

# FAT12/FAT16 Boot Sector/Boot Record Layout.

#      The data contained in the boot sector after the OEM name string is
#                referred to as the BIOS parameter block or BPB.
# Offset Length                              Field
#  00h        3               Machine code for jump over the data.
#  03h        8        OEM name string (of OS which formatted the disk).
#  0Bh        2   Bytes per sector, nearly always 512 but can be 1024,2048 or
#                                            4096.
#  0Dh        1 Sectors per cluster, valid number are: 1,2,4,8,16,32,64 and 128,
#                     but a cluster size larger than 32K should not occur.
#  0Eh        2     Reserved sectors (number of sectors before the first FAT
#                            including the boot sector), usually 1.
#  10h        1                Number of FAT's (nearly always 2).
#  11h        2            Maximum number of root directory entries.
#  13h        2  Total number of sectors (for small disks only, if the disk is
#                  too big this is set to 0 and offset 20h is used instead).
#  15h        1  Media descriptor byte, pretty meaningless now (see below).
#  16h        2                         Sectors per FAT.
#  18h        2                        Sectors per track.
#  1Ah        2                   Total number of heads/sides.
#  1Ch        4   Number of hidden sectors (those preceding the boot sector).
#  20h        4             Total number of sectors for large disks.
	# Starts FAT12/16-specific
#  24h       26       Either extended BPB (see below) or machine code.
#  3Eh      448                          Machine code.
#  1FEh       2                      Boot Signature AA55h.

	# Starts FAT32-specific
# 0x24              4 Sectors per file allocation table
# 0x28              2 FAT Flags
# 0x2a              2 Version
# 0x2c              4 Cluster number of root directory start
# 0x30              2 Sector number of FS Information Sector
# 0x32              2 Sector number of a copy of this boot sector
# 0x34             12 Reserved
# 0x40              1 Physical Drive Number
# 0x41              1 Reserved
# 0x42              1 Extended boot signature.
# 0x43              4 ID (serial number)
# 0x47             11 Volume Label
# 0x52              8 FAT file system type: "FAT32   "
# 0x5a            420 Operating system boot code
#  0x1FE              2 Boot sector signature (0x55 0xAA)


my @boot_c = (	jump	=> 'A3',
		oem	=> 'A8',
		sector_size	=> 'v',
		sectors_in_cluster	=> 'C',
		FAT_table_off	=> 'v',
		num_FAT_tables	=> 'C',
		root_dir_entries	=> 'v',
		total_sectors1	=> 'v',
		media_type	=> 'C',
		sectors_per_FAT16	=> 'v',
		sectors_per_track	=> 'v',
		heads	=> 'v',
		hidden_sectors	=> 'V',
		total_sectors2	=> 'V',
    );
my @boot_16 = (	extended_bpb	=> 'a26',
		machine_code	=> 'a448',
		boot_signature	=> 'v',
    );
my @boot_32 = (	sectors_per_FAT32	=> 'V',
		FAT_flags	=> 'v',
		version	=> 'v',
		rootdir_start_cluster	=> 'V',
		fsi_sector_sector	=> 'v',
		bootcopy_sector_sector	=> 'v',
		reserved1	=> 'a12',
		physical_drive	=> 'C',
		reserved2	=> 'C',
		ext_boot_signature	=> 'C',
		serial_number	=> 'V',
		volume_label	=> 'A11',
		FS_type	=> 'A8',
		machine_code	=> 'a420',
		boot_signature	=> 'v',
    );


# FAT12/Fat16 Extended BPB.
#
#     The Extended BIOS parameter block is not present prior to DOS 4.0
#                              formatted disks.
#                                   Offset
#                             Length (in bytes)
#                                   Field
# 24h 1 Physical drive number (BIOS system ie 80h is first HDD, 00h is first FDD).
# 25h 1 Current head (not used for this; WinNT bit 0 is a dirty flag to request chkdsk at boot time. bit 1 requests surface scan too).
# 26h 1 Signature (must be 28h or 29h to be recognised by NT).
# 27h 4 The serial number, the serial number is stored in reverse order
#          and is the hex representation of the bytes stored here.
# 2Bh 11 Volume label.
# 36h 8 File system ID. "FAT12", "FAT16" or "FAT  ".

# Further structure used by FAT32:
# Byte Offset Length (bytes)                 Description
#        0x24              4 Sectors per file allocation table
#        0x28              2 FAT Flags
#        0x2a              2 Version
#        0x2c              4 Cluster number of root directory start
#        0x30              2 Sector number of FS Information Sector
#        0x32              2 Sector number of a copy of this boot sector
#        0x34             12 Reserved
#        0x40              1 Physical Drive Number
#        0x41              1 Reserved
#        0x42              1 Extended boot signature (0x28 0x29).
#        0x43              4 ID (serial number)
#        0x47             11 Volume Label
#        0x52              8 FAT file system type: "FAT32   "
#        0x5a            420 Operating system boot code
#       0x1FE              2 Boot sector signature (0x55 0xAA)

my @e_boot = (
		physical_drive	=> 'C',
		head___dirty_flags	=> 'C',
		ext_boot_signature	=> 'C',
		serial_number	=> 'V',
		volume_label	=> 'A11',
		FS_type		=> 'A8',
    );

# FS Information Sector
# Byte Offset Length (bytes)                          Description
#        0x00              4 FS information sector signature (0x52 0x52 0x61 0x41 / "RRaA")
#        0x04            480 Reserved (byte values are 0x00)
#       0x1e4              4 FS information sector signature (0x72 0x72 0x41 0x61 / "rrAa")
#       0x1e8              4 Number of free clusters on the drive, or -1 if unknown
#       0x1ec              4 Number of the most recently allocated cluster
#       0x1f0             14 Reserved (byte values are 0x00)
#       0x1fe              2 FS information sector signature (0x55 0xAA)

sub preprocess_bootsect ($) {
  my $s = shift;
  $s->{total_sectors} = $s->{total_sectors1} || $s->{total_sectors2};
  $s->{sectors_per_FAT} = $s->{sectors_per_FAT32} || $s->{sectors_per_FAT16};
  $s->{pre_sectors} = $s->{FAT_table_off}
    + $s->{num_FAT_tables} * $s->{sectors_per_FAT}
      + $s->{root_dir_entries} * 0x20 / $s->{sector_size};
  $s->{sector_of_cluster0} = $s->{pre_sectors} - 2*$s->{sectors_in_cluster};
  $s->{last_cluster} = int(($s->{total_sectors} - $s->{pre_sectors}
			   + $s->{sectors_in_cluster} - 1)/$s->{sectors_in_cluster}) + 2;
}

sub guess_width ($$) {
  my ($s, $raw) = (shift, shift);
  my $w = 12;
  my %bpb = decode_fields \@e_boot, $s->{extended_bpb};
  if ($s->{last_cluster} >= 0x10000 or $s->{root_dir_entries} == 0
      or $bpb{ext_boot_signature} != 0x28 and $bpb{ext_boot_signature} != 0x29) {
    $w = 32;
    %$s = decode_fields [@boot_c, @boot_32], $raw;
    preprocess_bootsect $s;
  } elsif ($s->{last_cluster} >= 0x1000) {
    $w = 16
  } else {			# Any other way to determine width???
  }
  $s->{bpb_ext_boot_signature} = $bpb{ext_boot_signature};
  @$s{keys %bpb} = values %bpb unless $w == 32;
  $s->{guessed_FAT_flavor} = $w;
  $s->{raw} = $raw;
}

sub interpret_bootsector ($) {
  my $bootsect = shift;
  my $s = {decode_fields [@boot_c, @boot_16], $bootsect};
  preprocess_bootsect $s;
  guess_width $s, $bootsect;
  $s
}

sub check_bootsector ($;$) {
  my $s = shift;
  # Expected size of FAT with 12bit per entry
  my $exp = $s->{last_cluster} * $s->{guessed_FAT_flavor}/8/$s->{sector_size};
  die "FAT has $s->{sectors_per_FAT} sectors: expecting $exp"
    unless $s->{sectors_per_FAT} >= $exp;
  warn "FAT has $s->{sectors_per_FAT} sectors: expecting $exp"
    unless $s->{sectors_per_FAT} <= $exp + 10;

# How to distinguish bootsector from MBR?  Jump on FAT12 is "EB 3C 90";
# 0x90 is NOP, 0xEB is jump(displacement8).  In FAT32, there are extra
# 28 bytes, so displacement should be 0x58.  To be extra safe (e.g., allow
# chymera bootsector-and-MBR), one should tolerate other jumps...

  die sprintf "Unexpected bootsector: first byte %#02x\n",
    ord substr $s->{raw},0,1 
      if shift and not $s->{raw} =~ /^\xEB/; # Check JMP instruction
  return 1 if
    ($s->{ext_boot_signature} == 0x28 or $s->{ext_boot_signature} == 0x29)
      and $s->{boot_signature} == 0xAA55
	and $s->{FS_type} =~ /^fat(\d{2})?/i
	  and (not $1 or $1 eq $s->{guessed_FAT_flavor});
  die <<EOD
Unexpected bootsector: guessed_width=$s->{guessed_FAT_flavor}, last_cluster=$s->{last_cluster}, root_dir_entries=$s->{root_dir_entries},
  boot_signature=$s->{boot_signature}, ext_boot_signature16=$s->{bpb_ext_boot_signature}, ext_boot_signature=$s->{ext_boot_signature}, FS_type=$s->{FS_type}
EOD
}

sub string_to_n ($$$$) {
  my($s, $offset, $n, $w) = (shift, shift, shift, shift);
  my($n2, $w2) = ($n, ($w>>3));
  $n2 >>= 1, $w2 = 3 if $w == 12;
  $offset += $w2 * $n2;
  my $out = unpack 'V', substr($$s, $offset, $w2) . "\0\0";
  if ($w == 12) {
    if ($n % 2) {
      $out >>= 12
    } else {
      $out &= 0xFFF
    }
  }
  $out
}

sub FAT_2array ($$$;$$) {
  my($fat, $s, $w, $offset, $lim) = (shift, shift, shift, shift || 0, shift);
  $lim = length($$s) - $offset unless defined $lim;
  die "Too large offset=$offset, lim=$lim" if $lim + $offset > length $$s;
  if ($w == 12) {
    $lim += $offset;
    while ($offset < $lim) {
      my $ss = substr $$s, $offset, 3;
      my $n32 = unpack 'V', "$ss\0";
      # warn sprintf "got %#04x\n", $n32;
      push @$fat, ($n32 & 0xFFF), ($n32 >> 12);
      $offset += 3;
    }
  } else {
    my $f = ($w == 32) ? 'V' : 'v';
    $w >>= 3;
    $lim = int($lim/$w);
    # Do not extend stack too much:
    while ($lim >= 1) {
      my $l = ($lim > 1000) ? 1000 : $lim;
      push @$fat, unpack "x$offset $f$l", $$s;
      $lim -= $l;
      $offset += $l * $w;
    }
  }
  # warn "FAT = @$fat\n"
}

sub check_FAT_array ($$;$) {
  my ($fat, $b, $offset, @fat) = (shift, shift, shift || 0);
  FAT_2array(\@fat, $fat, $b->{guessed_FAT_flavor}, $offset, 2*4),
    $fat = \@fat unless 'ARRAY' eq ref $fat; # Make into array

  my $max_cluster = (1<<$b->{guessed_FAT_flavor}) - 1;
  die sprintf "Wrong signature %d=%#x, media=%#x in cluster(0)",
    $fat->[0], $fat->[0], $b->{media_type}
      unless $fat->[0] == (($b->{media_type} | 0xffffff00) & $max_cluster);

  my $eof = $fat->[1];		# Leading 0 in FAT32:
  die sprintf "Wrong signature %d=%#x in cluster(1)", $eof, $eof
    unless ($eof >> 3) == ($max_cluster >> (3 + 4*(32==$b->{guessed_FAT_flavor})));
  return 1;
}

sub cluster_chain ($$$$;$$) {
  my ($cluster, $maxc, $fat, $b, $compress, $offset) = (shift, shift, shift, shift, shift, shift||0);
  my $last_cluster = $b->{last_cluster};
  die "problem with cluster=$cluster as a cluster leader"
    unless $cluster >= 2 and $cluster <= $last_cluster;
  my ($c, @clusters) = (1, $cluster);
  my $w = $b->{guessed_FAT_flavor};
  my $stop_3 = (1<<($w - 3 - 4*($w==32))) - 1; # Leading 0 in FAT32
  my $total = 1;
  my $subr = ($compress and ref $compress eq 'CODE' and $compress);
  while (--$maxc) {
    # warn "processing $cluster, rem=$maxc, stop_3=$stop_3, w=$w";
    my $next;
    if (ref $fat eq 'ARRAY') {
      $next = $fat->[$cluster];
    } else {			# A reference to 'V*'-string
      $next = string_to_n($fat, $offset, $cluster, $w);
    }
    if ($compress) {
      $c++, next if $next == ++$cluster;
      if ($subr) {
	$subr->($clusters[-1], $c);
	pop @clusters;
      } else {
	push @clusters, $c;
      }				# New cluster would be inserted later
      $total += $c - 1;
      $c = 1;
    }
    return $total, \@clusters if ($next >> 3) == $stop_3;
    $next = 'undef' unless defined $next; # XXX ???
    die "problem with cluster(+1)=$cluster => $next in a cluster chain"
      unless $next >= 2 and $next <= $last_cluster;
    $total++, push @clusters, $cluster = $next;
  }
  return 0, \@clusters
}

sub min($$){my($a,$b)=@_;$a>$b? $b:$a}

sub seek_and_read ($$$$;$) {
  my ($fh, $seek, $read) = (shift,shift,shift);
  sysseek $fh, $seek, 0 or die "sysseek $seek: $!" if defined $seek;
  $_[0]=' ', $_[0] x= $read, $_[0] = '' unless defined $_[0];
  die "seek_and_read outside of string" if ($_[1] || 0) > length $_[0];
  substr($_[0], $_[1] || 0) = '';
  my($r,$t,$c) = ($read, 0);
  $r -= $c, $t += $c
    while $r and $c = sysread $fh, $_[0], min($r, $lim_read), length $_[0];
  die "Short read ($t instead of $read)" unless $t == $read;
  1;
}

sub read_FAT_data ($$;$$$) {
  my ($fh, $how, $offset, $b, $FAT) = (shift, shift, shift||0, shift, shift);
  my ($close, $inif, $out, $mbr, $b_read);
  unless (ref $fh) {
    open IN, '<', $inif = $fh or die "open `$fh' for read: $!";
    $fh = \*IN;
    $close = 1;
  }
  binmode $fh;
  if (defined $how->{do_MBR}) {
    seek_and_read $fh, $offset, 512, $mbr;
    if ($how->{do_MBR} eq 'maybe' and defined $how->{do_bootsector}) {
      eval { my $b1 = interpret_bootsector $mbr;
	     check_bootsector $b1;
	     $out->{bootsect_off} = $offset;
	     $b = $out->{bootsector} = $b1;
	     $b_read = 1 } and undef $mbr;
    }
    if ($mbr and (defined $how->{parse_MBR} or defined $how->{do_bootsector}
		  or defined $how->{do_rootdir} or defined $how->{do_FAT})) {
      my($fields, @p) = MBR_2_partitions $mbr or die "Wrong signature in MBR";
      my @valid = defined $how->{partition} ? $how->{partition} : (0..3);
      # Type = 0 is Empty; FreeSpace is not marked as a partition???
      @valid = grep $p[$_]{start_lba} && $p[$_]{sectors} && $p[$_]{type}, @valid;
      unless (@valid) {
	die "Partition $how->{partition} invalid" if $how->{partition};
	die "No valid partition found";
      }
      die "Too many valid partitions: @valid" if @valid > 1;
      $offset += $p[$valid[0]]{start_lba} * 512;
      $out->{mbr} = {%$fields, partitions => \@p};
    }
  }
  if (defined $how->{do_bootsector} and not $b_read) {
    die "Bootsector given as argument and needs to be read too?" if $b;
    seek_and_read $fh, $offset, 512, my $bs;
    if (defined $how->{parse_bootsector} or defined $how->{do_rootdir}
	or defined $how->{do_FAT}) {
      $b = interpret_bootsector $bs;
      check_bootsector $b;
    } else {
      $b = {raw => $bs};
    }
    $out->{bootsector_offset} = $offset;
    $out->{bootsector} = $b;
  }
  if (defined $how->{do_FAT}) {
    die "need bootsector" unless $b;
    die "FAT given as argument and needs to be read too?" if $FAT;
    my $o = $offset;
    $o += ($b->{FAT_table_off} + $how->{do_FAT} * $b->{sectors_per_FAT})
      * $b->{sector_size} unless $how->{FAT_separate};
    die "FAT[$how->{do_FAT}] not present: only $b->{num_FAT_tables} FAT table"
      if $b->{num_FAT_tables} <= $how->{do_FAT};
    seek_and_read $fh, $o, $b->{sector_size} * $b->{sectors_per_FAT}, my $F;
    if (defined $how->{parse_FAT}
	and $b->{last_cluster} < ($how->{parse_FAT} || 3e6)) {
      my @f;
      $#f = $b->{last_cluster};
      @f = ();
      FAT_2array(\@f, \$F, $b->{guessed_FAT_flavor});
      $FAT = \@f;
    } else {
      $FAT = \$F;
    }
    $out->{FAT} = $FAT;
    $out->{FAT_raw} = \$F if $how->{raw_FAT} or not defined $how->{parse_FAT};
  }
  if (defined $how->{do_rootdir}) {
    die "need bootsector" unless $b;
    my($s, $l, $o) = '';
    if ($how->{rootdir_is_standalone}) {
      local $/;
      $s = <$fh>;
    } else {
      my($L, $S) = ($b->{sector_size} * $b->{sectors_in_cluster},
		      $offset + $b->{sector_of_cluster0}*$b->{sector_size});
      if ($b->{guessed_FAT_flavor} == 32) {
	my $appender = sub ($$) {
	  my($start, $len) = (shift, shift);
	  seek_and_read $fh, $S + $L * $start, $len * $L, $s, length $s;
	}
	;
	if ($FAT) {
	  cluster_chain($b->{rootdir_start_cluster}, 0, $FAT, $b, $appender);
	} else {
	  $appender->($b->{rootdir_start_cluster}, 1); # XXX Assume 1 cluster
	}
      } else {
	my $off = ($offset + $b->{sector_size} *
		   ($b->{FAT_table_off} + $b->{num_FAT_tables} * $b->{sectors_per_FAT}));
	seek_and_read $fh, $off, $b->{root_dir_entries} * 0x20, $s;
      }
    }
    if (defined $how->{parse_rootdir}) {
      my($res, $f) = interpret_directory $s, $b->{guessed_FAT_flavor} == 32,
	$how->{keep_del}, $how->{keep_dots}, $how->{keep_labels};
      die "Directory ended in the middle of LFN" if ($res || 0) eq 'mid';
      $out->{rootdir_files} = $f;
      $out->{rootdir_ended} = $res;
    }
    $out->{rootdir_raw} = $s;
  }
  close $fh or die "close `$inif' for read: $!" if $close;
  return $out;
}

sub output_cluster_chain ($$$$$$;$) {
  my($ifh, $ofh, $start, $size, $b, $FAT, $offset) = 
    (shift, shift, shift, shift, shift, shift, shift||0);
  return unless $size;
  my($L, $S) = ($b->{sector_size} * $b->{sectors_in_cluster},
		$offset + $b->{sector_of_cluster0}*$b->{sector_size});
  my $piper = sub ($$) {
    my($start1, $len) = ($L * shift, $L * shift);
    # warn "Piper: start=$start1, len=$len\n";
    if ($len > $size) {
      die "Cluster chain too long, len=$len, cl=$L, sz=$size" if $len - $L >= $size;
      $len = $size;
    }
    while ($len) {
      my $l = ($len > (1<<24)) ? (1<<24) : $len; # 16M chunks
      my $s;
      seek_and_read $ifh, $S + $start1, $l, $s;
      syswrite $ofh, $s, length $s;
      $len -= $l, $size -= $l, $start1 += $l;
    }
  };
  my $sz = int(($size + $L - 1)/$L);
  $piper->($start, $sz), return 1 if not defined $FAT;
  # Inspect the last cluster for end of chain too
  my ($total) = cluster_chain $start, $sz+1, $FAT, $b, $piper;
  die "No end of cluster chain" unless $total;
  1;
}

sub read_cluster_chain ($$$$;$$) { # No size, as in dir...
  my($ifh, $start, $b, $FAT, $offset, $exp_len) =
    (shift, shift, shift, shift, shift||0, shift);
  my($L, $S, $s) = ($b->{sector_size} * $b->{sectors_in_cluster},
		    $offset + $b->{sector_of_cluster0}*$b->{sector_size}, '');
  (seek_and_read $ifh, $S + $L * $start, $exp_len, $s),
    return \$s if not defined $FAT and defined $exp_len;
  my $piper = sub ($$) {
    my($start1, $l) = (shift, shift);
    seek_and_read $ifh, $S + $L * $start1, $L * $l, $s, length $s;
  };
  my ($total) = cluster_chain $start, 0, $FAT, $b, $piper;
  die "No end of cluster chain" unless $total;
  \$s;
}

sub write_file ($$$$$;$) {
  my ($fh, $dir, $f, $b, $FAT, $offset) =
    (shift, shift, shift, shift, shift, shift||0);
  return if $f->{is_volume_label}
    or $f->{name} eq 'EA DATA. SF' or $f->{name} eq 'WP ROOT. SF';
  die "directory `$f->{name}' as file!" if $f->{is_subdir};
  my $name = "$dir/$f->{name}";
  open O, '>', $name or die "error opening $name for write: $!";
  binmode O;
  output_cluster_chain($fh, \*O, $f->{cluster}, $f->{size}, $b, $FAT, $offset);
  close O or die "error closing $name for write: $!";
  chmod 0555, $name if $f->{attrib} & 0x1;	# read only
  # unset archive mode?
}

sub recurse_dir ($$$$$$$;$);
sub recurse_dir ($$$$$$$;$) {
  my ($callbk, $path, $fh, $how, $f, $b, $FAT, $offset) =
    (shift, shift, shift, shift, shift, shift, shift, shift||0);
  my $files =
    interpret_directory( $$f, $b->{guessed_FAT_flavor} == 32, $how->{keep_del},
			 $how->{keep_dots}, $how->{keep_labels} );
  for my $file (@$files) {
    # next if $file->{is_volume_label};
    my $res = $callbk->($path, $file);
    if ($res and $file->{is_subdir} and not $file->{deleted}
	and $file->{name} !~ /^\.(\.)?$/) {
      push @$path, $file->{name};
      my $exp_len;
      $exp_len = $b->{sector_size} * $b->{sectors_in_cluster}
	unless defined $FAT;	# XXXX Expect dir size of one cluster???
      recurse_dir($callbk, $path, $fh, $how,
		  read_cluster_chain($fh, $file->{cluster}, $b, $FAT, $offset,
				     $exp_len),
		  $b, $FAT, $offset);
      pop @$path;
    }
  }
}

sub write_dir ($$$$$;$$$$) {
  my ($fh, $o_root, $ff, $b, $FAT, $how, $depth, $offset, $exists) =
    (shift, shift, shift, shift, shift, shift, shift||0, shift);
  $depth = 1e100 unless defined $depth;
  my $callbk = sub ($$) {
    my($path,$f) = (shift, shift);
    next if $f->{is_volume_label} or $f->{name} =~ /^\.(\.)?$/;
    my $p = join '/', $o_root, @$path;
    return write_file $fh, $p, $f, $b, $FAT, $offset unless $f->{is_subdir};
    return 0 if @$path >= $depth;
    mkdir "$p/$f->{name}", 0777 or die "mkdir `$p/$f->{name}': $!"
      unless $exists and not @$path;
    return 1;
  };
  recurse_dir($callbk, [], $fh, $how||{}, $ff, $b, $FAT, $offset);
}

sub list_dir ($$$$;$$$) {
  my ($fh, $ff, $b, $FAT, $how, $depth, $offset) =
    (shift, shift, shift, shift, shift, shift, shift||0, shift);
  $depth = 1e100 unless defined $depth;
  my $callbk = sub ($$) {
    my($path,$f,$pre) = (shift, shift, '');
    print("# label=$f->{name}\n"), return if $f->{is_volume_label};
    my $p = join '/', @$path, $f->{name};
    $p .= '/' if $f->{is_subdir};
    $pre = '#del ' if $f->{deleted};
    $pre = '# ' if $f->{name} =~ /^\.(\.)?$/;
    print "$pre$f->{attrib}\t$f->{size}\t$f->{date_write}/$f->{time_write}\t$f->{cluster}\t$p\n";
    return @$path < $depth;
  };
  recurse_dir($callbk, [], $fh, $how||{}, $ff, $b, $FAT, $offset);
}

# First FAT entry contains 0xFF*, the rest 0x0F*; so 0x2*, 0xA* do not conflict
sub compress_FAT ($$$) {	# Down to 2-4 bytes/file after gzip...
  my($FAT, $w, $fh) = (shift, shift, shift);
  my ($c, $cc, $c0, $off, $ee, $remain, @out, $F) = (0, 0, 0, 0);
  local $\ = '';
  while (1) {
    if (ref $FAT eq 'ARRAY') {
      $F = $FAT, $remain = 0;
    } else {
      $remain = length $$FAT unless defined $remain;
      my $l = $remain;
      $l = 750000 if $l > 750000; # Should be divisible by 12...
      FAT_2array($F = [], $FAT, $w, $off, $l);
      $remain -= $l, $off += $l;
    }
    for my $e (@$F) {
      $c++;			# Next cluster
      if ($e) {
	(push @out, 0xA0000000 + $c0), $c0 = 0 if $c0;
	$cc++, next if $e == $c;
	(push @out, 0x20000000 + $cc), $cc = 0 if $cc;
	push @out, $e;
      } else {
	(push @out, 0x20000000 + $cc), $cc = 0 if $cc;
	$c0++, next;
      }
      (print $fh pack 'V*', @out), @out = () if @out > 1000;
    }
    last unless $remain;
  }
  push @out, 0xA0000000 + $c0 if $c0;
  push @out, 0x20000000 + $cc if $cc;
  print $fh pack 'V*', @out;
}

sub _FAT_2string ($$$$) {
  my($FAT, $w, $start, $c) = @_;
  if ($w eq 12) {
    my($out, $e) = ('', $start + $c);
    while ($start < $e) {	# Assume even
      my $x = pack 'V', $FAT->[$start] + ($FAT->[$start+1]<<12);
      $out .= substr $x, 0, 3;
      $start += 2;
    }
    $out;
  } else {	# $w is 'V' or 'v'
    pack "$w*", @$FAT[$start .. $start + $c - 1];
  }
}

sub output_FAT ($$$) {
  my($FAT, $w, $fh, $s) = (shift, shift, shift, 0);
  local $\ = '';
  (print $fh $$FAT), return unless ref $FAT eq 'ARRAY';
  my $c = @$FAT;
  $w = (32 == $w) ? 'V' : 'v' if $w != 12;
  while ($c) {
    my $cc = ($c > 750000) ? 750000 : $c;
    print $fh _FAT_2string($FAT, $w, $s, $cc);
    $c -= $cc, $s += $cc;
  }
}

sub __emit ($$$) {
  my($ofh, $out, $w) = (shift, shift, shift);
  my $outc = @$out;
  my $cut;
  $cut = 1, $outc-- if $w eq 12 and $outc % 2;
  print $ofh _FAT_2string($out, $w, 0, $outc);
  @$out = $cut ? $$out[-1] : ();
}

sub uncompress_FAT ($$$) {
  my($ifh, $w, $ofh) = (shift, shift, shift);
  my ($c, @f, @out, $F) = (0);
  @f[0x2, 0xA] = (0x2, 0xA);
  local $\ = '';
  $w = (32 == $w) ? 'V' : 'v' if $w != 12;
  while (1) {
    last unless sysread $ifh, $F, 4*1e4;
    for my $n (unpack 'V*', $F) {
      my $n1 = $f[$n >> 28];
      if ($n1) {		# Special
	my $cc = $n & 0xFFFFFFF;
	while ($cc) {
	  my ($ccc, @rest) = $cc;
	  $ccc = 1e4 if $ccc > 1e4;
	  if ($n1 == 0x2) {	# A run
	    push @out, $c + 1 .. $c + $ccc;
	  } else {		# 0s
	    push @out, (0) x $ccc;
	  }
	  $cc -= $ccc, $c += $ccc;
	  __emit($ofh, \@out, $w) if @out >= 1e4;
	}
      } else {
	$c++;
	push @out, $n;
      }
    }
    __emit($ofh, \@out, $w) if @out >= 1e4;
  }
  __emit($ofh, \@out, $w);
  die "Odd number of uncompressed items, w=$w" if @out;
}

1;
__END__

=head1 NAME

FileSystem::LL::FAT - Perl extension for low-level access to FAT partitions

=head1 SYNOPSIS

  use FileSystem::LL::FAT;
  blah blah blah

=head1 DESCRIPTION

=head2 MBR_2_partitions($sector)

  ($fields, @partitions) = MBR_2_partitions($sector) or die "Not an MBR";

Takes the first sector as a string, extracts the partition info and
other information.  Currently the only fields in the hash referenced by
$fields is C<bootcode> (string of length 446) and C<signature> (0xAA55).

Each element of @partitions is a hash reference with fields

  raw is_active start_head start_sec_trac type end_head end_sec_track
  start_lba sectors start_sec end_sec start_trac end_track

Returns an empty list unless signature is correct.

=head2 interpret_bootsector($bootsector)

Takes a string containing 512Byte bootsector; returns a hash reference
with decoded fields.  The keys include

  jump oem sector_size sectors_in_cluster FAT_table_off num_FAT_tables
  root_dir_entries total_sectors1 media_type sectors_per_FAT16
  sectors_per_track heads hidden_sectors total_sectors2
  machine_code FS_type boot_signature volume_label physical_drive
  ext_boot_signature serial_number raw

  bpb_ext_boot_signature guessed_FAT_flavor
  total_sectors sectors_per_FAT pre_sectors last_cluster sector_of_cluster0

(the last line contains info calculated based on other entries;
C<guessed_FAT_flavor> is one of 12,16,32, and
C<bpb_ext_boot_signature> is the C<ext_boot_signature> calculated
assuming FAT12 or FAT16 layout of bootsector).

Additional flavor-dependent keys: in FAT32 case

  sectors_per_FAT32 FAT_flags version rootdir_start_cluster
  fsi_sector_sector bootcopy_sector_sector reserved1 reserved2

otherwise

  extended_bpb head___dirty_flags

=head2 check_bootsector($fields)

Takes a hash reference with decoded fields of a bootsector; returns
TRUE if minimal sanity checks hold; die()s otherwise.

=head2 interpret_directory($dir, $is_fat32, [$keep_del, [$keep_dots, [$keep_labels]]])

  ($res, $files) = interpret_directory($dir, $is_FAT32);
  $files = interpret_directory($dir, $is_FAT32);

Takes catenation of directory cluster(s) as a string, extracts
information about the files in the directory.  Each element of array
referenced by $files is a hash reference with keys

  raw basename ext attrib name_ext_case creation_01sec time_create
  date_create date_access cluster_high time_write date_write cluster_low
  size cluster name dos_name time_creation
  is_readonly is_hidden is_system is_volume_label is_subdir is_archive is_device

and possibly C<lfn_name>, C<lfn_name_UTF16>, C<lfn_raw> (if
applicable).  (The last row lists flags extracted from C<attrib>.)

C<basename> and $<ext> are parts of the "DOS name" (lowercased if
indicated by the flags), C<time_create> has 0.01sec granularity (while
C<time_creation> has 2sec granularity).  Entries for deleted files are
filtered out unless $keep_del is TRUE; F<.> and F<..> are also
filtered out unless $keep_dots is TRUE; records representing volume
labels are also deleted unless $keep_labels is TRUE.  If not filtered
out, hashes for deleted files have an extra key C<deleted> with a true
value.

C<lfn_raw> contains an array reference with all the fractional entries
which contain the Long File Name.  Each of them is a hash reference
with keys

  raw seq_number name_chars_1 attrib nt_reserved checksum_dosname
  name_chars_2 cluster_low name_chars_3 name_chars

$res is C<'end'> if end-of-directory entry is encountered; it is
C<'mid'> if directory ends in middle of LFN info.  Otherwise $res is
not defined.

=head2 FAT_2array($fat, $s, $w [, $offset [, $lim ] ] )

Takes a reference $s to a string, at offset $offset of which is the
string representation of the FAT table; the length of FAT table in
bytes is assumed to be $lim.  $offset defaults to 0, $lim defaults to
go to the end of string.

Appends to the array referenced by $fat a numeric array representating
FAT.  $w is the bitwidth of the field (in 12,16,32).

=head2 check_FAT_array($fat, $b [, $offset ])

$fat is a reference to a numeric array, or to the string containing
the representation of FAT at $offset (which defaults to 0).  $b is a
hash reference with keys C<guessed_FAT_flavor>, C<media_type> (e.g.,
the result of interpret_bootsector()).

Returns TRUE if the first two clusters satisfy the FAT conventions;
otherwise die()s.

=head2 cluster_chain($cluster, $maxc, $fat, $b [, $compress [, $offset ] ])

 ($total, $chain) = cluster_chain($cluster, $maxc, $fat, $b, $offset);

$fat is a reference to numeric array, or to the string containing the
representation of FAT at $offset (which defaults to 0).  $cluster is
the start cluster, $maxc is the maximal number of clusters to look for
(0 meaning no limit).  $b is a hash reference with keys
C<guessed_FAT_flavor>, C<last_cluster> (e.g., the result of
interpret_bootsector()).

$chain is an array reference with the clusters in the chain.  $total
is FALSE if no end-of-a-chain marker was seen; otherwise it contains
the total number of clusters.

If $compress is TRUE (defaults to FALSE), the cluster chain is
run-compressed: each continuous run of clusters is converted to a pair
of numbers: the starting cluster number, and length in clusters.  If
$compress is a subroutine reference, then it is called with these
numbers as arguments; otherwise these numbers are pushed into $chain.

=head2 read_FAT_data($fh, $how [, $offset, $b, $FAT ])

  $hash = read_FAT_data($fh, $how [, $offset, $b, $FAT ]);

Extracts one or more of MBR, bootsector, FAT table, root directory
from a file $fh containg "contents of a disk".  $fh may be a reference
to a file handle, or a name of the file.  The optional argument
$offset is the offset inside the file of the first entry to extract,
or of bootsector (default 0).

The hash reference $how contains extraction instructions.  If values
of keys C<do_MBR>, C<do_bootsector>, C<do_FAT>, C<do_rootdir> are
defined, the corresponding parts of filesystem are read.  If
C<do_MBR>'s value is C<'maybe'> and C<do_bootsector>'s is defined, the
MBR part is checked whether it is an actual MBR or a bootsector.  The
actual value of the key C<do_FAT> chooses the copy of FAT to work
with.

The value of key C<partition> governs which partition of 0..3 to
choose (only primaries are currently supported); if not defined, and
the number of valid partitions differs from 1, the call die()s.

If the value of key C<FAT_separate> is TRUE, $offset is the offset of
the start of (the first) FAT in the file; otherwise it is the offset
of MBR or bootsector (offsets of other parts are calculated as
needed).  If the value of kye C<rootdir_is_standalone> is TRUE,
rootdir is assumed to be the whole content of the file.

If the values of keys C<parse_MBR>, C<parse_bootsector>, C<parse_FAT>,
C<parse_rootdir> are defined (or this is needed for processing of
remaining parts to extract), the corresponding read parts are
interpreted as in MBR_2_partitions(), interpret_bootsector(),
FAT_2array(), interpret_directory().

The corresponding parsed values are put into C<$hash-E<gt>{MBR}>,
C<$hash-E<gt>{bootsector}>; if not parsed, the values are hash
references C<{raw =E<gt> STRING}>.  C<$hash-E<gt>{FAT}> is suitable
for argument of cluster_chain(): it is either a reference to string
representation of the FAT, or to array representation of FAT.

(To avoid overflowing the memory) the FAT is converted to array only
if C<parse_FAT> is defined, I<AND> the number of clusters is below a
certain limit.  The limit is the value of C<parse_FAT> unless 0; if 0,
the default value 3000000 is used (the corresponding memory usage for
array FAT representation is about 60MB).

When bootsector is read, C<$hash-E<gt>{bootsector_offset}> is the actual
offset of bootsector (useful if $offset is actually referencing an
MBR).  Finally, if C<parse_rootdir>'s value is defined,
C<$hash-E<gt>{rootdir_files}> is a reference to array of files in the
root directory, C<$hash-E<gt>{rootdir_ended}> is true if
end-of-directory marker was seen (i.e., the directory ends before the
end of the allocated space); anyway, C<$hash-E<gt>{rootdir_raw}> is
string representation of the root directory.

The keys C<keep_del>, C<keep_dots>, C<keep_labels> are given as
corresponding arguments to interpret_directory().  If values
referenced by C<raw_FAT> is TRUE, or by C<parse_FAT> is undefined,
C<$hash-E<gt>{FAT_raw}> contains a reference to the string
representation of FAT.

=head2 write_dir($fh, $o_root, $d, $b, $FAT, [$how, $depth, $offset, $exists])

recursively extract the content of directory $d (a reference to raw
string representation of the directory as represented on disk).
$depth zero corresponds to no extraction of subdirectories (give
C<undef> or an insanely large number to have unlimited depth; e.g.,
1e100).  $fh should be a file handle representing the disk content
with bootsector at $offset.  $o_root is the output directory: the
files in $d will be put there.

If $exists is TRUE, $o_root exists.  (The parent of $o_root should
always exist.)

$how is an optional hash reference, with values for keys C<keep_del>,
C<keep_dots>, C<keep_labels> giving arguments for
interpret_directory() call.

=head2 write_file($fh, $dir, $file, $b, $FAT [, $offset ] )

Extract $file (should be a hash reference representing a record from a
directory) into a directory $dir.  $fh should be a file handle
representing the disk content with bootsector at $offset.

=head1 EXPORT

None by default.

=head1 EXAMPLES

  perl -MFileSystem::LL::FAT=interpret_directory -wle "
    {local $/; binmode STDIN; $s = <STDIN>}
    (undef,@f) = interpret_directory $s, 1;
    print qq($_->{is_subdir} $_->{cluster}\t$_->{size}\t$_->{name}) for @f"
        < dir-clusters

outputs content of a "directory converted to a file" (may be created
by disasterous B<chkdsk> run), including the starting cluster.

Given an information about the number of "pre-cluster sectors", and
size of the cluster, one can convert the starting cluster number to
starting sector number.  Then one can extract the files by raw-read of
the disk partition:

  $sector = $bootsec->{pre_sectors}
          + ($cluster - 2)*$bootsec->{sectors_in_cluster}
	  = $bootsec->{sector_of_cluster0}
          + $cluster * $bootsec->{sectors_in_cluster}

Likewise, one can inspect a bootsector via

  perl -MFileSystem::LL::FAT=interpret_bootsector,check_bootsector -wle
   "{local $/; binmode STDIN; $s = <STDIN>}
    $b = interpret_bootsector $s; check_bootsector $b;
    print qq($_\t=>\t$b->{$_}) for sort keys %$b"
       < disk.bootsector

On DOSish systems one can read bootsector of drive F<d:> by reading
the first 512 bytes of the file F<\\.\d:>.  E.g., with B<dd> one could
do it as

  dd if=//./d: bs=512 count=1 of=disk.bootsector

On UNIXish systems one needs to find the corresponding device file (by
calling B<mount> or B</sbin/mount>?), and do

  dd if=/dev/hda3 bs=512 count=1 of=disk.bootsector

Other DOSish conventions (see also F<diskext>, F<bootpart>, F<mkbt> programs):

  \\?\Device\Harddisk0\Partition0 	# Partition0 is entire disk
  //./physicaldrive0
  /dev/fd0				# Floppy 0 under CygWin
  /dev/sdc				# physical HDs No. 2 (=c) under CygWin
  /dev/sdc1				# Same, partition 1

Other programs may be used too:

  D:\mkbt20>mkbt -x -c e: c:\bootstrap-e2
  * Expert mode (-x)
  * Copy bootsector mode (-c)

  dd if=//./e: of=c:/bootstrap-e-dd count=16
  dd --list

CygWin's C<dd> may be flacky; you may want to try
L<http://www.chrysocome.net/dd>.  You may need I<"elevated privilige">
under Vista.

=head1 BUGS

When lowercasing non-LFN names, which codepage should one use (and how)?

We ignore LFNs records with C<seq-number E<gt> 0x7F>, unless 0xE5.
When do they appear?

How to follow logical partitions?

Test suite is practically absent...

When recursing into a directory without FAT table present, we assume
that subdirs have size of one cluster.  To do otherwise, need to
check that subsequent clusters are not directories; how to do it?

And how often are directories continuous on disk?

=head1 SEE ALSO

See L<http://en.wikipedia.org/wiki/Fat32>.

=head1 AUTHOR

Ilya Zakharevich, E<lt>ilyaz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
