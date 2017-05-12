use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lavoco::Web::App',
    AUTHOR              => q{Rob Brown <rob@intelcompute.com>},
    VERSION_FROM        => 'lib/Lavoco/Web/App.pm',
    ABSTRACT_FROM       => 'lib/Lavoco/Web/App.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'           => 0,
        'Test::Exception'      => 0,
        'Moose'                => 0,
        'Data::Dumper'         => 0,
        'DateTime'             => 0,
        'Email::Stuffer'       => 0,
        'Encode'               => 0,
        'FCGI'                 => 0,
        'File::Slurp'          => 0,
        'FindBin'              => 0,
        'JSON'                 => 0,
        'Log::AutoDump'        => 0,
        'Plack::Handler::FCGI' => 0,
        'Plack::Request'       => 0,
        'Template'             => 0,
        'Term::ANSIColor'      => 0,
        'Time::HiRes'          => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lavoco-Web-App-*' },
);
