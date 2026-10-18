########################################################################
# housekeeping
########################################################################
package FindBin::Bin v1.0.0;
use v5.40;

use parent qw( Exporter );

use Cwd;
use File::stat;

use Symbol  qw( qualify_to_ref   );

use File::Spec::Functions
qw
(
    canonpath
    catdir
    catpath
    curdir
    file_name_is_absolute
    rel2abs
    splitpath
);

sub pwd()
{
    # preserve symlinks in the path as "pwd -L"
    # while still working on MSW, VMS.

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
        # cwd and having abs_path resolve symlinks.

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

BEGIN
{
    # recall that $0 is an lvalue!!
    # grab it quickly before it can change.
    # this will not change during execution, compute it once.
    #
    # note that $0 is initialized to a file path, not a dir. 

    my $bin
    = do
    {
        if( $0 =~ m{^ (?: -e | - | interactive ) }x )
        {
            pwd
        }
        elsif( file_name_is_absolute $0 )
        {
            catpath( ( splitpath $0 )[0,1], '' )
        }
        else
        {
            my ($v, $d) = splitpath $0;

            catpath $v, catdir( pwd, $d ), ''
        }
    };

    $bin = canonpath $bin;

    # initialize $Bin as a ref-to-const, Bin is a
    # constant sub. absent further twiddling with
    # Symbol these should remain stable throuout
    # execution.

    eval qq/ *{ qualify_to_ref 'Bin' } = \\'$bin' /; ;
    eval qq/ sub Bin(){ '$bin' } /;
}

########################################################################
# package variables & sanity checks
########################################################################

our @EXPORT_OK  = qw( $Bin Bin );

1
__END__

=head1 NAME

FindBin::Bin - Find the execution directory, exported via BIN()

=head1 SYNOSIS

    # the most common case is splitting off a volume and 
    # directory list from $0. This avoids resolving any 
    # symlinks in the path so that symlinked executables 
    # can access other files relative to their execution
    # path not where they are stored.
    #
    # to get the absolute path to the executable use 
    # Cwd::abs_path.
    #
    # this gets messier if $0 is any one of:
    # '-e' or '-' or 'interactive'. the common fix of 
    # "cwd" or "getcwd" or "curdir" from Cwd or File::Spec
    # return the resolved path to the working directory 
    # and we want the symlinks left in place.
    #
    # the fix there is system specific:
    #
    # VMS: $ENV{ DEFAULT }
    # MSW: curdir (which doesn't resolve symlinks)
    # *NIX or Cygwin use a version of the logic in "pwd" 
    # which trusts $ENV{ PWD } IFF it references the same
    # device and inode as '.'.
    #
    # the fall back without DEFAULT or PWD or if PWD 
    # doesn't match '.' is living with 'getcwd' and the
    # resolved symlinks.
    #
    # $Bin is defined via ref-to-constant, Bin is a 
    # constant sub. they will remain constant through 
    # execution unless someone twiddles them with refs.

    #!/usr/bin/env perl

    use FindBin::Bin qw( $Bin );

    say $Bin;
    # e.g., /tmp/FindBin-libs/t/10-Bin-path

    # sub call

    use FindBin::Bin qw(  Bin );

    say Bin;
    # e.g., /tmp/FindBin-libs/t/10-Bin-path

    my $path = Bin;

    say $path;
    # e.g., /tmp/FindBin-libs/t/10-Bin-path

    # command line execution shows the difference between
    # using Bin and getcwd: cd into a symlink, Bin and getcwd
    # return different results: Bin.pm returns the same result
    # from "perl -E" as it does with the #! invocation and an
    # executable for $0.

    perl -MFindBin::bin=Bin 'say Bin';
    # e.g., /tmp/FindBin-libs/10-Bin-path

    $ cd /tmp;
    $ ln -fsv FindBin-libs foobar;
    'foobar' -> '/scratch/lembark/sandbox/Modules/Perl/FindBin-libs'

    $ cd foobar;
    $ perl -MCwd=getcwd -MFindBin::Bin=Bin -E 'say Bin; say getcwd';
    /tmp/foobar
    /scratch/lembark/sandbox/Modules/Perl/FindBin-libs
