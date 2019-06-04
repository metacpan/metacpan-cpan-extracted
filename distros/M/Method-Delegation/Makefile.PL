use strict;
use warnings;
require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Method::Delegation',
    'VERSION_FROM' => 'lib/Method/Delegation.pm',
    'PREREQ_PM'    => {
        'Test::Most'   => '0.35',
        'Sub::Install' => '0.928',
    },
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {},
    META_MERGE    => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:Ovid/method-delegation.git',
                web  => 'https://github.com/Ovid/method-delegation.git',
            },
        },
    },
);
