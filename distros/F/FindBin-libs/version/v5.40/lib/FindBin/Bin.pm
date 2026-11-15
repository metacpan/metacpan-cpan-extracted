########################################################################
# housekeeping
########################################################################
package FindBin::Bin v2.3.0;
use v5.40;

use parent qw( Exporter );

use File::stat;

use Cwd         qw( abs_path getcwd );
use List::Util  qw( uniq            );
use Symbol      qw( qualify_to_ref  );

use File::Spec::Functions
qw
(
    catdir
    catpath
    curdir
    file_name_is_absolute
    rootdir
    splitdir
    splitpath
);

sub pwd()
{
    # preserve symlinks in the path as with
    # "pwd -L" while still working on MSW, VMS.
    # note the *NIX PWD reality check with '.'.

    state $pwd
    = do
    {
        # getcwd returns undef if the working directory has been
        # removed.  abs_path cannot detect this: it returns a
        # missing last component unchanged.

        my $cwd = getcwd()
        // die "Unresolvable working directory: getcwd() returned undef ($!)\n";

        if( $^O eq 'MSWin32' )
        {
            # getcwd does not resolve junctions or symlinks here, and
            # there is no usable inode to validate $PWD against.

            $cwd
        }
        elsif( $^O eq 'VMS' )
        {
            # $ENV{DEFAULT} keeps rooted logicals unexpanded.

            $ENV{ DEFAULT } // $cwd
        }
        else
        {
            # *NIX, Cygwin, MSYS: trust $PWD only if it 
            # still names the current directory (same 
            # check as "pwd -L").  otherwise live with
            # cwd and having abs_path resolve symlinks.

            if( my $pwd = $ENV{ PWD } )
            {
                # a stale $PWD (e.g., after a builtin chdir, which
                # does not update it) leaves getcwd with symlinks
                # resolved: the logical path is lost.

                my $env
                = $pwd =~ m{^/}
                ? File::stat::stat $pwd
                : undef
                ;
                my $cur = File::stat::stat '.';

                if
                (
                       $env
                    && $env->ino
                    && $cur->ino
                    && $env->dev == $cur->dev
                    && $env->ino == $cur->ino
                )
                {
                    $pwd
                }
                else
                {
                    warn "Mismatched working directory: '$pwd' is stale, "
                    . "using '$cwd', this resolves symbolic links.\n";

                    $cwd
                }
            }
            else
            {
                $cwd
            }
        }
    }
}

sub canon_dir( $dir )
{
    # notice that this ignores any volume, the caller
    # can deal with it. this also expects a dir, not a
    # file, path.

    $dir or return pwd;

    my $raw
    = file_name_is_absolute( $dir )
    ? $dir
    : catdir pwd, $dir
    ;
    
    # caller gets back the path.

    if( $^O eq 'VMS' )
    {
        $raw
    }
    else
    {
        # MSW and *NIX have the same process:
        # clean up '.' and '..' in the path without
        # calling abs_path to resolve the symlinks.
        # can't use rel2abs as it is inconsistent in 
        # handling symlinks: absolute paths get 
        # canonpath, relative paths go through abs_path.

        state $root_marker = ( splitdir rootdir )[ 0 ];
        
        my @dirz    = splitdir $raw;
        my @stack   = ();

        while( @dirz )
        {
            my $part = shift @dirz;

            next if $part eq q{.};

            if( $part eq q{..} )
            {
                pop @stack
                if @stack && $stack[ -1 ] ne $root_marker;
            }
            else
            {
                push @stack, $part;
            }
        }

        catdir @stack
    }
}

