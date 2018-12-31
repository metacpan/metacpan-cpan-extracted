# File : Makefile.PL
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'    => 'MathML::itex2MML',            # Name of package
	'VERSION_FROM' => 'lib/MathML/itex2MML.pm', # finds $VERSION
	'AUTHOR'       => 'Jacques Distler (distler@golem.ph.utexas.edu)',
	'ABSTRACT'     => 'Convert itex equations to MathML',
	'PREREQ_PM'    => {
                     'Test::Simple' => '>= 0.44'
	},
	'test'         => {TESTS => 't/*.pl'},
	'LIBS'    => [],                    # Name of custom libraries
	'DEFINE'  => '-Ditex2MML_CAPTURE',
	'OBJECT'  => 'y.tab.o lex.yy.o itex2MML_perl.o'  # Object files
);

