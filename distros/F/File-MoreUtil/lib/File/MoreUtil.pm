## no critic: Subroutines::ProhibitExplicitReturnUndef
package File::MoreUtil;

use 5.010001;
use strict;
use warnings;

use Cwd ();
use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-02'; # DATE
our $DIST = 'File-MoreUtil'; # DIST
our $VERSION = '0.628'; # VERSION

our @EXPORT_OK = qw(
                       file_exists
                       l_abs_path
                       dir_empty
                       dir_not_empty
                       dir_has_entries
                       dir_has_files
                       dir_has_dot_files
                       dir_has_non_dot_files
                       dir_has_subdirs
                       dir_has_non_subdirs
                       dir_has_dot_subdirs
                       dir_has_non_dot_subdirs
                       dir_only_has_files
                       dir_only_has_dot_files
                       dir_only_has_non_dot_files
                       dir_only_has_subdirs
                       dir_only_has_dot_subdirs
                       dir_only_has_non_dot_subdirs

                       get_dir_entries
                       get_dir_dot_entries
                       get_dir_subdirs
                       get_dir_non_subdirs
                       get_dir_dot_subdirs
                       get_dir_non_dot_subdirs
                       get_dir_files
                       get_dir_dot_files
                       get_dir_non_dot_files
                       get_dir_only_file
                       get_dir_only_subdir
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

sub dir_not_empty {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return 1;
    }
    0;
}

sub dir_has_entries { goto \&dir_not_empty }

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

sub dir_only_has_files {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    my $has_files;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return 0 unless -f "$dir/$e";
        $has_files++;
    }
    $has_files ? 1:0;
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

sub dir_only_has_dot_files {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    my $has_dot_files;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return 0 unless $e =~ /\A\./;
        return 0 unless -f "$dir/$e";
        $has_dot_files++;
    }
    $has_dot_files ? 1:0;
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

sub dir_only_has_non_dot_files {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    my $has_nondot_files;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return 0 if $e =~ /\A\./;
        return 0 unless -f "$dir/$e";
        $has_nondot_files++;
    }
    $has_nondot_files ? 1:0;
}

sub dir_has_subdirs {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        next if -l "$dir/$e";
        next unless -d _;
        return 1;
    }
    0;
}

sub dir_only_has_subdirs {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    my $has_subdirs;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return 0 unless -d "$dir/$e";
        $has_subdirs++;
    }
    $has_subdirs ? 1:0;
}

sub dir_has_non_subdirs {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return 1 if -l "$dir/$e";
        return 1 if !(-d _);
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
        next if -l "$dir/$e";
        next unless -d _;
        return 1;
    }
    0;
}

sub dir_only_has_dot_subdirs {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    my $has_dot_subdirs;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return 0 unless $e =~ /\A\./;
        return 0 unless -d "$dir/$e";
        $has_dot_subdirs++;
    }
    $has_dot_subdirs ? 1:0;
}

sub dir_has_non_dot_subdirs {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        next if $e =~ /\A\./;
        next if -l "$dir/$e";
        next unless -d _;
        return 1;
    }
    0;
}

sub dir_only_has_non_dot_subdirs {
    my ($dir) = @_;
    return undef unless (-d $dir);
    return undef unless opendir my($dh), $dir;
    my $has_nondot_subdirs;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return 0 if $e =~ /\A\./;
        return 0 unless -d "$dir/$e";
        $has_nondot_subdirs++;
    }
    $has_nondot_subdirs ? 1:0;
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
    my @res = grep { $_ ne '.' && $_ ne '..' && (-f "$dir/$_")} readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_dot_files {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && /\A\./ && (-f "$dir/$_")} readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_non_dot_files {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && !/\A\./ && (-f "$dir/$_")} readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_subdirs {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && !(-l "$dir/$_") && (-d _) } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_non_subdirs {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && ((-l "$dir/$_") || !(-d _)) } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_dot_subdirs {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && /\A\./ && !(-l "$dir/$_") && (-d _) } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_non_dot_subdirs {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my @res = grep { $_ ne '.' && $_ ne '..' && !/\A\./ && !(-l "$dir/$_") && (-d _) } readdir $dh;
    closedir $dh; # we're so nice
    @res;
}

sub get_dir_only_file {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my $res;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return unless -f "$dir/$e";
        return if defined $res;
        $res = $e;
    }
    return unless defined $res;
    $res;
}

