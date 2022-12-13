use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME                => 'GitHub::Actions',
              AUTHOR              => 'JJ Merelo <jmerelo@CPAN.org>',
              VERSION_FROM        => 'lib/GitHub/Actions.pm',
              ABSTRACT_FROM       => 'lib/GitHub/Actions.pm',
              PL_FILES            => {},
              PREREQ_PM => {
                            'Test::More' => 0,
                            'version'    => 0,
                           },
              TEST_REQUIRES => { "Test::Perl::Critic" => 0,
                                 "Test::Output" => 0,
                                 "Test::File::Contents" => 0},
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'GitHub-Actions-*' },
              META_MERGE => {
                            'meta-spec' => { version => 2 },
                            resources => {
                                repository  => {
                                    type => 'git',
                                    url  => 'https://github.com/JJ/perl-GitHub-Actions/',
                                    web  => 'https://github.com/JJ/perl-GitHub-Actions/',
                                },
                                bugtracker  => { web => 'https://github.com/JJ/perl-GitHub-Actions/issues' },
                            }
                           },
);
