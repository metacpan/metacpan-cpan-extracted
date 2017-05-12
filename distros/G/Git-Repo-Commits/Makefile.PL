use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Git::Repo::Commits',
    AUTHOR              => 'JJ <JMERELO@cpan.org>',
    VERSION_FROM        => 'lib/Git/Repo/Commits.pm',
    ABSTRACT_FROM       => 'lib/Git/Repo/Commits.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	    'version'    => 0,
	    'Git' => 0,
	    'Test::Perl::Critic', 
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Git-Repo-Commits-*' },
);
