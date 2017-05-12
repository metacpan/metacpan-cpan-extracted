# Makefile.PL for Debug::Trace.

use ExtUtils::MakeMaker;

my %ctl = (
    NAME		=> 'Debug::Trace',
    VERSION_FROM	=> 'lib/Debug/Trace.pm',
    PREREQ_PM		=> {
	'Data::Dumper'	=> 2.101,
    },
);

if ( $] >= 5.005 ) {
    $ctl{ABSTRACT_FROM} = 'lib/Debug/Trace.pm';
    $ctl{AUTHOR}        = 'JPC, KANE, JV';
}

WriteMakefile(%ctl);
