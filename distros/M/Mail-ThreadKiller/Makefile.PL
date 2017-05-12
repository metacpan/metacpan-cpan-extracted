use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mail::ThreadKiller',
    AUTHOR              => 'Dianne Skoll <dfs@roaringpenguin.com>',
    VERSION_FROM        => 'lib/Mail/ThreadKiller.pm',
    ABSTRACT_FROM       => 'lib/Mail/ThreadKiller.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/threadkiller-clean-db.pl',
			     'bin/threadkiller-kill-msgids.pl' ],
    MAN1PODS            => { 'bin/threadkiller-clean-db.pl' => 'blib/man1/threadkiller-clean-db.pl.1',
			     'bin/threadkiller-kill-msgids.pl' => 'blib/man1/threadkiller-kill-msgids.pl.1'},

    PREREQ_PM => {
	    'DB_File' => 0,
    },
    TEST_REQUIRES => {
	    'Test::More' => 0,
	    'Test::Deep' => 0,
	    'Email::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mail-ThreadKiller-*' },
);
