use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'List::NSect',
    VERSION_FROM => 'lib/List/NSect.pm',
    AUTHOR       => 'Michael R. Davis (mrdvt)',
    ABSTRACT_FROM=> 'lib/List/NSect.pm',
    PREREQ_PM    => {
                     'Test::Simple'    => 0.44,
                     'List::MoreUtils' => 0,
                     'Exporter'        => 0,
                    },
    'META_MERGE' => {
                     'resources' => {
                       'repository' => {
                         'web' => 'https://github.com/mrdvt92/perl-List-NSect.git',
                         'url' => 'git@github.com:mrdvt92/perl-List-NSect.git',
                         'type' => 'git'
                       },
                       'homepage' => 'https://github.com/mrdvt92/perl-List-NSect',
                       'bugtracker' => {
                         'web' => 'https://github.com/mrdvt92/perl-List-NSect/issues'
                       },
                     },
                     'meta-spec' => {'version' => 2},
                    },
);
