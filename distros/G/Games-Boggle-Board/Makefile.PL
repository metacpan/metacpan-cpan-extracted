use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Games::Boggle::Board',
    'VERSION_FROM' => 'Board.pm', # finds $VERSION
);
