package File::stat::Extra;
use strict;
use warnings;
use warnings::register;

use 5.006;

# ABSTRACT: An extension of the File::stat module, provides additional methods.
our $VERSION = '0.009'; # VERSION

#pod =begin :prelude
#pod
#pod =for test_synopsis
#pod my ($st, $file);
#pod
#pod =end :prelude
#pod
#pod =head1 SYNOPSIS
#pod
#pod   use File::stat::Extra;
#pod
#pod   $st = lstat($file) or die "No $file: $!";
#pod
#pod   if ($st->isLink) {
#pod       print "$file is a symbolic link";
#pod   }
#pod
#pod   if (-x $st) {
#pod       print "$file is executable";
#pod   }
#pod
#pod   use Fcntl 'S_IRUSR';
#pod   if ( $st->cando(S_IRUSR, 1) ) {
#pod       print "My effective uid can read $file";
#pod   }
#pod
#pod   if ($st == stat($file)) {
#pod       printf "%s and $file are the same", $st->file;
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module's default exports override the core stat() and lstat()
#pod functions, replacing them with versions that return
#pod C<File::stat::Extra> objects when called in scalar context. In list
#pod context the same 13 item list is returned as with the original C<stat>
#pod and C<lstat> functions.
#pod
#pod C<File::stat::Extra> is an extension of the L<File::stat>
#pod module.
#pod
#pod =for :list
#pod * Returns non-object result in list context.
#pod * You can now pass in bare file handles to C<stat> and C<lstat> under C<use strict>.
#pod * File tests C<-t> C<-T>, and C<-B> have been implemented too.
#pod * Convenience functions C<filetype> and C<permissions> for direct access to filetype and permission parts of the mode field.
#pod * Named access to common file tests (C<isRegular> / C<isFile>, C<isDir>, C<isLink>, C<isBlock>, C<isChar>, C<isFIFO> / C<isPipe>, C<isSocket>).
#pod * Access to the name of the file / file handle used for the stat (C<file>, C<abs_file> / C<target>).
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<File::stat> for the module for which C<File::stat::Extra> is the extension.
#pod * L<stat> and L<lstat> for the original C<stat> and C<lstat> functions.
#pod
#pod =head1 COMPATIBILITY
#pod
#pod As with L<File::stat>, you can no longer use the implicit C<$_> or the
#pod special filehandle C<_> with this module's versions of C<stat> and
#pod C<lstat>.
#pod
#pod Currently C<File::stat::Extra> only provides an object interface, the
#pod L<File::stat> C<$st_*> variables and C<st_cando> funtion are not
#pod available. This may change in a future version of this module.
#pod
#pod =head1 WARNINGS
#pod
#pod When a file (handle) can not be (l)stat-ed, a warning C<Unable to
#pod stat: %s>. To disable this warning, specify
#pod
#pod     no warnings "File::stat::Extra";
#pod
#pod The following warnings are inhereted from C<File::stat>, these can all
#pod be disabled with
#pod
#pod     no warnings "File::stat";
#pod
#pod =over 4
#pod
#pod =item File::stat ignores use filetest 'access'
#pod
#pod You have tried to use one of the C<-rwxRWX> filetests with C<use
#pod filetest 'access'> in effect. C<File::stat> will ignore the pragma, and
#pod just use the information in the C<mode> member as usual.
#pod
#pod =item File::stat ignores VMS ACLs
#pod
#pod VMS systems have a permissions structure that cannot be completely
#pod represented in a stat buffer, and unlike on other systems the builtin
#pod filetest operators respect this. The C<File::stat> overloads, however,
#pod do not, since the information required is not available.
#pod
#pod =back
#pod
#pod =cut

# Note: we are not defining File::stat::Extra as a subclass of File::stat
# as we need to add an additional field and can not rely on the fact that
# File::stat will always be implemented as an array (struct).

our @ISA = qw(Exporter);
our @EXPORT = qw(stat lstat);

