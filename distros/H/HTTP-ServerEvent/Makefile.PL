use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTTP::ServerEvent',
    AUTHOR              => q{Max Maischein <corion@cpan.org>},
    VERSION_FROM        => 'lib/HTTP/ServerEvent.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp'       => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    META_MERGE          => {
        resources           => {
            repository          =>  'https://github.com/Corion/http-serverevent',
        },
    },
);
