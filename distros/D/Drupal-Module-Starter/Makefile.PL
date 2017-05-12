use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Drupal::Module::Starter',
    AUTHOR              => 'Steve McNabb <smcnabb@cpan.org>',
    VERSION_FROM        => 'lib/Drupal/Module/Starter.pm',
    ABSTRACT_FROM       => 'lib/Drupal/Module/Starter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML' => 0,
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
    },
    EXE_FILES => [ 'scripts/drupal-module-starter' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Drupal-ModStarter-*' },
);
