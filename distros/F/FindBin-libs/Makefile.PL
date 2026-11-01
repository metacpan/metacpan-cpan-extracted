#!/usr/bin/env perl
########################################################################
# even the old version is guaranteed not to work
# with anything earlier than 5.008.

use 5.008;
use strict;
use feature 'say';
use version;

use ExtUtils::MakeMaker;

use ExtUtils::Manifest  qw();
use File::Basename      qw( basename    );
use File::Find          qw( find        );
use File::Path          qw( make_path remove_tree );
use List::Util          qw( first       );

use File::Spec::Functions
qw
(
    splitpath
    catpath
    catdir
    catfile
    curdir
);

########################################################################
# optional version argument overrides the running perl version when
# selecting a version/ directory.

my $forced_version
= @ARGV && $ARGV[0] =~ m{^  v? (?:\d+[.]?)+ $}x
? shift @ARGV
: undef
;

########################################################################
# deal with MakeMaker version.

my $mm_v    = ExtUtils::MakeMaker->VERSION;

my @config_requires
= $mm_v < 6.52
? ()
:   (
        CONFIGURE_REQUIRES =>
        {
            (
                map
                {
                    (
                        $_->[0],
                        version->parse( $_->[1] )->numify
                    )
                }
                (
                    [ qw( File::Copy::Recursive::Reduced  v0.6  ) ],
                    [ qw( List::Util                      v1.46 ) ],
                )
            ),
            (
                map
                {
                    ( $_ => 0 )
                }
                qw
                (
                    strict
                    version
                    ExtUtils::MakeMaker
                    File::Basename
                    List::Util
                    File::Spec::Functions
                    YAML::Tiny
                )
            ),
        }
    )
;

########################################################################
# install the correct version of libs.pm based on the running perl
# version. after that take the version from whatever's on the disk.
#
# When running from a dist tarball there is no version/ directory;
# lib/ and t/ are already in place -- skip the dircopy entirely.
########################################################################

if( -d 'version' || $ENV{ FORCE_VERSION } )
{
    my $perl_v
    = do
    {
        my $text
        = $forced_version
        // sprintf '%vd' => $^V;

        print "\n# Parsing perl version: '$text'\n";

        eval { version->parse( $text )->numify }
        or die "Un-parsable perl version: '$text'";
    };

    print "\n# Running perl version: '$perl_v'\n";

    my $src_d
    = $ENV{ FORCE_VERSION }
    || do
    {
        my @v_dirz = glob "./version/*"
        or die "Unable to locate version dirs: './version/*'";

        my $found
        = first
        {
            $_->[0] <= $perl_v
        }
        sort
        {
            # desc sort allows first dir <= $^V.

            $b->[0] <=> $a->[0]
        }
        map
        {
            my $base    = basename $_;
            my $ver
            = eval
            {
                version->parse( $base )->numify
            };

            if( $ver )
            {
                [ $ver => $_ ]
            }
            else
            {
                print "Ignoring Un-parsable version: '$base' ($_), $@";
                ()
            }
        }
        @v_dirz
        or
        die "Unable to install with Perl version '$perl_v'";

        $found->[ -1 ]
    };

    -e $src_d
    or die "Botched source dir: Non-existant $src_d";

    -d $src_d
    or die "Botched source dir: Non-directory $src_d";

    print "\n# Version directory: $src_d <= $perl_v.\n";

    require File::Copy::Recursive::Reduced;

    # MANIFEST is saved before dircopy and restored after; it is not
    # touched during cleanup.  If it is absent (e.g. first install from
    # a tarball) dircopy provides the version-local one, which is left
    # in place.

    my $manifest_text
    = do
    {
        local $/;

        if( open my $fh, '<', 'MANIFEST' )
        {
            <$fh>
        }
        else
        {
            undef
        }
    };

    # remove every working-copy item that dircopy is about to install,
    # skipping MANIFEST (handled by save/restore).

    for my $src ( glob catfile( $src_d, '*' ) )
    {
        my $name    = basename $src;
        my $dest    = catfile curdir, $name;

        next if $name eq 'MANIFEST';
        next unless -e $dest || -l $dest;

        -d $dest && ! -l $dest
        ? remove_tree( $dest )
        : unlink $dest;
    }

    say "\n# Note: FCR2 'Copying a symlink...whose target does not exist' warnings",
        "\n# for t/bin/install-tests.d/*.inst are false positives -- relative",
        "\n# symlinks whose target exists in the same directory are copied",
        "\n# correctly.  The warnings are suppressed.";

    # FCR2 warns "whose target does not exist" for relative symlinks because
    # it checks !-e $target against CWD, not against the symlink's directory.
    # The symlinks (e.g. t/bin/install-tests.d/*.inst -> _inst_t) are copied
    # correctly; suppress the false-positive noise.

    {
        local $SIG{ __WARN__ } = sub
        {
            my $w = shift;

            warn $w
            unless $w =~ /Copying a symlink.*whose target does not exist/;
        };

        File::Copy::Recursive::Reduced::dircopy( $src_d => '.' )
        or die "Failed copy from $src_d.\n";
    }

    if( defined $manifest_text )
    {
        open my $fh, '>', 'MANIFEST'
        or die "Cannot restore MANIFEST: $!";
        print $fh $manifest_text;
        close $fh;
    }
}
else
{
    print "\n# Dist install: lib/ and t/ already in place; skipping dircopy.\n";
}

