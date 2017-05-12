use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::SearchPage',
    AUTHOR              => 'Payan Canaran <pcanaran@cpan.org>',
    VERSION_FROM        => 'lib/HTML/SearchPage.pm',
    ABSTRACT_FROM       => 'lib/HTML/SearchPage.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'              => 0,
        'CGI'                     => 0,
        'CGI::Session'            => 0,
        'DBI'                     => 0,
        'List::Util'              => 0,
        'LWP::Simple'             => 0,
        'Spreadsheet::WriteExcel' => 0,
        'Storable'                => 0,
        'Tie::IxHash'             => 0,
        'Time::Format'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-SearchPage-*' },
);
