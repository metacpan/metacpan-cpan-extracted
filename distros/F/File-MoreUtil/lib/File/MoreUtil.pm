package File::MoreUtil;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-13'; # DATE
our $DIST = 'File-MoreUtil'; # DIST
our $VERSION = '0.623'; # VERSION

use 5.010001;
use strict;
use warnings;

use Cwd ();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       file_exists
                       l_abs_path
                       dir_empty
                       dir_has_files
                       dir_has_dot_files
                       dir_has_non_dot_files
                       dir_has_subdirs
                       dir_has_dot_subdirs
                       dir_has_non_dot_subdirs

                       get_dir_entries
                       get_dir_dot_entries
                       get_dir_subdirs
                       get_dir_dot_subdirs
                       get_dir_non_dot_subdirs
                       get_dir_files
                       get_dir_dot_files
                       get_dir_non_dot_files
               );

our %SPEC;

sub file_exists {
    my $path = shift;

    !(-l $path) && (-e _) || (-l _);
}

sub l_abs_path {
    my $path = shift;
    return Cwd::abs_path($path) unless (-l $path);

    $path =~ s!/\z!!;
    my ($parent, $leaf);
    if ($path =~ m!(.+)/(.+)!s) {
        $parent = Cwd::abs_path($1);
        return undef unless defined($path);
        $leaf   = $2;
    } else {
        $parent = Cwd::getcwd();
        $leaf   = $path;
    }
    "$parent/$leaf";
}

sub dir_empty {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return 0;
    }
    1;
}

sub dir_has_files {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        next unless -f "$dir/$e";
        return 1;
    }
    0;
}

sub dir_has_dot_files {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        next unless $e =~ /\A\./;
        next unless -f "$dir/$e";
        return 1;
    }
    0;
}

sub dir_has_non_dot_files {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        next if $e =~ /\A\./;
        next unless -f "$dir/$e";
        return 1;
    }
    0;
}

sub dir_has_subdirs {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        next unless -d "$dir/$e";
        return 1;
    }
    0;
}

sub dir_has_dot_subdirs {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        next unless $e =~ /\A\./;
        next unless -d "$dir/$e";
        return 1;
    }
    0;
}

sub dir_has_non_dot_subdirs {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        next if $e =~ /\A\./;
        next unless -d "$dir/$e";
        return 1;
    }
    0;
}

sub get_dir_entries {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_dot_entries {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && /\A\./ } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_files {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && -f } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_dot_files {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && /\A\./ && -f } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_non_dot_files {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && !/\A\./ && -f } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_subdirs {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && -d } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_dot_subdirs {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && /\A\./ && -d } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_non_dot_subdirs {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && !/\A\./ && -d } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

1;
# ABSTRACT: File-related utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

File::MoreUtil - File-related utilities

=head1 VERSION

This document describes version 0.623 of File::MoreUtil (from Perl distribution File-MoreUtil), released on 2020-04-13.

=head1 SYNOPSIS

 use File::MoreUtil qw(
     file_exists
     l_abs_path
     dir_empty
     dir_has_files
     dir_has_dot_files
     dir_has_non_dot_files
     dir_has_subdirs
     dir_has_dot_subdirs
     dir_has_non_dot_subdirs

     dir_entries
     dir_dot_entries
     dir_non_dot_entries
 );

 print "file exists" if file_exists("/path/to/file/or/dir");
 print "absolute path = ", l_abs_path("foo");
 print "dir exists and is empty" if dir_empty("/path/to/dir");

=head1 DESCRIPTION

=head1 FUNCTIONS

None are exported by default, but they are exportable.

=head2 file_exists

Usage:

 file_exists($path) => BOOL

This routine is just like the B<-e> test, except that it assume symlinks with
non-existent target as existing. If C<sym> is a symlink to a non-existing
target:

 -e "sym"             # false, Perl performs stat() which follows symlink

but:

 -l "sym"             # true, Perl performs lstat()
 -e _                 # false

This function performs the following test:

 !(-l "sym") && (-e _) || (-l _)

=head2 l_abs_path

Usage:

 l_abs_path($path) => STR

Just like Cwd::abs_path(), except that it will not follow symlink if $path is
symlink (but it will follow symlinks for the parent paths).

Example:

 use Cwd qw(getcwd abs_path);

 say getcwd();              # /home/steven
 # s is a symlink to /tmp/foo
 say abs_path("s");         # /tmp/foo
 say l_abs_path("s");       # /home/steven/s
 # s2 is a symlink to /tmp
 say abs_path("s2/foo");    # /tmp/foo
 say l_abs_path("s2/foo");  # /tmp/foo

Mnemonic: l_abs_path -> abs_path is analogous to lstat -> stat.

Note: currently uses hardcoded C</> as path separator.

=head2 dir_empty

Usage:

 dir_empty($dir) => BOOL

Will return true if C<$dir> exists and is empty.

This should be trivial but alas it is not. C<-s> always returns true (in other
words, C<-z> always returns false) for a directory.

=head2 dir_has_files

Usage:

 dir_has_files($dir) => BOOL

Will return true if C<$dir> exists and has one or more plain files in it. A
plain file is one that passes Perl's C<-f> operator. A symlink to a plain file
counts as a plain file. Non-plain files include named pipes, Unix sockets, and
block/character special files.

=head2 dir_has_dot_files

Usage:

 dir_has_dot_files($dir) => BOOL

Will return true if C<$dir> exists and has one or more plain dot files in it.
See L</dir_has_files> for the definition of plain files. Dot files a.k.a. hidden
files are files with names beginning with a dot.

=head2 dir_has_non_dot_files

Usage:

 dir_has_non_dot_files($dir) => BOOL

Will return true if C<$dir> exists and has one or more plain non-dot files in
it. See L</dir_has_dot_files> for the definitions. =head2 dir_has_subdirs

=head2 dir_has_subdirs

Usage:

 dir_has_files($dir) => BOOL

Will return true if C<$dir> exists and has one or more subdirectories in it.

=head2 dir_has_dot_subdirs

Usage:

 dir_has_dot_subdirs($dir) => BOOL

Will return true if C<$dir> exists and has one or more dot subdirectories (i.e.
subdirectories with names beginning with a dot) in it.

=head2 dir_has_non_dot_subdirs

Usage:

 dir_has_non_dot_subdirs($dir) => BOOL

Will return true if C<$dir> exists and has one or more non-dot subdirectories
(i.e. subdirectories with names not beginning with a dot) in it.

=head2 get_dir_entries

Usage:

 my @entries = get_dir_entries([ $dir ]);

Get all entries of a directory specified by C<$dir> (or the current dir if
unspecified), including dotfiles but excluding "." and "..". Dies if directory
does not exist or cannot be read.

Basically a shortcut for something like:

 my @entries = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' } readdir $dh };

=head2 get_dir_dot_entries

Usage:

 my @dot_entries = get_dir_dot_entries([ $dir ]);

Get all "dot" entries of a directory specified by C<$dir> (or the current dir if
unspecified), excluding "." and "..". Dies if directory does not exist or cannot
be read.

Basically a shortcut for something like:

 my @dot_entries = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && /\A\./ } readdir $dh };

