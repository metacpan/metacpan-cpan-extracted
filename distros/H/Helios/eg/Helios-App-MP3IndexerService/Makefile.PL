use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %mmopts = (
    NAME              => 'Helios::App::MP3IndexerService',
    VERSION_FROM      => 'lib/Helios/App/MP3IndexerService.pm',
    PREREQ_PM         => {
                             'Helios'    => 2.80,
                             'MP3::Info' => 1.24,
                         },
    EXE_FILES         => [ 'mp3submit4index.pl' ],
    INST_SCRIPT       => 'bin',

);

if ( $] >= 5.005 ) {
	$mmopts{ABSTRACT_FROM} = 'lib/Helios/App/MP3IndexerService.pm';
	$mmopts{AUTHOR} = 'Andrew Johnson <lajandy at cpan dotorg';
}

WriteMakefile(%mmopts);