use File::stat ();
use File::Spec ();
use Cwd ();
use Fcntl ();

require Carp;
$Carp::Internal{ (__PACKAGE__) }++; # To get warnings reported at correct caller level

#pod =func stat( I<FILEHANDLE> )
#pod
#pod =func stat( I<DIRHANDLE> )
#pod
#pod =func stat( I<EXPR> )
#pod
#pod =func lstat( I<FILEHANDLE> )
#pod
#pod =func lstat( I<DIRHANDLE> )
#pod
#pod =func lstat( I<EXPR> )
#pod
#pod When called in list context, these functions behave as the original
#pod C<stat> and C<lstat> functions, returning the 13 element C<stat> list.
#pod When called in scalar context, a C<File::stat::Extra> object is
#pod returned with the methods as outlined below.
#pod
#pod =cut

# Runs stat or lstat on "file"
sub __stat_lstat {
    my $func = shift;
    my $file = shift;

    return $func eq 'lstat' ? CORE::lstat($file) : CORE::stat($file);
}

# Wrapper around stat/lstat, handles passing of file as a bare handle too
sub _stat_lstat {
    my $func = shift;
    my $file = shift;

    my @stat = __stat_lstat($func, $file);

    if (@stat) {
        # We have a file, so make it absolute (NOT resolving the symlinks)
        $file = File::Spec->rel2abs($file) if !ref $file;
    } else {
        # Try again, interpretting $file as handle
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        local $! = undef;
        require Symbol;
        my $fh = \*{ Symbol::qualify($file, caller(1)) };
        if (defined fileno $fh) {
            @stat = __stat_lstat($func, $fh);
        }
        if (!@stat) {
            warnings::warnif("Unable to stat: $file");
            return;
        }
        # We have a (valid) file handle, so we make file point to it
        $file = $fh;
    }

    if (wantarray) {
        return @stat;
    } else {
        return bless [ File::stat::populate(@stat), $file ], 'File::stat::Extra';
    }
}

sub stat(*) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    return _stat_lstat('stat', shift);
}

sub lstat(*) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    return _stat_lstat('lstat', shift);
}

#pod =method dev
#pod
#pod =method ino
#pod
#pod =method mode
#pod
#pod =method nlink
#pod
#pod =method uid
#pod
#pod =method gid
#pod
#pod =method rdev
#pod
#pod =method size
#pod
#pod =method atime
#pod
#pod =method mtime
#pod
#pod =method ctime
#pod
#pod =method blksize
#pod
#pod =method blocks
#pod
#pod These methods provide named acced to the same fields in the original
#pod C<stat> result. Just like the original L<File::stat>.
#pod
#pod =method cando( I<ACCESS>, I<EFFECTIVE> )
#pod
#pod Interprets the C<mode>, C<uid> and C<gid> fields, and returns whether
#pod or not the current process would be allowed the specified access.
#pod
#pod I<ACCESS> is one of C<S_IRUSR>, C<S_IWUSR> or C<S_IXUSR> from the
#pod L<Fcntl> module, and I<EFFECTIVE> indicates whether to use
#pod effective (true) or real (false) ids.
#pod
#pod =cut

BEGIN {
    no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)

    # Define the main field accessors and the cando method using the File::stat version
    for my $f (qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks cando)) {
        *{$f} = sub { $_[0][0]->$f; }
    }

#pod =for Pod::Coverage S_ISBLK S_ISCHR S_ISDIR S_ISFIFO S_ISLNK S_ISREG S_ISSOCK
#pod
#pod =cut

    # Create own versions of these functions as they will croak on use
    # if the platform doesn't define them. It's important to avoid
    # inflicting that on the user.
    # Note: to stay (more) version independent, we do not rely on the
    # implementation in File::stat, but rather recreate here.
    for (qw(BLK CHR DIR LNK REG SOCK)) {
        *{"S_IS$_"} = defined eval { &{"Fcntl::S_IF$_"} } ? \&{"Fcntl::S_IS$_"} : sub { '' };
    }
    # FIFO flag and macro don't quite follow the S_IF/S_IS pattern above
    *{'S_ISFIFO'} = defined &Fcntl::S_IFIFO ? \&Fcntl::S_ISFIFO : sub { '' };
}

