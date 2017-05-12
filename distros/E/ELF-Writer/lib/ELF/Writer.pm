package ELF::Writer;
use Moo 2;
use Carp;
use IO::File;
BEGIN {
	# Check if we need a wrapper for 'pack'
	eval "use ELF::Writer::PackWrapper 'pack'"
		unless eval{ pack('Q<',1) };
}
use namespace::clean;

our $VERSION= '0.011';

# ABSTRACT: Encode elf files with pure-perl


sub _init_enum {
	my ($to_sym, $from_sym, @name_to_num)= @_;
	%$from_sym= @name_to_num;
	%$to_sym= reverse @name_to_num;
}


our (%class_to_sym, %class_from_sym);
_init_enum(\%class_to_sym, \%class_from_sym,
	'32bit' => 1,
	'64bit' => 2,
);

has class => ( is => 'rw', coerce => sub {
	my $x= $class_from_sym{$_[0]};
	defined $x? $x
		: (int($_[0]) == $_[0])? $_[0]
		: croak "$_[0] is not a valid 'class'"
});

sub class_sym {
	my $self= shift;
	$self->class($_[0]) if @_;
	my $v= $self->class;
	$class_to_sym{$v} || $v
}


our (%data_to_sym, %data_from_sym);
_init_enum(\%data_to_sym, \%data_from_sym,
	'2LSB' => 1,
	'2MSB' => 2,
);

has data => ( is => 'rw', coerce => sub {
	my $x= $data_from_sym{$_[0]};
	defined $x? $x
		: (int($_[0]) == $_[0])? $_[0]
		: croak "$_[0] is not a valid 'data'"
});

sub data_sym {
	my $self= shift;
	$self->data($_[0]) if @_;
	my $v= $self->data;
	$data_to_sym{$v} || $v
}


has header_version  => ( is => 'rw', default => sub { 1 } );


our (%osabi_to_sym, %osabi_from_sym);
_init_enum(\%osabi_to_sym, \%osabi_from_sym,
	'SystemV'  => 0,
	'HP-UX'    => 1,
	'NetBSD'   => 2,
	'Linux'    => 3,
	'Solaris'  => 6,
	'AIX'      => 7,
	'IRIX'     => 8,
	'FreeBSD'  => 9,
	'OpenBSD'  => 0x0C,
	'OpenVMS'  => 0x0D,
);

has osabi => ( is => 'rw', coerce => sub {
	my $x= $osabi_from_sym{$_[0]};
	defined $x? $x
		: (int($_[0]) == $_[0])? $_[0]
		: croak "$_[0] is not a valid 'osabi'"
});

sub osabi_sym {
	my $self= shift;
	$self->osabi($_[0]) if @_;
	my $v= $self->osabi;
	$osabi_to_sym{$v} || $v
}


has osabi_version   => ( is => 'rw', default => sub { 0 } );

our (%type_to_sym, %type_from_sym);
_init_enum(\%type_to_sym, \%type_from_sym,
	'none'        => 0,
	'relocatable' => 1,
	'executable'  => 2,
	'shared'      => 3,
	'core'        => 4,
);

has type => ( is => 'rw', coerce => sub {
	my $x= $type_from_sym{$_[0]};
	defined $x? $x
		: (int($_[0]) == $_[0])? $_[0]
		: croak "$_[0] is not a valid 'type'"
});

sub type_sym {
	my $self= shift;
	$self->type($_[0]) if @_;
	my $v= $self->type;
	$type_to_sym{$v} || $v
}


our (%machine_to_sym, %machine_from_sym);
_init_enum(\%machine_to_sym, \%machine_from_sym,
	'SPARC'       => 0x02,
	'i386'        => 0x03,
	'Motorola68K' => 0x04,
	'Motorola88K' => 0x05,
	'i860'        => 0x07,
	'MIPS-RS3000' => 0x08,
	'MIPS-RS4000' => 0xA0,
	'PowerPC'     => 0x14,
	'ARM'         => 0x28,
	'SuperH'      => 0x2A,
	'IA-64'       => 0x32,
	'x86-64'      => 0x3E,
	'AArch64'     => 0xB7,
);

