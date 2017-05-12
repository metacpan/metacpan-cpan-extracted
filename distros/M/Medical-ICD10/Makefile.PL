use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Medical::ICD10',
    AUTHOR              => q{Spiros Denaxas <s.denaxas@gmail.com>},
    VERSION_FROM        => 'lib/Medical/ICD10.pm',
    ABSTRACT_FROM       => 'lib/Medical/ICD10.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Text::CSV'       => 0,
        'Data::Dumper'    => 0,
        'Class::Accessor' => 0,
        'Graph'           => 0,
        'File::Temp'      => 0,
        'Test::Deep'      => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Medical-ICD10-*' },
);
