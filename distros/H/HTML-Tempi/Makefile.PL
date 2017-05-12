use ExtUtils::MakeMaker qw(prompt WriteMakefile);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

if (system ("flex -f tempi.flex")) { die "Please install flex\n"; }

WriteMakefile(
    'NAME'		=> 'HTML::Tempi',
    'VERSION_FROM'	=> 'Tempi.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'LIBS'		=> ["-lm"], # e.g., '-lm'
		'OBJECT' => 'Tempi.o libs.o lex.yy.o',
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other',
		'OPTIMIZE' => '-O0'
);
