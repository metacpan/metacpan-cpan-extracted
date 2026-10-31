########################################################################
# housekeeping
########################################################################
package FindBin::Bin v2.0.0;
use v5.40;

use parent qw( Exporter );

use File::stat;

use Cwd qw( getcwd              );
use Symbol  qw( qualify_to_ref  );

use File::Spec::Functions
qw
(
    canonpath
    catdir
    catpath
    curdir
    file_name_is_absolute
    rel2abs
    rootdir
    splitdir
    splitpath
);

sub pwd()
{
    # preserve symlinks in the path as with
    # "pwd -L" while still working on MSW, VMS.

    if( $^O eq 'MSWin32' )
    {
        # getcwd does not resolve junctions or symlinks here, and
        # there is no usable inode to validate $PWD against.

        getcwd
    }
    elsif( $^O eq 'VMS' )
    {
        # $ENV{DEFAULT} keeps rooted logicals unexpanded.

        $ENV{ DEFAULT } // getcwd
    }
    else
    {
        # *NIX, Cygwin, MSYS: trust $PWD only if it 
        # still names the current directory (same 
        # check as "pwd -L").  otherwise live with
        # cwd and having rel2abs resolve symlinks.

        if( my $pwd = $ENV{ PWD } )
        {
            if( $pwd =~ m{^/} )
            {
                my $env = File::stat::stat $pwd ;
                my $cur = File::stat::stat '.'  ;

                   $env->ino
                && $cur->ino
                && $env->dev == $cur->dev
                && $env->ino == $cur->ino
                ? $pwd
                : getcwd
            }
            else
            {
                getcwd
            }
        }
        else
        {
            getcwd
        }
    }
}

sub canon_dir( $dir )
{
    # notice that this ignores any volume, the caller
    # can deal with it. this also expects a dir, not a
    # file, path.

    $dir or return;

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
        # calling rel2abs to resolve the symlinks.

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
        if( $0 =~ m{^ (?: -e | - | interactive ) }x )
        {
            my $raw = pwd;

            (
                $raw
              , Cwd::abs_path( $raw ) // $raw
            )
        }
        else
        {
            my( $v, $dir ) = ( splitpath $0, '' )[0,1];

            my $raw
            = file_name_is_absolute( $dir )
            ? $dir
            : catdir pwd, $dir
            ;

            (
                catpath( $v, canon_dir( $raw ),                          '' )
              , catpath( $v, Cwd::abs_path( $raw ) // canonpath( $raw ), '' )
            )
        }
    };
    
    # notice that these are installed into the *local* package.
    # callers inherit them via import(), below.

    # $Bin_l -- logical path (canon_dir, like "pwd -L")

    eval qq| *{ qualify_to_ref 'Bin_l' } = \\'$logical'  |;
    eval qq| sub Bin_l(){ '$logical'  } |;

    # $Bin_p --  physical path (abs_path, like "pwd -P"
    # resolves symlinks)

    eval qq| *{ qualify_to_ref 'Bin_p' } = \\'$physical' |;
    eval qq| sub Bin_p(){ '$physical' } |;

    # $Bin -- module-level default = logical; import() may 
    # alias to physical

    eval qq| *{ qualify_to_ref 'Bin' } = \\'$physical' |;
    eval qq| sub Bin(){ '$physical' } |;
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

    # list context captures the matched string, not a count.
    my ($flag)  = grep { m{abspath} } @_;
    $flag     //= '';
    my @want    = grep { ! m{abspath} } @_;

    my $use_phys
    = $flag eq 'noabspath'
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

    # They differ when the program's directory path contains symlinks.
    # If /home/jowbloe is a symlink to /real/home/jowbloe:

    say $Bin_l;  # /home/jowbloe/project/bin   (symlinks preserved)
    say $Bin_p;  # /real/home/jowbloe/project/bin  (symlinks resolved)

    # Interactive invocations (perl -e, perl -E, perl -, debugger):
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

C<$Bin_l> ("logical", like C<pwd -L>) is computed via C<canon_dir()>,
a stack algorithm that removes B<all> C<..> and C<.> segments without
touching the filesystem.  Symbolic links in the path are B<preserved>.

=head2 $Bin_p and Bin_p()

C<$Bin_p> ("physical", like C<pwd -P>) is computed via C<Cwd::abs_path()>,
which resolves all symbolic links.  If C<abs_path> fails, C<$Bin_l> is
used as a fallback.

=head2 Symlinks

C<$Bin_l> preserves directory symlinks in the path (logical, like
C<pwd -L>).  C<$Bin_p> resolves them to the real on-disk location
(physical, like C<pwd -P>).  They are identical when no symlinks appear
in the directory path.

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

=head3 Interactive invocations

When C<$0> is C<-e>, C<->, or C<interactive> (one-liner, stdin, or
debugger), the directory is taken from C<pwd()>:

    $Bin_l = pwd()
    $Bin_p = Cwd::abs_path( pwd() )   # resolves symlinks in CWD

=head3 Named program files

When C<$0> holds a file path:

    $Bin_l = catpath( $vol, canon_dir( $raw ),   '' )  # logical, '..' removed
    $Bin_p = catpath( $vol, abs_path( $raw ),    '' )  # physical, symlinks resolved

where C<$raw> is the absolute directory string derived from the
directory component of C<$0> (with C<pwd()> prepended for relative paths).

All variables are defined as read-only ref-to-constant scalars and
constant subs; they do not change after the C<BEGIN> block runs.

=head2 pwd()

Returns the same value as C<"pwd -L"> -- an absolute path to the CWD
with symbolic links left as-is.  On *NIX and Cygwin it validates
C<$ENV{PWD}> against the inode of C<'.'> and falls back to
C<Cwd::getcwd()> (which resolves symlinks) only when they disagree.
On VMS it uses C<$ENV{DEFAULT}>; on MSWin32 it uses C<Cwd::getcwd()>.

The result is memoised; C<pwd()> always returns the value from program
startup.

=head2 canon_dir()

Accepts an absolute or relative path and returns an absolute path with
all C<.> and C<..> components removed via a stack algorithm.  Symlinks
are not consulted.  A relative input has C<pwd()> prepended.

    canon_dir '/foo/bar/../bim/../../bletch';
    # => '/bletch'  (.. backs off bar, then bim, then foo)

    canon_dir '/foo/bar/../../../../../../../';
    # => '/'  (cannot go above root)
