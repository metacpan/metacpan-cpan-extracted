use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Geo::libpostal',
    VERSION_FROM   => 'lib/Geo/libpostal.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Exporter' => '5.57', 'Test::Fatal' => 0, 'Const::Fast' => 0 },
    ABSTRACT_FROM  => 'lib/Geo/libpostal.pm',
    AUTHOR         => 'David Farrell',
    CCFLAGS        => '-Wall',
    LIBS           => ['-lpostal'],
    OPTIMIZE       => '-O3',
    DEFINE         => '',
    INC            => '-I.',
    LICENSE        => 'freebsd',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/dnmfarrell/Geo-libpostal.git',
                web  => 'https://github.com/dnmfarrell/Geo-libpostal',
            },
        }})
     : ()
    ),
);
