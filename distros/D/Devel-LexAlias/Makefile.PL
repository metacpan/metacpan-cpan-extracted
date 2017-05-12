use strict;
use ExtUtils::MakeMaker;
my $module = 'LexAlias.pm';
WriteMakefile(
    'NAME'         => 'Devel::LexAlias',
    'VERSION_FROM' => $module,
    'ABSTRACT_FROM' => $module,
    'AUTHOR' => 'Richard Clamp <richardc@unixbeard.net>',
    'LICENSE' => 'perl',
    'PREREQ_PM'    => {
        'Test::More' => 0,
        'Devel::Caller' => 0.03,
    },
);
