use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'File::CacheDir',
    'VERSION_FROM'	=> 'CacheDir.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'AUTHOR' => 'earl@cpan.org',
);

sub postamble {
  return qq^
    
pm_to_blib: README

README: CacheDir.pm
\tpod2text CacheDir.pm >README
  ^;
}

1;
