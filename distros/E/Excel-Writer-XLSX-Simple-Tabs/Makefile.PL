use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::META_MERGE::GitHub;
my $mm = ExtUtils::MakeMaker::META_MERGE::GitHub->new(owner=>"mrdvt92", repo=>"perl-Excel-Writer-XLSX-Simple-Tabs");
WriteMakefile(
    $mm->META_MERGE,
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
);
