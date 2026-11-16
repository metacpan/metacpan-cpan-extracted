#!/usr/bin/env perl
########################################################################
# build File::Util::SecureDir distribution.
########################################################################
use v5.36;

use ExtUtils::MakeMaker;

use File::Basename      qw( basename    );
use File::Path          qw( remove_tree );
use List::Util          qw( first       );

use File::Spec::Functions
qw
(
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
                )
            ),
        }
    )
;

########################################################################
# install the correct version of File/Util/SecureDir.pm and its tests
# based on the running perl version. after that take the version from
# whatever's on the disk.
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

    File::Copy::Recursive::Reduced::dircopy( $src_d => '.' )
    or die "Failed copy from $src_d.\n";

    if( defined $manifest_text )
    {
        open my $fh, '>', 'MANIFEST'
        or die "Cannot restore MANIFEST: $!";
        print $fh $manifest_text;
        close $fh;
    }

    # lib/ and t/ were just generated, so any saved MANIFEST is stale:
    # regenerate it (MANIFEST.SKIP leaves out version/ and build debris)
    # so that make dist works straight after perl Makefile.PL.

    require ExtUtils::Manifest;

    {
        local $ExtUtils::Manifest::Quiet = 1;

        ExtUtils::Manifest::mkmanifest();
    }
}
else
{
    print "\n# Dist install: lib/ and t/ already in place; skipping dircopy.\n";
}

WriteMakefile
(
    NAME             => 'File::Util::SecureDir'
  , VERSION          => v0.1.0
  , ABSTRACT_FROM    => 'lib/File/Util/SecureDir.pm'
  , AUTHOR           => 'Steven Lembark <lembark@wrkhors.com>'
  , LICENSE          => 'perl'
  , MIN_PERL_VERSION => '5.036'
  , PREREQ_PM        =>
    {
        qw(
            Carp            0
            Config          0
            File::Temp      0
            List::Util      0
            Test::More      0
        )

        # Win32 owner and ACL checks, and the process-token identity.

      , (
            $^O eq 'MSWin32'
            ? qw( Win32 0 Win32::API 0 )
            : ()
        )
    }

  , @config_requires,
);

__END__
