package Filesys::Virtual;

###########################################################################
### Filesys::Virtual
### L.M.Orchard (deus_x@ninjacode.com)
### David Davis (xantus@cpan.org)
###
### Object oriented interface to a filesystem datasource
###
### Copyright (c) 2001 Leslie Michael Orchard.  All Rights Reserved.
### This module is free software; you can redistribute it and/or
### modify it under the same terms as Perl itself.
###
### Changes Copyright (c) 2003-2005 David Davis and Teknikill Software
###########################################################################

use strict;
use Carp;
use IO::File;

our $VERSION = '0.06';

# login: exactly that

sub login {
	my ($self, $username, $password) = @_;
	
	carp ref($self)."::login() Unimplemented";
	
	return 0;
}

# size: get a file's size

sub size {
	my ($self, $mode, $fn) = @_;
	
	carp ref($self)."::size() Unimplemented";
	
	return 0;
}

# chmod: Change a file's mode

sub chmod {
	my ($self, $mode, $fn) = @_;
	
	carp ref($self)."::chmod() Unimplemented";
	
	return 0;
}

# modtime: Return the modification time for a given file

sub modtime {
	my ($self, $fn) = @_;
	
	carp ref($self)."::modtime() Unimplemented";
	
	return 0;
}

# delete: Delete a given file

sub delete {
	my ($self, $fn) = @_;
	
	carp ref($self)."::delete() Unimplemented";
	
	return 0;
}

# cwd:

sub cwd {
	my ($self, $cwd) = @_;
	
	carp ref($self)."::cwd() Unimplemented";
	
	return 0;
}

# chdir: Change the cwd to a new path

sub chdir {
	my ($self, $dir) = @_;
	
	carp ref($self)."::chdir() Unimplemented";
	
	return 0;
}

# mkdir: Create a new directory

sub mkdir {
	my ($self, $dir) = @_;
	
	carp ref($self)."::mkdir() Unimplemented";
	
	return 0;
}

# rmdir: Remove a directory or file

sub rmdir {
	my ($self, $dir) = @_;
	
	carp ref($self)."::rmdir() Unimplemented";
	
	return 0;
}

# list: List files in a path.

sub list {
	my ($self, $dirfile) = @_;
	
	carp ref($self)."::list() Unimplemented";
	
	return undef;
}

# list_details: List files in a path, in full ls -al format.

sub list_details {
	my ($self, $dirfile) = @_;
	
	carp ref($self)."::list_details() Unimplemented";
	
	return undef;
}

# stat: Perform a stat on a given file

sub stat {
	my ($self, $fn) = @_;
	
	carp ref($self)."::stat() Unimplemented";
	
	return undef;
}

# test: Perform a given filesystem test

#    -r  File is readable by effective uid/gid.
#    -w  File is writable by effective uid/gid.
#    -x  File is executable by effective uid/gid.
#    -o  File is owned by effective uid.

#    -R  File is readable by real uid/gid.
#    -W  File is writable by real uid/gid.
#    -X  File is executable by real uid/gid.
#    -O  File is owned by real uid.

#    -e  File exists.
#    -z  File has zero size.
#    -s  File has nonzero size (returns size).

#    -f  File is a plain file.
#    -d  File is a directory.
#    -l  File is a symbolic link.
#    -p  File is a named pipe (FIFO), or Filehandle is a pipe.
#    -S  File is a socket.
#    -b  File is a block special file.
#    -c  File is a character special file.
#    -t  Filehandle is opened to a tty.

#    -u  File has setuid bit set.
#    -g  File has setgid bit set.
#    -k  File has sticky bit set.

#    -T  File is a text file.
#    -B  File is a binary file (opposite of -T).

#    -M  Age of file in days when script started.
#    -A  Same for access time.
#    -C  Same for inode change time.

sub test {
	my ($self, $test, $fn) = @_;
	
	carp ref($self)."::test() Unimplemented";
	
	return undef;
}

# open_read

sub open_read {
	my ($self, $fin, $create) = @_;

	carp ref($self)."::open_read() Unimplemented";
	
	return undef;
}

# close_read

sub close_read {
	my ($self, $fh) = @_;

	carp ref($self)."::close_read() Unimplemented";
	
	return undef;
}

# open_write

sub open_write {
	my ($self, $fin, $append) = @_;

	carp ref($self)."::open_write() Unimplemented";
	
	return undef;
}

# close_write

sub close_write {
	my ($self, $fh) = @_;

	carp ref($self)."::close_write() Unimplemented";
	
	return undef;
}

# seek: seek, if supported by filesystem...
# ie $fh is a filehandle
# $fh->seek($first, $second);
# see the module Filehandle

sub seek {
	my ($self, $fh, $first, $second) = @_;

	carp ref($self)."::seek() Unimplemented";

	return undef;
}

# utime: modify access time and mod time

sub utime {
	my ($self, $atime, $mtime, @fn) = @_;

	carp ref($self)."::utime() Unimplemented";

	return undef;
}

1;

__END__

=head1 NAME

Filesys::Virtual - Perl extension to provide a framework for a virtual filesystem

=head1 SYNOPSIS

  use Filesys::Virtual;

=head1 DESCRIPTION

This is a base class.  See L<SEE ALSO> below.

=head2 EXPORT

None by default.

=head2 TODO

Please contact David if you have any suggestions.

=head1 AUTHORS

David Davis, E<lt>xantus@cpan.orgE<gt>, http://teknikill.net/

L.M.Orchard, E<lt>deus_x@pobox.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<Filesys::Virtual>, L<Filesys::Virtual::SSH>,
L<Filesys::Virtual::DAAP>, L<POE::Component::Server::FTP>,
L<Net::DAV::Server>, L<HTTP::Daemon>,
http://perladvent.org/2004/20th/

=cut
