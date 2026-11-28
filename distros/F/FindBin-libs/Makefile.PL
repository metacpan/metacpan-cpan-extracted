#!/usr/bin/env perl
########################################################################
# even the old version is guaranteed not to work
# with anything earlier than 5.008001.

use 5.008001;
use strict;
use version;

use ExtUtils::MakeMaker;

use File::Basename      qw( basename    );
use File::Path          qw( mkpath rmtree );
use List::Util          qw( first       );

# everything used here has to work on perl v5.8.1: modules are either
# core in v5.8.1 with the functions used (mkpath and rmtree, not
# File::Path 2.07's make_path and remove_tree) or are listed in
# CONFIGURE_REQUIRES with a release that installs on v5.8.1.

use File::Spec::Functions
qw
(
    catdir
    catfile
    curdir
);

########################################################################
# deal with MakeMaker version.
#
# CONFIGURE_REQUIRES is read by installers from the static META.json,
# written by whatever perl ran "make dist", before this file is run:
# it cannot be selected by perl version here.  Every entry must
# install on v5.8.1:
#
#   version 0.77 (not core before v5.10; parse() needs 0.77, v5.10.0
#   ships 0.74);
#   File::Copy::Recursive::Reduced, which uses parent without declaring
#   it (parent is core from v5.10.1, installs on v5.6) and whose tests
#   need Path::Tiny (v5.8.1): the reason the floor is v5.8.1;
#   List::Util for first(), present in every release.

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
                    [ qw( version                         v0.77 ) ],
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
                    parent
                    ExtUtils::MakeMaker
                    File::Basename
                    File::Path
                    List::Util
                    File::Spec::Functions
                )
            ),
        }
    )
;

########################################################################
# perl version used to select the version/ directory and the
# prerequisites.  PERL_VERSION (if set) stands in for the running
# perl, so any version/ directory can be selected for validation.
#
# version->parse handles both: $^V is a plain v-string on v5.8.1, and
# PERL_VERSION is a string ("v5.8.1", "v5.40", "v5.30.1").  The ternary
# is used instead of // to keep this file v5.8.1 safe.

my $perl_v
= defined $ENV{ PERL_VERSION }
? version->parse( $ENV{ PERL_VERSION } )
: version->parse( $^V )
;

########################################################################
# install the correct version of libs.pm based on the running perl
# version. after that take the version from whatever's on the disk.
#
# When running from a dist tarball there is no version/ directory;
# lib/ and t/ are already in place -- skip the dircopy entirely.
########################################################################

# version of the directory installed, '' for a dist install.

my $src_v   = '';

if( -d 'version' || $ENV{ FORCE_VERSION } )
{
    # $perl_v is set above from PERL_VERSION or $^V.

    print "\n# Installing with perl version: '$perl_v'\n";

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
                version->parse( $base )
            };

            if( defined $ver )
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

    $src_v  = version->parse( basename $src_d );

    require File::Copy::Recursive::Reduced;

    # The top-level MANIFEST is the package MANIFEST: tracked in git
    # and shipped in the tarball, it lists every version/ tree.  It is
    # saved before dircopy and restored after, so the version-local
    # MANIFEST that dircopy installs never replaces it; it is not
    # touched during cleanup.

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
        ? rmtree( $dest )
        : unlink $dest;
    }

    print "\n# Note: FCR2 'Copying a symlink...whose target does not exist' warnings",
        "\n# for t/bin/install-tests.d/*.inst are false positives -- relative",
        "\n# symlinks whose target exists in the same directory are copied",
        "\n# correctly.  The warnings are suppressed.\n";

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

# install-tests generates the t/01-bash/, t/02-syntax/, t/03-version/
# symlinks and the t/20-*/ t/21-*/ etc. groups from tests.yaml; none
# of them are distributed.  Called from the test target after
# dependencies are installed.

my $install_tests   = catfile curdir, 't', 'bin', 'install-tests';

-f $install_tests
and chmod 0755, $install_tests;

# only version/v5.40 has t/bin/install-tests and tests in t/*/: the
# Makefile runs install-tests only when t/bin is a directory and
# install-tests is an executable file, and globs t/*/*.t only when
# there are tests to match (an unmatched glob is passed to the
# harness as a literal name).

my $test_bin_d  = catdir curdir, 't', 'bin';

my $has_install
= -d $test_bin_d
&& -f $install_tests
&& -x _
;

my @sub_tests   = glob catfile( 't', '*', '*.t' );

