use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'EmbedIT::WebIT',
    AUTHOR              => q{Dimitris Evmorfopoulos <devmorfo@gmail.com>},
    VERSION_FROM        => 'lib/EmbedIT/WebIT.pm',
    ABSTRACT_FROM       => 'lib/EmbedIT/WebIT.pm',
                           ($ExtUtils::MakeMaker::VERSION >= 6.3002
                           ? ('LICENSE'=> 'perl')
                           : ()),
    PL_FILES            => {},
    PREREQ_PM           => {
                             'HTTP::Date' => undef,
                             'IO::Select' => undef,
                             'IO::Socket' => undef,
                             'LWP::MediaTypes' => undef,
                             'IPC::Open3' => undef,
                             'Taint::Runtime' => '0.03',
                             'MIME::Base64' => undef,
                             'Test::More' => 0,
                           },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'EmbedIT-WebIT-*' },
);
