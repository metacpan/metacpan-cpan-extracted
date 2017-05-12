
package Filesys::Type;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.02;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw (fstype case diagnose);
	%EXPORT_TAGS = (all => [qw(fstype case diagnose)]);
}


=head1 NAME

Filesys::Type - Portable way of determining the type of a file system.

=head1 SYNOPSIS

  use Filesys::Type qw(fstype);
  
  ...
  my $fs = '/mnt/hda7';
  warn "Not able to share with Windows"
     if (fstype($fs) ne 'vfat');


=head1 DESCRIPTION

This module provides a portable interface, either to Unix mount -n
or to Win32::filesys or to another native OS interface.

The module is pluggable, which will allow for other operating systems
to be added in future without needing to change the core module.

=head2 fstype

This exportable function takes a string, which is a file or directory 
path, and returns the file system type, e.g. vfat, ntfs, ext2, etc.
Note that the exact string returned is operating system dependent.

=head2 case

This is another exportable function that returns the case sensitivity
of a file system. It either takes a file system type as returned by
fstype, or a path as input. It returns one of the following:

=over 4

=item C<sensitive>

like Unix ext2, ext3, etc.

=item C<lower>

VMS ODS-2 filenames are case insensitive. System services return the
names in upper case, but the CRTL which provides globbing and the
command line interface turns to lower case.

=item C<insensitive>

This is the behaviour of Windows file systems, FAT16, FAT32 and NTFS.
The file names are case insensitive, i.e. foo, Foo and FOO refer to the
same file, but the initial case of the letters of the file name is
preserved from the time it was created.

=back

=head2 C<diagnose>

Use this to determine what went wrong if fstype returned undef. Returns
a string suitable for printing in a log or on stderr.

=head1 SECURITY

Note that some platforms use backtick shell commands to derive information
about the file systems. Be careful that a rogue user could execute 
operating system commands by injecting into the path.

It is recommended only to pass in untainted strings. See perldoc perlsec
for details of running in taint mode, and for a description of how to untaint
a string passed in from outside.

=head1 BUGS

Please report bugs to http://rt.cpan.org. Post to bug-filesys-type@rt.cpan.org


=head1 HISTORY

0.01 Sun Jun 12 2005
	- original version; created by ExtUtils::ModuleMaker 0.32

0.02 Fri Jul 08 2005
	- Change plugins to be OO. Add diagnostic facility to see 
	  more about failing tests on some platforms.

=head1 AUTHOR

	I. Williams
	ivorw@cpan.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Win32>.

=cut

use Module::Pluggable instantiate => 'new';
our ($plugin) = grep {defined $_} __PACKAGE__->plugins;
warn "failed to detect suitable Filesys::Type::Plugin"
	unless defined $plugin;

sub fstype {
	$plugin->fstype(shift);
}

our %case_sensitivity = (
	msdos => 'insensitive',
	umsdos => 'insensitive',
	vfat => 'insensitive',
	ntfs => 'insensitive',
	minix => 'sensitive',
	xiafs => 'sensitive',
	ext2 => 'sensitive',
	ext3 => 'sensitive',
	iso9660 => 'sensitive',
	hpfs => 'sensitive',
	sysv => 'sensitive',
	nfs => 'sensitive',
	smb => 'insensitive',
	ncpfs => 'insensitive',
	FAT => 'insensitive',
	FAT32 => 'insensitive',
	CDFS => 'insensitive',
	NTFS => 'insensitive',
	'ODS-2' => 'lower',
	);

sub case {
    my $fs = shift;

    return $case_sensitivity{$fs} if exists $case_sensitivity{$fs};
    $fs = fstype($fs);

    $case_sensitivity{$fs};
}

sub diagnose {
    $plugin->diagnose;
}

1; #this line is important and will help the module return a true value
__END__

