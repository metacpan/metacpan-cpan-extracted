use ExtUtils::MakeMaker;
# See the perldoc for ExtUtils::MakeMaker for details of how to
# influence the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'LaTeX::Parser',
    'VERSION' => '0.01',
    'clean' => {'FILES' => "test.dvi test.aux test.log"},
);