BEGIN
{
    # recall that $0 is an lvalue!!
    # grab it quickly before it can change.
    # this will not change during execution, compute it once.
    #
    # note that $0 is initialized to a file path, not a dir. 

    my ( $logical, $physical )
    = do
    {
        # a /dev/ path (e.g., perl /dev/stdin, or /dev/fd/N from bash
        # process substitution) is input via a filehandle: like '-'
        # it has no program directory.

        if( $0 =~ m{^ (?: -e | - | interactive | /dev/ .* ) $}x )
        {
            my $raw = pwd;

            (
                $raw
              , abs_path( $raw )
            )
        }
        else
        {
            my $phys
            = do
            {
                my ( $v, $d ) = ( splitpath abs_path( $0 ), '' )[0,1];
                catpath $v, catdir( $d ), ''
            };

            my $log
            = do
            {
                my ( $v, $d ) = ( splitpath $0, '' )[0,1];
                catpath $v, canon_dir( $d ), ''
            };

            ( $log, $phys )
        }
    };

    # notice that these are installed into the *local* package.
    # callers inherit them via import(), below, or just use them
    # with package names FindBin::Bin::*.
    #
    # $Bin_l -- logical path (canon_dir $0, like "pwd -L")
    # $Bin_p -- physical path (abs_path of $0, like "pwd -P")
    # $Bin   -- module-level default = physical; import()
    #           aliases the caller's $Bin to $Bin_l with
    #           'noabspath'
    #
    # q#...# stores each path as a string literal.
    # '#' is the delimiter and '\' is the escape character.
    # All other non-word chars are literal inside q#...# and need no escaping.

    for
    (
        [ Bin_l => $logical   ]
      , [ Bin_p => $physical  ]
      , [ Bin   => $physical  ]
    )
    {
        my( $name, $raw ) = @$_;

        # q#...# uses '#' as the delimiter and '\' as the escape
        # character. Escape '\' first (doubles it), then escape '#'
        # so that '\#' in a path does not collapse the escape sequence.

        my $cooked  = $raw =~ s{\\}{\\\\}gr
                               =~ s{(?=[#])}{\\}gr;

        eval qq| *{ qualify_to_ref '$name' } = \\q#$cooked# |;
        eval qq| sub $name(){ q#$cooked# }                  |;
    }
}

########################################################################
# package variables & sanity checks
########################################################################

our @EXPORT    = qw( $Bin Bin );
our @EXPORT_OK = qw( $Bin Bin $Bin_l Bin_l $Bin_p Bin_p pwd canon_dir );

########################################################################
# interface
########################################################################

sub import
{
    my $pkg     = shift;
    my $caller  = caller;

    # take the first value if multiples are listed.
    
    my $abs     = ( grep { m{^(?:no)?abspath$} } @_ )[0] // '';
    my @want    = uniq grep { ! m{ abspath$ }x  } @_;

    my $use_phys
    = $abs eq 'noabspath'
    ? ''
    : 1
    ;

    # No explicit requests -- use default @EXPORT list.

    @want = @EXPORT
    unless @want;

    if( grep { m{ ^ [&\$]? Bin $ }x } @want )
    {
        my $flavor = $use_phys ? 'Bin_p' : 'Bin_l';
        my $src    = qualify_to_ref $flavor => __PACKAGE__;
        my $dst    = qualify_to_ref 'Bin'   => $caller;

        # Alias $Bin (SCALAR slot) -- preserves read-only constraint.
        *{ $dst } = *{ $src }{ SCALAR };

        # Alias Bin() (CODE slot) when the bare sub was requested.
        *{ $dst } = *{ $src }{ CODE }
        if grep { m{ ^ [&]? Bin $ }x } @want;

        @want = grep { ! m{ ^ [&\$]? Bin $ }x } @want;
    }

    $pkg->export_to_level( 1, $pkg, @want )
    if @want;
}

1
__END__

=head1 NAME

FindBin::Bin - Absolute path to the executable's directory, with two
normalization strategies for paths containing C<..> segments.

=head1 SYNOPSIS

    # Exports two variables (and matching constant subs) for the
    # directory containing the running program, plus two utilities.
    # $Bin defaults to the physical path (abspath); pass 'noabspath'
    # to get the logical path.  This matches FindBin::libs behavior.

    use FindBin::Bin
    qw(
        $Bin      # physical path by default; logical with 'noabspath' (see below)
        Bin       # constant sub returning same value as $Bin
        $Bin_l    # logical path via canon_dir (stack-based '..' removal, like pwd -L)
        Bin_l     # constant sub returning $Bin_l
        $Bin_p    # physical path via Cwd::abs_path (resolves symlinks, like pwd -P)
        Bin_p     # constant sub returning $Bin_p
        pwd       # absolute CWD, symlinks preserved (like "pwd -L")
        canon_dir # remove '..' and '.' without touching the filesystem
    );

    # $Bin defaults to the physical path (same as $Bin_p, abspath).
    # Pass 'noabspath' to get the logical path (same as $Bin_l):

    use FindBin::Bin qw( $Bin );            # $Bin == $Bin_p  (physical, default)
    use FindBin::Bin qw( $Bin noabspath );  # $Bin == $Bin_l  (logical)
    use FindBin::Bin qw( $Bin abspath );    # $Bin == $Bin_p  (physical, explicit)

    # For paths with no symlinks, all three variables are identical:

    say $Bin;    # /home/jowbloe/project/bin
    say $Bin_l;  # /home/jowbloe/project/bin   (canon_dir, logical)
    say $Bin_p;  # /home/jowbloe/project/bin   (abs_path,  physical)

    # They differ when the path to the program ($0) includes any
    # symbolic links.
    # If /home/jowbloe is a symlink to /real/home/jowbloe:

    say $Bin_l;  # /home/jowbloe/project/bin   (symlinks preserved)
    say $Bin_p;  # /real/home/jowbloe/project/bin  (symlinks resolved)

    # Interactive invocations (perl -e, perl -E, perl -, debugger) and
    # input via a filehandle (perl /dev/stdin, perl <( ... )):
    # $Bin_l = pwd()          -- CWD as returned by pwd()
    # $Bin_p = abs_path(pwd()) -- CWD with symlinks resolved

    perl -MFindBin::Bin=Bin -e 'say Bin';

    perl - < ../../foo/bar/bim;

    # Named programs: directory component of $0, with pwd() prepended
    # when $0 is relative.  All variables are absolute at program startup.

    use FindBin::Bin qw( pwd );
    my $cwd = pwd;         # same as "pwd -L" on *NIX

    use FindBin::Bin qw( canon_dir );
    my $path = canon_dir '/foo/bar/../bletch/./../blort';
    # => '/foo/blort'

    my $clamped = canon_dir '/foo/bar/../../../../../../../';
    # => '/'  (cannot '..' past root)


=head1 DESCRIPTION

This module computes three absolute-path forms of the directory that
contains the running program (C<$0>) and exports them at compile time
in a C<BEGIN> block.

=head2 $Bin and Bin()

C<$Bin> is a configurable alias.  By default it equals C<$Bin_p> (the
physical path, symlinks resolved).  Passing C<'noabspath'> in the import
list makes C<$Bin> equal C<$Bin_l> (the logical path, symlinks preserved)
in the calling package:

    use FindBin::Bin qw( $Bin );            # $Bin == $Bin_p  (physical, default)
    use FindBin::Bin qw( $Bin noabspath );  # $Bin == $Bin_l  (logical)
    use FindBin::Bin qw( $Bin abspath );    # $Bin == $Bin_p  (physical, explicit)

C<Bin()> follows the same logic: it is aliased to C<Bin_p()> or
C<Bin_l()> depending on the C<noabspath> flag.

This behavior matches L<FindBin::libs>, which also defaults to the
physical path and accepts C<noabspath> to select the logical path.

The first argument to C<import> is the package name C<FindBin::Bin>,
not an object instance.  These modules provide no OO interface.

=head2 $Bin_l and Bin_l()

C<$Bin_l> ("logical", like C<pwd -L>) is the directory of C<$0> as
given, with C<pwd()> prepended if C<$0> is relative, cleaned up via
C<canon_dir()>: a stack algorithm that removes B<all> C<..> and C<.>
segments without touching the filesystem.  Symbolic links in the path
are B<preserved>; if C<$0> is itself a symlink, C<$Bin_l> is the
directory containing the symlink.  Because C<pwd()> uses C<$ENV{PWD}>
when it is valid, a relative C<$0> keeps the symlinks in the working
directory as well.

=head2 $Bin_p and Bin_p()

C<$Bin_p> ("physical", like C<pwd -P>) is the directory of
C<Cwd::abs_path( $0 )>: the physical directory of the executable file,
with all symbolic links resolved.  If C<$0> is itself a symlink,
C<$Bin_p> is the directory containing the file it points to.

=head2 Symlinks

C<$Bin_l> preserves directory symlinks in the path (logical, like
C<pwd -L>).  C<$Bin_p> resolves them to the real on-disk location
(physical, like C<pwd -P>).  They are identical when no symlinks appear
in the path to C<$0>, including C<$0> itself:

    # $0 = /home/user/bin/script, a symlink to /work/app/bin/script

    $Bin_l = /home/user/bin          # directory of the symlink
    $Bin_p = /work/app/bin           # directory of the executable file

Bind mounts, on *NIX systems that support them, can also give a
different C<$Bin_l>.  If C<$ENV{PWD}> names the working directory via
one mount point and the process entered it via another, both have the
same device and inode, so C<pwd()> accepts C<$ENV{PWD}>.  With a
relative C<$0>, C<$Bin_l> then uses the C<$ENV{PWD}> mount point while
C<$Bin_p> uses the one returned by C<abs_path>, though neither path
contains a symlink.

=head3 Example: two lib trees, one symlink

Consider a sandbox layout where C</home/user/app> is a directory
symlink pointing to the real project under C</work/projects/app>:

    /home/user/                       # logical subtree
    +-- lib/
    |   \-- UserLib.pm                # visible only via $Bin_l
    \-- app -> /work/projects/app     # directory symlink

    /work/projects/                   # physical subtree
    +-- lib/
    |   \-- WorkLib.pm                # visible only via $Bin_p
    \-- app/
        \-- bin/
            \-- script                # $0 -- the running program

When C<script> is invoked via the symlink path
(C</home/user/app/bin/script>):

    $Bin_l = /home/user/app/bin       # symlink path preserved
    $Bin_p = /work/projects/app/bin   # symlink resolved

C<FindBin::libs> (and any other code that walks up from C<$Bin>) finds
different C<lib/> directories depending on which variable it uses as the
starting point.

B<Using C<$Bin_l>> (C<noabspath>):

    walk: /home/user/app/bin  ->  /home/user/app  ->  /home/user
    lib found: /home/user/lib
    use lib '/home/user/lib'    # loads UserLib.pm

B<Using C<$Bin_p>> (C<abspath>, the default):

    walk: /work/projects/app/bin  ->  /work/projects/app  ->  /work/projects
    lib found: /work/projects/lib
    use lib '/work/projects/lib'  # loads WorkLib.pm

This is the "regression testing via symlinks" pattern: place a directory
symlink to the program's bin inside a test sandbox that has its own
C<lib/> tree.  Toggle between the sandbox libraries (logical) and the
source-tree libraries (physical) with the C<abspath> setting in
C<FindBin::libs>, or by choosing which variable to use directly.

The default C<$Bin> equals C<$Bin_p> unless the caller passes
C<'noabspath'> at import time (see L</"$Bin and Bin()">).

=head2 Resolving the working directory

The C<$Bin*> variables and C<Bin*()> subs are computed once, when
C<FindBin::Bin> is first loaded: at compile time of the first
C<use FindBin::Bin> or C<use FindBin::libs>.  When C<$0> is relative
or an interactive invocation they are based on the value of C<pwd()>
at that time; an absolute C<$0> does not use C<pwd()>.

If C<FindBin::libs> or C<FindBin::Bin> is used before any C<chdir>,
they reflect the working directory at startup: a relative C<$0> is
resolved against the original C<pwd()>, giving the correct absolute
path.  A later C<chdir> does not change them.  Using C<FindBin::libs>
before other modules avoids the problems below.

A C<chdir> made before C<FindBin::Bin> is first loaded, e.g., by a
module used earlier, affects them:

=over 4

=item * Builtin C<chdir>

Does not update C<$ENV{PWD}>.  C<pwd()> finds the stale C<$PWD>, warns,
and uses C<Cwd::getcwd()>, so C<$Bin_l> does not preserve symlinks.

=item * C<Cwd::chdir>

Updates C<$ENV{PWD}>.  C<pwd()> uses it without a warning.

=back

In either case, if the working directory is not restored before
C<FindBin::Bin> is loaded, a relative C<$0> is resolved against the
new working directory, and C<$Bin_l> and C<$Bin_p> are wrong.

=head3 Interactive invocations

When C<$0> is C<-e>, C<->, or C<interactive> (one-liner, stdin, or
debugger), or a path under C</dev/> (input via a filehandle, e.g.,
C<perl /dev/stdin> or C</dev/fd/N> from bash process substitution),
the directory is taken from C<pwd()>:

    $Bin_l = pwd()
    $Bin_p = Cwd::abs_path( pwd() )   # resolves symlinks in CWD

=head3 Named program files

When C<$0> holds a file path:

    $Bin_l = catpath( $vol, canon_dir( $dir ), '' )
    $Bin_p = directory of abs_path( $0 )

where C<$vol> and C<$dir> are the volume and directory of C<$0> as
given; C<canon_dir()> prepends C<pwd()> to a relative C<$dir>.
C<$Bin_l> keeps symlinks, including a symlinked C<$0>; C<$Bin_p>
resolves them, following a symlinked C<$0> to the executable file.

All variables are defined as read-only ref-to-constant scalars and
constant subs; they do not change after the C<BEGIN> block runs.

=head2 pwd()

Returns the working directory determined at runtime, the same value as
C<"pwd -L"> -- an absolute path with symbolic links left as-is.  On *NIX and Cygwin it validates
C<$ENV{PWD}> against the inode of C<'.'> and falls back to
C<Cwd::getcwd()> (which resolves symlinks) only when they disagree.
On VMS it uses C<$ENV{DEFAULT}> if that is defined, otherwise
C<Cwd::getcwd()>; on MSWin32 it uses C<Cwd::getcwd()>.

If C<$ENV{PWD}> is set but stale -- not an absolute path, a path that
does not exist, or not the same device and inode as C<'.'> -- C<pwd()>
warns:

    Mismatched working directory: '<$ENV{PWD}>' is stale,
    using '<getcwd>', this resolves symbolic links.

and returns C<Cwd::getcwd()>, so symlinks in the working directory are
not preserved.  The usual cause is a builtin C<chdir>, which does not
update C<$ENV{PWD}>; C<Cwd::chdir> does.  No warning is issued when
C<$ENV{PWD}> is unset.

If the working directory cannot be resolved, e.g., it has been
removed, C<getcwd> returns undef and C<pwd()> dies:

    Unresolvable working directory: getcwd() returned undef (<$!>)

This is checked first, on all platforms, before C<$ENV{PWD}> or
C<$ENV{DEFAULT}> is examined.  C<abs_path> cannot detect it, since it
returns a missing last path component unchanged.

The result is cached on the first call to C<pwd()>: later calls return
the same value, even after a C<chdir>.  The first call is not
necessarily at program startup.  Loading C<FindBin::Bin> calls
C<pwd()> only when C<$0> is relative or an interactive invocation
(C<-e>, C<->, C<interactive>, C</dev/...>); otherwise the first call
is the caller's, and reflects any C<chdir> made before it.

=head2 canon_dir()

Accepts an absolute or relative path and returns an absolute path with
all C<.> and C<..> components removed via a stack algorithm.  Symlinks
are not consulted.  A relative input has C<pwd()> prepended.

    canon_dir '/foo/bar/../bim/../../bletch';
    # => '/bletch'  (.. backs off bar, then bim, then foo)

    canon_dir '/foo/bar/../../../../../../../';
    # => '/'  (cannot go above root)

