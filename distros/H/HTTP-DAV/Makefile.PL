use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @programs_to_install = qw(dave);

WriteMakefile(
    'NAME'	=> 'HTTP::DAV',
    'VERSION_FROM' => 'lib/HTTP/DAV.pm',
    'dist' => {
        COMPRESS => 'gzip -9f --best',
        SUFFIX => '.gz',
        #PREOP => 'bin/dist'
    },
    'EXE_FILES' => [ map {"bin/$_"} @programs_to_install ],
    'PREREQ_PM' => { 
        'Cwd'          => 0,
        'File::Temp'   => 0,
        'LWP'          => 5.48,
        'Scalar::Util' => 0,
        'Time::Local'  => 0,
        'URI'          => 0,
        'URI::Escape'  => 0,
        'XML::DOM'     => 0,

        # bin/dave specific dependencies
        'Getopt::Long'     => 0,
        'Term::ReadLine'   => 0,
        'Text::ParseWords' => 0,
        'Pod::Usage'       => 0,
    },
);

