use 5.014;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Math::Geometry::HexGrid',
    VERSION_FROM     => 'lib/Math/Geometry/HexGrid.pm',
    ABSTRACT_FROM    => 'lib/Math/Geometry/HexGrid.pm',
    AUTHOR           => 'Steffen Mueller <cpan@steffen-mueller.net>',
    LICENSE          => 'mit',
    OBJECT           => '$(O_FILES)',
    C                => ['hexgrid.c', 'HexGrid.c'],
    H                => ['hexgrid.h'],
    INC              => '-I.',
    OPTIMIZE         => '-O3',
    PREREQ_PM        => {
        'XSLoader' => 0,
    },
    TEST_REQUIRES    => {
        'Test::More' => '0.98',
        'JSON::PP'   => 0,
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/robot-ai-strategy/Math-Geometry-HexGrid.git',
                web  => 'https://github.com/robot-ai-strategy/Math-Geometry-HexGrid',
            },
        },
    },
);