#pod =method file
#pod
#pod Returns the full path to the original file (or the filehandle) on which
#pod C<stat> or C<lstat> was called.
#pod
#pod Note: Symlinks are not resolved. And, like C<rel2abs>, neither are
#pod C<x/../y> constructs. Use the C<abs_file> / C<target> methods to
#pod resolve these too.
#pod
#pod =cut

sub file {
    return $_[0][1];
}

#pod =method abs_file
#pod
#pod =method target
#pod
#pod Returns the absolute path of the file. In case of a file handle, this is returned unaltered.
#pod
#pod =cut

sub abs_file {
    return ref $_[0]->file ? $_[0]->file : Cwd::abs_path($_[0]->file);
}

*target = *abs_file;

#pod =method permissions
#pod
#pod Returns just the permissions (including setuid/setgid/sticky bits) of the C<mode> stat field.
#pod
#pod =cut

sub permissions {
    return Fcntl::S_IMODE($_[0]->mode);
}

#pod =method filetype
#pod
#pod Returns just the filetype of the C<mode> stat field.
#pod
#pod =cut

sub filetype {
    return Fcntl::S_IFMT($_[0]->mode);
}

#pod =method isFile
#pod
#pod =method isRegular
#pod
#pod Returns true if the file is a regular file (same as -f file test).
#pod
#pod =cut

sub isFile {
    return S_ISREG($_[0]->mode);
}

*isRegular = *isFile;

#pod =method isDir
#pod
#pod Returns true if the file is a directory (same as -d file test).
#pod
#pod =cut

sub isDir {
    return S_ISDIR($_[0]->mode);
}

#pod =method isLink
#pod
#pod Returns true if the file is a symbolic link (same as -l file test).
#pod
#pod Note: Only relevant when C<lstat> was used!
#pod
#pod =cut

sub isLink {
    return S_ISLNK($_[0]->mode);
}

#pod =method isBlock
#pod
#pod Returns true if the file is a block special file (same as -b file test).
#pod
#pod =cut

sub isBlock {
    return S_ISBLK($_[0]->mode);
}

#pod =method isChar
#pod
#pod Returns true if the file is a character special file (same as -c file test).
#pod
#pod =cut

sub isChar {
    return S_ISCHR($_[0]->mode);
}

#pod =method isFIFO
#pod
#pod =method isPipe
#pod
#pod Returns true if the file is a FIFO file or, in case of a file handle, a pipe  (same as -p file test).
#pod
#pod =cut

sub isFIFO {
    return S_ISFIFO($_[0]->mode);
}

*isPipe = *isFIFO;

#pod =method isSocket
#pod
#pod Returns true if the file is a socket file (same as -S file test).
#pod
#pod =cut

sub isSocket {
    return S_ISSOCK($_[0]->mode);
}

