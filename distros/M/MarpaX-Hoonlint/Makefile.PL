use 5.010001;
use strict;
use warnings;
use ExtUtils::Install;
use Fatal qw(open close mkdir chdir);
use File::Spec 0.82;
use File::Find 1.12;
use File::Copy;
use IPC::Cmd;
use English qw( -no_match_vars );
use Time::Piece 1.12;
use Cwd;

use Config;
use ExtUtils::MakeMaker;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '1.006000';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

# This comment reminds me of how to use Module::CoreList.
# It's here for convenience in working on this file.
# perl -MModule::CoreList -E 'print $Module::CoreList::version{5.010001}{Carp};'

my $requires            = {
    'Carp' => 0,
    'Cwd' => 0,
    'Data::Dumper' => 0,
    'DynaLoader' => 0,
    'English' => 0,
    'Exporter' => 0,
    'ExtUtils::CBuilder' => 0,
    'ExtUtils::MakeMaker' => 0,
    'ExtUtils::Manifest' => 0,
    'ExtUtils::Mkbootstrap' => 0,
    'Fatal' => 0,
    'File::Copy' => 0,
    'File::Spec' => 0,
    'IPC::Cmd' => 0,
    'List::Util' => 0,
    'Marpa::R2' => 8.000000,
    'Scalar::Util' => 0,
    'Test::Differences' => 0,
    'Test::More' => 0,
    'Time::Piece' => 0,
    'XSLoader' => 0,
};

my @files_to_cleanup = (
);

WriteMakefile(
    clean    => { FILES => ( join q{ }, @files_to_cleanup ) },
    NAME     => 'MarpaX::Hoonlint',
    VERSION => $STRING_VERSION,
    AUTHOR   => 'Jeffrey Kegler',
    ABSTRACT => 'Hoonlint',

    # Let the three of these be the same.
    CONFIGURE_REQUIRES => $requires,
    BUILD_REQUIRES => $requires,
    PREREQ_PM => $requires,

    EXE_FILES => [ 'hoonlint' ],

    MIN_PERL_VERSION => '5.10.1',
    META_MERGE => {
        resources =>
            { repository => 'git://github.com/jeffreykegler/hoonlint.git', },
    },
    LICENSE  => 'mit',
);

# vim: shiftwidth=4:
