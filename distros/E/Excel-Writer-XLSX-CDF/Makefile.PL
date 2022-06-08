use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'Excel::Writer::XLSX::CDF',
    VERSION_FROM   => 'lib/Excel/Writer/XLSX/CDF.pm',
    LICENSE        => 'mit',
    PREREQ_PM      => {
                       'Package::New'                    => 0,
                       'List::Util'                      => 0,
                       'List::MoreUtils'                 => 0,
                       'Math::Round::SignificantFigures' => 0,
                       'DateTime'                        => 0,
                       'Excel::Writer::XLSX'             => 0,
                       'File::Temp'                      => 0,
                      },
    ABSTRACT_FROM  => 'lib/Excel/Writer/XLSX/CDF.pm',
    AUTHOR         => 'Michael R. Davis <mdavis@localdomain>',
    META_MERGE     => {
                       'meta-spec' => { 'version' => 2 },
                       'resources' => {
                                       repository => {
                                                      web  => 'https://github.com/mrdvt92/perl-Excel-Writer-XLSX-CDF.git',
                                                      url  => 'git@github.com:mrdvt92/perl-Excel-Writer-XLSX-CDF.git',
                                                      type => 'git',
                                                     },
                                       homepage   => 'https://github.com/mrdvt92/perl-Excel-Writer-XLSX-CDF',
                                       bugtracker => {web => 'https://github.com/mrdvt92/perl-Excel-Writer-XLSX-CDF/issues' },
                                      },
                      },

);
