use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Encode::UTF8::Slow',
    VERSION_FROM   => 'lib/Encode/UTF8/Slow.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Exporter' => '5.57' },
    ABSTRACT_FROM  => 'lib/Encode/UTF8/Slow.pm',
    AUTHOR         => 'David Farrell',
    LICENSE        => 'freebsd',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/dnmfarrell/Encode-UTF8-Slow.git',
                web  => 'https://github.com/dnmfarrell/Encode-UTF8-Slow',
            },
        }})
     : ()
    ),
);
