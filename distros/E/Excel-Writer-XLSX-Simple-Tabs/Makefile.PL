use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Excel::Writer::XLSX::Simple::Tabs',
    VERSION_FROM   => 'lib/Excel/Writer/XLSX/Simple/Tabs.pm',
    AUTHOR         => 'Michael R. Davis',
    ABSTRACT_FROM  => 'lib/Excel/Writer/XLSX/Simple/Tabs.pm',
    LICENSE        => 'perl',
    BUILD_REQUIRES => {
                       'ExtUtils::MakeMaker' => 6.46,
                       'ExtUtils::MakeMaker::META_MERGE::GitHub' => 0,
                       'Test::Simple'                            => 0.44,
                      },
    PREREQ_PM     => {
                      'Package::New'                            => 0,
                      'IO::Scalar'                              => 0, #package is IO-stringy
                      'Excel::Writer::XLSX'                     => 0,
                     },
    META_MERGE    => {
                      'resources' => {
                                       'repository' => {
                                                         'web' => 'https://github.com/mrdvt92/perl-Excel-Writer-XLSX-Simple-Tabs.git',
                                                         'url' => 'git@github.com:mrdvt92/perl-Excel-Writer-XLSX-Simple-Tabs.git',
                                                         'type' => 'git'
                                                       },
                                       'homepage' => 'https://github.com/mrdvt92/perl-Excel-Writer-XLSX-Simple-Tabs',
                                       'bugtracker' => {
                                                         'web' => 'https://github.com/mrdvt92/perl-Excel-Writer-XLSX-Simple-Tabs/issues'
                                                       }
                                     },
                      'meta-spec' => {
                                       'version' => 2
                                     },
                     },
);
