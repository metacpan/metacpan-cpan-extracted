use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::GMap',
    AUTHOR              => 'Payan Canaran <pcanaran@cpan.org>',
    VERSION_FROM        => 'lib/HTML/GMap.pm',
    ABSTRACT_FROM       => 'lib/HTML/GMap.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'CGI'             => 0,
        'CGI::Session'    => 0,
        'DBD::mysql'      => 0,
        'DBI'             => 0,
        'File::Temp'      => 0,
        'GD::Graph::pie'  => 0,
        'GD::Icons'       => 0,
        'List::MoreUtils' => 0,
        'List::Util'      => 0,
        'LWP::Simple'     => 0,
        'Storable'        => 0,
        'Template'        => 0,
        'Time::Format'    => 0,
        'XML::Simple'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-GMap-*' },
);
