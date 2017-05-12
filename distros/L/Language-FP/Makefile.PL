use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Language::FP',
    'VERSION_FROM'	=> 'FP.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Parse::RecDescent' => 0.01,
			     'Regexp::Common' => 0.01 },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => "Sean O'Rourke <seano@cpan.org>") : ()),
);