# install-tests generates the t/20-*/ t/21-*/ etc. symlinks from
# tests.yaml; called from the test target after dependencies are installed.

my $install_tests   = catfile curdir, 't', 'bin', 'install-tests';

-f $install_tests
and chmod 0755, $install_tests;

########################################################################
# reasonable question as to whether all of the version/* files represent
# the same version of code: the older ones have minimal bug maintainence
# only and it doesn't seem reasonable to up their version number if they
# don't change.
########################################################################

# Test fixtures that cannot appear in MANIFEST because manifind skips
# directory symlinks and cyclic symlinks.  dircopy creates them from
# version/v5.40; this block is a fallback for clean tarball installs.
#
# 09-Bin-symlink-exec.t is a file symlink so that $0 is a symlink when
# make test runs it, letting the test verify $Bin_l/$Bin_p behavior.

for my $spec
(
    [ catfile( 't', '10-Bin-path', 'foo' ), 'bar',                '../../.'                                              ]
  , [ 't',                                  '12-Bin_l',           '11-Bin'                                               ]
  , [ catfile( 't', '10-Bin-path'        ), '09-Bin-symlink-exec.t', '../../version/v5.40/t/10-Bin-path/09-Bin-symlink-exec.t' ]
)
{
    my ( $dir, $name, $target ) = @$spec;
    my $path = catfile $dir, $name;

    -l $path
    and next;

    # dircopy may have copied a regular file where the symlink belongs.
    -e $path
    and do
    {
        unlink $path
        or warn "Cannot remove '$path' before symlinking: $!";
    };

    -d $dir
    or make_path $dir;

    symlink $target, $path
    or warn "Cannot create symlink '$path' -> '$target': $!";
}

# ExtUtils::MakeMaker calls manicheck() when no Makefile exists yet.
# manifind uses File::Find follow_fast, which dies (Perl 5.42+) when it
# re-encounters t/12-Bin_l (a dir symlink to t/11-Bin).  Touch an empty
# placeholder so EUMM skips the check; WriteMakefile overwrites it.
unless( -f 'Makefile' )
{
    open my $fh, '>', 'Makefile'
    or die "Cannot create placeholder Makefile: $!";
}

WriteMakefile
(
qw
(
    NAME            FindBin::libs
    LICENSE         perl
),

# note that the VERSION_FROM path is handled *after* the
# copy from ./version/* is dealt with in the previous step.
#
# after three modules and examples the version has to float
# independent of just the modules.

  VERSION         => v5.1.5
, AUTHOR          => 'Steven Lembark <lembark@wrkhors.com>'
, PREREQ_PM       =>
    {
        'Cwd'
        => version->parse( 'v3.73'  )->numify,

        'File::Copy::Recursive::Reduced'
        => version->parse( 'v0.002' )->numify,

        # particular versions
        # are unlikely to cause pain.

        qw
        (
            Carp                    0
            Cwd                     0
            Data::Dump              0
            File::Basename          0
            File::Spec::Functions   0
            File::Temp              0
            File::stat              0
            List::Util              0
            Test::More              0
            Symbol                  0
            strict                  0
            version                 0
        )
    }

, @config_requires,
);

{
    package MY;

    sub postamble
    {
        <<END
TEST_FILES = t/*.t t/*/*.t

# pure_all runs during the build phase; test depends on it.
# Hooking here ensures install-tests runs before the harness
# discovers which test files exist, not after.

pure_all :: prepare_tests

prepare_tests :
\tt/bin/install-tests

.PHONY : prepare_tests
END
    }
}

__END__
