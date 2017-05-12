use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 't/data';

WriteMakefile(
    NAME             => 'Finance::StockAccount',
    AUTHOR           => q{John Everett Refior <jrefior@gmail.com>},
    VERSION_FROM     => 'lib/Finance/StockAccount.pm',
    ABSTRACT_FROM    => 'lib/Finance/StockAccount.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'File::ShareDir' => 0,
    },
    PREREQ_PM => {
        'Time::Moment'              => 0.07,
        'Carp'                      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Finance-StockAccount-*' },
);

package MY;
use File::ShareDir::Install 'postamble';
