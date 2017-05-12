use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Hash::KeyMorpher',
    VERSION_FROM    => 'lib/Hash/KeyMorpher.pm',
    AUTHOR          => 'Michael Holloway <michael@thedarkwinter.com>',
    PREREQ_PM       => { 'Test::More' => 0, 'Exporter' =>0 },
    dist            => { COMPRESS => 'gzip', SUFFIX => '.gz', },
);
