use ExtUtils::MakeMaker;
WriteMakefile(
    LICENSE        => 'mit',
    NAME           => 'Math::Round::SignificantFigures',
    VERSION_FROM   => 'lib/Math/Round/SignificantFigures.pm',
    PREREQ_PM      => {
                       POSIX => 0,
                      },
    ABSTRACT_FROM  => 'lib/Math/Round/SignificantFigures.pm',
    AUTHOR         => 'Michael R. Davis',
    'META_MERGE'   => {
                       'resources' => {
                         'repository' => {
                           'web' => 'https://github.com/mrdvt92/perl-Math-Round-SignificantFigures.git',
                           'url' => 'git@github.com:mrdvt92/perl-Math-Round-SignificantFigures.git',
                           'type' => 'git'
                         },
                         'homepage' => 'https://github.com/mrdvt92/perl-Math-Round-SignificantFigures',
                         'bugtracker' => {
                             'web' => 'https://github.com/mrdvt92/perl-Math-Round-SignificantFigures/issues'
                         }
                       },
                       'meta-spec' => {'version' => 2}
                      },
);
