use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'ExtUtils::XSBuilder',
    'VERSION_FROM' => 'XSBuilder.pm', 
	'AUTHOR' => 'Gerald Richter <richter@dev.ecos.de>',
	'ABSTRACT' => 'Automatic XS glue code generation',
    'PREREQ_PM'    => { 'Parse::RecDescent' => 0, 'Tie::IxHash' => 0 },

);

