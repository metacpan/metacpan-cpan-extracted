use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MPE::IMAGE',
    'VERSION_FROM'	=> 'IMAGE.pm', # finds $VERSION
    'AUTHOR'            => 'Ted Ashton <ashted@southern.edu>',
    'ABSTRACT'          => "Access to MPE's TurboIMAGE intrinsics",
);

sub MY::postamble {
  '
README: IMAGE.pm
	/PERL/PUB/pod2text IMAGE.pm > README
  ';
}
