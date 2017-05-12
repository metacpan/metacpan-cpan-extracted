use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 'EJBCA::CrlPublish',
    'VERSION_FROM'		=> 'CrlPublish.pm',	# finds $VERSION
    'dist'			=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'INSTALLSCRIPT'		=> '/usr/bin',
    'INSTALLSITESCRIPT'		=> '/usr/bin',
    'INSTALLVENDORSCRIPT'	=> '/usr/bin',
    'EXE_FILES'			=> [ 'crlpublish' ],
    'MAN1PODS'			=> { 'pod/crlpublish' => 'blib/man1/crlpublish.1' },
);
