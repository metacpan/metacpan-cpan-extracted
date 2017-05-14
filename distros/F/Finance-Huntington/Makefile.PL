use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Finance::Huntington',
    'VERSION'   	=> '0.01', 
    'PREREQ_PM'		=> {
                        HTML::Parser    => '3.11', }, 
);
