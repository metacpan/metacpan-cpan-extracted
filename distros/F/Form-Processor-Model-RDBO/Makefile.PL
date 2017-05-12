use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Form::Processor::Model::RDBO',
    AUTHOR              => 'Viacheslav Tikhanovskii <vti@cpan.org>, Dmitry Zhariy <dzhariy@cpan.org>',
    VERSION_FROM        => 'lib/Form/Processor/Model/RDBO.pm',
    ABSTRACT_FROM       => 'lib/Form/Processor/Model/RDBO.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Form::Processor' => 0,
        'Rose::DB::Object' => 0.774,
        'Test::More' => 0,
        'DBD::SQLite' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Form-Processor-Model-RDBO-*' },
);
