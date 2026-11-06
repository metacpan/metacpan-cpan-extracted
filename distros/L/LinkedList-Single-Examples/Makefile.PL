#!/usr/bin/env perl
########################################################################
# LinkedList::Single::Examples: worked examples built with
# LinkedList::Single v2, which requires perl v5.40.
#
# same approach as LinkedList::Single: the source lives in
# version/vX.YY/{lib,t,app,benchmarks}; Makefile.PL picks the newest
# version directory that is not newer than the running perl and copies
# its contents to the top level, where MakeMaker expects them.
########################################################################

use strict;
use warnings;

# the examples use v5.40 syntax; do not try to build anything older.
# exiting 0 without a Makefile is the convention for "not applicable".

BEGIN
{
    $] >= 5.040
    or do
    {
        print "\n# LinkedList::Single::Examples requires perl v5.40"
            , " (this is v", sprintf( '%vd' => $^V ), ").\n\n";

        exit 0;
    };
}

use ExtUtils::MakeMaker;

use File::Path  qw( remove_tree );
use List::Util  qw( first       );
use version;

use File::Spec::Functions
qw
(
    catdir
    catpath
    curdir
    splitpath
);

# use with splitpath to describe whether the last element
# is treated as a basename or part of the directory.

sub no_file()   { 1  };
sub with_file() { '' };

########################################################################
# pick the version directory.
########################################################################

my $perl_v = version->parse( sprintf '%vd' => $^V )->numify;

print "\n# Running perl version: '$perl_v'\n";

my ( $cwd_v, $cwd_d ) = ( splitpath curdir, no_file )[0,1];

my $src_d
= $ENV{ FORCE_VERSION }
|| do
{
    my $glob = catpath $cwd_v, catdir( $cwd_d, 'version' ), '*';

    my @v_dirz
    = glob $glob
    or die "Unable to locate version dirs: '$glob'";

    my $found
    = first
    {
        $_->[0] <= $perl_v
    }
    sort
    {
        # descending, so the first dir <= $^V is the newest usable.

        $b->[0] <=> $a->[0]
    }
    map
    {
        eval
        {
            my $base    = ( splitpath $_, with_file )[-1];
            my $ver     = version->parse( $base )->numify
            or die "Ignore unparsable version: '$base' at '$_'\n";

            [ $ver => $_ ]
        }
        or do
        {
            print $@;
            ()
        }
    }
    @v_dirz
    or die "Unable to install with Perl version '$perl_v'";

    $found->[1]
};

-d $src_d
or die "Botched source dir: Non-directory '$src_d'";

print "\n# Version directory: $src_d ($perl_v).\n";

########################################################################
# copy the version directory to the top level. the copies are build
# output (see .gitignore and MANIFEST.SKIP), so any left from an earlier
# run are replaced. the generated test tiers hold the absolute paths of
# the tree they were made in, so they are not copied; they are made again
# below from the copy.
########################################################################

require File::Copy::Recursive::Reduced;

my @generated = qw( t/00-syntax t/00-pod );

for my $i ( glob "$src_d/*" )
{
    my $base    = ( splitpath $i )[-1];

    -d $i
    or next;

    remove_tree $base;

    File::Copy::Recursive::Reduced::dircopy( $i => $base )
    or die "Failed copy of $i to $base.\n";
}

remove_tree @generated;

# tiers whose subjects are discovered, not listed. the generator finds
# perl scripts with file(1); without it only the hand-written tests run.

if( -x 't/bin/install-unit' )
{
    system( 't/bin/install-unit' ) == 0
    or warn "# t/bin/install-unit failed ($?): generated tiers skipped.\n";
}

########################################################################
# MakeMaker's "is the kit complete" check walks the tree with File::Find
# and follow_fast, which dies on a directory it reaches twice. all it has
# to do is report the files listed in MANIFEST that are missing, which
# does not need the walk.
########################################################################

{
    no warnings 'redefine';

    *ExtUtils::MakeMaker::check_manifest
    = sub
    {
        print "Checking if your kit is complete...\n";

        open my $fh, '<', 'MANIFEST'
        or die "Botched MANIFEST: $!\n";

        my @missing
        = grep
        {
            ! -e
        }
        map
        {
            ( split ' ' )[0] // ()
        }
        <$fh>;

        @missing
        or return print "Looks good\n";

        print "Warning: the following files are missing in your kit:\n";
        print "\t$_\n" for @missing;
        print "Please inform the author.\n";
    };
}

########################################################################
# VERSION is hardwired: the distribution has its own version, not that of
# LinkedList::Single or of any one module. there is no API to track, so
# vX is the LinkedList::Single major version the examples are built for.
# in vX.Y.Z, Y is raised for any noticeable change in the *.pm modules
# that run Perl code; Z is raised for any other change: a POD.pm, other
# documentation, the benchmarks, the tests.
#
# each POD.pm carries its own version, independent of the above: the last
# digit for spelling, typos and minor rewording; the middle digit for new
# topics or sections or major rewording; the first digit when the content
# is largely rewritten.
#
# the examples are modules under lib/. the apps and benchmarks stay in
# the distribution as source to read and run; they are not installed.
########################################################################

WriteMakefile
(
    qw
    (
        NAME                LinkedList::Single::Examples
        LICENSE             perl
        MIN_PERL_VERSION    5.040
    )
  , VERSION         => 'v2.0.1'
  , ABSTRACT_FROM   => 'lib/LinkedList/Single/Examples.pm'
  , AUTHOR          => 'Steven Lembark <lembark@wrkhors.com>'

  , CONFIGURE_REQUIRES =>
    {
        'ExtUtils::MakeMaker'               => 0
      , 'File::Copy::Recursive::Reduced'    => 0
      , 'File::Path'                        => 0
      , 'List::Util'                        => 0
      , 'version'                           => 0
    }

  , PREREQ_PM =>
    {
        'LinkedList::Single'    => '2.001000'
      , 'Devel::Size'           => 0
      , 'FindBin::libs'         => 0
      , 'Scalar::Util'          => 0
      , 'Time::HiRes'           => 0
    }

  , TEST_REQUIRES =>
    {
        'File::Basename'    => 0
      , 'Pod::Checker'      => 0
      , 'Test::Deep'        => 0
      , 'Test::More'        => 0
    }

  , test =>
    {
        # the tests live one directory down, in t/NN-name/*.t.

        TESTS => 't/*.t t/*/*.t'
    }
);

__END__