#pod =method -X operator
#pod
#pod You can use the file test operators on the C<File::stat::Extra> object
#pod just as you would on a file (handle). However, instead of querying the
#pod file system, these operators will use the information from the
#pod object itself.
#pod
#pod The overloaded filetests are only supported from Perl version 5.12 and
#pod higer. The named access to these tests can still be used though.
#pod
#pod Note: in case of the special file tests C<-t>, C<-T>, and C<-B>, the
#pod file (handle) I<is> tested the I<first> time the operator is
#pod used. After the first time, the initial result is re-used and no
#pod further testing of the file (handle) is performed.
#pod
#pod =method Unary C<""> (stringification) operator
#pod
#pod The unary C<""> (stringification) operator is overloaded to return the the device and inode
#pod numbers separated by a C<.> (C<I<dev>.I<ino>>). This yields a uniqe file identifier (as string).
#pod
#pod =method Comparison operators C<< <=> >>, C<cmp>, and C<~~>
#pod
#pod The comparison operators use the string representation of the
#pod C<File::stat::Extra> object. So, to see if two C<File::stat::Extra>
#pod object point to the same (hardlinked) file, you can simply say
#pod something like this:
#pod
#pod     print 'Same file' if $obj1 == $obj2;
#pod
#pod For objects created from an C<stat> of a symbolic link, the actual
#pod I<destination> of the link is used in the comparison! If you want to
#pod compare the actual symlink file, use C<lstat> instead.
#pod
#pod Note: All comparisons (also the numeric versions) are performed on the
#pod full stringified versions of the object. This to prevent files on the
#pod same device, but with an inode number ending in a zero to compare
#pod equally while they aren't (e.g., 5.10 and 5.100 compare equal
#pod numerically but denote a different file).
#pod
#pod Note: the smartmatch C<~~> operator is only overloaded on Perl version
#pod 5.10 and above.
#pod
#pod =method Other operators
#pod
#pod As the other operators (C<+>, C<->, C<*>, etc.) are meaningless, they
#pod have not been overloaded and will cause a run-time error.
#pod
#pod =cut

my %op = (
    # Use the named version of these tests
    f => sub { $_[0]->isRegular },
    d => sub { $_[0]->isDir },
    l => sub { $_[0]->isLink },
    p => sub { $_[0]->isFIFO },
    S => sub { $_[0]->isSocket },
    b => sub { $_[0]->isBlock },
    c => sub { $_[0]->isChar },

    # Defer implementation of rest to File::stat
    r => sub { -r $_[0][0] },
    w => sub { -w $_[0][0] },
    x => sub { -x $_[0][0] },
    o => sub { -o $_[0][0] },

    R => sub { -R $_[0][0] },
    W => sub { -W $_[0][0] },
    X => sub { -X $_[0][0] },
    O => sub { -O $_[0][0] },

    e => sub { -e $_[0][0] },
    z => sub { -z $_[0][0] },
    s => sub { -s $_[0][0] },

    u => sub { -u $_[0][0] },
    g => sub { -g $_[0][0] },
    k => sub { -k $_[0][0] },

    M => sub { -M $_[0][0] },
    C => sub { -C $_[0][0] },
    A => sub { -A $_[0][0] },

    # Implement these operators by testing the underlying file, caching the result
    t => sub { defined $_[0][2] ? $_[0][2] : $_[0][2] = (-t $_[0]->file) || 0 }, ## no critic (InputOutput::ProhibitInteractiveTest)
    T => sub { defined $_[0][3] ? $_[0][3] : $_[0][3] = (-T $_[0]->file) || 0 },
    B => sub { defined $_[0][4] ? $_[0][4] : $_[0][4] = (-B $_[0]->file) || 0 },
);

sub _filetest {
    my ($s, $op) = @_;
    if ($op{$op}) {
        return $op{$op}->($s);
    } else {
        # We should have everything covered so this is just a safegauard
        Carp::croak "-$op is not implemented on a File::stat::Extra object";
    }
}

sub _dev_ino {
    return $_[0]->dev . "." . $_[0]->ino;
}

sub _compare {
    my $va = shift;
    my $vb = shift;
    my $swapped = shift;
    ($vb, $va) = ($va, $vb) if $swapped;

    return "$va" cmp "$vb"; # Force stringification when comparing
}

use overload
    # File test operators (as of Perl v5.12)
    $^V >= 5.012 ? (-X => \&_filetest) : (),

    # Unary "" returns the object as "dev.ino", this should be a
    # unique string for each file.
    '""' => \&_dev_ino,

    # Comparison is done based on the unique string created with the stringification
    '<=>' => \&_compare,
    'cmp' => \&_compare,

    # Smartmatch as of Perl v5.10
    $^V >= 5.010 ? ('~~' => \&_compare) : (),

    ;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::stat::Extra - An extension of the File::stat module, provides additional methods.

