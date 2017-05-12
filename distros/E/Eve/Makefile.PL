use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Eve',
    AUTHOR              => q{Igor Zinovyev <zinigor@gmail.com>},
    VERSION_FROM        => 'lib/Eve.pm',
    ABSTRACT_FROM       => 'lib/Eve.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Contextual::Return' => 0,
        'Test::More' => 0,
        'Test::Class' => 0,
        'PadWalker' => 0,
        'Test::MockObject' => 0,
        'Exception::Class' => 0,
        'Tie::IxHash' => 0,
        'Template' => 0,
        'DateTime' => 0,
        'DBD::Pg' => 0,
        'URI' => 0,
        'CGI::Session' => 0,
        'Email::Sender::Simple' => 0,
        'DateTime::Format::Pg' => 0,
        'DateTime::Format::HTTP' => 0,
        'Hash::MultiValue' => 0,
        'JSON::XS' => 0,
        'Plack::Request' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Eve-*' },
);
