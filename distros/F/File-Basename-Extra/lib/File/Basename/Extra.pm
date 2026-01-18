package File::Basename::Extra;
use strict;
use warnings;

# ABSTRACT: Extension to File::Basename, adds named access to file parts and handling of filename suffixes
our $VERSION = '0.006'; # VERSION

#pod =head1 SYNOPSIS
#pod
#pod   # Note: by default no symbols get exported so make sure you export
#pod   # the ones you need!
#pod   use File::Basename::Extra qw(basename);
#pod
#pod   # basename and friends
#pod   my $file      = basename('/foo/bar/file.txt');          # "file.txt"
#pod   my $fileext   = basename_suffix('/foo/bar/file.txt');   # ".txt"
#pod   my $filenoext = basename_nosuffix('/foo/bar/file.txt'); # "file"
#pod
#pod   # dirname
#pod   my $dir       = dirname('/foo/bar/file.txt');           # "/foo/bar/"
#pod
#pod   # fileparse
#pod   my ($filename, $dirs, $suffix) = fileparse('/foo/bar/file.txt', qr/\.[^.]*/);
#pod                                                           # ("file", "/foo/bar/", ".txt")
#pod
#pod   # pathname
#pod   my $path      = pathname('/foo/bar/file.txt');          # "/foo/bar/"
#pod
#pod   # fullname and friends
#pod   my $full      = fullname('/foo/bar/file.txt');          # "/foo/bar/file.txt"
#pod   my $fullext   = fullname_suffix('/foo/bar/file.txt');   # ".txt"
#pod   my $fullnoext = fullname_nosuffix('/foo/bar/file.txt'); # "/foo/bar/file"
#pod
#pod   # getting/setting the default suffix patterns
#pod   my @patterns = default_suffix_patterns(); # Returns the currently active patterns
#pod
#pod   # setting the default suffix patterns
#pod   my @previous = default_suffix_patterns(qr/[._]bar/, '\.baz');
#pod                  # Now only .bar, _bar, and .baz are matched suffixes
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides functionalty for handling file name suffixes (aka
#pod file name extensions).
#pod
#pod =head1 SEE ALSO
#pod
#pod L<File::Basename> for the suffix matching and platform specific details.
#pod
#pod =cut

use File::Basename 2.74; # For _strip_trailing_sep

our @ISA = qw(Exporter File::Basename);
our @EXPORT = ();
our @EXPORT_OK = (@File::Basename::EXPORT,
                  qw(basename_suffix basename_nosuffix
                     filename filename_suffix filename_nosuffix
                     pathname
                     fullname fullname_suffix fullname_nosuffix
                     default_suffix_patterns));

my @default_suffix_patterns = (qr/\.[^.]*/);

# Special version of the fileparse function, used in the basename versions of the functions
sub _basename_fileparse {
    my $path = shift;
    my @suffix_patterns = @_ ? map { "\Q$_\E" } @_ : @default_suffix_patterns;

    # "hidden" function in File::Basename, strips final path separator
    # (e.g., / or \)
    File::Basename::_strip_trailing_sep($path);

    my($basename, $dirname, $suffix) = fileparse( $path, @suffix_patterns );

    # The suffix is not stripped if it is identical to the remaining
    # characters in string.
    if( length $suffix and !length $basename ) {
        $basename = $suffix;
        $suffix = '';
    }

    # Ensure that basename '/' == '/'
    if( !length $basename ) {
        $basename = $dirname;
        $dirname = '';
    }

    return ($basename, $dirname, $suffix);
}

#pod =func fileparse FILEPATH
#pod
#pod =func fileparse FILEPATH PATTERN_LIST
#pod
#pod =func basename FILEPATH
#pod
#pod =func basename FILEPATH PATTERN_LIST
#pod
#pod =func dirname FILEPATH
#pod
#pod =func fileparse_set_fstype FSTYPE
#pod
#pod These functions are exactly the same as the corresponding ones from
#pod L<File::Basename> except that they aren't exported by default.
#pod
#pod =func basename_suffix FILEPATH
#pod
#pod =func basename_suffix FILEPATH PATTERN_LIST
#pod
#pod Returns the file name suffix part of the given filepath. The default
#pod suffix patterns are used if none are provided. Behaves the same as
#pod C<basename>, i.e., it uses the last last level of a filepath as
#pod filename, even if the last level is clearly directory.
#pod
#pod Also, like C<basename>, files that consist of only a matched suffix
#pod are treated as if they do not have a suffix. So, using the default
#pod suffix pattern, C<basename_suffix('/Users/home/.profile')> would
#pod return an empty string.
#pod
#pod Note: Like the original C<basename> function from L<File::Basename>,
#pod suffix patterns are automatically escaped so pattern C<.bar> only
#pod matches C<.bar> and not e.g., C<_bar> (this is B<not> done for the
#pod default suffix patterns, nor for patterns provided to the non-basename
#pod family functions of this module!).
#pod
#pod =cut

sub basename_suffix {
    my (undef, undef, $suffix) = _basename_fileparse(@_);
    return $suffix;
}

#pod =func basename_nosuffix FILEPATH
#pod
#pod =func basename_nosuffix FILEPATH PATTERN_LIST
#pod
#pod Acts basically the same as the original C<basename> function, except
#pod that the default suffix patterns are used to strip the name of its
#pod suffixes when none are provided.
#pod
#pod Also, like C<basename>, files that consist of only a matched suffix
#pod are treated as if they do not have a suffix. So, using the default
#pod suffix pattern, C<basename_nosuffix('/Users/home/.profile')> would
#pod return C<.profile>.
#pod
#pod Note: Like the original C<basename> function from L<File::Basename>,
#pod suffix patterns are automatically escaped so pattern C<.bar> only
#pod matches C<.bar> and not e.g., C<_bar> (this is B<not> done for the
#pod default suffix patterns, nor for patterns provided to the non-basename
#pod family of functions of this module!).
#pod
#pod =cut

sub basename_nosuffix {
    my ($name, undef, undef) = _basename_fileparse(@_);
    return $name;
}

#pod =func filename FILEPATH
#pod
#pod =func filename FILEPATH PATTERN_LIST
#pod
#pod Returns just the filename of the filepath, optionally stripping the
#pod suffix when it matches a provided suffix patterns. Basically the same
#pod as calling C<fileparse> in scalar context.
#pod
#pod =cut

sub filename {
    my ($filename, undef, undef) = fileparse(@_);
    return $filename;
}

#pod =func filename_suffix FILEPATH
#pod
#pod =func filename_suffix FILEPATH PATTERN_LIST
#pod
#pod Returns the matched suffix of the filename. The default suffix
#pod patterns are used when none are provided.
#pod
#pod =cut

sub filename_suffix {
    my $fullname = shift;
    my (undef, undef, $suffix) = fileparse($fullname, (@_ ? @_ : @default_suffix_patterns));
    return $suffix;
}

#pod =func filename_nosuffix FILEPATH
#pod
#pod =func filename_nosuffix FILEPATH PATTERN_LIST
#pod
#pod Returns the filename with the the matched suffix stripped. The default
#pod suffix patterns are used when none are provided.
#pod
#pod =cut

sub filename_nosuffix {
    my $fullname = shift;
    my ($filename, undef, undef) = fileparse($fullname, (@_ ? @_ : @default_suffix_patterns));
    return $filename;
}

#pod =func pathname FILEPATH
#pod
#pod Returns the path part of the file. Contrary to C<dirname>, a filepath
#pod that is clearly a directory, is treated as such (e.g., on Unix,
#pod C<pathname('/foo/bar/')> returns C</foo/bar/>).
#pod
#pod =cut

sub pathname {
    my (undef, $pathname, undef) = fileparse(@_);
    return $pathname;
}

#pod =func fullname FILEPATH
#pod
#pod =func fullname FILEPATH PATTERN_LIST
#pod
#pod Returns the provided filepath, optionally stripping the filename of
#pod its matching suffix.
#pod
#pod =cut

sub fullname {
    my $fullname = shift;
    return @_ ? fullname_nosuffix($fullname, @_) : $fullname;
}

#pod =func fullname_suffix FILEPATH
#pod
#pod =func fullname_suffix FILEPATH PATTERN_LIST
#pod
#pod Synonym for filename_suffix.
#pod
#pod =cut

*fullname_suffix = *filename_suffix;

#pod =func fullname_nosuffix FILEPATH
#pod
#pod =func fullname_nosuffix FILEPATH PATTERN_LIST
#pod
#pod Returns the full filepath with the the matched suffix stripped. The
#pod default suffix patterns are used when none are provided.
#pod
#pod =cut

sub fullname_nosuffix {
    my $fullname = shift;
    my $suffix = filename_suffix($fullname, @_);
    $fullname =~ s/\Q$suffix\E$// if $suffix;
    return $fullname;
}

#pod =func default_suffix_patterns
#pod
#pod =func default_suffix_patterns NEW_PATTERN_LIST
#pod
#pod The default suffix pattern list (see the C<fileparse> function in
#pod L<File::Basename> for details) is C<qr/\.[^.]*/>. Meaning that this
#pod defines the suffix as the part of the filename from (and including)
#pod the last dot. In other words, the part of a filename that is popularly
#pod known as the file extension.
#pod
#pod You can alter the suffix matching by proving this function with a
#pod different pattern list.
#pod
#pod This function returns the pattern list that was effective I<before>
#pod optionally changing it.
#pod
#pod =cut

sub default_suffix_patterns {
    my @org_suffix_patterns = @default_suffix_patterns;
    @default_suffix_patterns = @_ if @_;
    return @org_suffix_patterns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Basename::Extra - Extension to File::Basename, adds named access to file parts and handling of filename suffixes

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  # Note: by default no symbols get exported so make sure you export
  # the ones you need!
  use File::Basename::Extra qw(basename);

  # basename and friends
  my $file      = basename('/foo/bar/file.txt');          # "file.txt"
  my $fileext   = basename_suffix('/foo/bar/file.txt');   # ".txt"
  my $filenoext = basename_nosuffix('/foo/bar/file.txt'); # "file"

  # dirname
  my $dir       = dirname('/foo/bar/file.txt');           # "/foo/bar/"

  # fileparse
  my ($filename, $dirs, $suffix) = fileparse('/foo/bar/file.txt', qr/\.[^.]*/);
                                                          # ("file", "/foo/bar/", ".txt")

  # pathname
  my $path      = pathname('/foo/bar/file.txt');          # "/foo/bar/"

  # fullname and friends
  my $full      = fullname('/foo/bar/file.txt');          # "/foo/bar/file.txt"
  my $fullext   = fullname_suffix('/foo/bar/file.txt');   # ".txt"
  my $fullnoext = fullname_nosuffix('/foo/bar/file.txt'); # "/foo/bar/file"

  # getting/setting the default suffix patterns
  my @patterns = default_suffix_patterns(); # Returns the currently active patterns

  # setting the default suffix patterns
  my @previous = default_suffix_patterns(qr/[._]bar/, '\.baz');
                 # Now only .bar, _bar, and .baz are matched suffixes

=head1 DESCRIPTION

This module provides functionalty for handling file name suffixes (aka
file name extensions).

=head1 FUNCTIONS

=head2 fileparse FILEPATH

=head2 fileparse FILEPATH PATTERN_LIST

=head2 basename FILEPATH

=head2 basename FILEPATH PATTERN_LIST

=head2 dirname FILEPATH

=head2 fileparse_set_fstype FSTYPE

These functions are exactly the same as the corresponding ones from
L<File::Basename> except that they aren't exported by default.

=head2 basename_suffix FILEPATH

=head2 basename_suffix FILEPATH PATTERN_LIST

Returns the file name suffix part of the given filepath. The default
suffix patterns are used if none are provided. Behaves the same as
C<basename>, i.e., it uses the last last level of a filepath as
filename, even if the last level is clearly directory.

Also, like C<basename>, files that consist of only a matched suffix
are treated as if they do not have a suffix. So, using the default
suffix pattern, C<basename_suffix('/Users/home/.profile')> would
return an empty string.

Note: Like the original C<basename> function from L<File::Basename>,
suffix patterns are automatically escaped so pattern C<.bar> only
matches C<.bar> and not e.g., C<_bar> (this is B<not> done for the
default suffix patterns, nor for patterns provided to the non-basename
family functions of this module!).

=head2 basename_nosuffix FILEPATH

=head2 basename_nosuffix FILEPATH PATTERN_LIST

Acts basically the same as the original C<basename> function, except
that the default suffix patterns are used to strip the name of its
suffixes when none are provided.

Also, like C<basename>, files that consist of only a matched suffix
are treated as if they do not have a suffix. So, using the default
suffix pattern, C<basename_nosuffix('/Users/home/.profile')> would
return C<.profile>.

Note: Like the original C<basename> function from L<File::Basename>,
suffix patterns are automatically escaped so pattern C<.bar> only
matches C<.bar> and not e.g., C<_bar> (this is B<not> done for the
default suffix patterns, nor for patterns provided to the non-basename
family of functions of this module!).

=head2 filename FILEPATH

=head2 filename FILEPATH PATTERN_LIST

Returns just the filename of the filepath, optionally stripping the
suffix when it matches a provided suffix patterns. Basically the same
as calling C<fileparse> in scalar context.

=head2 filename_suffix FILEPATH

=head2 filename_suffix FILEPATH PATTERN_LIST

Returns the matched suffix of the filename. The default suffix
patterns are used when none are provided.

=head2 filename_nosuffix FILEPATH

=head2 filename_nosuffix FILEPATH PATTERN_LIST

Returns the filename with the the matched suffix stripped. The default
suffix patterns are used when none are provided.

=head2 pathname FILEPATH

Returns the path part of the file. Contrary to C<dirname>, a filepath
that is clearly a directory, is treated as such (e.g., on Unix,
C<pathname('/foo/bar/')> returns C</foo/bar/>).

=head2 fullname FILEPATH

=head2 fullname FILEPATH PATTERN_LIST

Returns the provided filepath, optionally stripping the filename of
its matching suffix.

=head2 fullname_suffix FILEPATH

=head2 fullname_suffix FILEPATH PATTERN_LIST

Synonym for filename_suffix.

=head2 fullname_nosuffix FILEPATH

=head2 fullname_nosuffix FILEPATH PATTERN_LIST

Returns the full filepath with the the matched suffix stripped. The
default suffix patterns are used when none are provided.

=head2 default_suffix_patterns

=head2 default_suffix_patterns NEW_PATTERN_LIST

The default suffix pattern list (see the C<fileparse> function in
L<File::Basename> for details) is C<qr/\.[^.]*/>. Meaning that this
defines the suffix as the part of the filename from (and including)
the last dot. In other words, the part of a filename that is popularly
known as the file extension.

You can alter the suffix matching by proving this function with a
different pattern list.

This function returns the pattern list that was effective I<before>
optionally changing it.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker
L<website|https://github.com/HayoBaan/File-Basename-Extra/issues>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Basename> for the suffix matching and platform specific details.

=head1 AUTHOR

Hayo Baan <info@hayobaan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Hayo Baan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