=head2 get_dir_files

Usage:

 my @filenames = get_dir_files([ $dir ]);

Get all filename entries of a directory specified by C<$dir> (or the current dir
if unspecified), including dotfiles but excluding "." and "..". Dies if
directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @filenames = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && -f } readdir $dh };

=head2 get_dir_dot_files

Usage:

 my @dot_filenames = get_dir_dot_files([ $dir ]);

Get all "dot" filename entries of a directory specified by C<$dir> (or the
current dir if unspecified). Dies if directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @dot_filenames = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && /\A\./ && -f } readdir $dh };

=head2 get_dir_non_dot_files

Usage:

 my @non_dot_filenames = get_dir_non_dot_files([ $dir ]);

Get all non-"dot" filename entries of a directory specified by C<$dir> (or the
current dir if unspecified). Dies if directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @non_dot_filenames = do { opendir my $dh, $dir; grep { !/\A\./ && -f } readdir $dh };

=head2 get_dir_subdirs

Usage:

 my @subdirnames = get_dir_subdirs([ $dir ]);

Get all subdirectory entries of a directory specified by C<$dir> (or the current
dir if unspecified), including dotsubdirs but excluding "." and "..". Dies if
directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @subdirnames = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && -d } readdir $dh };

=head2 get_dir_dot_subdirs

Usage:

 my @dot_subdirnames = get_dir_dot_subdirs([ $dir ]);

Get all "dot" subdirectory entries of a directory specified by C<$dir> (or the
current dir if unspecified). Dies if directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @dot_subdirnames = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && /\A\./ && -d } readdir $dh };

=head2 get_dir_non_dot_subdirs

Usage:

 my @non_dot_subdirnames = get_dir_non_dot_subdirs([ $dir ]);

Get all non-"dot" subdirectory entries of a directory specified by C<$dir> (or
the current dir if unspecified). Dies if directory does not exist or cannot be
read.

Basically a shortcut for something like:

 my @non_dot_subdirnames = do { opendir my $dh, $dir; grep { !/\A\./ && -d } readdir $dh };

=head1 FAQ

=head2 Where is file_empty()?

For checking if some path exists, is a plain file, and is empty (content is
zero-length), you can simply use the C<-z> filetest operator.

=head2 Where is get_dir_non_dot_entries()?

That would be a regular glob("*").

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-MoreUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SHARYANTO-File-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-MoreUtil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::FileTestUtils> includes CLI's for functions like L</dir_empty>, etc.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
