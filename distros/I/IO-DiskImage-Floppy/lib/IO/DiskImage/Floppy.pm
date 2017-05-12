#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  IO::DiskImage::Floppy
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package IO::DiskImage::Floppy;
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.01';
our $DEBUG = 0;

our $SEEK_SET = 0;
our $SEEK_CUR = 1;

our @SYSTEM_FORMAT = (
	# 0x00
	jmpcode             => 'a3',
	oemlabel            => 'A8',
	bytes_per_sector    => 'v',
	sectors_per_cluster => 'C',
	reserved_sectors    => 'v',
	# 0x10
	nr_fat_tables       => 'C',
	max_root_entries    => 'v',
	nr_sectors          => 'v',
	media_descriptor    => 'C',
	fat_size            => 'v',
	sectors_per_track   => 'v',
	nr_heads            => 'v',
	hidden_sectors      => 'V',
	# 0x20
	large_sectors       => 'V',
	drive_number        => 'C',
	reserved1           => 'a1',
	boot_signature      => 'C',
	volumeid            => 'a4',
	label               => 'A11',
	fslabel             => 'A8',
	# 0x3e(62)
);
our @SYSTEM_KEYS   = do{ my$i=0; grep{ $i^=1 } @SYSTEM_FORMAT };
our $SYSTEM_PACK   = join(' ', @{{@SYSTEM_FORMAT}}{@SYSTEM_KEYS});

