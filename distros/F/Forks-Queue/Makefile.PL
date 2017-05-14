use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010001;

our %RECOMMENDED = ( DBI => 0, 'DBD::SQLite' => 0);
our %REQUIRED = ( JSON => '2.0', 'Time::HiRes' => 0, 'File::Temp' => 0 );
our @NO_INDEX = ();

our %META_MERGE
    = (recommends => \%RECOMMENDED);
if (@NO_INDEX) {
    $META_MERGE{no_index} = { 'package' => \@NO_INDEX };
}

our $FILES_TO_CLEAN
    = join " ", qw(Forks-Queue-* t/cfg* t/rq* t/*cfg);

our @TEST_FILES = ('t/[0-9]*.t');
if ($] >= 5.012) {
    unshift @TEST_FILES, 't/_*.t';
}

######################################################################

my $MM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(

    NAME                => 'Forks::Queue',
    AUTHOR              => q[Marty O'Brien <mob@cpan.org>],       #'],
    VERSION_FROM        => 'lib/Forks/Queue.pm',
    ABSTRACT_FROM       => 'lib/Forks/Queue.pm',
    PL_FILES            => {},
    PREREQ_PM => \%REQUIRED,
    test                => { TESTS => join(' ',@TEST_FILES) },

    ($MM_VERSION >= 6.46   ? ('META_MERGE' => \%META_MERGE ) : ()),
    ($MM_VERSION >= 6.3002 ? ('LICENSE'    => 'perl')        : ()),

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => $FILES_TO_CLEAN },

);



#############################################################################

package MY;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# additional testing targets
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub MY::postamble {
    # placeholder for future use
    return "";
}