has machine => ( is => 'rw', coerce => sub {
	my $x= $machine_from_sym{$_[0]};
	defined $x? $x
		: (int($_[0]) == $_[0])? $_[0]
		: croak "$_[0] is not a valid 'machine'"
});

sub machine_sym {
	my $self= shift;
	$self->machine($_[0]) if @_;
	my $v= $self->machine;
	$machine_to_sym{$v} || $v
}


has version         => ( is => 'rw', default => sub { 1 } );

has flags           => ( is => 'rw', default => sub { 0 } );

has entry_point     => ( is => 'rw' );


our $Magic= "\x7fELF";

sub elf_header_len {
	my $class= shift->class;
	return $class == 1? 52
		: $class == 2? 64
		: croak "Don't know structs for elf class $class";
}
our @Elf_Header_Pack= (
	'a4 C C C C C a7 v v V V V V V v v v v v v', # 32-bit LE
	'a4 C C C C C a7 n n N N N N N n n n n n n', # 32-bit BE
	'a4 C C C C C a7 v v V Q< Q< Q< V v v v v v v', # 64-bit LE
	'a4 C C C C C a7 n n N Q> Q> Q> N n n n n n n', # 64-bit BE
);
sub _elf_header_packstr {
	my ($self, $encoding)= @_;
	$encoding= $self->_encoding unless defined $encoding;
	$Elf_Header_Pack[ $encoding ];
}

sub segment_header_elem_len {
	my $class= shift->class;
	return $class == 1? 32
		: $class == 2? 56
		: croak "Don't know structs for elf class $class";
}
# Note! there is also a field swap between 32bit and 64bit
our @Segment_Header_Pack= (
	'V V V V V V V V',
	'N N N N N N N N',
	'V V Q< Q< Q< Q< Q< Q<',
	'N N Q> Q> Q> Q> Q> Q>',
);
sub _segment_header_packstr {
	my ($self, $encoding)= @_;
	$encoding= $self->_encoding unless defined $encoding;
	$Segment_Header_Pack[ $encoding ];
}

sub section_header_elem_len {
	my $class= shift->class;
	return $class == 1? 40
		: $class == 2? 64
		: croak "Don't know structs for elf class $class";
}
our @Section_Header_Pack= (
	'V V V V V V V V V V',
	'N N N N N N N N N N',
	'V V Q< Q< Q< Q< V V Q< Q<',
	'N N Q> Q> Q> Q> N N Q> Q>',
);
sub _section_header_packstr {
	my ($self, $encoding)= @_;
	$encoding= $self->_encoding unless defined $encoding;
	$Section_Header_Pack[ $encoding ];
}

# Returns a number 0..3 used by the various routines when packing binary data
sub _encoding {
	my $self= shift;
	my $endian= $self->data;
	my $bits=   $self->class;
	defined $endian && $endian > 0 && $endian < 3 or croak "Can't encode for data=$endian";
	defined $bits && $bits > 0 && $bits < 3 or croak "Can't encode for class=$bits";
	return ($bits-1)*2 + ($endian-1);
}


has segments => ( is => 'rw', coerce => \&_coerce_segments, default => sub { [] } );
sub segment_count { scalar @{ shift->segments } }
sub segment_list { @{ shift->segments } }


has sections => ( is => 'rw', coerce => \&_coerce_sections, default => sub { [] } );
sub section_count { scalar @{ shift->sections } }
sub section_list { @{ shift->sections } }

has section_name_string_table_idx => ( is => 'rw' );


