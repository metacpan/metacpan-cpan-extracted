#!/usr/bin/env perl
########################################################################
# LL::S v1 uses v5.24; v2 requires 5.40.

use v5.24;

use ExtUtils::MakeMaker;

use List::Util  qw( first   );

use File::Spec::Functions
qw
(
    splitpath
    catpath
    catdir
    curdir
);

# use with splitpath to descibe whether the last element 
# is treated as a basename or part of the directory.

sub no_file()   { 1  };
sub with_file() { '' };

########################################################################
# deal with MakeMaker version.

my @config_requires
= ExtUtils::MakeMaker->VERSION < 6.52
? ()
: (
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
          )
        , (
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
          )
      }
  )
;

########################################################################
# install the correct version of libs.pm based on the running perl
# version. after that take the version from whatever's on the disk.
########################################################################

my $perl_v
= eval
{
    my $text    = sprintf '%vd' => $^V;

    print "\n# Parsing perl version: '$text'\n";

    version->parse( $text )->numify
}
or die "Un-parsable perl version: '$^V'";

print "\n# Running perl version: '$perl_v'\n";

my ( $cwd_v, $cwd_d ) = ( splitpath curdir, no_file )[0,1];

my $src_d   
= $ENV{ FORCE_VERSION } 
|| do
{
    my $glob
    = catpath $cwd_v, catdir( $cwd_d, 'version' ), '*';

    my @v_dirz = glob $glob
    or die "Unable to locate version dirs: '$glob'";

    say join "\n\t", "Searching version dirs:", @v_dirz;

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
        eval
        {
            my $base    = ( splitpath $_, with_file )[-1];
            my $ver     = version->parse( $base )->numify
            or die "Ignore unparsable version: '$base' at '$_'\n";

            [ $ver => $_ ]
        }
        or do
        {
            say "$@";
            ()
        }
    }
    @v_dirz
    or die "Unable to install with Perl version '$perl_v'"
    ;

    $found->[ -1 ]
};

-e $src_d
or die "Botched source dir: Non-existant $src_d";

-d $src_d
or die "Botched source dir: Non-directory $src_d";

print "\n# Version directory: $src_d ($perl_v).\n";

# examples are development material: the top-level ./examples is a
# tracked symlink into version/*, and Examples is the submodule that
# is released as LinkedList::Single::Examples with its own Makefile.PL
# and tests. neither is removed, copied, or tested from here.

my %not_copied = ( examples => 1, Examples => 1 );

# remove stale symlinks used during development

for my $i ( glob "$src_d/*" )
{
    my $j   = ( splitpath $i )[-1];

    $not_copied{ $j }
    and next;

    unlink $j;

    $! =~ m{^No such}
    and next;

    -e $j
    and die "Existing $j collides with $i and must be removed ($!).";
}

# don't validate the count, just give up
# if it fails entirely.
#
# note that the behavior is returning undef on failure, 
# but in this case we know there should be files copied 
# so any false value is fatal.

do
{
    my @curr_d  = ( splitpath curdir, no_file )[0,1];
    my @src_p   = ( splitpath $src_d, no_file )[0,1];

    my @subz    = glob catpath @src_p, '*'
    or die "No dubsirs found in $src_d\n";

    for( @subz )
    {
        my $base    = ( splitpath $_, with_file )[-1];
        my $dst     = catpath @curr_d, $base;
    }
};

# if we are still alive at this point then we can 
# reasonably copy the version subdir's.

require File::Copy::Recursive::Reduced;

for my $i ( glob "$src_d/*" )
{
    my $base    = ( splitpath $i )[-1];

    $not_copied{ $base }
    and next;

    my $copy
    = -d $i
    ? \&File::Copy::Recursive::Reduced::dircopy
    : \&File::Copy::Recursive::Reduced::fcopy
    ;

    $copy->( $i => $base )
    or die "Failed copy of $i.\n";
}

########################################################################
# reasonable question as to whether all of the version/* files represent
# the same version of code: the older ones have minimal bug maintainence
# only and it doesn't seem reasonable to up their version number if they
# don't change.
########################################################################

########################################################################
# MakeMaker's "is the kit complete" check walks the tree with File::Find
# and follow_fast, which dies on a directory it reaches twice. the
# development symlinks (./examples, examples/*/t/bin) do exactly that.
# the check only has to report files listed in MANIFEST that are missing,
# which does not need the walk.
########################################################################

{
    no warnings 'redefine';

    *ExtUtils::MakeMaker::check_manifest
    = sub
    {
        say "Checking if your kit is complete...";

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
        or return say "Looks good";

        say "Warning: the following files are missing in your kit:";
        say "\t$_" for @missing;
        say "Please inform the author.";
    };
}

########################################################################
# the distribution has its own version, hardwired here and in CHANGES.
# the modules under version/* carry their own versions. an API change
# raises the major version of everything. otherwise a file's version is
# its own: sub-version for internal changes and bug fixes, last number
# for tests, docs and comments. this version is raised by the largest
# kind of change in the release (any sub-version change: sub-version;
# only last-number changes: last number), so it can differ from the
# files' versions, and it restarts with each major release.
########################################################################

WriteMakefile
(
    qw
    (
        NAME            LinkedList::Single
        LICENSE         perl
    ),
  , VERSION         => 'v2.1.0'
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

            Benchmark               0
            Carp                    0
            Data::Dump              0
            Devel::Size             0
            File::Basename          0
            File::Spec::Functions   0
            File::Temp              0
            List::Util              0
            Test::More              0
            Symbol                  0
            strict                  0
            version                 0
        )
    }

  , test            =>
    {
        # the tests live one directory down, in t/NN-name/*.t.

        TESTS => 't/*.t t/*/*.t'
    }

  , @config_requires,
);

__END__