=head1 VERSION

version 0.009

=for test_synopsis my ($st, $file);

=head1 SYNOPSIS

  use File::stat::Extra;

  $st = lstat($file) or die "No $file: $!";

  if ($st->isLink) {
      print "$file is a symbolic link";
  }

  if (-x $st) {
      print "$file is executable";
  }

  use Fcntl 'S_IRUSR';
  if ( $st->cando(S_IRUSR, 1) ) {
      print "My effective uid can read $file";
  }

  if ($st == stat($file)) {
      printf "%s and $file are the same", $st->file;
  }

=head1 DESCRIPTION

This module's default exports override the core stat() and lstat()
functions, replacing them with versions that return
C<File::stat::Extra> objects when called in scalar context. In list
context the same 13 item list is returned as with the original C<stat>
and C<lstat> functions.

C<File::stat::Extra> is an extension of the L<File::stat>
module.

=over 4

=item *

Returns non-object result in list context.

=item *

You can now pass in bare file handles to C<stat> and C<lstat> under C<use strict>.

=item *

File tests C<-t> C<-T>, and C<-B> have been implemented too.

=item *

Convenience functions C<filetype> and C<permissions> for direct access to filetype and permission parts of the mode field.

=item *

Named access to common file tests (C<isRegular> / C<isFile>, C<isDir>, C<isLink>, C<isBlock>, C<isChar>, C<isFIFO> / C<isPipe>, C<isSocket>).

=item *

Access to the name of the file / file handle used for the stat (C<file>, C<abs_file> / C<target>).

=back

=head1 FUNCTIONS

=head2 stat( I<FILEHANDLE> )

=head2 stat( I<DIRHANDLE> )

=head2 stat( I<EXPR> )

=head2 lstat( I<FILEHANDLE> )

=head2 lstat( I<DIRHANDLE> )

=head2 lstat( I<EXPR> )

When called in list context, these functions behave as the original
C<stat> and C<lstat> functions, returning the 13 element C<stat> list.
When called in scalar context, a C<File::stat::Extra> object is
returned with the methods as outlined below.

=head1 METHODS

=head2 dev

=head2 ino

=head2 mode

=head2 nlink

=head2 uid

=head2 gid

=head2 rdev

=head2 size

=head2 atime

=head2 mtime

=head2 ctime

=head2 blksize

=head2 blocks

These methods provide named acced to the same fields in the original
C<stat> result. Just like the original L<File::stat>.

=head2 cando( I<ACCESS>, I<EFFECTIVE> )

Interprets the C<mode>, C<uid> and C<gid> fields, and returns whether
or not the current process would be allowed the specified access.

I<ACCESS> is one of C<S_IRUSR>, C<S_IWUSR> or C<S_IXUSR> from the
L<Fcntl> module, and I<EFFECTIVE> indicates whether to use
effective (true) or real (false) ids.

=head2 file

Returns the full path to the original file (or the filehandle) on which
C<stat> or C<lstat> was called.

Note: Symlinks are not resolved. And, like C<rel2abs>, neither are
C<x/../y> constructs. Use the C<abs_file> / C<target> methods to
resolve these too.

=head2 abs_file

=head2 target

Returns the absolute path of the file. In case of a file handle, this is returned unaltered.

=head2 permissions

Returns just the permissions (including setuid/setgid/sticky bits) of the C<mode> stat field.

=head2 filetype

Returns just the filetype of the C<mode> stat field.

=head2 isFile

=head2 isRegular

Returns true if the file is a regular file (same as -f file test).

=head2 isDir

Returns true if the file is a directory (same as -d file test).

=head2 isLink

