use strict;
use warnings;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

WriteMakefile( NAME          => 'Games::WoW::Armory',
               AUTHOR        => 'franck cuny <franck.cuny@gmail.com>',
               LICENSE       => 'perl',
               VERSION_FROM  => 'lib/Games/WoW/Armory.pm',
               ABSTRACT_FROM => 'lib/Games/WoW/Armory.pm',
               PL_FILES      => {},
               PREREQ_PM     => {
                              'Test::More'            => 0,
                              'version'               => 0,
                              'LWP::UserAgent'        => 0,
                              'XML::Simple'           => 0,
                              'Class::Accessor::Fast' => 0,
                              'Test::Perl::Critic' => 0,
               },
               dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
               clean => { FILES => 'Games-WoW-Armory-*' },
);
