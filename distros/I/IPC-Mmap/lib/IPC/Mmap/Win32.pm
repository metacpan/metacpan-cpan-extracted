#/**
# Concrete implementation of the IPC::Mmap class for Win32.
# <p>
# Permission is granted to use this software under the same terms as Perl itself.
# Refer to the <a href='http://perldoc.perl.org/perlartistic.html'>Perl Artistic License</a>
# for details.
#
# @author D. Arnold
# @since 2006-05-01
# @self $self
#*/
package IPC::Mmap::Win32;
#
#	define and export Win32  equivalents for MMAP_* and
#	PROT_* flags
#
use Carp;
use Win32::MMF;
use Win32::MMF qw(
	CreateFile OpenFile CloseHandle CreateFileMapping OpenFileMapping
	MapViewOfFile UnmapViewOfFile ClaimNamespace ReleaseNamespace UseNamespace
	CreateSemaphore WaitForSingleObject ReleaseSemaphore);

use IPC::Mmap;
use IPC::Mmap qw(MAP_ANON MAP_ANONYMOUS MAP_FILE MAP_PRIVATE MAP_SHARED
	PROT_READ PROT_WRITE);
use base qw(IPC::Mmap);

our $VERSION = '0.11';

#/**
# Constructor. mmap()'s using Win32::MMF::UseNameSpace,
# Win32::MMF::ClaimNameSpace, Win32::MMF::MapViewOfFile,
# and Win32::MMF::CreateSemaphore methods.
#
# @param $filename
# @param $length 	optional
# @param $protflags optional
# @param $mmapflags optional
#
# @return the IPC::Mmap::Win32 object on success; undef on failure
#*/
sub new {
	my ($class, $file, $length, $prot, $mmap) = @_;

	croak 'Filename required for Win32'
		if (! $file) || (ref $file);
#
#	if no length given, Win32::MMF defaults to 128K
#
	$length = 128 * 1024 unless $length;
#
#	if MMAP_FILE set, then we creat the swapfile from
#	the filename, and use it as the namespace too
#
    my $self = {
        _file     => $file,
        _maxlen   => $length,
        _swapfile  => (($mmap & MAP_FILE) ? $file : undef),
        _fh        => 0,           # swap file handle
        _ns        => 0,           # namespace handle
        _addr      => 0,           # view address
        _semaphore => 0,           # semaphore used for exclusive locking
        _access    => $prot,       # enforced in module
        _slop      => 0			# dummy value; needed on POSIX
    };
#
#	try the file first; if not found, create it
#
	($self->{_fh}, $self->{_ns}) = ClaimNamespace($self->{_swapfile}, $file, $length)
		unless $self->{_ns} = UseNamespace($file);
#
# set default view to the namespace
#
	$self->{_addr} = MapViewOfFile($self->{_ns}, 0, $length)
		or croak "Can't map view of file";
#
# create semaphore object for the view
#
	my @sem = split(/[\/\\]/, $file);
	$self->{_semaphore} = CreateSemaphore(1, 1, $sem[-1] . '.lock')
		or croak("Can not create semaphore!");

	return bless $self, $class;
}

#/**
# Locks the mmap'ed region. Implemented using Win32::MMF::WaitForSingleObject().
# <i>May</i> be sufficient for multithread locking.
#*/
sub lock {
    return WaitForSingleObject($_[0]->{_semaphore}, 0x7FFFFFFF);
}

#/**
# Unlocks the mmap'ed region. Implemented using Win32::MMF::ReleaseSemaphore().
#*/
sub unlock {
    return ReleaseSemaphore($_[0]->{_semaphore}, 1);
}
#/**
# Unmap the mmap()ed region.
#*/
sub close {
    my $self = shift;

    # unmap existing views
    UnmapViewOfFile($self->{_addr});

    # close namespace and swap file
    ReleaseNamespace($self->{_swap}, $self->{_ns});
}
#
#	unmap and close the file
#	NOTE: we need a ref count for multithreaded environments ?;
#	for now we'll just bypass DESTROY
#
sub oldDESTROY {
    my $self = shift;

    # unmap existing views
    UnmapViewOfFile($self->{_addr});

    # close namespace and swap file
    ReleaseNamespace($self->{_swap}, $self->{_ns});
}

1;