sub serialize {
	my $self= shift;
	
	# Faster than checking bit lengths on every field ourself
	use warnings FATAL => 'pack';
	
	# Make sure all required attributes are defined
	defined($self->$_) || croak "Attribute $_ is not defined"
		for qw( class data osabi type machine header_version osabi_version version entry_point );
	
	# Clone the segments and sections so that our changes don't affect the
	# configuration the user built.
	my @segments= map { $_->clone } $self->segment_list;
	my @sections= map { $_->clone } $self->section_list;
	my $segment_table;
	my $section_table;
	
	# Now apply defaults and set numbering for diagostics of errors
	my $i= 0;
	for (@segments) {
		$_->_index($i++);
		$self->_apply_segment_defaults($_);
		
		# There can be one segment which loads the segment table itself
		# into the program's address space.  If used, we track the pointer
		# to that segment.  We also clear it's 'data' and set it's 'size'
		# to keep from confusing the code below.
		if ($_->type == 6) {
			croak "There can be only one segment of type 'phdr'"
				if defined $segment_table;
			$segment_table= $_;
			$segment_table->data(undef);
			$segment_table->size($self->segment_header_len * @segments);
		}
	}
	$i= 0;
	for (@sections) {
		$_->_index($i++);
		$self->_apply_section_defaults($_);
	}
	
	# Build a list of every defined range of data in the file,
	# and a list of every segment/section which needs automatically placed.
	my @defined_ranges;
	my @auto_offset;
	for (@segments, @sections) {
		# size is guaranteed to be defined by "_apply...defaults()"
		# Data might not be defined if the user just wanted to point the
		# segment at something, and offset might not be defined if the user
		# just wants it appended wherever.
		if (!defined $_->offset) {
			push @auto_offset, $_;
		}
		else {
			$_->offset >= 0 or croak $_->_name." offset cannot be negative";
			push @defined_ranges, $_
				if defined $_->data && length $_->data;
		}
	}
	
	if (@sections) {
		# First section must always be the NULL section.  If the user forgot this
		# then their indicies might be off.
		$sections[0]->type == 0
			or croak "Section 0 must be type NULL";
		# Sections may not overlap, regardless of whether the user attached data to them
		my $prev_end= 0;
		my $prev;
		for (sort { $a->offset <=> $b->offset } $self->section_list) {
			croak 'Section overlap between '.$_->_name.' and '.$prev->_name
				if $_->offset < $prev_end;
			$prev_end= $_->offset + $_->size;
		}
	}
	
	# Each segment and section can define data to be written to the file,
	# but segments can overlap sections.  Make sure their defined data doesn't
	# conflict, or we wouldn't know which to write.
	my $prev;
	my $prev_end= $self->elf_header_len;
	my $first_data;
	@defined_ranges= sort { $a->data_offset <=> $b->data_offset } @defined_ranges;
	for (@defined_ranges) {
		croak 'Data overlap between '.$_->_name.' and '.($prev? $prev->_name : 'ELF header')
			if $_->data_offset < $prev_end;
		$prev= $_;
		$prev_end= $_->data_offset + $_->size;
	}
	
	# For each segment or section that needs an offset assigned, append to
	# end of file.
	for (@auto_offset) {
		my $align= $_->_required_file_alignment;
		$prev_end= int(($prev_end + $align - 1) / $align) * $align;
		$_->offset($prev_end);
		push @defined_ranges, $_ if defined $_->data && length $_->data;
		$prev_end += $_->size;
	}
	
	# Now, every segment and section have an offset and a length.
	# We can now encode the tables.
	my @insert;
	if (@segments) {
		my $segment_table_data= '';
		$segment_table_data .= $self->_serialize_segment_header($_)
			for @segments;
		# The user might have defined this segment on their own.
		# Otherwise we just create a dummy to use below.
		if (!defined $segment_table) {
			$segment_table= ELF::Writer::Segment->new(
				align => ($self->class == 2? 8 : 4),
				filesize => length($segment_table_data),
				data => $segment_table_data,
			);
			push @insert, $segment_table;
		} else {
			$segment_table->data($segment_table_data);
		}
	}
	if (@sections) {
		my $section_table_data= '';
		$section_table_data .= $self->_serialize_section_header($_)
			for @sections;
		
		$section_table= ELF::Writer::Segment->new(
			align => ($self->class == 2? 8 : 4),
			filesize => length($section_table_data),
			data => $section_table_data,
		);
		push @insert, $section_table;
	}
	
	# Find a spot for the segment and/or section tables.
	# Due to alignment, there is probably room to squeeze the table(s) inbetween
	# other defined ranges.  Else, put them at the end.
	$prev_end= $self->elf_header_len;
	for (my $i= 0; @insert and $i <= @defined_ranges; ++$i) {
		my $align= $insert[0]->_required_file_alignment;
		$prev_end= int(($prev_end + $align-1) / $align) * $align;
		if ($i == @defined_ranges
			or $prev_end + $insert[0]->size <= $defined_ranges[$i]->data_offset
		) {
			$insert[0]->offset($prev_end);
			splice @defined_ranges, $i, 0, shift @insert;
		}
	}
	
	# Now, we can finally encode the ELF header.
	my $header= pack($self->_elf_header_packstr,
		$Magic, $self->class, $self->data, $self->header_version,
		$self->osabi, $self->osabi_version, '',
		$self->type, $self->machine, $self->version, $self->entry_point,
		($segment_table? $segment_table->offset : 0),
		($section_table? $section_table->offset : 0),
		$self->flags, $self->elf_header_len,
		$self->segment_header_elem_len, $self->segment_count,
		$self->section_header_elem_len, $self->section_count,
		$self->section_name_string_table_idx || 0,
	);
	# sanity check
	length($header) == $self->elf_header_len
		or croak "Elf header len mismatch";
	
	# Write out the header and each range of defined bytes, padded with NULs as needed.
	my $data= $header;
	for (@defined_ranges) {
		my $pad= $_->data_offset - length($data);
		$data .= "\0" x $pad if $pad;
		$data .= $_->data;
	}
	return $data;
}

