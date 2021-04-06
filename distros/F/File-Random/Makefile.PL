use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'            => 'File::Random',
    'VERSION_FROM'    => 'Random.pm', # finds $VERSION
    'LICENSE'         => 'perl',
    'PREREQ_PM'        => {
        Want                  => 0,
        # Test-Modules
        Test::Class           => 0.03,
        Test::Exception       => 0.10,    # minimal version depends on Test::Class
        Test::More            => 0.44,
        Test::Warn            => 0.05,
        Test::ManyParams      => 0,
        Set::Scalar           => 0,       # didn't know the minimal version
        File::Temp            => 0
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url => 'git://github.com/hanfried/File-Random.git',
                    web => 'https://github.com/hanfried/File-Random',
                },
        },
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Random.pm', # retrieve abstract from module
       AUTHOR        => 'Janek Schleicher <bigj@kamelfreund.de>') : ()),
);
