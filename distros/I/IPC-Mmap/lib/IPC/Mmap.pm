#/**
# Provides a minimal interface to POSIX mmap(), and its
# Win32 equivalent. Abstract base class that is used by
# the IPC::Mmap::POSIX and IPC::Mmap::Win32 implementations.
# <p>
# Permission is granted to use this software under the same terms as Perl itself.
# Refer to the <a href='http://perldoc.perl.org/perlartistic.html'>Perl Artistic License</a>
# for details.
#
# @author D. Arnold
# @since 2006-05-01
# @self $self
# @exports MAP_SHARED	permit the mmap'd area to be shared with other processes
# @exports MAP_PRIVATE	do not permit the mmap'ed area to be shared with other processes
# @exports MAP_ANON 		do not use a backing file
# @exports MAP_ANONYMOUS same as MAP_ANON
# @exports MAP_FILE		use a backing file for the memory mapped area
# @exports PROT_READ		permit read access to the mmap'ed area
# @exports PROT_WRITE	permit write access to the mmap'ed area
#*/
package IPC::Mmap;

use Carp;
use DynaLoader;
use Exporter;
our @ISA = qw(Exporter DynaLoader);
our $VERSION = '0.21';

bootstrap IPC::Mmap $VERSION;

use strict;
use warnings;

our @EXPORT = qw(MAP_ANON MAP_ANONYMOUS MAP_FILE MAP_PRIVATE MAP_SHARED
	PROT_READ PROT_WRITE);

	if ($^O eq 'MSWin32') {
		require IPC::Mmap::Win32;
	}
	else {
		require IPC::Mmap::POSIX;
	}
#
#	these are generated within the appropriate XS code;
#	gruesome, perhaps, but gets the job done
#
sub MAP_ANON { return constant('MAP_ANON', 0); }
sub MAP_ANONYMOUS { return constant('MAP_ANONYMOUS', 0); }
sub MAP_FILE { return constant('MAP_FILE', 0); }
sub MAP_PRIVATE  { return constant('MAP_PRIVATE', 0); }
sub MAP_SHARED { return constant('MAP_SHARED', 0); }
sub PROT_READ  { return constant('PROT_READ', 0); }
sub PROT_WRITE { return constant('PROT_WRITE', 0); }


#/**
# Constructor. Maps the specified number of bytes of the specified file
# into the current process's address space. Read/write access protection
# (default is read-only), and mmap() control flags may be specified
# (default is MAP_SHARED). If no length is given, maps the file's current length.
# <p>
# The specified file will be created if needed, and openned in an
# access mode that is compatible with the specified access protection.
# If the size of the file is less than the specified length, and the access flags
# include write access, the file will be extended with NUL characters to the
# specified length.
# <p>
# <b>Note</b> that for Win32, the specified file is used as a <i>"namespace"</i>,
# rather than physical file, if an "anonymous" mmap() is requested.
# <p>
# On POSIX platforms, an anonymous, private shared memory region
# can be created <i>(to be inherited by any fork()'ed
# child processes)</i> by using a zero-length filename, and
# "private" (MAP_PRIVATE) mmap() flags.
# <p>
# On Win32 platforms, the default behavior is to create a "namespace", and use the
# Windows swap file for the backing file. However, by including MAP_FILE in the
# mmap() flags parameter, the specified file will be opened and/or created,
# and used for the backing file, rather than the system swap file.
#
# @param $filename	name of file (or namespace) to be mapped
# @param $length 	optional number of bytes to be mapped
# @param $protflags optional read/write access flags
# @param $mmapflags optional mmap() control flags
#
# @return the IPC::Mmap object on success; undef on failure
#*/
sub new {
	my ($class, $file, $length, $prot, $mmap) = @_;

	$length = 0 unless defined($length);
	$prot = PROT_READ unless defined($prot);
	$mmap = MAP_SHARED unless defined($mmap);
#
#	we're just a factory for the platform-specific objects
#
	return ($^O eq 'MSWin32') ?
		IPC::Mmap::Win32->new($file, $length, $prot, $mmap) :
		IPC::Mmap::POSIX->new($file, $length, $prot, $mmap);
}