sub _serialize_segment_header {
	my ($self, $seg)= @_;
	
	# Faster than checking bit lengths on every field ourself
	use warnings FATAL => 'pack';
	
	# Make sure all required attributes are defined
	defined $seg->$_ or croak "Attribute $_ is not defined"
		for qw( type offset virt_addr align );
	
	my $filesize= $seg->filesize;
	$filesize= length($seg->data) + $seg->data_offset
		unless defined $filesize;
	
	my $align= $seg->align;
	my $memsize= $seg->memsize;
	$memsize= int(($filesize + $align - 1) / $align) * $align
		unless defined $memsize;
	
	# 'flags' moves depending on 32 vs 64 bit, so changing the pack string isn't enough
	return $self->_encoding < 2?
		pack($self->_segment_header_packstr,
			$seg->type, $seg->offset, $seg->virt_addr, $seg->phys_addr || 0,
			$filesize, $memsize, $seg->flags, $seg->align
		)
		: pack($self->_segment_header_packstr,
			$seg->type, $seg->flags, $seg->offset, $seg->virt_addr,
			$seg->phys_addr || 0, $filesize, $memsize, $seg->align
		);
}

sub _serialize_section_header {
	my ($self, $sec)= @_;
	
	# Make sure all required attributes are defined
	defined $sec->$_ or croak "Attribute $_ is not defined"
		for qw( type name flags addr offset size link info addralign entsize );
	
	# Faster than checking bit lengths on every field ourself
	use warnings FATAL => 'pack';
	
	return pack($self->_section_header_packstr,
		$sec->name, $sec->type, $sec->flags, $sec->addr, $sec->offset,
		$sec->size, $sec->link, $sec->info, $sec->align, $sec->entry_size
	);
}


