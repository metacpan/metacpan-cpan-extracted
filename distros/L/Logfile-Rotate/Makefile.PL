use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	       => 'Logfile::Rotate',
    'VERSION_FROM' => 'Rotate.pm', # finds $VERSION
    'PREREQ_PM'    => { 'File::Copy'  => 2.02 }, # requires
    'dist'         => {
		PREOP      => '/opt/perl5/bin/pod2text Rotate.pm > README;\
                       /opt/perl5/bin/pod2html --noindex \
                       Rotate.pm > Logfile-Rotate.man.html',
		COMPRESS=> 'gzip -9f', SUFFIX=>'gz',
    },
);
