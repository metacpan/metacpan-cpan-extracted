package File::Strmode;

our $VERSION = '0.03';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(strmode);

use Carp;

BEGIN {
    require Fcntl;
    require constant;
    eval { Fcntl->import($_); 1 } || constant->import($_, 0)
	for qw(S_IFDIR S_IFCHR S_IFBLK S_IFREG S_IFLNK S_IFMT S_IRUSR
	       S_IWUSR S_IXUSR S_ISUID S_IRGRP S_IWGRP S_IXGRP S_ISGID
	       S_IROTH S_IWOTH S_IXOTH S_ISVTX S_IFSOCK S_IFIFO);
}

my %type = (  S_IFDIR, 'd',
	      S_IFCHR, 'c',
	      S_IFBLK, 'b',
	      S_IFREG, '-',
	      S_IFLNK, 'l',
	      S_IFSOCK, 's',
	      S_IFIFO, 'p' );

delete $type{0}; # if some type constant is not defined for the
                 # running OS, it will end at this slot.

my %cache;

sub strmode {
    my $mode = shift;
    return undef unless defined $mode;
    $cache{$mode} ||= do {
	my $str = $type{$mode & S_IFMT} || '?';
	$str .= (($mode & S_IRUSR) ? 'r' : '-');
	$str .= (($mode & S_IWUSR) ? 'w' : '-');
	if ($mode & S_IXUSR) {
	    $str .= (($mode & S_ISUID) ? 's' : 'x');
	}
	else {
	    $str .= (($mode & S_ISUID) ? 'S' : '-');
	}
	$str .= (($mode & S_IRGRP) ? 'r' : '-');
	$str .= (($mode & S_IWGRP) ? 'w' : '-');
	if (($mode & S_IXGRP)) {
	    $str .= (($mode & S_ISGID) ? 's' : 'x');
	}
	else {
	    $str .= (($mode & S_ISGID) ? 'S' : '-');
	}
	$str .= (($mode & S_IROTH) ? 'r' : '-');
	$str .= (($mode & S_IWOTH) ? 'w' : '-');
	if ($mode & S_IXOTH) {
	    $str .= (($mode & S_ISVTX) ? 't' : 'x');
	}
	else {
	    $str .= (($mode & S_ISVTX) ? 'T' : '-');
	}
	$str .= ' '; # will be a '+' if ACL's implemented
	$str
    };
}

1;
__END__

=head1 NAME

File::Strmode - Converts a file mode into a symbolic string

=head1 SYNOPSIS

  use File::Strmode;

  my $mode = (stat $filename)[2];
  my $strmode = strmode($mode);
  print "$strmode $filename\n";

=head1 DESCRIPTION

The C<strmode()> function exported from this module converts a file
mode (the type and permission information associated with an inode,
see L<perlfunc/stat>) into a symbolic string.  This string is eleven
characters in length.

BSD derived operating systems offer this function as part of its C
library. The following description has been copied from the NetBSD
strmode man page:

The first character is the inode type, and will be one of the following:

  -     regular file
  a     regular file in archive state 1
  A     regular file in archive state 2
  b     block special
  c     character special
  d     directory
  l     symbolic link
  p     fifo
  s     socket
  w     whiteout
  ?     unknown inode type

The next nine characters encode three sets of permissions, in three
characters each.  The first three characters are the permissions for
the owner of the file, the second three for the group the file belongs
to, and the third for the I<other>, or default, set of users.

Permission checking is done as specifically as possible.  If read
permission is denied to the owner of a file in the first set of
permissions, the owner of the file will not be able to read the file.
This is true even if the owner is in the file's group and the group
permissions allow reading or the I<other> permissions allow reading.

If the first character of the three character set is an C<r>, the file
is readable for that set of users; if a dash C<->, it is not readable.

If the second character of the three character set is a C<w>, the file
is writable for that set of users; if a dash C<->, it is not writable.

The third character is the first of the following characters that apply:

=over 4

=item S

If the character is part of the owner permissions and the file is
not executable or the directory is not searchable by the owner, and
the set-user-id bit is set.

=item S

If the character is part of the group permissions and the file is
not executable or the directory is not searchable by the group, and
the set-group-id bit is set.

=item T

If the character is part of the other permissions and the file is
not executable or the directory is not searchable by others, and
the I<sticky> (S_ISVTX) bit is set.

=item s

If the character is part of the owner permissions and the file is
executable or the directory searchable by the owner, and the set-
user-id bit is set.

=item s

If the character is part of the group permissions and the file is
executable or the directory searchable by the group, and the set-
group-id bit is set.

=item t

If the character is part of the other permissions and the file is
executable or the directory searchable by others, and the
I<sticky> (S_ISVTX) bit is set.

=item x

The file is executable or the directory is searchable.

=item -

None of the above apply.

=back

The last character is a plus sign C<+> if there are any alternative or
additional access control methods associated with the inode, otherwise it
will be a space.

Archive state 1 and archive state 2 represent file system dependent ar-
chive state for a file.  Most file systems do not retain file archive
state, and so will not report files in either archive state.  msdosfs
will report a file in archive state 1 if it has been archived more
recently than modified.  Hierarchical storage systems may have multiple
archive states for a file and may define archive states 1 and 2 as appro-
priate.

=head1 SEE ALSO

L<strmode(2)>, L<perlfunc/stat>, L<perlfunc/lstat>.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

This manual page is based on NetBSD strmode manual page that has the
following copyright:

Copyright (c) 1994-2009 The NetBSD Foundation, Inc.

=cut
