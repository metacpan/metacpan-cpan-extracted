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
        'Test::Exception' => 0,
        'Cwd'        => 0,
        'File::Basename' => 0,
        'File::Temp' => 0,
	    'version'    => 0,
	    'Git' => 0,
	    'Test::Perl::Critic' => 0, 
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Git-Repo-Commits-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                url  => 'https://github.com/JJ/perl-git-commit/',
                web  => 'https://github.com/JJ/perl-git-commit/',
            },
            bugtracker  => { web => 'https://github.com/JJ/perl-git-commit/issues' },
        }
    },

);
