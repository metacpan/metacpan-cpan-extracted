package Filesys::Statvfs;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(statvfs fstatvfs);
$VERSION = '0.82';
bootstrap Filesys::Statvfs $VERSION;

1;
__END__

=head1 NAME

Filesys::Statvfs - Perl extension for statvfs() and fstatvfs()

=head1 SYNOPSIS

  use Filesys::Statvfs;

	my($bsize, $frsize, $blocks, $bfree, $bavail,
	$files, $ffree, $favail, $flag, $namemax) = statvfs("/tmp");

	#### Pass an open filehandle. Verify that fileno() returns a defined
	#### value. If you pass undef to fstatvfs you will get unexpected results
	my $fd = fileno(FILE_HANDLE);
	if(defined($fd)) {
		($bsize, $frsize, $blocks, $bfree, $bavail,
		$files, $ffree, $favail, $flag, $namemax) = fstatvfs($fd);
	}

=head1 DESCRIPTION

Interface for statvfs() and fstatvfs()

Unless you need access to the bsize, flag, and namemax values,
you should probably look at using Filesys::DfPortable or
Filesys::Df instead. They will generally provide you with more
functionality and portability.

The module should work with all flavors of Unix that implement the
C<statvfs()> and C<fstatvfs()> calls. This would include Linux, *BSD,
HP-UX, AIX, Solaris, Mac OS X, Irix, Cygwin, etc ...

The C<statvfs()> and C<fstatvfs()> functions will return a list of
values, or will return C<undef> and set C<$!> if there was an error.

The values returned are described in the statvfs/fstatvfs header or
the C<statvfs()/fstatvfs()> man page.

The module assumes that if you have C<statvfs()>, C<fstatvfs()> will
also be available.

=head1 AUTHOR

Ian Guthrie
IGuthrie@aol.com

Copyright (c) 2006 Ian Guthrie. All rights reserved.
               This program is free software; you can redistribute it and/or
               modify it under the same terms as Perl itself.

=head1 SEE ALSO

statvfs(2), fstatvfs(2), Filesys::DfPortable, Filesys::Df

=cut