sub write_file {
	my ($self, $filename, $mode)= @_;
	$mode= 0755 unless defined $mode;
	require File::Temp;
	my ($fh, $tmpname)= File::Temp::tempfile( $filename.'-XXXXXX' );
	print $fh $self->serialize or croak "write: $!";
	close $fh or croak "close: $!";
	chmod($mode, $tmpname) or croak "chmod: $!";
	rename($tmpname, $filename) or croak "rename: $!";
}

# coerce arrayref of hashrefs into arrayref of objects
sub _coerce_segments {
	my $spec= shift;
	return [ map { (__PACKAGE__.'::Segment')->coerce($_) } @$spec ];
}

# coerce arrayref of hashrefs into arrayref of objects
sub _coerce_sections {
	my $spec= shift;
	return [ map { (__PACKAGE__.'::Section')->coerce($_) } @$spec ];
}

# Overridden by subclasses for machine-specific defaults
sub _apply_section_defaults {
	my ($self, $sec)= @_;
	# Undef type is "null" type 0
	my $type= $sec->type;
	defined $type
		or $sec->type($type= 0);
	my $offset= $sec->offset;
	my $size= $sec->size;
	
	if ($type == 0) { # 'null'
		# Ensure length and offset are zero
		$size= $sec->size(0) unless defined $size;
		$offset= $sec->offset(0) unless defined $offset;
		croak "null section should have offset=0 and size=0"
			if $offset || $size;
	}
	elsif ($type == 8) { # 'nobits'
		# Offset can be set but ensure size is zero
		$size= $sec->size(0) unless defined $size;
		croak "nobits section should have size=0"
			if $size;
		
	}
	else {
		# 'size' is required, but can be computed from 'data' and 'data_offset'.
		if (!defined $size) {
			defined $sec->data or croak "Section must define 'size' or 'data'"; 
			$sec->size($sec->data_start + length($sec->data));
		}
	}
}

# Overridden by subclasses for machine-specific defaults
sub _apply_segment_defaults {
	my ($self, $seg)= @_;
	# Undef type is "null" type 0
	my $type= $seg->type;
	defined $type
		or $seg->type($type= 0);
	my $offset= $seg->offset;
	my $filesize= $seg->filesize;
	
	if ($type == 0) { # 'null'
		# Ensure length and offset are zero
		$filesize= $seg->filesize(0) unless defined $filesize;
		$offset= $seg->offset(0) unless defined $offset;
		croak "null segment should have offset=0 and filesize=0"
			if $offset || $filesize;
	}
	else {
		# 'filesize' is required, but can be computed from 'data' and 'data_offset'
		if (!defined $filesize) {
			defined $seg->data or croak "Segment must define 'filesize' or 'data'";
			$filesize= $seg->filesize($seg->data_start + length($seg->data));
		}
		# Default memsize to filesize
		$seg->memsize($filesize) unless defined $seg->memsize;
	}
}

# Loaded last, to make sure all data in this module is initialized
require ELF::Writer::Segment;
require ELF::Writer::Section;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELF::Writer - Encode elf files with pure-perl

=head1 VERSION

version 0.011

=head1 SYNOPSIS

  my $elf= ELF::Writer::Linux_x86_64->new(
    type => 'executable',
    segments => [{
      virt_addr   => 0x10000,
      data        => $my_machine_code,
    }],
    entry_point => 0x10000,
  );
  $elf->write_file($binary_name);
  
  # Example above wastes almost 4K to align the first segment.
  # We can overlap the first segment with the elf header, so that the entire
  # file gets paged into RAM, but then the entry point needs adjusted by the
  # size of the ELF headers.
  
  my $prog_offset= $elf->elf_header_len + $elf->segment_header_elem_len;
  $elf->segments->[0]->offset(0);
  $elf->segments->[0]->data_start( $prog_offset );
  $elf->entry_point( $elf->segments->[0]->virt_addr + $prog_offset );

=head1 MODULE STATUS

