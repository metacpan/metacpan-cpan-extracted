use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Exim::SpoolMessage',
    AUTHOR              => q{Kirill Miazine <km@krot.org>},
    VERSION_FROM        => 'lib/Exim/SpoolMessage.pm',
    ABSTRACT_FROM       => 'lib/Exim/SpoolMessage.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'Fcntl' => 0,
        'Mail::Header' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Exim-SpoolMessage-*' },
);
