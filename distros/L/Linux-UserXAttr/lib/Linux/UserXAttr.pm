package Linux::UserXAttr;

use 5.008008;
use strict;
use warnings;

use Exporter qw/import/;

our %EXPORT_TAGS=
    (flags=>[qw/XATTR_CREATE XATTR_REPLACE/],
     functions=>[qw/setxattr lsetxattr getxattr lgetxattr
		    listxattr llistxattr removexattr lremovexattr/]);
$EXPORT_TAGS{all}=[map {@{$EXPORT_TAGS{$_}}} keys %EXPORT_TAGS];
our @EXPORT_OK=@{$EXPORT_TAGS{all}};

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Linux::UserXAttr', $VERSION);

1;
__END__

=encoding utf8

=head1 NAME

Linux::UserXAttr - Support for extended file attributes on Linux

=head1 SYNOPSIS

 use Linux::UserXAttr qw/:all/;

 $success=setxattr $filename_or_handle, $name, $value, $flags;
 $success=lsetxattr $filename, $name, $value, $flags;
 $value=getxattr $filename_or_handle, $name;
 $value=lgetxattr $filename, $name;
 @names=listxattr $filename_or_handle;
 @names=llistxattr $filename;
 $success=removexattr $filename_or_handle, $name;
 $success=lremovexattr $filename, $name;

=head1 DESCRIPTION

This module implements a very thin layer around the extended attributes
syscalls on Linux. See L<setxattr(2)>, L<getxattr(2)>, L<listxattr(2)> and
L<removexattr(2)> for more information.

Due to varying support in different kernels the test suite of this module
is really simple. It verfies that the functions and constants are exported
but does not call the actual syscalls. If you smell a wumpus try C<strace>,
e.g.:

 strace perl -MLinux::UserXAttr=:all -le 'setxattr qw/. user.name value/'

and look up the syscall like:

 setxattr(".", "user.name", "value", 5, 0) = 0

=head2 Functions

=head3 $success=setxattr $filename_or_handle, $name, $value, $flags

creates or modifies the extended attribute C<$name> and sets its value
to C<$value>. C<$flags> can be used to refine the semantics of the operation.
The 2 constants are allowed C<XATTR_CREATE> and C<XATTR_REPLACE>.

For more information see the L<setxattr(2)> manpage.

C<$filename_or_handle> may be a file or directory name or an open file or
directory handle.

On success true is returned. On failure the empty list is returned and C<$!>
set accordingly.

Note, support for extended attributes and particularly for C<$flags> may
vary for different kernels.

=head3 $success=lsetxattr $filename, $name, $value, $flags

same as C<setxattr> but fails if C<$filename> is a symlink.

=head3 $value=getxattr $filename_or_handle, $name

reads an extended attribute.

On failure the empty list is returned and C<$!> set accordingly.

=head3 $value=lgetxattr $filename, $name

same as C<getxattr> but fails if C<$filename> is a symlink.

=head3 @names=listxattr $filename_or_handle

returns a list of names of extended attributes.

=head3 @names=llistxattr $filename

same as C<listxattr> but fails if C<$filename> is a symlink.

=head3 $success=removexattr $filename_or_handle, $name

removes the extended attribute C<$name>.

On success true is returned. On failure the empty list is returned and C<$!>
set accordingly.

=head3 $success=lremovexattr $filename, $name

same as C<removexattr> but fails if C<$filename> is a symlink.

=head1 EXPORT

None by default.

On demand all functions and constants are exported.

=head3 Export tags

=over 4

=item :flags

exports C<XATTR_CREATE> and C<XATTR_REPLACE>

=item :functions

exports C<setxattr>, C<lsetxattr>, C<getxattr>, C< lgetxattr>,
C<listxattr>, C<llistxattr>, C<removexattr> and C<lremovexattr>.

=item :all

all of the above

=back

=head1 SEE ALSO

Linux manual.

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