our @DIRENTRY_FORMAT = (
	basename      => 'A8',
	extension     => 'A3',
	attribute     => 'C',
	reserved1     => 'a1',
	ctime_10ms    => 'C',
	ctime_time    => 'v',
	ctime_date    => 'v',
	atime_date    => 'v',
	position_high => 'v',
	mtime_time    => 'v',
	mtime_date    => 'v',
	position      => 'v',  # cluster start position.
	size          => 'V',
);
our @DIRENTRY_KEYS   = @DIRENTRY_FORMAT[map{$_*2}0..$#DIRENTRY_FORMAT/2];
our $DIRENTRY_PACK   = join(' ', @{{@DIRENTRY_FORMAT}}{@DIRENTRY_KEYS});

our $ATTR_READONLY    = 0x01;
our $ATTR_HIDDEN      = 0x02;
our $ATTR_SYSTEM      = 0x04;
our $ATTR_VOLUMELABEL = 0x08;
our $ATTR_DIRECTORY   = 0x10;
our $ATTR_FILE        = 0x20;

caller or __PACKAGE__->run(@ARGV);

# -----------------------------------------------------------------------------
# $pkg->run.
#
sub run
{
	my $pkg = shift;
	local($|) = 1;
	
	my $create;
	my $file;
	my @cmd;
	foreach (@_)
	{
		/^(--create)$/      and $create = $1, next;
		/^(-a|--append)$/   and push(@cmd, ['append']),  next;
		/^(-l|--list)$/     and push(@cmd, ['list']),    next;
		/^(-x|--extract)$/  and push(@cmd, ['extract']), next;
		/^(--ipl)$/         and push(@cmd, ['ipl']),     next;
		/^(--ipl-address)$/ and push(@cmd, ['ipl_address']), next;
		/^-/ and $pkg->usage("unknown option: $_");
		defined($file) or $file=$_, next;
		@cmd or $pkg->usage("no operation specified for file $_");
		push(@{$cmd[-1]}, $_);
	}
	
	defined($file) or die "no file specified";
	my $image = $pkg->new(file=>$file, create=>$create);
	
	foreach my $cmd (@cmd)
	{
		my $op = shift @$cmd;
		$image->$op(@$cmd);
	}
}

# -----------------------------------------------------------------------------
# $pkg->usage(msg).
#
sub usage
{
	my $pkg = shift;
	my $msg = shift;
	print "$msg\n";
	print "usage:\n";
	print "  fdimage [options] image-file [files..]\n";
	print "options:\n";
	print "  --create           create new image\n";
	print "  -a|--append file   append file\n";
	print "  -l|--list          list files contained in image\n";
	print "  -x|--extract       extract file from image\n";
	print "  --ipl ipl.img      set ipl image\n";
	exit $msg ? 1 : 0;
}

# -----------------------------------------------------------------------------
# $pkg->new();
#
sub new
{
	my $pkg = shift;
	my $opts = {@_};
	my $mode = $opts->{create} ? '+>' : '+<';
	my $file = $opts->{file};
	$file or die "no file specified";
	
	open(my $fh, $mode, $file) or die "open failed [$file] : $!";
	binmode($fh);
	
	if( $opts->{create} )
	{
		$pkg->_format($fh);
	}
	
	my $this = bless {}, $pkg;
	$this->{file}   = $file;
	$this->{handle} = $fh;
	$this->{system} = undef;
	$this->{ipl_address} = 0x3e;
	$this->_load_system();
	$this;
}

# -----------------------------------------------------------------------------
# $pkg->_format($fh);
#  format image.
#
sub _format
{
	my $pkg = shift;
	my $fh  = shift;
	truncate($fh, 2880*512);
	
	my $system = {
		# 0x00
		jmpcode             => "\xeb\x3c\x90", # jmp +0x3c; noop;
		oemlabel            => "FDIMG.PL",
		bytes_per_sector    => 512,
		sectors_per_cluster => 1,
		reserved_sectors    => 1,
		# 0x10
		nr_fat_tables       => 2,
		max_root_entries    => 224,  # 14 sectors.
		nr_sectors          => 2880,
		media_descriptor    => 0xf0, # f8:harddisk.
		fat_size            => 9,
		sectors_per_track   => 19,
		nr_heads            => 2,
		hidden_sectors      => 0,
		# 0x20
		large_sectors       => 0,
		drive_number        => 0,
		reserved1           => 0,
		boot_signature      => 0x29, # (?)
		volumeid            => pack("C4",map{rand(256)}1..4),
		label               => 'NO NAME    ',
		fslabel             => 'FAT12   ',
		# 0x3e(62)
	};
	my $data = pack($SYSTEM_PACK, @$system{@SYSTEM_KEYS});
	$data .= "\0"x(512-2-length($data));
	$data .= "\x55\xaa";
	seek($fh, 0, $SEEK_SET) or die "seek failed: $!";
	print $fh $data;
	
	# FAT reserved cluster.
	seek($fh, 512, $SEEK_SET) or die "seek failed: $!";
	print $fh "\xf0\xff\xff";
	# FAT reserved  cluster(spare).
	seek($fh, 10*512, $SEEK_SET) or die "seek failed: $!";
	print $fh "\xf0\xff\xff";
	
	$fh;
}

# -----------------------------------------------------------------------------
# $obj->_load_system()
#
sub _load_system()
{
	my $this = shift;
	seek($this->{handle}, 0, $SEEK_SET) or die "seek failed: $!";
	my $read_len = read($this->{handle}, my $data, 62);
	defined($read_len) or die "read failed: $!";
	$read_len!=62 and die "read few data ($read_len/62)";
	
	my $system = {};
	$system->{header} = $data;
	@$system{@SYSTEM_KEYS} = unpack($SYSTEM_PACK, $data);
	$this->{system} = $system;
	#print Dumper($this->{system});use Data::Dumper;
	$this;
}

# -----------------------------------------------------------------------------
# $obj->list()
#
sub list()
{
	my $this = shift;
	$this->_list(sub{
		my $dirent = shift;
		# drwxr-xr-x root/root         0 2006-11-07 18:28:52 l_cc_c_9.1.045/
		my $is_dir      = $dirent->{attribute} & $ATTR_DIRECTORY;
		my $is_readonly = $dirent->{attribute} & $ATTR_READONLY;
		my $attr = '';
		$attr .= $is_dir ? 'd' : '-';
		$attr .= 'r';
		$attr .= !$is_readonly ? 'w' : '-';
		$attr .= 'x';
		my $mtime = sprintf('%04d-%02d-%02d %02d:%02d:%02d',
			($dirent->{mtime_date}>>9)+1980,
			($dirent->{mtime_date}>>5)&15,
			($dirent->{mtime_date}>>0)&31,
			($dirent->{mtime_time}>>11)&31,
			($dirent->{mtime_time}>>5)&63,
			($dirent->{mtime_time}&31)<<1);
		my $dot = $dirent->{extension} ne '' ? '.' : '';
		print sprintf("%s %7d  %s  %-8s%s%-3s\n", $attr, $dirent->{size}, $mtime, $dirent->{basename}, $dot, $dirent->{extension});
	});
}

# -----------------------------------------------------------------------------
# $obj->_list(\&callback)
#
sub _list
{
	my $this = shift;
	my $cb = shift or die "no callback for _list";
	
	my $system = $this->{system};
	my $pos = $system->{reserved_sectors} + $system->{fat_size} * $system->{nr_fat_tables};
	seek($this->{handle}, $pos*512, $SEEK_SET) or die "seek failed: $!";
	for( my $i=0; $i<$system->{max_root_entries}-1; ++$i )
	{
		my $read_len = read($this->{handle}, my $data, 32);
		defined($read_len) or die "read failed: $!";
		$read_len!=32 and die "read few data ($read_len/32)";
		my %dirent;
		@dirent{@DIRENTRY_KEYS} = unpack($DIRENTRY_PACK, $data);
		$dirent{attribute}==0x0f and next; # Long File Name.
		$dirent{basename} =~ /^\0/  and last;
		$dirent{basename} =~ /[^ ]/ or  next;
		$cb->(\%dirent, @_);
	}
}

# -----------------------------------------------------------------------------
# $obj->extract($file)
#
sub extract
{
	my $this = shift;
	my $file = shift;
	defined($file) or die "no file specified for extract";
	my $file_uc = $file; $file_uc =~ tr/a-z/A-Z/;
	my $found;
	$this->_list(sub{
		my $dirent = shift;
		my $got = $dirent->{basename};
		$dirent->{extension} ne '' and $got .= ".$dirent->{extension}";
		$got =~ tr/a-z/A-Z/;
		$got eq $file_uc and $found = $dirent;
	});
	
	if( !$found )
	{
		print "no such file in image [$file]\n";
		return;
	}
	
	# found.
	my $system = $this->{system};
	my $fatsect  = $system->{reserved_sectors};
	my $basesect = $system->{reserved_sectors}
	             + $system->{fat_size} * $system->{nr_fat_tables}
	             + $system->{max_root_entries} * 32 / 512;
	my $data = '';
	my $cluster = $found->{position};
	my $ENDMARK = 0x0FF0;
	do
	{
		#print sprintf("cluster %d (0x%x)\n", $cluster, $cluster);
		if( $cluster<=0x0001 || $cluster>=$ENDMARK )
		{
			die "invalid cluster index found: $cluster";
		}
		# read cluster data.
		seek($this->{handle}, ($basesect+$cluster-2)*512, $SEEK_SET) or die "seek failed: $!";
		my $read_len = read($this->{handle}, $data, 512, length($data));
		defined($read_len) or die "read failed: $!";
		$read_len!=512 and die "read few data ($read_len/512)";
		# find next cluster.
		my $offset = int($cluster*3/2);
		#print sprintf("x1.5 %d (0x%x)\n", $offset, $offset);
		my $r = $fatsect+int($offset/512);
		#print sprintf("sect %d (0x%x)\n", $r, $r);
		seek($this->{handle}, ($fatsect+int($offset/512))*512, $SEEK_SET) or die "seek failed: $!";
		$read_len = read($this->{handle}, my $fat, 512);
		defined($read_len) or die "read failed: $!";
		$read_len!=512 and die "read few data ($read_len/512)";
		my $odd = $cluster & 1;
		$cluster = unpack("v", substr($fat, $offset&511, 2));
		#print sprintf("next %d (0x%x)\n", $cluster, $cluster);
		$odd and $cluster >>= 4;
		#print sprintf("next %d (0x%x)\n", $cluster, $cluster);
		$cluster &= 0x0FFF;
		#print sprintf("next %d (0x%x)\n", $cluster, $cluster);
	} while( $cluster<0x0FF0 );
	$data = substr($data, 0, $found->{size});
	
	open(my $fh, '>', $file) or die "could not open file for output [$file] : $!";
	print $fh $data;
	close $fh;
	return $this;
}

# -----------------------------------------------------------------------------
# $obj->append($file)
#
sub append
{
	my $this = shift;
	my $file = shift;
	defined($file) or die "no file specified for extract";
	$file =~ /^(\w{1,8})(?:\.\w{1,3})$/ or die "not 8.3 file name [$file]";
	my $file_uc = $file; $file_uc =~ tr/a-z/A-Z/;
	
	my @st;
	my $data = do {
		open(my $fh, '<', $file) or die "could not open file [$file]: $!";
		@st = stat($fh);
		local($/) = undef;
		my $tmp = <$fh>;
		close $fh;
		$tmp;
	};
	
	my $system = $this->{system};
	
	# find data spaces.
	my @spaces;
	{
		my $table = '';
		my $available_sectors = $system->{nr_sectors}
		                      - $system->{reserved_sectors}
		                      - ($system->{fat_size} * $system->{nr_fat_tables})
		                      - ($system->{max_root_entries} * 32 / 512);
		$DEBUG and print STDERR "find sectors, fat at $system->{reserved_sectors}, $available_sectors clusters\n";
		seek($this->{handle}, $system->{reserved_sectors}*512, $SEEK_SET) or die "seek failed: $!";
		for( my $i=0; $i<$available_sectors; ++$i )
		{
			if( length($table)<2 )
			{
				my $read_len = read($this->{handle}, $table, 512, length $table);
				defined($read_len) or die "read failed: $!";
				$read_len!=512 and die "read few data ($read_len/512)";
				$i==2 and $table =~ s/^...//s;
				#print unpack("H*", $table)."\n";
			}
			my $cluster = unpack("v", $table);
			#print sprintf("%d %04x\n", $i, $cluster);
			if( $i&1 )
			{
				$table =~ s/^..//s;
				$cluster >>= 4;
			}else
			{
				$table =~ s/^.//s;
			}
			$cluster &= 0x0FFF;
			$DEBUG and print sprintf("$i: %03x \n", $cluster);
			$cluster==0 or next;
			push(@spaces, $i);
			@spaces*512>= length($data) and last;
		}
		if( @spaces*512<length($data) )
		{
			die "no space left";
		}
	}
	
	# find directory entry.
	my $newentry;
	my $space;
	my $sect = $system->{reserved_sectors} + $system->{fat_size} * $system->{nr_fat_tables};
	seek($this->{handle}, $sect*512, $SEEK_SET) or die "seek failed: $!";
	my $index = 0;
	for( $index=0; $index<$system->{max_root_entries}; ++$index )
	{
		my $read_len = read($this->{handle}, my $data, 32);
		defined($read_len) or die "read failed: $!";
		$read_len!=32 and die "read few data ($read_len/32)";
		my %dirent;
		@dirent{@DIRENTRY_KEYS} = unpack($DIRENTRY_PACK, $data);
		$dirent{attribute}==0x0f and next; # Long File Name.
		$dirent{basename} eq ''      and $space||=$index,last;
		$dirent{basename} =~ /^\0/   and $space||=$index,last;
		$dirent{basename} =~ /^\xe5/ and $space||=$index,next;
		$dirent{basename} =~ /^\x05/ and $space||=$index,next;
		$dirent{basename} =~ /[^ ]/  or  $space||=$index,next;
		#
		my $got = $dirent{basename};
		$dirent{extension} ne '' and $got .= ".$dirent{extension}";
		$got =~ tr/a-z/A-Z/;
		if( $got eq $file_uc )
		{
			$newentry = \%dirent;
			last;
		}
	}
	if( !defined($space) && !$newentry )
	{
		die "no space on root entry";
	}
	
	# update data space.
	{
		my $basesect = $system->{reserved_sectors}
		             + $system->{fat_size} * $system->{nr_fat_tables}
		             + $system->{max_root_entries} * 32 / 512;
		foreach my $i (0..$#spaces)
		{
			seek($this->{handle}, ($basesect+$spaces[$i]-2)*512, $SEEK_SET) or die "seek failed: $!";
			print {$this->{handle}} substr($data, $i*512, 512);
		}
	}
	# update fat entry.
	{
		my $fatsect  = $system->{reserved_sectors};
		seek($this->{handle}, $fatsect*512, $SEEK_SET) or die "seek failed: $!";
		my $read_len = read($this->{handle}, my $fat_table, 512*$system->{fat_size});
		defined($read_len) or die "read failed: $!";
		$read_len!=512*$system->{fat_size} and die "read few data ($read_len/512*$system->{fat_size})";
		
		foreach my $i (0..$#spaces)
		{
			my $odd = $spaces[$i] & 1;
			my $offset = int($spaces[$i]*3/2);
			my $cluster = unpack("v", substr($fat_table, $offset, 2));
			my $next = $i==$#spaces ? 0x0FFF : $spaces[$i+1];
			if( !$odd )
			{
				$cluster &= 0xF000;
				$cluster |= $next;
			}else
			{
				$cluster &= 0x000F;
				$cluster |= $next<<4;
			}
			substr($fat_table, $offset, 2, pack('v', $cluster));
		}
		seek($this->{handle}, $fatsect*512, $SEEK_SET) or die "seek failed: $!";
		print {$this->{handle}} $fat_table;
	}
	
	# update directory entry.
	if( $newentry )
	{
		# update.
		seek($this->{handle}, -32, $SEEK_CUR) or die "seek failed: $!";
	}else
	{
		# create.
		my $pos = $sect*512 + $space*32;
		#print sprintf("create: sect  = %d (0x%x)\n", $sect, $sect);
		#print sprintf("create: space = %d (0x%x)\n", $space, $space);
		#print sprintf("create: pos   = %d (0x%x)\n", $pos, $pos);
		seek($this->{handle}, $pos, $SEEK_SET) or die "seek failed: $!";
		my ($base,$ext)= split(/\./, $file);
		$newentry->{basename}      = uc($base);
		$newentry->{extension}     = defined($ext) ? uc($ext) : '';
		$newentry->{attribute}     = $ATTR_FILE;
		$newentry->{reserved1}     = "\0";
		$newentry->{position_high} = 0;
	}
	my ($ST_ATIME, $ST_MTIME, $ST_CTIME) = (8, 9, 10);
	my @ctime = gmtime($st[$ST_CTIME]);
	my @mtime = gmtime($st[$ST_MTIME]);
	my @atime = gmtime($st[$ST_ATIME]);
	$newentry->{ctime_10ms}      = ($ctime[0]%2)*100;
	$newentry->{ctime_time}    = ($ctime[2]<<11) + ($ctime[1]<<5) + ($ctime[0]>>1);
	$newentry->{ctime_date}    = (($ctime[5]-1980)<<9) + (($ctime[4]+1)<<5) + $ctime[3];
	$newentry->{atime_date}    = (($atime[5]-1980)<<9) + (($atime[4]+1)<<5) + $atime[3];
	$newentry->{mtime_time}    = ($mtime[2]<<11) + ($mtime[1]<<5) + ($mtime[0]>>1);
	$newentry->{mtime_date}    = (($mtime[5]-1980)<<9) + (($mtime[4]+1)<<5) + $mtime[3];
	$newentry->{position}      = $spaces[0];
	$newentry->{size}          = length $data;
	
	my $de = pack($DIRENTRY_PACK, @$newentry{@DIRENTRY_KEYS});
	length($de)==32 or die "direntry size not 32";
	print {$this->{handle}} $de;
	
	#print "updated.\n";
	$this;
}

# -----------------------------------------------------------------------------
# $obj->ipl_address()
# $obj->ipl_address($addr)
#
sub ipl_address
{
	my $this = shift;
	my $addr = shift;
	if( defined($addr) )
	{
		$addr =~ /^0x([0-9a-fA-F]+)$/ and $addr = hex($1);
		$addr =~ /^(\d+$)/ or die "ipl_address is not numeric: $addr";
		$addr>=0xfe and die "ipl_address too large: $addr";
		$this->{ipl_address} = $addr;
	}else
	{
		my $hex = sprintf('0x%x', $this->{ipl_address});
		print "ipl-address: $hex ($this->{ipl_address})\n";
	}
	$this;
}

# -----------------------------------------------------------------------------
# $obj->ipl($file)
#
sub ipl
{
	my $this = shift;
	my $file = shift;
	if( defined($file) )
	{
		open(my $fh, '<', $file) or die "could not open file [$file]: $!";
		local($/);
		my $data = <$fh>;
		close $fh;
		my $size = length($data);
		$this->{ipl_address}+$size >= 0xfe and die "ipl image too large: $size";
		seek($this->{handle}, $this->{ipl_address}, $SEEK_SET) or die "seek failed: $!";
		print {$this->{handle}} $data;
		$this;
	}else
	{
		my $size = 0xfe - $this->{ipl_address};
		seek($this->{handle}, $this->{ipl_address}, $SEEK_SET) or die "seek failed: $!";
		my $read_len = read($this->{handle}, my $data, $size);
		defined($read_len) or die "read failed: $!";
		$read_len!=$size and die "read few data ($read_len/$size)";
		binmode(STDOUT);
		print $data;
	}
}

# -----------------------------------------------------------------------------
# End of Module.
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT

=head1 NAME

IO::DiskImage::Floppy - manipulate fdd (FAT12) image.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

 $ fdimage.pl [options] image-file [files...]
 $ perl File::FDImage -e 'File::FDImage->run(@ARGV)' ...
 
	options:
	  --create           create new image
	  -a|--append file   append file
	  -l|--list          list files contained in image
	  -x|--extract       extract file from image

=head1 EXPORT

no functions exported.

=head1 METHODS

=head2 $pkg->new(..)

 file => $file:   image file
 create => $bool: create new image.

=head2 $obj->append(@files)

append files into image.

=head2 $obj->list()

show contained files.

=head2 $obj->extract(@files)

extract files from image.

=head2 $obj->ipl($file)

set ipl image.

=head2 $obj->ipl_address([$addr])

if argument is passed, set ipl start address.
otherwise print ipl start address.

=head2 $obj->usage([$msg])

show usage.

=head2 $obj->run(@ARGV)

run commands.

=head1 LIMITATIONS

 - directories are not implemented yet.
 - delete entrty is not imelemented yet.

=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-io-diskimage-floppy at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-DiskImage-Floppy>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::DiskImage::Floppy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-DiskImage-Floppy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-DiskImage-Floppy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-DiskImage-Floppy>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-DiskImage-Floppy>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 YAMASHINA Hio, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of IO::DiskImage::Floppy
