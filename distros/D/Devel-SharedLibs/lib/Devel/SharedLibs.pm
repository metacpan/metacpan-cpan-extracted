########################################################################
# housekeeping
########################################################################

package Devel::SharedLibs;
use v5.22;

use IO::File;

use List::MoreUtils qw( uniq );

########################################################################
# package variables
########################################################################

our $VERSION = 'v0.3.2';
$VERSION    = eval "$VERSION";

sub import
{
    state $usable_ldd
    = do
    {
$DB::single = 1;

        # Aside: Need to check whether ldd on BSD, etc, supports
        # long option for version.

        my $result  = qx{ ldd --version 2>&1 };

        my $success = ! $?
        or warn <<"END";
# Non-zeo exit: ldd --version ($result)
# SharedLibs unable to generate output.
END

        $success
    };

    # all this does it localize $path for the END closure.
    # kwikhak for the moment until I find out if there is 
    # any decent way to deal with ldd on BSD.

    my ( undef, $path ) = @_;

    END
    {
$DB::single = 1;

        $ENV{ DEVEL_SHAREDLIBS_PRINT }
        or return;

        $path   ||= $ENV{ DEVEL_SHAREDLIBS_PATH }
        or say "# False path & DEVEL_SHAREDLIBS_PATH: output to stdout.";

        # avoid stale output.
        # if ldd is not usable then this leaves nothing behind.

        my $continue    = $usable_ldd;

        if( $path && -e $path )
        {
            say "# Remove stale: '$path'";

            unlink $path
            or do
            {
                warn <<"END";
# Failed unlink: '$path', no SharedLibs output.
# SharedLibs unable to generate output.
END

                $continue   = ''
            };
        }

        if( $continue )
        {
            use autodie qw( open close );

            local $,    = "\n";
            local $\    = "\n";

            my $fh
            = $path
            ? IO::File->new( $path, 'w' )
            : *STDOUT{ IO }
            ;

            # sort isn't necessary for uniqueness but helps 
            # by giving a stable output.

            print $fh
            "# ldd '$^X', '$0'" =>
            sort { $a cmp $b }
            uniq
            map
            {
                # the literal '=>' dodges linux-vdso & friends,
                # which lack a path and also the 
                # "not a dynamic executable" messages from 
                # most of the contents.

                my ( $lib ) = m{ => \s+ (\S+) }x;

                $lib || ()
            }
            map
            {
                split "\n" => qx(ldd $_ 2>/dev/null ) 
            }
            (
                $^X,
                values %INC
            );

            close $fh;

            say STDERR "SharedLibs output: '$path'";
        }
        else
        {
            say STDERR "SharedLibs unable to generate output."
        }
    }
}

# keep require happy
1
__END__

=head1 NAME

Devel::SharedLibs -- output of ldd results for $^X and %INC

=head1 SYNOPSIS

    # if $ENV{ DEVEL_SHAREDLIBS_PRINT } is true at the end 
    # of execution then print results of runing ldd on 
    # everything in %INC to STDOUT.
    #
    # if $ENV{ DEVEL_SHAREDLIBS_PATH } is true then it 
    # will be used for the list instead of stdout.

    use Devel::SharedLibs;

    # this can be mangled any time during execution it is not
    # checked until END time.
    #
    # true dumps list to stdout or path; false does nothing.

    $ENV{ DEVEL_SHAREDLIBS_PRINT } = 1;

    __END__

    # the argument to import overrides the environment 
    # variable setting.

    # output in ./libfiles.out insted of stdout:

    use Devel::SharedLibs qw( ./libfiles.out );

    # or

    $ENV{ DEVEL_SHAREDLIBS_PATH } = './libfiles.out';

    # or, of course, set them both in the shell before
    # running the program:

    DEVEL_SHAREDLIBS_PRINT=1 \
    DEVEL_SHAREDLIBS_PATH='./libfiles.out' \
    your_perl_program;

=head1 DESCRIPTION

=head2 Initial Sanity Checks

Aside from failing to open the output file, lack of "ldd" on 
the user's path will cause this to fail. When DEVEL_SHAREDLIBS_PRINT
is true an intiail check of "ldd --version" is run. If this returns
non-zero then a failure message printed.

=head2 Output

All this does it get a unique output from running "ldd" on all
of the paths in values %INC. The scan is done at END time to 
ensure that anything pulled in via dynamic loading is listed.

Ouptut includes the executable path ("$^X") and the executable
path ($0, which may have been munged during execution).

For example, to see which shared object lib's (.so files) perl
itself is linked with use:

    #!/usr/bin/env  perl

    use Devel::SharedLibs;
    __END__

which outputs something like:

    $ DEVEL_SHAREDLIBS_PRINT=1 perl t/bin/exec-stdout
    # ldd '/opt/perl/5.22/bin/perl', 't/bin/exec-stdout'
    /lib64/libc.so.6
    /lib64/libcrypt.so.1
    /lib64/libdl.so.2
    /lib64/libm.so.6
    /lib64/libnsl.so.1
    /lib64/libpthread.so.0
    /lib64/libutil.so.1

=head2 Fine, but, why bother?

A truly idiotic thing about most linux container doc's (Docker
is a great example, but not alone in this) is putting a full
copy of the OS as a 'base layer' for the container. The claimed
reason is having access to necessary shared object lib's in the
distro.

Catch: Aside from security and bloat issues, it simply does not work.
Problem is that there is no gurarantee that the executables being
run on the container system were complied on the same distro with 
compatable lib's. 

A really simple fix is to build the container using whatever 
.so files are actually *used* by the executable. 

For something running #!perl this can be done by examining the
values of %^X and %INC (i.e., included paths)
with ldd.

At the very least it'll give you a good place to start. For a an 
reasonable set of modules (i.e., the usuall collection of files that 
go along with a crawler, PSGI or CGI web back end, or log watcher)
this runs in the 10MB - 20MB range (vs. 1GB or more for a full linux 
distro).

=head1 CAVEAT UTILITOR

=over 4

=item 

This is probably only useful to use once as there is no bookkeeping
of the output path: the path is examined once at END time based on
the arguments to the last call to import. Then again, it is probably
only useful to put this in #! code anway, so this does not seem to
be a major problem [anyone who finds it such can warn me and we 
will find a better solution].

=item 

You will require a usable ldd to run this. Any general-purpose
*NIX system from the last 30 years should have one; if you are
running an embedded system (e.g., openwrt, andriod) this may not
work.

=item 

This will help deal with so's, it will not help you if libc or the
kernel headers are far enough out of sync. Most of the time using
something based on lxc the libc and kernel versions are close enough
that it won't kill you.

=back

=head1 SEE ALSO

=over 4

=item ldd(1)

Speicfics of running ldd on your system.

=item How to use this with Docker

Brief explanation of building a '-lib' image for docker using 
ldd output:

=item perldoc perlvar

Description of $^X variable in Perl.

<http://www.slideshare.net/lembark/shared-object-images-in-docker-when-what-you-need-is-what-you-want>

=back

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 License

This package is licensed under the same terms as Perl-5.22 or any
later version of Perl.
