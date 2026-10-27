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
    state $pwd
    = do
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

    my ( $abs, $canon )
    = do
    {
        if( $0 =~ m{^ (?: -e | - | interactive ) }x )
        {
            my $raw = pwd;

            (
                rel2abs( $raw )
              , $raw
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
                catpath( $v, rel2abs(    $raw ), '' )
              , catpath( $v, canon_dir( $raw ), '' )
            )
        }
    };

    # initialize $Bin as a ref-to-const, Bin is a
    # constant sub. absent further twiddling with
    # Symbol these should remain stable throuout
    # execution.

    eval qq| *{ qualify_to_ref 'Bin' } = \\'$abs' |;
    eval qq| sub Bin(){ '$abs' } |;

    eval qq| *{ qualify_to_ref 'Bin_c' } = \\'$canon' |;
    eval qq| sub Bin_c(){ '$canon' } |;
}

########################################################################
# package variables & sanity checks
########################################################################

our @EXPORT_OK  = qw( $Bin Bin $Bin_c Bin_c pwd canon_dir );

1
__END__

=head1 NAME

FindBin::Bin - Absolute path to the executable's directory, with two
normalization strategies for paths containing C<..> segments.

=head1 SYNOPSIS

    # Exports two variables (and matching constant subs) for the
    # directory containing the running script, plus two utilities:

    use FindBin::Bin
    qw(
        $Bin      # absolute path via File::Spec::canonpath
        Bin       # constant sub returning $Bin
        $Bin_c    # absolute path via canon_dir (stack-based '..' removal)
        Bin_c     # constant sub returning $Bin_c
        pwd       # absolute CWD, symlinks preserved (like "pwd -L")
        canon_dir # remove '..' and '.' without touching the filesystem
    );

    # For paths with no '..' segments both variables are identical:

    say $Bin;    # /home/jowbloe/project/bin
    say $Bin_c;  # /home/jowbloe/project/bin

    # They differ when the resolved path contains intermediate '..'
    # segments.  canonpath (used for $Bin) only removes a trailing
    # '/..' and leading '/../'; canon_dir removes every '..':

    # $0 = 'goes/../../up/script.pl', pwd = /home/jowbloe/project
    say $Bin;    # /home/jowbloe/project/goes/../../up  (canonpath)
    say $Bin_c;  # /home/jowbloe/up                     (canon_dir)

    # Both variables preserve symlinks -- neither calls Cwd::abs_path.
    # If you need the physical (dereferenced) path, call abs_path()
    # from Cwd yourself.

    # Interactive invocations (perl -e, perl -E, perl -, debugger):
    # $Bin_c = pwd()          -- CWD as returned by pwd()
    # $Bin   = rel2abs(pwd()) -- canonpath of pwd() (equal for clean paths)

    perl -MFindBin::Bin=Bin -e 'say Bin';

    perl - < ../../foo/bar/bim;

    # Named scripts: directory component of $0, with pwd() prepended
    # when $0 is relative.  Both are absolute at program startup.

    use FindBin::Bin qw( pwd );
    my $cwd = pwd;         # same as "pwd -L" on *NIX

    use FindBin::Bin qw( canon_dir );
    my $path = canon_dir '/foo/bar/../bletch/./../blort';
    # => '/foo/blort'

    my $clamped = canon_dir '/foo/bar/../../../../../../../';
    # => '/'  (cannot '..' past root)


=head1 DESCRIPTION

This module computes two absolute-path forms of the directory that
contains the running script (C<$0>) and exports them at compile time
in a C<BEGIN> block.  Both forms preserve symbolic links; they differ
only in how they handle C<..> segments in the path.

=head2 $Bin and Bin()

C<$Bin> is computed via C<File::Spec::rel2abs>, which reduces to
C<File::Spec::canonpath> for an already-absolute path.  C<canonpath>
performs string-level normalisation: it collapses repeated slashes,
removes C</./> sequences, and strips a leading C</../> or a trailing
C</..>, but it does B<not> remove intermediate C</../> segments such
as C</foo/bar/../baz>.

For most scripts, where C<$0> contains no C<..>, C<$Bin> and C<$Bin_c>
are identical.

=head2 $Bin_c and Bin_c()

C<$Bin_c> is computed via C<canon_dir()>, which uses a stack algorithm
to process every path component.  It removes B<all> C<..> and C<.>
segments regardless of position, producing the shortest equivalent
absolute path without touching the filesystem.

=head2 Symlinks

Neither C<$Bin> nor C<$Bin_c> resolves symbolic links.  Both are
derived from C<pwd()> (which behaves like C<pwd -L>) and from C<$0>
as Perl set it -- the path through which the script was invoked.  If
you need the physical path with symlinks dereferenced, use
C<Cwd::abs_path()> directly.

=head2 Resolving the working directory

=head3 Interactive invocations

When C<$0> is C<-e>, C<->, or C<interactive> (one-liner, stdin, or
debugger), the directory is taken from C<pwd()>:

    $Bin_c = pwd()
    $Bin   = rel2abs( pwd() )   # == canonpath( pwd() ) for clean paths

=head3 Named script files

When C<$0> holds a file path the directory component is extracted via
C<splitpath>.  A relative directory has C<pwd()> prepended before
normalisation:

    $Bin   = catpath( $vol, rel2abs(  $raw ) )
    $Bin_c = catpath( $vol, canon_dir( $raw ) )

where C<$raw> is the absolute directory string.

Both variables are defined as read-only ref-to-constant scalars and
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
