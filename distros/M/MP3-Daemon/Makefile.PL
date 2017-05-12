use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'MP3::Daemon',
    'VERSION_FROM'  => 'Daemon.pm',
    'ABSTRACT_FROM' => 'Daemon.pm',
    'EXE_FILES'     => [ qw(bin/mp3 bin/pimp) ],
    'PREREQ_PM'     => {
        'Audio::Play::MPG123' => 0,
        'IO::Socket'          => 0,
        'MP3::Info'           => 0,
        'Pod::Usage'          => 0,
        'POSIX'               => 0,
    },
    'dist'          => {
        'COMPRESS'  => 'gzip -9v',
        'SUFFIX'    => '.gz',
    },
);

sub MY::postamble {
'
readme : README.mp3 README.pimp README

README : Daemon.pm
	pod2text Daemon.pm > README

README.mp3 : bin/mp3
	pod2text bin/mp3 > README.mp3

README.pimp : bin/pimp
	pod2text bin/pimp > README.pimp

';
}

# vim:syntax=perl
# $Id: Makefile.PL,v 1.9 2001/02/14 22:45:53 beppu Exp $