#/**
# Reads data from a specific area of the mmap()'ed file.
#
# @param $data scalar to receive the data
# @param $offset optional offset into mmap'ed area; default is zero
# @param $length optional length to read; default is from the offset to the end of the file
#
# @return the number of bytes actually read on success; undef on failure
#*/
sub read {
	my $self = shift;

	croak "Invalid access on write-only region",
	return undef
		unless $self->{_access} & PROT_READ;

	my $off = ($_[1] || 0) + $self->{_slop};
	my $len = $_[2] || $self->{_maxlen};

	croak "read failed: offset exceeds region length",
	return undef
		if ($off >= $self->{_maxlen});

	return mmap_read($self->{_addr}, $self->{_maxlen},
		$off, $_[0], $len);
}

#/**
# Write data to the mmap()'ed region.
# Writes the specified number of bytes of the specified scalar variable
# to the mmap'ed region starting at the specified offset. If not specified,
# offset defaults to zero, and length> defaults to the length of the scalar.
# If the specified length exceeds the available length of the mmap'ed region
# starting from the offset, only the available region length will be written.
#
# @param $data the data to be written
# @param $offset optional offset where the data should be written; default is zero
# @param $length optional length of the data to write; default is the length of the data
#
# @return on success, returns the actual number of bytes written; returns undef
#		if the offset exceeds the length of the region
#*/
sub write {
	my ($self, $var, $off, $len) = @_;

	croak "Invalid access on read-only region",
	return undef
		unless $self->{_access} & PROT_WRITE;

	$off = 0 unless defined($off);
	$off += $self->{_slop};
	$len = length($var) unless $len;

	croak "write failed: offset exceeds region length",
	return undef
		if ($off >= $self->{_maxlen});

	return mmap_write($self->{_addr}, $self->{_maxlen},
		$off, $var, $len);
}
#/**
# Packs a list of values according to the specified pack string, and writes
# the binary result to the mmap'ed region at specified offset.
# If the offset plus the packed data length extends beyond the end of the
# region, only the available number of bytes will be written.
#
# @param $offset	offset to write the packed data
# @param $packstr	pack string to be applied to the data
# @param @values	list of values to pack and write
#
# @return undef if $offset is beyond the end of the mmap'ed region; otherwise,
#			the total number of bytes written
#*/
sub pack {
	my $self = shift;
	my $off = shift;
	my $packstr = shift;
	return $self->write(CORE::pack($packstr, @_), $off);
}
#/**
# Read the specified number of bytes starting at the specified offset
# and unpack into Perl scalars using the specified pack() string.
#
# @param $offset	offset to start reading from
# @param $length	number of bytes to read
# @param $packstr	pack string to apply to the read data
#
# @return on success, the list of unpacked values; undef on failure
#*/
sub unpack {
	my ($self, $off, $length, $packstr) = @_;
	my $val;
	return undef
		unless $self->read($val, $off, $length);
	return CORE::unpack($packstr, $val);
}

#/**
# Locks the mmap'ed region. Pure virtual function to be implemented
# in the OS-specific implementation subclass.
#*/
sub lock { }

#/**
# Unlock the mmap'ed region. Pure virtual function
# to be implemented in the OS-specific implementation
# subclass.
#
#*/
sub unlock { }
#/**
# Get the filename (or namespace on Win32) for the mmap'ed file.
#
# @return the mmap'ed filename.
#*/
sub getFilename { return $_[0]->{_file}; }

#/**
# Get the filehandle for the mmap'ed file. If MAP_ANON
# was specified for POSIX platforms, or MAP_FILE was <b>not</b> specified
# on Win32 platforms, returns undef.
#
# @return the file handle used for the mmap'ed file.
#*/
sub getFileHandle { return $_[0]->{_fh}; }
#/**
# Get the length of the mmap'ed region
#
# @return the length of the mmap()ed region.
#*/
sub getLength { return $_[0]->{_maxlen}; }
#/**
# Get the base address to which the mmap'ed region was mapped.
#
# @return the address of the mmap()ed region.
#*/
sub getAddress { return $_[0]->{_addr}; }


1;
