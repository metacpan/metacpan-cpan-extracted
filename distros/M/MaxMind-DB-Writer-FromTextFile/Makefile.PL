use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'MaxMind::DB::Writer::FromTextFile',
    VERSION_FROM => 'lib/MaxMind/DB/Writer/FromTextFile.pm',
    PREREQ_PM    => {
        'Net::Works::Network'       => 0.16,
        'MaxMind::DB::Reader'       => 0.050005,
        'MaxMind::DB::Reader::XS'   => 0.060004,
        'MaxMind::DB::Writer'       => 0,
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/MaxMind/DB/Writer/FromTextFile.pm',
            AUTHOR        => 'Chen Gang <yikuyiku.com@gmail.com>'
          )
        : ()
    ),
);