I wrote this module while learning the ELF format, so this is not the work of an
expert.  But, since there wasn't anything on CPAN yet, I decided to implement as
complete an API as I could and release it.  Bug reports are very welcome.

=head1 DESCRPTION

This module lets you define the attributes, segments, and sections of the ELF
specification, and then serialize it to a file.  All data must reside in
memory before writing, so this module is really just a very elaborate call to
'pack'.  This module also assumes you know how an ELF file is structured,
and the purpose of Segments and Sections.  Patches welcome for adding
user-friendly features and sanity checks.

=head1 ATTRIBUTES

B<Note on enumerated values>: The ELF format has enumerations for many of its
fields which are left open-ended to be extended in the future.  Also, the symbolic
names seem to differ between various sources, so it was difficult to determine
what the official names should be.  My solution was to store the attribute as the
numeric value, but auto-convert symbolic names, and allow access to the symbolic
name by a second attribute accessor with suffix "_sym".

=head2 class, class_sym

8-bit integer, or one of: C<"32bit"> or C<"64bit">.  Must be set before writing.

=head2 data, data_sym

8-bit integer, or one of: C<"2LSB"> or C<"2MSB">. (2's complement least/most
significant byte first)  i.e. little-endian or big-endian

Must be set before writing.

=head2 header_version

8-bit integer; defaults to '1' for original version of ELF.

=head2 osabi, osabi_sym

8-bit integer, or one of: C<"SystemV">, C<"HP-UX">, C<"NetBSD">, C<"Linux">, C<"Solaris">,
C<"AIX">, C<"IRIX">, C<"FreeBSD">, C<"OpenBSD">, C<"OpenVMS">.  Must be set before writing.

=head2 osabi_version

Depends on osabi.  Not used for Linux.  Defaults to 0.

=head2 type, type_sym

16-bit integer, or one of: C<"relocatable">, C<"executable">, C<"shared">, C<"core">.
Must be set before writing.

=head2 machine, machine_sym

16-bit integer, or one of: C<"Sparc">, C<"x86">, C<"MIPS">, C<"PowerPC">, C<"ARM">, C<"SuperH">,
C<"IA-64">, C<"x86-64">, C<"AArch64">.

=head2 version

32-bit integer; defaults to C<1> for original version of ELF.

=head2 entry_point

32-bit or 64-bit pointer to address where process starts executing.
Defaults to C<0> unless type is C<"executable">, then you must specify it before
writing.

=head2 flags

32 bit flags, defined per-machine.

=head2 elf_header_len

Read-only, determined from L</class>.  (52 or 64 bytes)

=head2 segment_header_elem_len

Read-only, determined from L</class>.  (32 or 56 bytes)

=head2 section_header_elem_len

Read-only, determined from L</class>.  (40 or 64 bytes)

=head2 segments

Arrayref of L<ELF::Writer::Segment> objects.  You can also pass hashrefs to
the constructor which will be coerced automatically.

=head2 segment_count

Handy alias for C<< $#{ $elf->segments } >>

=head2 segment_list

Handy alias for C<< @{ $elf->segments } >>

=head2 sections

Arrayref of L<ELF::Writer::Section> objects.  You can also pass hashrefs to
the constructor which will be coerced automatically.

=head2 section_count

Handy alias for C<< $#{ $elf->sections } >>

=head2 section_list

Handy alias for C<< @{ $elf->sections } >>

=head2 section_name_string_table_idx

Index into the section array of a string-table section where the names of
the sections are stored.

=head1 METHODS

=head2 serialize

Return a string of the composed ELF file.  Throws exceptions if required
attributes are missing.

=head2 write_file

  $elf->write_file( $filename [, $mode]);

Convenience method for writing to a file.  Writes with mode 0755 by default.

=head1 SEE ALSO

Brian Raiter has a nice write-up of how to hack around on ELF files, which
I found very educational:

L<http://www.muppetlabs.com/~breadbox/software/tiny/teensy.html>

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
