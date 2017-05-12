use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Email::Template',
    AUTHOR              => 'Shaun Fryer <pause.cpan.org@sourcery.ca>',
    VERSION_FROM        => 'lib/Email/Template.pm',
    ABSTRACT_FROM       => 'lib/Email/Template.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Cwd' => 0,
        'Carp' => 0,
        'Test::More' => 0,
        'Template' => 0,
        'MIME::Lite' => '3.01_04',
        'HTML::FormatText::WithLinks::AndTables' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Template-*' },
);