sub get_dir_only_subdir {
    my ($dir) = @_;
    $dir //= ".";
    opendir my($dh), $dir or die "Can't opendir $dir: $!";
    my $res;
    while (defined(my $e = readdir $dh)) {
        next if $e eq '.' || $e eq '..';
        return unless -d "$dir/$e";
        return if defined $res;
        $res = $e;
    }
    return unless defined $res;
    $res;
}

1;
# ABSTRACT: File-related utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

File::MoreUtil - File-related utilities

=head1 VERSION

This document describes version 0.628 of File::MoreUtil (from Perl distribution File-MoreUtil), released on 2023-11-02.

=head1 SYNOPSIS

 use File::MoreUtil qw(
     file_exists
     l_abs_path
     dir_empty
     dir_has_files
     dir_has_dot_files
     dir_has_non_dot_files
     dir_has_subdirs
     dir_has_non_subdirs
     dir_has_dot_subdirs
     dir_has_non_dot_subdirs
     dir_only_has_files
     dir_only_has_dot_files
     dir_only_has_non_dot_files
     dir_only_has_subdirs
     dir_only_has_dot_subdirs
     dir_only_has_non_dot_subdirs

     get_dir_entries
     get_dir_dot_entries
     get_dir_subdirs
     get_dir_non_subdirs
     get_dir_dot_subdirs
     get_dir_non_dot_subdirs
     get_dir_files
     get_dir_dot_files
     get_dir_non_dot_files
     get_dir_only_file
     get_dir_only_subdir
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

Which one should you use: C<-e> or C<file_exists>? It depends on whether you
want to consider a broken symlink as "existing" or not. Sometimes one is more
appropriate than the other. If you use C<-e>, your application might overwrite a
(temporarily) broken symlink; on the other hand if you use C<file_exists>, your
application will see a file as existing but gets confused when it cannot open
it.

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

To test that a directory is C<not> empty, use L</dir_not_empty> (or its alias
L</dir_has_entries>).

=head2 dir_not_empty

Usage:

 dir_not_empty($dir) => BOOL

Will return true if C<$dir> exists and is not empty (has entries other than C<.>
and C<..>).

To test that a directory is empty, use L</dir_empty>.

=head2 dir_has_entries

Alias for L</dir_not_empty>.

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

 dir_has_subdirs($dir) => BOOL

Will return true if C<$dir> exists and has one or more subdirectories in it. A
symlink to a directory does I<NOT> count as subdirectory.

=head2 dir_has_non_subdirs

Usage:

 dir_has_non_subdirs($dir) => BOOL

Will return true if C<$dir> exists and has one or more non-subdirectories in it.
A symlink to a directory does I<NOT> count as subdirectory and thus counts as a
non-subdirectory.

=head2 dir_has_dot_subdirs

Usage:

 dir_has_dot_subdirs($dir) => BOOL

Will return true if C<$dir> exists and has one or more dot subdirectories (i.e.
subdirectories with names beginning with a dot) in it. A symlink to a directory
does I<NOT> count as subdirectory.

=head2 dir_has_non_dot_subdirs

Usage:

 dir_has_non_dot_subdirs($dir) => BOOL

Will return true if C<$dir> exists and has one or more non-dot subdirectories
(i.e. subdirectories with names not beginning with a dot) in it. A symlink to a
directory does I<NOT> count as subdirectory.

=head2 dir_only_has_files

Usage:

 dir_only_has_files($dir) => BOOL

Will return true if C<$dir> exists and has one or more plain files in it *and*
does not have anything else. See L</dir_has_files> for the definition of plain
files.

=head2 dir_only_has_dot_files

Usage:

 dir_only_has_dot_files($dir) => BOOL

Will return true if C<$dir> exists and has one or more plain dot files in it
*and* does not have anything else. See L</dir_has_files> for the definition of
plain files.

=head2 dir_only_has_non_dot_files

Usage:

 dir_only_has_non_dot_files($dir) => BOOL

Will return true if C<$dir> exists and has one or more plain non-dot files in it
*and* does not have anything else. See L</dir_has_files> for the definition of
plain files.

=head2 dir_only_has_subdirs

Usage:

 dir_only_has_subdirs($dir) => BOOL

Will return true if C<$dir> exists and has one or more subdirectories in it
*and* does not have anything else.

=head2 dir_only_has_dot_subdirs

Usage:

 dir_only_has_dot_subdirs($dir) => BOOL

Will return true if C<$dir> exists and has one or more dot subdirectories in it
*and* does not have anything else.

=head2 dir_only_has_non_dot_subdirs

Usage:

 dir_only_has_non_dot_subdirs($dir) => BOOL

Will return true if C<$dir> exists and has one or more plain non-dot
subdirectories in it *and* does not have anything else.

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

Get all plain filename entries of a directory specified by C<$dir> (or the
current dir if unspecified), including dotfiles but excluding "." and "..". See
L</dir_has_files> for definition of "plain files". Dies if directory does not
exist or cannot be read.

Basically a shortcut for something like:

 my @filenames = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && -f } readdir $dh };