Returns true if the file is a symbolic link (same as -l file test).

Note: Only relevant when C<lstat> was used!

=head2 isBlock

Returns true if the file is a block special file (same as -b file test).

=head2 isChar

Returns true if the file is a character special file (same as -c file test).

=head2 isFIFO

=head2 isPipe

Returns true if the file is a FIFO file or, in case of a file handle, a pipe  (same as -p file test).

=head2 isSocket

Returns true if the file is a socket file (same as -S file test).

=head2 -X operator

You can use the file test operators on the C<File::stat::Extra> object
just as you would on a file (handle). However, instead of querying the
file system, these operators will use the information from the
object itself.

The overloaded filetests are only supported from Perl version 5.12 and
higer. The named access to these tests can still be used though.

Note: in case of the special file tests C<-t>, C<-T>, and C<-B>, the
file (handle) I<is> tested the I<first> time the operator is
used. After the first time, the initial result is re-used and no
further testing of the file (handle) is performed.

=head2 Unary C<""> (stringification) operator

The unary C<""> (stringification) operator is overloaded to return the the device and inode
numbers separated by a C<.> (C<I<dev>.I<ino>>). This yields a uniqe file identifier (as string).

=head2 Comparison operators C<< <=> >>, C<cmp>, and C<~~>

The comparison operators use the string representation of the
C<File::stat::Extra> object. So, to see if two C<File::stat::Extra>
object point to the same (hardlinked) file, you can simply say
something like this:

    print 'Same file' if $obj1 == $obj2;

For objects created from an C<stat> of a symbolic link, the actual
I<destination> of the link is used in the comparison! If you want to
compare the actual symlink file, use C<lstat> instead.

Note: All comparisons (also the numeric versions) are performed on the
full stringified versions of the object. This to prevent files on the
same device, but with an inode number ending in a zero to compare
equally while they aren't (e.g., 5.10 and 5.100 compare equal
numerically but denote a different file).

Note: the smartmatch C<~~> operator is only overloaded on Perl version
5.10 and above.

=head2 Other operators

As the other operators (C<+>, C<->, C<*>, etc.) are meaningless, they
have not been overloaded and will cause a run-time error.

=head1 WARNINGS

When a file (handle) can not be (l)stat-ed, a warning C<Unable to
stat: %s>. To disable this warning, specify

    no warnings "File::stat::Extra";

The following warnings are inhereted from C<File::stat>, these can all
be disabled with

    no warnings "File::stat";

=over 4

=item File::stat ignores use filetest 'access'

You have tried to use one of the C<-rwxRWX> filetests with C<use
filetest 'access'> in effect. C<File::stat> will ignore the pragma, and
just use the information in the C<mode> member as usual.

=item File::stat ignores VMS ACLs

VMS systems have a permissions structure that cannot be completely
represented in a stat buffer, and unlike on other systems the builtin
filetest operators respect this. The C<File::stat> overloads, however,
do not, since the information required is not available.

=back

=for Pod::Coverage S_ISBLK S_ISCHR S_ISDIR S_ISFIFO S_ISLNK S_ISREG S_ISSOCK

=head1 BUGS

Please report any bugs or feature requests on the bugtracker
L<website|https://github.com/HayoBaan/File-stat-Extra/issues>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COMPATIBILITY

As with L<File::stat>, you can no longer use the implicit C<$_> or the
special filehandle C<_> with this module's versions of C<stat> and
C<lstat>.

Currently C<File::stat::Extra> only provides an object interface, the
L<File::stat> C<$st_*> variables and C<st_cando> funtion are not
available. This may change in a future version of this module.

=head1 SEE ALSO

=over 4

=item *

L<File::stat> for the module for which C<File::stat::Extra> is the extension.

=item *

L<stat> and L<lstat> for the original C<stat> and C<lstat> functions.

=back

=head1 AUTHOR

Hayo Baan <info@hayobaan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Hayo Baan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
