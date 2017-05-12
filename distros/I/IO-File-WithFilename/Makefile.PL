use 5.010001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'IO::File::WithFilename',
    VERSION_FROM      => 'lib/IO/File/WithFilename.pm',
    PREREQ_PM         => {
        'File::Temp' => '0.22',
        'IO::File'   => '1.14',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/IO/File/WithFilename.pm',
       AUTHOR         => 'Ivan Fomichev <ifomichev@cpan.org>') : ()),
);