=head2 get_dir_dot_files

Usage:

 my @dot_filenames = get_dir_dot_files([ $dir ]);

Get all "dot" plain filename entries of a directory specified by C<$dir> (or the
current dir if unspecified). See L</dir_has_files> for definition of "plain
files". Dies if directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @dot_filenames = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && /\A\./ && -f } readdir $dh };

=head2 get_dir_non_dot_files

Usage:

 my @non_dot_filenames = get_dir_non_dot_files([ $dir ]);

Get all non-"dot" plain filename entries of a directory specified by C<$dir> (or
the current dir if unspecified). See L</dir_has_files> for definition of "plain
files". Dies if directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @non_dot_filenames = do { opendir my $dh, $dir; grep { !/\A\./ && -f } readdir $dh };

=head2 get_dir_subdirs

Usage:

 my @subdirnames = get_dir_subdirs([ $dir ]);

Get all subdirectory entries of a directory specified by C<$dir> (or the current
dir if unspecified), including dotsubdirs but excluding "." and "..". See
L</dir_has_subdirs> for definition of "subdirectories". Dies if directory does
not exist or cannot be read.

Basically a shortcut for something like:

 my @subdirnames = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && !(-l) && (-d _) } readdir $dh };

=head2 get_dir_non_subdirs

Usage:

 my @nonsubdirnames = get_dir_non_subdirs([ $dir ]);

Get all non-subdirectory entries of a directory specified by C<$dir> (or the
current dir if unspecified). See L</dir_has_subdirs> for definition of
"subdirectories". Dies if directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @nonsubdirnames = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && !(-l) && !(-d) } readdir $dh };

=head2 get_dir_dot_subdirs

Usage:

 my @dot_subdirnames = get_dir_dot_subdirs([ $dir ]);

Get all "dot" subdirectory entries of a directory specified by C<$dir> (or the
current dir if unspecified). See L</dir_has_subdirs> for definition of
"subdirectories". Dies if directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @dot_subdirnames = do { opendir my $dh, $dir; grep { $_ ne '.' && $_ ne '..' && /\A\./ && -d } readdir $dh };

=head2 get_dir_non_dot_subdirs

Usage:

 my @non_dot_subdirnames = get_dir_non_dot_subdirs([ $dir ]);

Get all non-"dot" subdirectory entries of a directory specified by C<$dir> (or
the current dir if unspecified). See L</dir_has_subdirs> for definition of
"subdirectories". Dies if directory does not exist or cannot be read.

Basically a shortcut for something like:

 my @non_dot_subdirnames = do { opendir my $dh, $dir; grep { !/\A\./ && -d } readdir $dh };

=head2 get_dir_only_file

Usage:

 my $filename = get_dir_only_file([ $dir ]);

Return filename inside directory C<$dir> (or current directory if unspecified)
only if C<$dir> has a single plain file and nothing else.

=head2 get_dir_only_subdir

Usage:

 my $subdirname = get_dir_only_subdir([ $dir ]);

Return subdirectory name inside directory C<$dir> (or current directory if
unspecified) only if C<$dir> has a single subdirectory and nothing else.

=head1 FAQ

=head2 Where is file_empty()?

For checking if some path exists, is a plain file, and is empty (content is
zero-length), you can simply use the C<-s> or C<-z> filetest operator.

=head2 Where is get_dir_non_dot_entries()?

That would be a regular glob("*").

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-MoreUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-MoreUtil>.

=head1 SEE ALSO

L<App::FileTestUtils> includes CLI's for functions like L</dir_empty>, etc.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2020, 2019, 2017, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-MoreUtil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
