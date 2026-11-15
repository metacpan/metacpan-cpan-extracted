########################################################################
# housekeeping
########################################################################
package FindBin::Parents  v1.0.0;
use v5.40;
use parent qw( Exporter );

use Carp            qw( croak   );

use File::Spec::Functions
qw
(
    splitpath
    splitdir
    catdir
    catpath
    file_name_is_absolute
);

use FindBin::Bin    qw( canon_dir pwd );

########################################################################
# package variables and sanity checks 
########################################################################

our @EXPORT_OK  
= qw
(
    dir_paths
    clear_parent_cache
);

my %path2dirz   = ();

########################################################################
# utility subs
########################################################################

########################################################################
# exported
########################################################################

# empty the cache, releasing its memory.

sub clear_parent_cache()
{
    %path2dirz  = ();
}

sub dir_paths( $path, $assume_dir = undef )
{
    # $assume_dir short circuits the "-d" test, mainly
    # for processing non-existent directories in testing.

    $path
    or croak 'Bogus dir_paths: false path argument.';

    my $dir
    = $path eq 'pwd'
    ? pwd
    : $path
    ;

    # a relative $path would be checked with -d against the current
    # directory but walked from the cached pwd(): after a chdir
    # these differ.

    file_name_is_absolute $dir
    or croak "Bogus dir_paths: '$path' is not an absolute path.";

    my $is_dir  
    = defined $assume_dir
    ? $assume_dir
    : -e $dir
    ? -d $dir
    : croak "Bogus dir_paths: '$path' does not exist; "
    . "pass \$assume_dir to treat it as a directory (true) or a file ('')."
    ;

    my $dirz
    = $path2dirz{ $dir . $; . "$is_dir" }
    ||= do
    {
        my ( $vol, $dir_part ) = splitpath $dir, $is_dir;

        my @dirz    = splitdir canon_dir $dir_part;

        # fix for File::Spec::VMS missing the leading empty
        # string on a split. this can be removed once File::Spec
        # is fixed -- which appears to be never.
        #
        # on *NIX and MSW the root splits to ( '', '' ): both are
        # removed, otherwise the second lists the root twice.

        my $tmp
        = $dirz[0] ne ''
        ? ''
        : $dirz[1] ne ''
          ? shift @dirz
          : splice @dirz, 0, 2
        ;

        [
            reverse
            map
            {
                catpath $vol => $_, ''
            }
            map
            {
                $tmp    = catdir $tmp, $_
            }
            (
                '' => @dirz[0..$#dirz]
            )
        ]
    };

    wantarray
    ?   @$dirz
    : [ @$dirz ]
}

1
__END__

=head1 NAME

FindBin::Parents - List the parent directories of a path, from the path to root.

=head1 SYNOPSIS

    use FindBin::Parents qw( dir_paths );

    # on *NIX (incl. OSX)
    # '/foo/bar/bim/bam' yields
    # /foo/bar/bim/bam
    # /foo/bar/bim
    # /foo/bar
    # /foo
    # /
    #
    # on VMS
    # 'Bletch$Blort:[foo.bar.bim.bam]' yields
    # Bletch$Blort:[foo.bar.bim.bam]
    # Bletch$Blort:[foo.bar.bim]
    # Bletch$Blort:[foo.bar]
    # Bletch$Blort:[foo]
    # followed by the device root.
    #
    # on MSW
    # 'z:/foo/bar/bim/bam' yields
    # z:\foo\bar\bim\bam
    # z:\foo\bar\bim
    # z:\foo\bar
    # z:\foo
    # z:\
    #
    # (each example assumes the path is an existing directory,
    # see below.)
    #
    # $path must be absolute, or the literal 'pwd'; a relative
    # path croaks (see "Relative paths" below).  the directory is
    # passed through FindBin::Bin::canon_dir, which cleans '.' and
    # '..' without resolving symlinks.
    #
    # note that the return value is context-sensitive:

    my $array_ref   = dir_paths $path;
    my @array       = dir_paths $path;

    # the second argument, $assume_dir, decides whether the last
    # component of $path is a directory:
    #
    # defined: used as given, without examining the path.  this
    # is for paths that do not exist, mainly in testing, or before
    # creating a directory, e.g., to check the directories above a
    # temporary directory.  a true value treats the path as a
    # directory; a defined false value ('' or 0) treats the last
    # component as a file.
    #
    # not given or undef: the path must exist and is checked with
    # -d.  a directory is the first entry; anything else (e.g., a
    # file such as $0) is dropped and the walk starts at its
    # parent.  a path that does not exist croaks: there is nothing
    # to check.
    #
    # see also: File::Spec::splitpath.

    # $assume_dir not given or undef, the path exists:

    dir_paths '/etc';                     # /etc /       (a directory)
    dir_paths '/etc/passwd';              # /etc /       (a file)
    dir_paths '/etc', undef;              # same as not given

    # $assume_dir not given or undef, the path does not exist:

    dir_paths '/foo/bar/bletch';          # croaks

    # $assume_dir defined, the path need not exist:

    dir_paths '/foo/bar/bletch', 1;       # /foo/bar/bletch /foo/bar /foo /
    dir_paths '/foo/bar/bletch', '';      # /foo/bar /foo /
    dir_paths '/usr/bin', '';             # /usr /  ('' overrides -d)

    # full example of a non-existent path with assume_dir true
    # or false:

    my @found
    = dir_paths '/foo/bar/bletch/blort/non-existent', 1;

    # returns:
    # /foo/bar/bletch/blort/non-existent    <- second argument true
    # /foo/bar/bletch/blort
    # /foo/bar/bletch
    # /foo/bar
    # /foo
    # /

    my @found
    = dir_paths '/foo/bar/bletch/blort/non-existent', '';

    # returns:
    # /foo/bar/bletch/blort
    # /foo/bar/bletch
    # /foo/bar
    # /foo
    # /

    # without the second argument this path croaks, since it
    # does not exist.

    # The literal string 'pwd' is a shorthand: dir_paths resolves it
    # to FindBin::Bin::pwd before the walk.  No separate import of
    # pwd is required:

    use FindBin::Parents qw( dir_paths );

    my @above_cwd = dir_paths 'pwd';

    # If the working directory is /home/user/projects/myapp:
    # /home/user/projects/myapp
    # /home/user/projects
    # /home/user
    # /home
    # /

    # This differs from passing $Bin_l or $Bin_p, which walk up from
    # the directory containing the running program ($0), not from CWD.
    # In most scripts those are the same; they diverge when the script
    # is invoked from a different directory or via a wrapper.

    # To resolve symlinks in the CWD before the walk, call pwd yourself
    # and pass the result through Cwd::abs_path:

    use FindBin::Bin    qw( pwd );
    use Cwd             qw( abs_path );

    my @above_real_cwd = dir_paths abs_path( pwd );

    # A relative path croaks; convert it to an absolute path first.
    # canon_dir prepends pwd, giving a logical path; prepending the
    # physical working directory gives a physical one.  'lib' must
    # exist, or pass $assume_dir:

    use FindBin::Bin            qw( canon_dir pwd );
    use Cwd                     qw( abs_path );
    use File::Spec::Functions   qw( catdir );

    my @logical     = dir_paths canon_dir 'lib';
    my @physical    = dir_paths canon_dir catdir abs_path( pwd ), 'lib';

    # Relative to the program's directory: prepend $Bin, $Bin_l, or
    # $Bin_p and clean the result with canon_dir.  '..' is removed
    # lexically, so it climbs the logical path with $Bin_l and the
    # physical path with $Bin_p:

    use FindBin::Bin            qw( canon_dir $Bin $Bin_l $Bin_p );

    my @from_bin    = dir_paths canon_dir catdir $Bin,   '..', 'lib';
    my @from_bin_l  = dir_paths canon_dir catdir $Bin_l, '..', 'lib';
    my @from_bin_p  = dir_paths canon_dir catdir $Bin_p, '..', 'lib';

=head1 DESCRIPTION

C<FindBin::Parents> exports C<dir_paths>, which returns the given
path, if it is a directory, and each of its ancestors through root,
nearest first.  If the last component of the path is not a
directory the list starts at its parent.  A path that does not
exist croaks unless C<$assume_dir> says what it is.

The canonical use is to inspect which directories C<FindBin::libs>
searched when looking for C<lib>, C<etc>, or other named trees:

    use FindBin::Bin    qw( $Bin_l $Bin_p );
    use FindBin::Parents qw( dir_paths );

    # show the logical walk (what FindBin::libs sees with noabspath)
    say for dir_paths $Bin_l;

    # show the physical walk (what FindBin::libs sees by default)
    say for dir_paths $Bin_p;

    # show the walk above CWD (independent of $0)
    say for dir_paths 'pwd';

Passing the literal string C<'pwd'> is a built-in shorthand: C<dir_paths>
calls C<FindBin::Bin::pwd> internally and uses the result as the starting
path, without requiring the caller to import C<pwd>.  C<pwd> returns
the logical working directory (symlinks preserved, like C<pwd -L>)
when C<$ENV{ PWD }> is valid; otherwise it warns and returns
C<getcwd>, with symlinks resolved.  It caches its first result, so
C<'pwd'> is the working directory at that first call: a later
C<chdir> does not change it.  See L<FindBin::Bin/pwd()>.

C<'pwd'> is useful when the script is invoked from a directory different
from the one it lives in.  It produces a walk up from where the process
is I<running>, whereas C<$Bin_l> and C<$Bin_p> walk up from where the
script I<lives>.  In interactive sessions (e.g., C<perl -d -e 0>) there
is no script: C<$Bin_l> is C<pwd> and C<$Bin_p> is its physical path.

=head2 Relative paths

C<dir_paths> requires an absolute path.  A relative path would be
checked with C<-e> and C<-d> against the process's current directory but
walked from C<FindBin::Bin::pwd>, which is cached: after a C<chdir>
the two differ.  Rejecting relative paths leaves the caller to
choose which directory they are relative to:

=over 4

=item logical

C<canon_dir $relative> prepends C<pwd>, symlinks preserved.

=item physical

C<canon_dir catdir abs_path( pwd ), $relative> prepends the
working directory with symlinks resolved.

=item program directory

C<canon_dir catdir $Bin, $relative>,
C<canon_dir catdir $Bin_l, $relative>, or
C<canon_dir catdir $Bin_p, $relative> makes it relative to the
directory of C<$0>.

=back

=head3 Paths relative to the program: $Bin, $Bin_l, $Bin_p

C<FindBin::Bin> gives the program's directory two ways: C<$Bin_l>,
the logical path (symlinks preserved), and C<$Bin_p>, the physical
path (symlinks resolved).  C<$Bin> is C<$Bin_p> by default and
C<$Bin_l> with C<noabspath>, matching the path C<FindBin::libs>
searches from.  All three are absolute.

C<canon_dir> cleans C<.> and C<..> lexically, without examining the
filesystem.  Applied to one of these with a relative path appended,
C<..> removes the preceding component of that path: with C<$Bin_l>
it climbs the logical tree, with C<$Bin_p> the physical one.  These
differ when the program's directory is reached through a symlink:

    # /home/user/bin is a symlink to /opt/tools/bin,
    # the program is /home/user/bin/frobnicate:
    #
    # $Bin_l = /home/user/bin
    # $Bin_p = /opt/tools/bin

    dir_paths canon_dir catdir $Bin_l, '..', 'lib';
    # /home/user/lib /home/user /home /

    dir_paths canon_dir catdir $Bin_p, '..', 'lib';
    # /opt/tools/lib /opt/tools /opt /

Each path must exist, or C<$assume_dir> must be given; see
L</$assume_dir>.

See L<FindBin::Bin/canon_dir()>, L<FindBin::Bin/$Bin_l and Bin_l()>,
L<FindBin::Bin/$Bin_p and Bin_p()>, and
L<FindBin::Bin/$Bin and Bin()>.

=head2 Arguments

=over 4

=item $path

The starting path, which must be absolute.  The literal C<'pwd'>
is replaced by C<FindBin::Bin::pwd>.  A false path, including
C<'0'>, croaks with C<Bogus dir_paths: false path argument.>  A
relative path croaks with
C<Bogus dir_paths: '$path' is not an absolute path.>  Without
C<$assume_dir>, a path that does not exist croaks with
C<Bogus dir_paths: '$path' does not exist; pass $assume_dir to treat
it as a directory (true) or a file ('').>

=item $assume_dir

Optional.  Whether the last component of C<$path> is a directory:

=over 4

=item defined

Used as given; the path is not examined and need not exist.  A
true value treats the path as a directory, so it is the first
entry:

    dir_paths '/foo/bar/bletch', 1;   # /foo/bar/bletch /foo/bar /foo /

A defined false value (C<''> or C<0>) treats the last component as
a file, so the list starts at its parent, even for an existing
directory:

    dir_paths '/foo/bar/bletch', '';  # /foo/bar /foo /
    dir_paths '/usr/bin', '';         # /usr /

This is for paths that do not exist, mainly in testing.

It is also useful before creating a directory.  The security of a
temporary directory depends on the directories above it: anyone who
can write to one of them can rename or replace what is below it.
When that affects the code's execution, list the directories above
the planned path and check them before creating it:

    my $tmpdir  = catdir $base, "frobnicate.$$";

    for my $dir ( dir_paths $tmpdir, '' )
    {
        # e.g., owned by root or the user, not group or other
        # writable unless sticky, as /tmp is.
        ...
    }

    mkdir $tmpdir, 0700
    or die "mkdir '$tmpdir': $!";

With C<''> the planned directory itself is dropped, and the walk
starts at C<$base>, which must exist to be checked.  With C<1> the
list starts at C<$tmpdir>, before it exists.

=item not given, or undef, and the path exists

The path is checked with C<-d>.  A directory is the first entry;
anything else, such as a file, is dropped:

    dir_paths '/etc';                 # /etc /
    dir_paths '/etc/passwd';          # /etc /

=item not given, or undef, and the path does not exist

There is nothing to check, so C<dir_paths> croaks:

    dir_paths '/foo/bar/bletch';      # croaks

=back

=back

=head2 Return value

In list context, the list of directories.  In scalar context, a
reference to a copy of that list: changing it does not change the
cache.

=head2 Caching

Results are cached by C<$path> as given (C<'pwd'> replaced by
C<FindBin::Bin::pwd>) and whether its last component is treated as
a directory (C<$assume_dir>, or the C<-e> and C<-d> tests, made on
every call before the cache is consulted).

The walk is computed from those strings alone, without examining
the filesystem: C<canon_dir> cleans the path lexically and
C<FindBin::Bin::pwd> is cached.  Relative paths, which would depend
on the current directory, are rejected.  A cached entry does not
go stale, including after a C<chdir>.  C<clear_parent_cache> empties the cache,
releasing its memory:

    use FindBin::Parents qw( dir_paths clear_parent_cache );

    clear_parent_cache;

=head1 SEE ALSO

=over 4

=item L<FindBin::Bin>

C<$Bin>, C<$Bin_l>, and C<$Bin_p> for the program's directory;
L<FindBin::Bin/pwd()> for the working
directory, its C<$ENV{ PWD }> check, and caching;
L<FindBin::Bin/canon_dir()> for converting relative paths;
L<FindBin::Bin/Resolving the working directory> for C<chdir>.

=item L<FindBin::libs>

=back

