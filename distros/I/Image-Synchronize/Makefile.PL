use 5.026002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::Synchronize',
    VERSION_FROM      => 'lib/Image/Synchronize.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    EXE_FILES => [ 'bin/imsync' ],
    PREREQ_PM         => {
                          'IO::Interactive' => 0,
                          'Image::ExifTool' => '10.14',
                          'Path::Class' => 0,
                          'Path::Iterator::Rule' => 0,
                          'Term::ProgressBar' => 0,
                          'XML::Twig' => 0,
                          'YAML::Any' => 0,
                         },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    ABSTRACT_FROM     => 'lib/Image/Synchronize.pm', # retrieve abstract from module
    AUTHOR            => 'Louis Strous <LS@quae.nl>',
    LICENSE           => 'perl',
);

sub MY::postamble {
  return <<'EOD';
# for MS Windows
imsync.exe: $(TO_INST_PM) $(EXE_FILES)
	pp -o imsync.exe -B -c bin/imsync

# for the imsync.quae.nl website
html: html/en/imsync.html html/nl/imsync.html

html/en/imsync.html: bin/imsync
	pod2cpanhtml $< > $@

html/nl/imsync.html: bin/imsync-nl.pod
	pod2cpanhtml $< > $@
EOD
}