my $test_files
= ( $has_install || @sub_tests )
? 't/*.t t/*/*.t'
: 't/*.t'
;

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
#
# each spec names the directory its test lives in: the fixtures only
# belong to the v5.40 tests, so a spec is skipped when the selected
# version's t/ does not have that directory (e.g., version/v5.28).

for my $spec
(
    [ 't',                                  '12-Bin_l',              '11-Bin'                                                , catfile( 't', '11-Bin'      ) ]
  , [ catfile( 't', '10-Bin-path'        ), '09-Bin-symlink-exec.t', '../../version/v5.40/t/10-Bin-path/09-Bin-symlink-exec.t', catfile( 't', '10-Bin-path' ) ]
)
{
    my ( $dir, $name, $target, $test_d ) = @$spec;
    my $path = catfile $dir, $name;

    -d $test_d
    or next;

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
    or mkpath $dir;

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

########################################################################
# prerequisites by version directory: each release lists only what
# its own lib/ and t/ use, so an older perl is never asked to install
# a module that requires a newer one (e.g., File::Util::SecureDir is
# v5.36+ and used only by v5.40).  These reach installers through
# MYMETA, generated here for the running perl.
#
# done_testing in the tests of every release needs Test::More 0.88.
# v5.40 uses List::Util uniq (1.45).  t/bin/install-tests reads
# tests.yaml with YAML::Tiny.

my %dir_prereqz =
(
    'v5.8.1'    =>
    {
        runtime =>
        {
            map { ( $_ => 0 ) }
            qw( Carp Cwd File::Basename File::Spec::Functions List::Util Symbol )
        }
      , test    =>
        {
            'File::Temp'    => 0
          , 'Test::More'    => 0.88
        }
    }
  , 'v5.40'     =>
    {
        runtime =>
        {
            ( map { ( $_ => 0 ) } qw( Carp File::Basename File::Spec::Functions File::stat Symbol parent ) )
          , 'Cwd'                   => version->parse( 'v3.73' )->numify
          , 'List::Util'            => 1.45
          , 'File::Util::SecureDir' => version->parse( 'v0.1.0' )->numify
        }
      , test    =>
        {
            ( map { ( $_ => 0 ) } qw( Encode File::Copy File::Find File::Path File::Temp IPC::Open3 YAML::Tiny autodie ) )
          , 'Test::More'    => 0.88
        }
    }
);

# v5.14 and v5.28 use the same modules as v5.8.1.

$dir_prereqz{ $_ } = $dir_prereqz{ 'v5.8.1' }
for qw( v5.14 v5.28 );

# the table entry is chosen by the version directory installed above;
# a dist install without version/ chooses by the perl version.

my $dir_v
= $src_v
? $src_v
: $perl_v
;

my $prereq_key
= first
{
    version->parse( $_ ) <= $dir_v
}
sort
{
    version->parse( $b ) <=> version->parse( $a )
}
keys %dir_prereqz
or die "No prerequisites for version '$dir_v'.\n";

my $prereqz = $dir_prereqz{ $prereq_key };

print "\n# Prerequisites for: '$prereq_key'.\n";

# TEST_REQUIRES needs MakeMaker 6.64, older versions get the test
# modules as runtime prerequisites.

my @test_requires
= $mm_v < 6.64
? ()
: ( TEST_REQUIRES => { %{ $prereqz->{ test } } } )
;

my @test_prereqs
= $mm_v < 6.64
? %{ $prereqz->{ test } }
: ()
;

# File::Copy::Recursive::Reduced is configure-only: MakeMaker before
# 6.52 has no CONFIGURE_REQUIRES, and gets it as a runtime one.

my @fcrr_prereq
= $mm_v < 6.52
? ( 'File::Copy::Recursive::Reduced' => version->parse( 'v0.6' )->numify )
: ()
;

WriteMakefile
(
qw
(
    NAME            FindBin::libs
    LICENSE         perl
    VERSION         v5.5.3
),

# note that the VERSION_FROM path is handled *after* the
# copy from ./version/* is dealt with in the previous step.
#
# after three modules and examples the version has to float
# independent of just the modules.

, AUTHOR          => 'Steven Lembark <lembark@wrkhors.com>'
, PREREQ_PM       =>
    {
        %{ $prereqz->{ runtime } }
      , @fcrr_prereq
      , @test_prereqs
    }

, @config_requires
, @test_requires,
);

{
    package MY;

    sub postamble
    {
        my $text    = "TEST_FILES = $test_files\n";

        $has_install
        or return $text;

        $text . <<END

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
